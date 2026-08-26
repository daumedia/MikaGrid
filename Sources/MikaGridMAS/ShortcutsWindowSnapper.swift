// ShortcutsWindowSnapper.swift
// MikaGrid (App Store)
//
// Erfüllt `WindowSnapping`, ohne ein einziges fremdes Fenster anzufassen (Feature 01,
// T12/T13). Die App rechnet den Zielrahmen und bittet Apples Kurzbefehle, ihn zu setzen.
//
// Genau darauf beruht die Zulässigkeit im App Store: Die Sandbox verbietet die
// Accessibility-API. Diese Fassung bekommt nie Zugriff auf fremde Fenster — sie spricht
// mit einer Systemkomponente, die der Nutzer ausdrücklich autorisiert hat.
// Swift 6.0 strict concurrency, macOS 15+

import AppKit
import MikaGridCore

@Observable
@MainActor
final class ShortcutsWindowSnapper: WindowSnapping {
    private let runner: ShortcutsRunning
    private let companion: CompanionShortcutManager
    private let snapHistory: SnapHistory

    /// Ein Aufruf gleichzeitig. Weitere Auslösungen werden **verworfen, nicht gestapelt**
    /// (EC-05): Zwei überlappende Läufe würden dasselbe Fenster gegeneinander schieben.
    private var isRunning = false

    /// Der `nonce` des laufenden Aufrufs. Eine Antwort ohne ihn gehört zu einem früheren
    /// Aufruf und wird verworfen (design.md, Missbrauchsschutz).
    private(set) var pendingNonce: String?

    private(set) var readiness: SnapReadiness = .ready

    init(runner: ShortcutsRunning, companion: CompanionShortcutManager, snapHistory: SnapHistory) {
        self.runner = runner
        self.companion = companion
        self.snapHistory = snapHistory
        self.readiness = Self.readiness(for: companion.state)
    }

    // MARK: - Snap

    func snap(_ action: SnapAction) -> SnapResult {
        guard !isRunning else { return .busy }

        // Vor JEDEM Aufruf prüfen, nicht nur beim Start: Der Kurzbefehl kann seit dem
        // letzten Snap gelöscht oder ersetzt worden sein (AK-17, AK-18).
        switch companion.refresh() {
        case .installed:
            break
        case .missing:
            readiness = Self.readiness(for: .missing)
            return .companionShortcutMissing
        case .altered:
            readiness = Self.readiness(for: companion.state)
            return .companionShortcutAltered
        case .automationDenied:
            readiness = Self.readiness(for: .automationDenied)
            return .automationDenied
        }

        // „Wiederherstellen" gibt es in dieser Fassung nicht: `Find Windows` liefert die
        // Rahmenwerte eines Fensters nicht zurück, also ist nichts zu merken (OF-02, in
        // T01 gemessen). Zehn der elf Aktionen bleiben.
        guard action != .restore else { return .nothingToRestore }

        // Der Kurzbefehl arbeitet auf dem VORDERSTEN Fenster. Beim Tastenkürzel ist das
        // von selbst die Zielanwendung — beim Klick auf eine Rasterzone aber Mika+Grid
        // selbst, weil das Popover im Stil `.window` die eigene App nach vorn holt (B01).
        // Ohne die folgende Zeile würde dann das Popover gesnappt.
        guard let target = frontmostForeignApp() else { return .noTargetApp }
        if NSWorkspace.shared.frontmostApplication?.bundleIdentifier == Bundle.main.bundleIdentifier {
            target.activate()
            // Kurz Zeit lassen, sonst ist beim Aufruf noch die eigene App vorne.
            Thread.sleep(forTimeInterval: 0.1)
        }
        guard let screen = screenForFrontmostWindow() else { return .noFocusedWindow }
        guard let frame = action.targetFrame(on: screen) else { return .noFocusedWindow }

        let nonce = SnapPayload.makeNonce()
        let payload = SnapPayload(action: action, targetFrame: frame, nonce: nonce)

        isRunning = true
        pendingNonce = nonce
        defer { isRunning = false; pendingNonce = nil }

        switch runner.run(shortcutNamed: CompanionShortcutManager.shortcutName, input: payload.encoded) {
        case .success(let reply):
            return SnapReply.interpret(reply, expecting: nonce)
        case .failure(.notAuthorised):
            readiness = Self.readiness(for: .automationDenied)
            return .automationDenied
        case .failure(.notFound):
            readiness = Self.readiness(for: .missing)
            return .companionShortcutMissing
        case .failure(.timedOut):
            return .timedOut
        case .failure(.other):
            return .noFocusedWindow
        }
    }

    // MARK: - Bereitschaft

    @discardableResult
    func refreshReadiness() -> SnapReadiness {
        readiness = Self.readiness(for: companion.refresh())
        return readiness
    }

    func performReadinessAction() {
        switch companion.state {
        case .missing, .altered:
            companion.beginInstallation()
        case .automationDenied:
            openAutomationSettings()
        case .installed:
            break
        }
    }

    func startMonitoring() { companion.startPolling() }
    func stopMonitoring()  { companion.stopPolling() }

    private static func readiness(for state: CompanionShortcutState) -> SnapReadiness {
        switch state {
        case .installed:
            return .ready
        case .missing:
            return SnapReadiness(
                isReady: false,
                headline: "Companion shortcut is missing",
                detail: "Mika+Grid uses a shortcut to move windows. It takes one click to add it.",
                actionTitle: "Set Up Shortcut"
            )
        case .altered:
            return SnapReadiness(
                isReady: false,
                headline: "Companion shortcut was changed",
                detail: "The shortcut no longer looks the way Mika+Grid created it, so it will not be run.",
                actionTitle: "Set Up Again"
            )
        case .automationDenied:
            return SnapReadiness(
                isReady: false,
                headline: "Permission to control Shortcuts is required",
                detail: "Allow Mika+Grid to control Shortcuts in System Settings › Privacy & Security › Automation.",
                actionTitle: "Open Settings"
            )
        }
    }

    private func openAutomationSettings() {
        let paths = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Automation",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation",
        ]
        for path in paths {
            if let url = URL(string: path), NSWorkspace.shared.open(url) { return }
        }
    }

    // MARK: - Ziel bestimmen

    /// Die vorderste **fremde** Anwendung.
    ///
    /// Nicht Mika+Grid selbst: Das Popover im Stil `.window` macht die eigene App zur
    /// vordersten, sobald es offen ist. Dann zählt die zuletzt aktive fremde (B01).
    private var lastForeignApp: NSRunningApplication?

    func noteActivation(of app: NSRunningApplication) {
        guard app.bundleIdentifier != Bundle.main.bundleIdentifier else { return }
        lastForeignApp = app
    }

    private func frontmostForeignApp() -> NSRunningApplication? {
        let front = NSWorkspace.shared.frontmostApplication
        if let front, front.bundleIdentifier != Bundle.main.bundleIdentifier {
            return front
        }
        return lastForeignApp
    }

    /// Der Bildschirm, auf dem gesnappt wird.
    ///
    /// EINSCHRÄNKUNG (AK-10): Ohne Zugriff auf die Fensterrahmen lässt sich der Bildschirm
    /// des Zielfensters nicht bestimmen — die Direktfassung nimmt dafür den Fenstermittel-
    /// punkt. Hier bleibt nur der Bildschirm mit dem Mauszeiger. In T01 wurde zudem
    /// gemessen, dass `Move Window` keine negativen Koordinaten annimmt; ein Bildschirm
    /// links oder oberhalb des Hauptbildschirms ist so nicht erreichbar (OF-10).
    private func screenForFrontmostWindow() -> NSScreen? {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
    }
}
