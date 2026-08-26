// SnapAction.swift
// MikaGrid
//
// Enum of all snap actions with geometry calculations and default key bindings.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit
import Carbon

public enum SnapAction: String, CaseIterable, Identifiable, Sendable {
    case leftHalf
    case rightHalf
    case topHalf
    case bottomHalf
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case maximize
    case center
    case restore

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .leftHalf:    return "Left Half"
        case .rightHalf:   return "Right Half"
        case .topHalf:     return "Top Half"
        case .bottomHalf:  return "Bottom Half"
        case .topLeft:     return "Top Left"
        case .topRight:    return "Top Right"
        case .bottomLeft:  return "Bottom Left"
        case .bottomRight: return "Bottom Right"
        case .maximize:    return "Maximize"
        case .center:      return "Center"
        case .restore:     return "Restore"
        }
    }

    public var systemImage: String {
        switch self {
        case .leftHalf:    return "rectangle.lefthalf.filled"
        case .rightHalf:   return "rectangle.righthalf.filled"
        case .topHalf:     return "rectangle.tophalf.filled"
        case .bottomHalf:  return "rectangle.bottomhalf.filled"
        case .topLeft:     return "rectangle.inset.topleft.filled"
        case .topRight:    return "rectangle.inset.topright.filled"
        case .bottomLeft:  return "rectangle.inset.bottomleft.filled"
        case .bottomRight: return "rectangle.inset.bottomright.filled"
        case .maximize:    return "rectangle.fill"
        case .center:      return "rectangle.center.inset.filled"
        case .restore:     return "arrow.uturn.backward"
        }
    }

    public var hotkeyID: UInt32 {
        switch self {
        case .leftHalf:    return 1
        case .rightHalf:   return 2
        case .topHalf:     return 3
        case .bottomHalf:  return 4
        case .topLeft:     return 5
        case .topRight:    return 6
        case .bottomLeft:  return 7
        case .bottomRight: return 8
        case .maximize:    return 9
        case .center:      return 10
        case .restore:     return 11
        }
    }

    public var defaultBinding: HotkeyBinding {
        let ctrlOpt = UInt32(controlKey | optionKey)
        switch self {
        case .leftHalf:    return HotkeyBinding(keyCode: 0x7B, modifiers: ctrlOpt)  // ⌃⌥←
        case .rightHalf:   return HotkeyBinding(keyCode: 0x7C, modifiers: ctrlOpt)  // ⌃⌥→
        case .topHalf:     return HotkeyBinding(keyCode: 0x7E, modifiers: ctrlOpt)  // ⌃⌥↑
        case .bottomHalf:  return HotkeyBinding(keyCode: 0x7D, modifiers: ctrlOpt)  // ⌃⌥↓
        case .topLeft:     return HotkeyBinding(keyCode: 0x20, modifiers: ctrlOpt)  // ⌃⌥U
        case .topRight:    return HotkeyBinding(keyCode: 0x22, modifiers: ctrlOpt)  // ⌃⌥I
        case .bottomLeft:  return HotkeyBinding(keyCode: 0x26, modifiers: ctrlOpt)  // ⌃⌥J
        case .bottomRight: return HotkeyBinding(keyCode: 0x28, modifiers: ctrlOpt)  // ⌃⌥K
        case .maximize:    return HotkeyBinding(keyCode: 0x24, modifiers: ctrlOpt)  // ⌃⌥↩
        case .center:      return HotkeyBinding(keyCode: 0x08, modifiers: ctrlOpt)  // ⌃⌥C
        case .restore:     return HotkeyBinding(keyCode: 0x33, modifiers: ctrlOpt)  // ⌃⌥⌫
        }
    }

    /// Zielrahmen für diese Aktion auf dem gegebenen Bildschirm, in AX-Koordinaten
    /// (Ursprung oben links). `nil` für `.restore` (kommt aus der History) und dann, wenn
    /// sich die Bezugshöhe nicht bestimmen lässt.
    public func targetFrame(on screen: NSScreen) -> CGRect? {
        guard let primaryHeight = NSScreen.primaryHeight else { return nil }
        return targetFrame(visibleFrame: screen.visibleFrame, primaryHeight: primaryHeight)
    }

    /// Reine Rechnung ohne Systemzugriff — der testbare Kern von `targetFrame(on:)`.
    ///
    /// - Parameters:
    ///   - visible: nutzbarer Bereich des Zielbildschirms in Cocoa-Koordinaten (Ursprung unten links)
    ///   - primaryHeight: Höhe des Bildschirms am globalen Ursprung (0,0) — Basis der Umrechnung
    ///   - rounding: Kanten auf ganze Punkte runden. Für echte Bildschirmmaße immer `true`;
    ///     `previewRect` rechnet im Einheitsquadrat und muss ungerundet bleiben.
    public func targetFrame(visibleFrame visible: CGRect, primaryHeight: CGFloat, rounding: Bool = true) -> CGRect? {
        if self == .restore { return nil }

        // Cocoa (unten links) → AX (oben links)
        let left   = visible.minX
        let right  = visible.maxX
        let top    = primaryHeight - visible.maxY
        let bottom = top + visible.height
        let midX   = left + visible.width / 2
        let midY   = top + visible.height / 2

        switch self {
        case .leftHalf:    return Self.rect(left, top,  midX,  bottom, rounding)
        case .rightHalf:   return Self.rect(midX, top,  right, bottom, rounding)
        case .topHalf:     return Self.rect(left, top,  right, midY, rounding)
        case .bottomHalf:  return Self.rect(left, midY, right, bottom, rounding)
        case .topLeft:     return Self.rect(left, top,  midX,  midY, rounding)
        case .topRight:    return Self.rect(midX, top,  right, midY, rounding)
        case .bottomLeft:  return Self.rect(left, midY, midX,  bottom, rounding)
        case .bottomRight: return Self.rect(midX, midY, right, bottom, rounding)
        case .maximize:    return Self.rect(left, top,  right, bottom, rounding)
        case .center:
            let insetX = visible.width / 6   // (1 − 2/3) / 2 → bleibt 2/3 der Fläche
            let insetY = visible.height / 6
            return Self.rect(left + insetX, top + insetY, right - insetX, bottom - insetY, rounding)
        case .restore:     return nil
        }
    }

    /// Anteil der nutzbaren Fläche, den diese Aktion belegt — Grundlage der Vorschau im
    /// Popover. Einheitenlos, Ursprung oben links, Werte von 0 bis 1. `nil` für `.restore`.
    ///
    /// Leitet sich aus `targetFrame(visibleFrame:primaryHeight:)` ab, damit Vorschau und
    /// Wirkung nicht auseinanderlaufen können.
    public var previewRect: CGRect? {
        let unit = CGRect(x: 0, y: 0, width: 1, height: 1)
        return targetFrame(visibleFrame: unit, primaryHeight: 1, rounding: false)
    }

    /// Baut den Rahmen aus GERUNDETEN Kanten — nicht aus gerundeter Breite/Höhe. Nur so stoßen linke
    /// und rechte Hälfte exakt aneinander (kein 1-px-Spalt, keine Überlappung), wenn `visibleFrame`
    /// gebrochene Maße hat: skalierte Displays, Notch-Menüleiste, Dock-Insets.
    ///
    /// `rounding` ist ausdrücklich ein Parameter und keine Heuristik über die Kantenlängen: Im
    /// Einheitsquadrat von `previewRect` würde jede Rundung eine 0,5-Kante auf 0 oder 1 ziehen und
    /// aus einer Hälfte die volle Breite machen.
    private static func rect(_ left: CGFloat, _ top: CGFloat, _ right: CGFloat, _ bottom: CGFloat,
                             _ rounding: Bool) -> CGRect {
        guard rounding else {
            return CGRect(x: left, y: top, width: max(0, right - left), height: max(0, bottom - top))
        }
        let l = left.rounded(), t = top.rounded(), r = right.rounded(), b = bottom.rounded()
        return CGRect(x: l, y: t, width: max(0, r - l), height: max(0, b - t))
    }
}
