// LaunchAtLoginManager.swift
// MikaGrid
//
// Manages Launch at Login via SMAppService (macOS 13+).
// System is source of truth — no UserDefaults needed.

import Observation
import ServiceManagement

@Observable
@MainActor
public final class LaunchAtLoginManager {
    public init() {}


    /// Grund des letzten Fehlschlags, für die Anzeige in den Einstellungen.
    ///
    /// Bis 1.1.1 wurde der Fehler nur auf die Konsole geschrieben: Der Schalter blieb auf „an"
    /// stehen, obwohl das System das Anmeldeobjekt nicht eingerichtet hatte — die Oberfläche
    /// behauptete einen Zustand, den es nicht gab.
    public private(set) var lastError: String?

    public var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    @discardableResult
    public func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            lastError = nil
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }
}
