// WindowSnapping.swift
// MikaGridCore
//
// Die einzige Naht zwischen den beiden Fassungen (Feature 01, T09).
//
// Oberhalb dieser Schnittstelle ist nicht erkennbar, ob die App Fenster selbst über die
// Accessibility-API bewegt (Direktvertrieb) oder Apples Kurzbefehle darum bittet
// (App Store). Popover, Tastenkürzel und Fehlermeldungen bleiben deshalb ungeteilt.
//
// Warum eine Schnittstelle und keine bedingte Übersetzung (`#if APP_STORE`):
// Bedingte Übersetzung verstreut den Unterschied über die ganze Datei und lässt sich nicht
// prüfen — es liefe immer nur ein Zweig. So ist der Unterschied genau eine austauschbare
// Stelle, und beide Erfüllungen sind einzeln testbar (design.md, Entscheidung 1).
// Swift 6.0 strict concurrency, macOS 14+

import Foundation

/// Ob gesnappt werden kann — und was dem Nutzer sonst zu sagen ist.
///
/// Beide Fassungen sind aus verschiedenen Gründen nicht bereit: der Direktfassung fehlt
/// womöglich die Bedienungshilfen-Berechtigung, der Store-Fassung der Companion-Shortcut
/// oder die Zustimmung zur Automatisierung. Für die Oberfläche ist das derselbe Zustand
/// mit anderem Text — deshalb trägt er den Text mit sich, statt ihn erraten zu lassen.
public struct SnapReadiness: Equatable, Sendable {
    /// Kann die App gerade Fenster bewegen?
    public let isReady: Bool
    /// Kurze Überschrift für das Hinweisband, etwa „Accessibility permission required".
    public let headline: String
    /// Ein Satz, der erklärt, was zu tun ist.
    public let detail: String
    /// Beschriftung der Schaltfläche, oder `nil`, wenn es nichts zu tun gibt.
    public let actionTitle: String?

    public init(isReady: Bool, headline: String, detail: String, actionTitle: String?) {
        self.isReady = isReady
        self.headline = headline
        self.detail = detail
        self.actionTitle = actionTitle
    }

    /// Alles in Ordnung — kein Hinweis nötig.
    public static let ready = SnapReadiness(
        isReady: true, headline: "", detail: "", actionTitle: nil
    )
}

/// Bewegt das vorderste Fenster. Erfüllt von `AccessibilityWindowSnapper` (Direkt) und
/// `ShortcutsWindowSnapper` (App Store).
@MainActor
public protocol WindowSnapping: AnyObject {
    /// Führt die Aktion aus. Das Ergebnis ist nie stillschweigend — jeder Abbruchpfad
    /// trägt seinen Grund (B01/B05, `SnapResult`).
    func snap(_ action: SnapAction) -> SnapResult

    /// Zuletzt ermittelter Bereitschaftszustand. Wird beobachtet, also günstig zu lesen.
    var readiness: SnapReadiness { get }

    /// Zustand neu ermitteln. Gibt das Ergebnis zurück, damit der Aufrufer nicht raten muss.
    @discardableResult
    func refreshReadiness() -> SnapReadiness

    /// Führt aus, was `readiness.actionTitle` verspricht — Systemeinstellungen öffnen,
    /// Shortcut einrichten, je nach Fassung.
    func performReadinessAction()

    /// Beginnt, den Zustand im Sekundentakt zu verfolgen, solange etwas davon sichtbar ist.
    ///
    /// Weder für TCC-Änderungen noch für die Kurzbefehle-Mediathek gibt es eine
    /// Benachrichtigung, die man abonnieren könnte. Abfragen ist der einzige Weg.
    /// Mehrfachaufrufe werden gezählt; der Takt endet, wenn sich alle abgemeldet haben.
    func startMonitoring()
    func stopMonitoring()
}
