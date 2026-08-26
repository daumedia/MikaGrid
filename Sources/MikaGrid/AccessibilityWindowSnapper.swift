// AccessibilityWindowSnapper.swift
// MikaGrid (Direct)
//
// Erfüllt `WindowSnapping` mit dem vorhandenen Weg: die App bewegt Fenster selbst über die
// Accessibility-API (Feature 01, T09).
//
// Diese Datei fügt kein Verhalten hinzu. Sie bündelt, was bis 1.2.0 direkt in `AppState`
// stand — `WindowManager` für die Bewegung, `AccessibilityManager` für die Berechtigung —
// hinter der Schnittstelle, die sich die Store-Fassung mit ihr teilt.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit
import MikaGridCore

@Observable
@MainActor
final class AccessibilityWindowSnapper: WindowSnapping {
    private let windowManager: WindowManager
    let accessibilityManager: AccessibilityManager
    private let snapHistory: SnapHistory

    private(set) var readiness: SnapReadiness = .ready

    init(snapHistory: SnapHistory, preferences: AppPreferences) {
        self.snapHistory = snapHistory
        self.windowManager = WindowManager(snapHistory: snapHistory)
        self.accessibilityManager = AccessibilityManager()

        // Ein früheres „Skip for now" ist gegenstandslos, sobald die Berechtigung vorliegt.
        // Ohne diese Rücknahme fragte die App nie wieder nach — auch dann nicht, wenn der
        // Nutzer die Zustimmung Monate später wieder entzieht.
        accessibilityManager.onChange = { [weak self, weak preferences] granted in
            guard let self else { return }
            if granted, preferences?.permissionSkipped == true {
                preferences?.permissionSkipped = false
            }
            if !granted {
                // Gespeicherte Rahmen sind ohne Berechtigung ohnehin nicht anwendbar.
                self.snapHistory.clearAll()
            }
            self.readiness = Self.readiness(granted: granted)
        }

        self.readiness = Self.readiness(granted: accessibilityManager.isGranted)
    }

    func snap(_ action: SnapAction) -> SnapResult {
        windowManager.snapFrontmostWindow(to: action)
    }

    @discardableResult
    func refreshReadiness() -> SnapReadiness {
        let granted = accessibilityManager.checkPermission()
        readiness = Self.readiness(granted: granted)
        return readiness
    }

    func performReadinessAction() {
        accessibilityManager.openSystemSettings()
    }

    func startMonitoring() { accessibilityManager.startPolling() }
    func stopMonitoring()  { accessibilityManager.stopPolling() }

    private static func readiness(granted: Bool) -> SnapReadiness {
        guard !granted else { return .ready }
        return SnapReadiness(
            isReady: false,
            headline: "Accessibility permission required",
            detail: "Mika+Grid needs permission to move windows of other apps.",
            actionTitle: "Open Settings"
        )
    }
}
