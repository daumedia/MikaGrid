// SnapAction.swift
// MikaGrid
//
// Enum of all snap actions with geometry calculations and default key bindings.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit
import Carbon

enum SnapAction: String, CaseIterable, Identifiable, Sendable {
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

    var id: String { rawValue }

    var label: String {
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

    var systemImage: String {
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

    var hotkeyID: UInt32 {
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

    var defaultBinding: HotkeyBinding {
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

    /// Calculate target frame for this snap action on the given screen.
    /// Returns frame in AX coordinates (top-left origin). `nil` für `.restore` (kommt aus der History).
    func targetFrame(on screen: NSScreen) -> CGRect? {
        if self == .restore { return nil }

        let visible = screen.visibleFrame

        // NSScreen visibleFrame (bottom-left origin) → AX-Koordinaten (top-left origin)
        let left   = visible.minX
        let right  = visible.maxX
        let top    = NSScreen.primaryHeight - visible.maxY
        let bottom = top + visible.height
        let midX   = left + visible.width / 2
        let midY   = top + visible.height / 2

        switch self {
        case .leftHalf:    return Self.rect(left, top,  midX,  bottom)
        case .rightHalf:   return Self.rect(midX, top,  right, bottom)
        case .topHalf:     return Self.rect(left, top,  right, midY)
        case .bottomHalf:  return Self.rect(left, midY, right, bottom)
        case .topLeft:     return Self.rect(left, top,  midX,  midY)
        case .topRight:    return Self.rect(midX, top,  right, midY)
        case .bottomLeft:  return Self.rect(left, midY, midX,  bottom)
        case .bottomRight: return Self.rect(midX, midY, right, bottom)
        case .maximize:    return Self.rect(left, top,  right, bottom)
        case .center:
            let insetX = visible.width / 6   // (1 − 2/3) / 2 → bleibt 2/3 der Fläche
            let insetY = visible.height / 6
            return Self.rect(left + insetX, top + insetY, right - insetX, bottom - insetY)
        case .restore:     return nil
        }
    }

    /// Baut den Rahmen aus GERUNDETEN Kanten — nicht aus gerundeter Breite/Höhe. Nur so stoßen linke
    /// und rechte Hälfte exakt aneinander (kein 1-px-Spalt, keine Überlappung), wenn `visibleFrame`
    /// gebrochene Maße hat: skalierte Displays, Notch-Menüleiste, Dock-Insets.
    private static func rect(_ left: CGFloat, _ top: CGFloat, _ right: CGFloat, _ bottom: CGFloat) -> CGRect {
        let l = left.rounded(), t = top.rounded(), r = right.rounded(), b = bottom.rounded()
        return CGRect(x: l, y: t, width: max(0, r - l), height: max(0, b - t))
    }
}
