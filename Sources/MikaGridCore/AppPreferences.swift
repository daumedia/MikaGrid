// AppPreferences.swift
// MikaGrid
//
// User preferences backed by UserDefaults.
// Swift 6.0 strict concurrency, macOS 14+

import Foundation

@Observable
@MainActor
public final class AppPreferences {
    private let defaults = UserDefaults.standard

    public var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }

    public var permissionSkipped: Bool {
        didSet { defaults.set(permissionSkipped, forKey: "permissionSkipped") }
    }

    public init() {
        self.hasCompletedOnboarding = defaults.object(forKey: "hasCompletedOnboarding") as? Bool ?? false
        self.permissionSkipped = defaults.object(forKey: "permissionSkipped") as? Bool ?? false
    }

    /// Eigene Schlüssel. `animationsEnabled` gibt es seit 1.1.1 nicht mehr — der Schlüssel bleibt
    /// gelistet, damit vorhandene Altbestände beim Zurücksetzen aufgeräumt werden.
    private static let ownKeys = [
        "hasCompletedOnboarding", "permissionSkipped", "animationsEnabled",
        "hotkeyBindings", "hotkeyBindingsSchemaVersion",
    ]

    /// Schlüssel von Sparkle in derselben Suite. Ohne sie bliebe nach „Alle Einstellungen
    /// zurücksetzen" insbesondere die unbeaufsichtigte Installation aktiv.
    private static let sparkleKeys = [
        "SUEnableAutomaticChecks", "SUAutomaticallyUpdate", "SUSendProfileInfo",
        "SULastCheckTime", "SUHasLaunchedBefore", "SUSkippedVersion",
        "SULastProfileSubmitDate", "SUUpdateGroupIdentifier",
    ]

    /// Versetzt die App in den Auslieferungszustand.
    ///
    /// Bis 1.1.1 setzte diese Methode `hasCompletedOnboarding` unmittelbar nach dem Löschen
    /// wieder auf `true` — „Alle Einstellungen zurücksetzen" führte damit gerade **nicht** in
    /// den Auslieferungszustand, und das Onboarding erschien nie wieder.
    ///
    /// Das Anmeldeobjekt und die Kürzel setzt `AppState.resetEverything()` zurück; hier stehen
    /// nur die Einstellungen, damit die Fachlogik nicht auf zwei Stellen verteilt ist.
    public func resetAllPreferences() {
        for key in Self.ownKeys + Self.sparkleKeys {
            defaults.removeObject(forKey: key)
        }
        hasCompletedOnboarding = false
        permissionSkipped = false
    }
}
