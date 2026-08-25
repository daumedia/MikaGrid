// WindowManager.swift
// MikaGrid
//
// AXUIElement-based window manipulation for snapping.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit
import ApplicationServices

@MainActor
final class WindowManager {
    private let snapHistory: SnapHistory

    /// Soll/Ist-Toleranz in Punkten: deckt HiDPI-Rundung ab, versteckt aber keinen echten Fehlschlag.
    private static let tolerance: CGFloat = 2.0
    /// Schreibdurchgänge: 1 regulär + 2 Korrekturen.
    private static let maxAttempts = 3
    /// Obergrenze pro AX-Message. Alle Aufrufe laufen synchron auf dem MainActor — ohne Timeout hängt
    /// die Menüleiste mit, sobald die Ziel-App blockiert (Beachball, Debugger-Breakpoint).
    private static let messagingTimeout: Float = 0.25
    /// Harte Obergrenze für einen kompletten Snap inklusive aller Nachkorrekturen.
    private static let deadline: TimeInterval = 0.6
    /// Für `AXEnhancedUserInterface` gibt es keine SDK-Konstante; der Schlüssel ist seit 10.9 stabil.
    private static let enhancedUIAttribute = "AXEnhancedUserInterface" as CFString

    /// Zuletzt aktive FREMDE App. Öffnet man das Menüleisten-Popover, wird Mika+Grid selbst frontmost
    /// (`.menuBarExtraStyle(.window)`) — dann ist `frontmostApplication` unbrauchbar als Snap-Ziel.
    private var lastForeignPID: pid_t?

    /// Beobachter für App-Wechsel, -Ende und Bildschirmänderungen. Werden im `deinit` abgemeldet —
    /// deshalb `nonisolated`, wie beim HotkeyManager: `deinit` läuft außerhalb des MainActors.
    nonisolated(unsafe) private var observers: [NSObjectProtocol] = []

    init(snapHistory: SnapHistory) {
        self.snapHistory = snapHistory
        observeWorkspace()
    }

    deinit {
        for observer in observers {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            NotificationCenter.default.removeObserver(observer)
        }
    }

    @discardableResult
    func snapFrontmostWindow(to action: SnapAction) -> SnapResult {
        guard AXIsProcessTrusted() else { return .missingPermission }
        guard let pid = targetPID() else { return .noTargetApp }

        // Der Timeout gilt laut AXUIElement.h ausschließlich für genau dieses Objekt — also pro Element
        // setzen, nicht einmal global.
        let appElement = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(appElement, Self.messagingTimeout)

        guard let window = focusedWindow(of: appElement) else { return .noFocusedWindow }
        AXUIElementSetMessagingTimeout(window, Self.messagingTimeout)

        guard let currentFrame = frame(of: window) else { return .noFocusedWindow }
        let key = WindowKey(window)

        // Restore greift auf die gespeicherte Position zurück statt auf berechnete Geometrie
        if action == .restore {
            guard let savedFrame = snapHistory.getPosition(for: key) else { return .nothingToRestore }
            return applyFrame(savedFrame, to: window, of: appElement)
        }

        let screen = screenForWindow(currentFrame)
        guard let targetFrame = action.targetFrame(on: screen) else { return .windowNotMovable }

        // Nur sichern, wenn das Fenster NICHT bereits auf einem Snap-Ziel sitzt. Sonst überschriebe
        // ⌃⌥← gefolgt von ⌃⌥→ den ursprünglichen Rahmen mit der linken Hälfte, und Restore führte
        // auf eine Zwischenstation statt auf die von Hand eingestellte Größe.
        if !isSnapTarget(currentFrame, on: screen) {
            snapHistory.savePosition(currentFrame, for: key)
        }
        return applyFrame(targetFrame, to: window, of: appElement)
    }

    // MARK: - Ziel-App

    /// Frontmost-App, außer wir sind es selbst — dann die zuletzt aktive fremde App.
    private func targetPID() -> pid_t? {
        let ownPID = ProcessInfo.processInfo.processIdentifier
        if let front = NSWorkspace.shared.frontmostApplication?.processIdentifier, front != ownPID {
            return front
        }
        return lastForeignPID
    }

    private func observeWorkspace() {
        let center = NSWorkspace.shared.notificationCenter
        let ownPID = ProcessInfo.processInfo.processIdentifier

        observers.append(center.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { notification in
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            guard let pid = app?.processIdentifier, pid != ownPID else { return }
            MainActor.assumeIsolated { self.lastForeignPID = pid }
        })

        // Endet die gemerkte App, zeigt ihre PID ins Leere — und könnte vom System sogar an einen
        // fremden Prozess neu vergeben werden. Deshalb vergessen statt hoffen.
        observers.append(center.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: .main
        ) { notification in
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            guard let pid = app?.processIdentifier else { return }
            MainActor.assumeIsolated {
                if self.lastForeignPID == pid { self.lastForeignPID = nil }
            }
        })

        // Wird ein Monitor abgezogen, ordnet macOS die Fenster neu an: Gespeicherte Rahmen zeigen
        // dann auf Koordinaten, die es nicht mehr gibt.
        observers.append(NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { _ in
            MainActor.assumeIsolated { self.snapHistory.clearAll() }
        })
    }

    // MARK: - Anwenden

    /// Schreibt den Zielrahmen und verifiziert ihn per Read-back.
    ///
    /// Reihenfolge **Size → Position → Size**:
    /// 1. `Size` zuerst, weil ein Positions-Write gegen die AKTUELLE Größe gewichtet wird
    ///    (`NSWindow.constrainFrameRect:toScreen:` hält die Titelleiste im sichtbaren Bereich) — ein
    ///    noch zu großes Fenster lässt sich nicht an die Zielkante schieben.
    /// 2. `Position` danach: das Fenster hat jetzt die Zielgröße, der Wert wird nicht mehr beschnitten.
    /// 3. `Size` erneut: Apps, die beim Move die Größe nachziehen (Chromium clamped die Breite auf den
    ///    Platz rechts vom Ursprung), werden korrigiert.
    ///
    /// Danach Read-back und bis zu `maxAttempts` Durchgänge. Abbruch bei Stillstand (zwei identische
    /// Messungen ⇒ die App KANN den Rahmen nicht erfüllen: Mindestgröße, Zeichenraster im Terminal)
    /// und bei Überschreiten von `deadline`.
    private func applyFrame(_ target: CGRect, to window: AXUIElement, of appElement: AXUIElement) -> SnapResult {
        // Vollbild ausdrücklich prüfen: Ein Vollbildfenster meldet Position und Größe teils als
        // setzbar, ignoriert die Werte aber — der Snap liefe ins Leere, ohne dass es auffiele.
        guard !isFullScreen(window) else { return .windowNotMovable }

        // Dialoge und nicht größenveränderbare Fenster gar nicht erst anfassen
        guard isSettable(kAXPositionAttribute, on: window),
              isSettable(kAXSizeAttribute, on: window) else { return .windowNotMovable }

        // Ist Enhanced UI aktiv, ANIMIERT AppKit die AX-Rahmenänderung — genau dann landet beim ersten
        // Auslösen nur die Größe. Für die Dauer der Writes aus, danach IMMER zurück (VoiceOver!).
        let hadEnhancedUI = enhancedUIEnabled(on: appElement)
        if hadEnhancedUI { setEnhancedUI(false, on: appElement) }
        defer { if hadEnhancedUI { setEnhancedUI(true, on: appElement) } }

        let expiry = Date().addingTimeInterval(Self.deadline)
        var previous: CGRect?

        for _ in 0 ..< Self.maxAttempts {
            write(size: target.size, to: window)
            write(position: target.origin, to: window)
            write(size: target.size, to: window)

            guard let actual = frame(of: window) else { return .noFocusedWindow }
            if actual.isNear(target, tolerance: Self.tolerance) { return .applied }
            if let previous, actual.isNear(previous, tolerance: 0.5) { return .applied }  // Stillstand
            if Date() >= expiry { return .applied }
            previous = actual
        }
        return .applied
    }

    private func write(position: CGPoint, to window: AXUIElement) {
        var point = position
        guard let value = AXValueCreate(.cgPoint, &point) else { return }
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, value)
    }

    private func write(size: CGSize, to window: AXUIElement) {
        var newSize = size
        guard let value = AXValueCreate(.cgSize, &newSize) else { return }
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, value)
    }

    // MARK: - Enhanced User Interface

    /// `AXEnhancedUserInterface` sitzt am APP-Element, nicht am Fenster. Gesetzt von VoiceOver und von
    /// Chromium-/Electron-/Java-Apps mit aktivem Accessibility-Modus.
    private func enhancedUIEnabled(on appElement: AXUIElement) -> Bool {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, Self.enhancedUIAttribute, &ref) == .success,
              let enabled = ref as? Bool
        else { return false }
        return enabled
    }

    /// `NSNumber(value:)` statt `kCFBooleanTrue`: der CF-Globale ist unter Swift-6-Strict-Concurrency
    /// kein nebenläufigkeitssicherer Zugriff. Zur Laufzeit ist es dasselbe `__NSCFBoolean`-Singleton.
    private func setEnhancedUI(_ enabled: Bool, on appElement: AXUIElement) {
        AXUIElementSetAttributeValue(appElement, Self.enhancedUIAttribute, NSNumber(value: enabled) as CFTypeRef)
    }

    // MARK: - Accessibility read

    private func focusedWindow(of appElement: AXUIElement) -> AXUIElement? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &ref) == .success,
              let value = ref,
              CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return (value as! AXUIElement)  // Typ via CFGetTypeID geprüft
    }

    private func frame(of window: AXUIElement) -> CGRect? {
        var posRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posRef) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef) == .success,
              let posValue = posRef, CFGetTypeID(posValue) == AXValueGetTypeID(),
              let sizeValue = sizeRef, CFGetTypeID(sizeValue) == AXValueGetTypeID()
        else { return nil }

        var origin = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(posValue as! AXValue, .cgPoint, &origin),
              AXValueGetValue(sizeValue as! AXValue, .cgSize, &size) else { return nil }
        return CGRect(origin: origin, size: size)  // AX/Quartz-Koordinaten (top-left)
    }

    private func isSettable(_ attribute: String, on window: AXUIElement) -> Bool {
        var settable: DarwinBoolean = false
        guard AXUIElementIsAttributeSettable(window, attribute as CFString, &settable) == .success
        else { return false }
        return settable.boolValue
    }

    /// `kAXFullScreenAttribute` ist nicht in allen SDK-Fassungen als Konstante vorhanden; der
    /// Attributname ist seit 10.7 stabil.
    private func isFullScreen(_ window: AXUIElement) -> Bool {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, "AXFullScreen" as CFString, &ref) == .success,
              let value = ref as? Bool else { return false }
        return value
    }

    // MARK: - Screens & Keys

    private func screenForWindow(_ axFrame: CGRect) -> NSScreen {
        // AX-Mittelpunkt (top-left) → NSScreen-Koordinaten (bottom-left)
        let primaryHeight = NSScreen.primaryHeight ?? 0
        let center = CGPoint(x: axFrame.midX, y: primaryHeight - axFrame.midY)
        for screen in NSScreen.screens where screen.frame.contains(center) { return screen }
        return NSScreen.main ?? NSScreen.screens[0]
    }

    /// Sitzt der Rahmen bereits auf einem der zehn Snap-Ziele dieses Bildschirms?
    private func isSnapTarget(_ frame: CGRect, on screen: NSScreen) -> Bool {
        for action in SnapAction.allCases {
            guard let target = action.targetFrame(on: screen) else { continue }
            if frame.isNear(target, tolerance: Self.tolerance) { return true }
        }
        return false
    }
}

// MARK: - Helpers

extension NSScreen {
    /// Höhe des Screens am globalen Ursprung (0,0) — Basis jeder Cocoa↔AX-Umrechnung.
    /// `NSScreen.screens.first` ist NICHT garantiert dieser Screen (Anordnung in den Systemeinstellungen).
    ///
    /// `nil`, wenn sich kein Bildschirm bestimmen lässt. Ein stiller Rückfall auf 0 machte jede
    /// Koordinatenumrechnung falsch, statt den Snap erkennbar abzubrechen.
    static var primaryHeight: CGFloat? {
        (NSScreen.screens.first { $0.frame.origin == .zero } ?? NSScreen.screens.first)?.frame.height
    }
}

extension CGRect {
    /// Kantenweiser Soll/Ist-Vergleich mit Punkt-Toleranz.
    func isNear(_ other: CGRect, tolerance: CGFloat) -> Bool {
        abs(minX - other.minX) <= tolerance
            && abs(minY - other.minY) <= tolerance
            && abs(width - other.width) <= tolerance
            && abs(height - other.height) <= tolerance
    }
}
