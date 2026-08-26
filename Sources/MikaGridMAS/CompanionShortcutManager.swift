// CompanionShortcutManager.swift
// MikaGrid (App Store)
//
// Kümmert sich um den mitgelieferten Kurzbefehl: Ist er da? Sieht er aus wie erwartet?
// Und wenn nicht — ihn zur Installation öffnen. (Feature 01, T11 · AK-17, AK-18, AK-26)
//
// GRENZE DER INTEGRITÄTSPRÜFUNG — bitte lesen, bevor jemand sie für stärker hält:
// Über „Shortcuts Events" sind je Kurzbefehl nur `name`, `action count`, `accepts input`,
// `subtitle`, `folder`, `color` und `icon` lesbar. **Was die Aktionen tun, ist nicht
// lesbar.** Am System geprüft (machbarkeit.md). Diese Prüfung erkennt daher einen
// versehentlich ersetzten oder umgebauten Kurzbefehl, aber keinen absichtlich mit
// gleicher Aktionszahl nachgebauten. AK-26 ist damit nur teilweise erfüllbar — siehe
// OF-11 in spec.md.
// Swift 6.0 strict concurrency, macOS 15+

import AppKit
import MikaGridCore

/// Zustand des Companion-Kurzbefehls.
enum CompanionShortcutState: Equatable {
    /// Vorhanden und so aufgebaut wie erwartet.
    case installed
    /// Nicht in der Mediathek (AK-17).
    case missing
    /// Vorhanden, aber Aufbau weicht ab (AK-18).
    case altered(reason: String)
    /// Die Mediathek war nicht lesbar — meist fehlt die Zustimmung zur Automatisierung.
    case automationDenied
}

@Observable
@MainActor
final class CompanionShortcutManager {
    /// Name in der Mediathek. Muss mit `scripts/make-companion-shortcut.sh` übereinstimmen.
    static let shortcutName = "Mika+Grid Snap"

    /// Erwartete Anzahl Aktionen, **so wie Kurzbefehle sie meldet**.
    ///
    /// Achtung: `action count` liegt reproduzierbar um eins über der Zahl der Aktionen in
    /// der Datei — an mehreren Kurzbefehlen gemessen. Der Wert stammt aus
    /// `scripts/make-companion-shortcut.sh`, das ihn beim Bauen ausgibt. `scripts/make-companion-shortcut.sh` gibt den Wert
    /// beim Bauen aus; ändert sich der Kurzbefehl, gehört die neue Zahl hierher.
    ///
    /// Ein Zahlenwert ist ein schwacher Prüfwert — mehr gibt die Schnittstelle nicht her.
    static let expectedActionCount = 21

    private(set) var state: CompanionShortcutState = .missing

    private var pollTimer: Timer?
    private var pollRequests = 0

    private let runner: ShortcutsRunning

    init(runner: ShortcutsRunning) {
        self.runner = runner
    }

    // MARK: - Prüfen

    /// Ermittelt den Zustand neu. Wird vor jedem Snap aufgerufen: Ein Kurzbefehl, der beim
    /// Start noch da war, kann inzwischen gelöscht oder ersetzt worden sein.
    @discardableResult
    func refresh() -> CompanionShortcutState {
        switch runner.describeShortcut(named: Self.shortcutName) {
        case .success(let description):
            state = Self.evaluate(description)
        case .failure(.notFound):
            state = .missing
        case .failure(.notAuthorised):
            state = .automationDenied
        case .failure(.timedOut), .failure(.other):
            // Im Zweifel nicht behaupten, alles sei in Ordnung: Ein Aufruf gegen einen
            // unbekannten Kurzbefehl ist schlimmer als eine Aufforderung zu viel.
            state = .missing
        }
        return state
    }

    private static func evaluate(_ d: ShortcutDescription) -> CompanionShortcutState {
        // Unmittelbar nach dem Import meldet Kurzbefehle für einige Sekunden `0` — der
        // Kurzbefehl ist da, aber noch nicht geladen. Das als „verändert" zu werten,
        // hieße den Nutzer genau in dem Moment abzuweisen, in dem er ihn gerade
        // hinzugefügt hat. Am System beobachtet.
        guard d.actionCount != 0 else { return .installed }

        guard d.actionCount == expectedActionCount else {
            return .altered(reason: "expected \(expectedActionCount) actions, found \(d.actionCount)")
        }
        guard d.acceptsInput else {
            return .altered(reason: "the shortcut no longer accepts input")
        }
        return .installed
    }

    var isReady: Bool { state == .installed }

    // MARK: - Einrichten

    /// Öffnet die mitgelieferte Datei. Den Import selbst muss der Nutzer bestätigen — ein
    /// Klick auf „Kurzbefehl hinzufügen", der sich nicht umgehen lässt (in T01 geprüft).
    /// Deshalb kann diese Methode nur anstoßen, nicht installieren.
    @discardableResult
    func beginInstallation() -> Bool {
        // Der Dateiname MUSS dem Anzeigenamen entsprechen: Kurzbefehle übernimmt beim
        // Import den Dateinamen, nicht irgendein Feld aus der Datei. Als
        // „MikaGridSnap.shortcut" hieß der Kurzbefehl in der Mediathek „MikaGridSnap"
        // und wurde hier nie gefunden.
        guard let url = Bundle.main.url(forResource: Self.shortcutName, withExtension: "shortcut") else {
            return false
        }
        return NSWorkspace.shared.open(url)
    }

    /// Ein abweichender Name für den Fall, dass der Nutzer schon einen eigenen Kurzbefehl
    /// so genannt hat (EC-02). Fremde Arbeit wird nicht überschrieben.
    static func alternativeName(attempt: Int) -> String {
        "\(shortcutName) \(attempt + 1)"
    }

    // MARK: - Beobachten

    /// Prüft im Sekundentakt, ob der Kurzbefehl aufgetaucht ist.
    ///
    /// Für die Mediathek gibt es keine Benachrichtigung, die man abonnieren könnte —
    /// dasselbe Muster wie bei der Berechtigung in B05. Mehrfachaufrufe werden gezählt.
    func startPolling() {
        pollRequests += 1
        guard pollTimer == nil else { return }
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func stopPolling() {
        pollRequests = max(0, pollRequests - 1)
        guard pollRequests == 0 else { return }
        pollTimer?.invalidate()
        pollTimer = nil
    }
}
