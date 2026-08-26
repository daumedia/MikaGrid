// AppState.swift
// MikaGridCore
//
// Central observable state for the app.
//
// Seit Feature 01 gemeinsam für beide Fassungen: Wie ein Fenster tatsächlich bewegt wird,
// steht hinter `WindowSnapping` und wird beim Start hineingegeben. Ob die App gerade über
// die Accessibility-API arbeitet oder über Kurzbefehle, ist hier nicht mehr sichtbar.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit
import SwiftUI

@Observable
@MainActor
public final class AppState {
    public let preferences = AppPreferences()
    public let launchAtLoginManager = LaunchAtLoginManager()
    public let snapHistory = SnapHistory()

    /// Die austauschbare Stelle: AX-Umsetzung im Direktziel, Kurzbefehle im Store-Ziel.
    public private(set) var snapper: (any WindowSnapping)?
    /// Nur im Direktvertrieb belegt — die Store-Fassung wird über den App Store aktualisiert.
    public private(set) var updater: (any UpdateChecking)?

    public var hotkeyManager: HotkeyManager?

    /// Meldung des letzten fehlgeschlagenen Snaps, für die Anzeige im Popover.
    /// Wird nach `feedbackDuration` von selbst wieder geleert.
    public private(set) var snapFeedback: String?
    private var feedbackTask: Task<Void, Never>?
    private static let feedbackDuration: Duration = .seconds(4)

    public init() {}

    /// Bereitschaft der aktiven Fassung. Ohne Snapper gilt „nicht bereit" — sonst
    /// verspräche die Oberfläche etwas, wofür es keine Umsetzung gibt.
    public var readiness: SnapReadiness {
        snapper?.readiness ?? SnapReadiness(
            isReady: false,
            headline: "Not ready",
            detail: "Window snapping is not available.",
            actionTitle: nil
        )
    }

    /// Gibt die Umsetzung hinein und verdrahtet die Tastenkürzel.
    ///
    /// Der Aufrufer ist das jeweilige App-Ziel: Es weiß als einziges, welche Fassung läuft.
    public func setup(snapper: any WindowSnapping, updater: (any UpdateChecking)? = nil) {
        self.snapper = snapper
        self.updater = updater

        self.hotkeyManager = HotkeyManager { [weak self] action in
            self?.performSnap(action)
        }
    }

    /// Der einzige Weg, einen Snap auszulösen — Tastenkürzel wie Popover-Klick.
    ///
    /// Bis 1.1.1 riefen beide direkt den `WindowManager` und verwarfen das Ergebnis: Ein
    /// fehlgeschlagener Snap war von einem gelungenen nicht zu unterscheiden. Jetzt gibt es
    /// bei jedem Fehlschlag einen Systemton und, solange das Popover offen ist, einen Grund.
    public func performSnap(_ action: SnapAction) {
        guard let result = snapper?.snap(action) else { return }
        guard !result.isSuccess else {
            clearFeedback()
            return
        }

        NSSound.beep()

        // Bei fehlender Berechtigung ist die Anzeige im Popover ohnehin schon eindeutig —
        // trotzdem den Zustand auffrischen, damit Ampel und Banner sofort stimmen.
        if result == .missingPermission || result == .companionShortcutMissing
            || result == .companionShortcutAltered || result == .automationDenied {
            snapper?.refreshReadiness()
        }

        guard let message = result.message else { return }
        showFeedback(message)
    }

    private func showFeedback(_ message: String) {
        feedbackTask?.cancel()
        snapFeedback = message
        feedbackTask = Task { [weak self] in
            try? await Task.sleep(for: Self.feedbackDuration)
            guard !Task.isCancelled else { return }
            self?.snapFeedback = nil
        }
    }

    private func clearFeedback() {
        feedbackTask?.cancel()
        feedbackTask = nil
        snapFeedback = nil
    }

    /// Setzt alles zurück, was ein Zurücksetzen der Einstellungen betrifft — an einer Stelle,
    /// damit kein Aufrufer einen Teil vergisst.
    public func resetEverything() {
        preferences.resetAllPreferences()
        launchAtLoginManager.setEnabled(false)
        snapHistory.clearAll()
        hotkeyManager?.restoreDefaults()
        clearFeedback()
    }
}
