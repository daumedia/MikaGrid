// SnapResult.swift
// MikaGrid
//
// Ergebnis eines Snap-Versuchs — damit ein Fehlschlag nicht stillschweigend verpufft.
// Swift 6.0 strict concurrency, macOS 14+

import Foundation

/// Warum ein Snap nichts bewirkt hat.
///
/// Bis 1.1.1 endeten alle Abbruchpfade mit einem stillen `return`: Aus Nutzersicht waren
/// sechs sehr verschiedene Ursachen nicht unterscheidbar — es passierte einfach nichts.
enum SnapResult: Equatable, Sendable {
    case applied
    /// Die Accessibility-Berechtigung fehlt. Der einzige Fall, den der Nutzer selbst beheben kann.
    case missingPermission
    /// Keine fremde App als Ziel bekannt (nur Mika+Grid war bisher aktiv).
    case noTargetApp
    /// Die Ziel-App hat kein fokussiertes Fenster oder antwortet nicht.
    case noFocusedWindow
    /// Vollbild, modaler Dialog oder ein Fenster fester Größe.
    case windowNotMovable
    /// Es gibt keine gespeicherte Position zum Wiederherstellen.
    case nothingToRestore

    var isSuccess: Bool { self == .applied }

    /// Kurzer Hinweistext für die Oberfläche. `nil`, wo eine Meldung nur stören würde.
    var message: String? {
        switch self {
        case .applied:          return nil
        case .missingPermission: return "Accessibility permission required"
        case .noTargetApp:      return "No window to snap"
        case .noFocusedWindow:  return "That app has no window to snap"
        case .windowNotMovable: return "This window can't be moved"
        case .nothingToRestore: return "Nothing to restore"
        }
    }
}
