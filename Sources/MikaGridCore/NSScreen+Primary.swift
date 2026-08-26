// NSScreen+Primary.swift
// MikaGridCore
//
// Bezugshöhe für jede Cocoa↔AX-Umrechnung. Lag bis Feature 01 in `WindowManager`; da
// `SnapAction.targetFrame` sie braucht und die Zielgeometrie für beide Fassungen dieselbe
// Wahrheit ist, gehört sie in die gemeinsame Bibliothek.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit

public extension NSScreen {
    /// Höhe des Screens am globalen Ursprung (0,0) — Basis jeder Cocoa↔AX-Umrechnung.
    /// `NSScreen.screens.first` ist NICHT garantiert dieser Screen (Anordnung in den Systemeinstellungen).
    ///
    /// `nil`, wenn sich kein Bildschirm bestimmen lässt. Ein stiller Rückfall auf 0 machte jede
    /// Koordinatenumrechnung falsch, statt den Snap erkennbar abzubrechen.
    static var primaryHeight: CGFloat? {
        (NSScreen.screens.first { $0.frame.origin == .zero } ?? NSScreen.screens.first)?.frame.height
    }
}

public extension CGRect {
    /// Kantenweiser Soll/Ist-Vergleich mit Punkt-Toleranz.
    ///
    /// Gehört zur Zielgeometrie und wird von den Tests geprüft — deshalb in der
    /// gemeinsamen Bibliothek und nicht in der AX-Umsetzung des Direktziels.
    func isNear(_ other: CGRect, tolerance: CGFloat) -> Bool {
        abs(minX - other.minX) <= tolerance
            && abs(minY - other.minY) <= tolerance
            && abs(width - other.width) <= tolerance
            && abs(height - other.height) <= tolerance
    }
}
