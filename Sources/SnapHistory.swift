// SnapHistory.swift
// MikaGrid
//
// Stores previous window positions for the Restore action.
// Swift 6.0 strict concurrency, macOS 14+

import ApplicationServices
import Foundation

/// Schlüssel eines Fensters in der Positionshistorie.
///
/// Trägt das `AXUIElement` des Fensters selbst. Die Accessibility-API garantiert, dass
/// zwei Referenzen auf dasselbe Fenster `CFEqual` sind — damit ist der Schlüssel stabil,
/// **auch wenn sich der Fenstertitel ändert** (Browser-Tab gewechselt, Datei gespeichert),
/// und zwei titellose Fenster derselben App kollidieren nicht mehr.
///
/// Bis 1.1.1 war der Schlüssel `"<PID>_<Fenstertitel>"`. Das brach bei jeder Titeländerung
/// und legte nebenbei Fenstertitel im Arbeitsspeicher ab, die Personenbezug haben können.
/// Nicht `Sendable`: `AXUIElement` ist es nicht, und der Schlüssel wird ausschließlich auf dem
/// MainActor gebildet und benutzt.
struct WindowKey: Hashable {
    private let element: AXUIElement

    init(_ element: AXUIElement) {
        self.element = element
    }

    static func == (lhs: WindowKey, rhs: WindowKey) -> Bool {
        CFEqual(lhs.element, rhs.element)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(CFHash(element))
    }
}

@MainActor
final class SnapHistory {
    /// Obergrenze der Historie. Ohne sie hinterlässt jedes je gesnappte Fenster dauerhaft
    /// einen Eintrag — bei einer App, die monatelang läuft, ein unbegrenzter Bestand.
    private static let capacity = 100

    private var positions: [WindowKey: CGRect] = [:]
    /// Reihenfolge der Benutzung, ältester zuerst — für die Verdrängung bei Überlauf.
    private var order: [WindowKey] = []

    var count: Int { positions.count }

    func savePosition(_ frame: CGRect, for key: WindowKey) {
        if positions[key] == nil {
            order.append(key)
            if order.count > Self.capacity, let oldest = order.first {
                order.removeFirst()
                positions[oldest] = nil
            }
        }
        positions[key] = frame
    }

    func getPosition(for key: WindowKey) -> CGRect? {
        positions[key]
    }

    /// Verwirft die gesamte Historie. Wird beim Zurücksetzen aller Einstellungen und beim
    /// Entzug der Accessibility-Berechtigung gerufen — in beiden Fällen sind die
    /// gespeicherten Rahmen wertlos oder unerwünscht.
    func clearAll() {
        positions.removeAll()
        order.removeAll()
    }
}
