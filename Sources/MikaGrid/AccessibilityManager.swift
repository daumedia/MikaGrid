// AccessibilityManager.swift
// MikaGrid
//
// Accessibility permission check and request.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit
@preconcurrency import ApplicationServices
import MikaGridCore

@Observable
@MainActor
final class AccessibilityManager {
    private(set) var isGranted: Bool = false
    private var pollTimer: Timer?
    /// Wie viele Stellen gerade eine laufende Abfrage brauchen (Onboarding-Schritt, offenes
    /// Popover, Einstellungen). Der Takt läuft, solange mindestens eine davon sichtbar ist —
    /// und keine Sekunde länger.
    private var pollRequests = 0

    /// Wird gerufen, wenn sich der Zustand ändert. `AppState` nutzt das, um ein früheres
    /// „Skip for now" zurückzunehmen, sobald die Berechtigung tatsächlich vorliegt.
    var onChange: ((Bool) -> Void)?

    init() {
        checkPermission()
    }

    @discardableResult
    func checkPermission() -> Bool {
        let granted = AXIsProcessTrusted()
        if granted != isGranted {
            isGranted = granted
            onChange?(granted)
        }
        return granted
    }

    /// Löst den Systemdialog aus und übernimmt das Ergebnis sofort.
    ///
    /// Bis 1.1.1 wurde der Rückgabewert verworfen: Danach stand `isGranted` womöglich noch auf
    /// `false`, obwohl das System bereits zugestimmt hatte.
    @discardableResult
    func requestPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        let granted = AXIsProcessTrustedWithOptions(options)
        if granted != isGranted {
            isGranted = granted
            onChange?(granted)
        }
        return granted
    }

    /// Öffnet die Systemeinstellungen im Bereich Bedienungshilfen.
    ///
    /// Ab macOS 13 heißt der Bereich `com.apple.settings.PrivacySecurity.extension`. Die alte
    /// Kennung wird bislang weitergeleitet, aber das ist nicht zugesichert — deshalb zuerst die
    /// aktuelle, und nur bei Fehlschlag die alte.
    func openSystemSettings() {
        let paths = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
        ]
        for path in paths {
            if let url = URL(string: path), NSWorkspace.shared.open(url) { return }
        }
    }

    /// Beginnt die Abfrage im Sekundentakt. Für TCC-Änderungen gibt es keine Benachrichtigung,
    /// die man abonnieren könnte — Abfragen ist der einzige Weg.
    ///
    /// Mehrere Aufrufer sind erlaubt und werden gezählt; der Takt endet erst, wenn sich alle
    /// wieder abgemeldet haben.
    func startPolling() {
        pollRequests += 1
        guard pollTimer == nil else { return }
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPermission()
            }
        }
    }

    func stopPolling() {
        pollRequests = max(0, pollRequests - 1)
        guard pollRequests == 0 else { return }
        pollTimer?.invalidate()
        pollTimer = nil
    }
}
