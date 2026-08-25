// AppState.swift
// MikaGrid
//
// Central observable state for the app.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit
import SwiftUI

@Observable
@MainActor
final class AppState {
    let preferences = AppPreferences()
    let launchAtLoginManager = LaunchAtLoginManager()
    let accessibilityManager = AccessibilityManager()
    let snapHistory = SnapHistory()
    let sparkleUpdater = SparkleUpdater()

    var windowManager: WindowManager?
    var hotkeyManager: HotkeyManager?

    /// Meldung des letzten fehlgeschlagenen Snaps, für die Anzeige im Popover.
    /// Wird nach `feedbackDuration` von selbst wieder geleert.
    private(set) var snapFeedback: String?
    private var feedbackTask: Task<Void, Never>?
    private static let feedbackDuration: Duration = .seconds(4)

    func setup() {
        // Ein früheres „Skip for now" ist gegenstandslos, sobald die Berechtigung vorliegt.
        // Ohne diese Rücknahme fragte die App nie wieder nach — auch dann nicht, wenn der Nutzer
        // die Zustimmung Monate später wieder entzieht.
        accessibilityManager.onChange = { [weak self] granted in
            guard let self else { return }
            if granted, self.preferences.permissionSkipped {
                self.preferences.permissionSkipped = false
            }
            if !granted {
                // Gespeicherte Rahmen sind ohne Berechtigung ohnehin nicht anwendbar.
                self.snapHistory.clearAll()
            }
        }

        let wm = WindowManager(snapHistory: snapHistory)
        self.windowManager = wm

        self.hotkeyManager = HotkeyManager { [weak self] action in
            self?.performSnap(action)
        }
    }

    /// Der einzige Weg, einen Snap auszulösen — Tastenkürzel wie Popover-Klick.
    ///
    /// Bis 1.1.1 riefen beide direkt den `WindowManager` und verwarfen das Ergebnis: Ein
    /// fehlgeschlagener Snap war von einem gelungenen nicht zu unterscheiden. Jetzt gibt es
    /// bei jedem Fehlschlag einen Systemton und, solange das Popover offen ist, einen Grund.
    func performSnap(_ action: SnapAction) {
        guard let result = windowManager?.snapFrontmostWindow(to: action) else { return }
        guard !result.isSuccess else {
            clearFeedback()
            return
        }

        NSSound.beep()

        // Bei fehlender Berechtigung ist die Anzeige im Popover ohnehin schon eindeutig —
        // trotzdem den Zustand auffrischen, damit Ampel und Banner sofort stimmen.
        if result == .missingPermission {
            accessibilityManager.checkPermission()
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
    func resetEverything() {
        preferences.resetAllPreferences()
        launchAtLoginManager.setEnabled(false)
        snapHistory.clearAll()
        hotkeyManager?.restoreDefaults()
        clearFeedback()
    }
}
