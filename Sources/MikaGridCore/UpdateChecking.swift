// UpdateChecking.swift
// MikaGridCore
//
// Selbstaktualisierung, so weit die gemeinsame Oberfläche sie kennen muss (Feature 01, T09).
//
// Nur die Direktfassung aktualisiert sich selbst — über Sparkle (B08). Die Store-Fassung
// bekommt ihre Updates aus dem App Store und liefert Sparkle gar nicht erst mit (AK-02).
// Damit die Einstellungen trotzdem in der gemeinsamen Bibliothek liegen können, ist der
// Aktualisierer hinter dieser Schnittstelle versteckt und im Store-Ziel schlicht `nil`.
// Swift 6.0 strict concurrency, macOS 14+

import Foundation

/// Was die Einstellungen über die Selbstaktualisierung wissen müssen.
///
/// Bewusst schmal: alles, was Sparkle darüber hinaus kann, bleibt im Direktziel.
@MainActor
public protocol UpdateChecking: AnyObject {
    /// Ob gerade geprüft werden kann — Sparkle sperrt das während eines laufenden Vorgangs.
    var canCheckForUpdates: Bool { get }
    var automaticallyChecksForUpdates: Bool { get set }
    /// Ob gefundene Updates von selbst geladen und installiert werden.
    var automaticallyDownloadsUpdates: Bool { get set }
    var lastUpdateCheckDate: Date? { get }
    /// Grund des letzten fehlgeschlagenen Prüflaufs, sonst `nil`.
    ///
    /// Bis 1.1.1 blieb ein dauerhaft toter Update-Weg unbemerkt und sah für den Nutzer aus
    /// wie „ich bin aktuell" (B08).
    var lastCheckError: String? { get }
    func checkForUpdates()
}
