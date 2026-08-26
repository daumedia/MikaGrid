// MikaPlusColors.swift
// MikaGrid
//
// Brand color palette for the Mika+ ecosystem.
// Swift 6.0 strict concurrency, macOS 14+

import AppKit
import SwiftUI

public extension NSColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let b = CGFloat(rgb & 0xFF) / 255.0
        self.init(srgbRed: r, green: g, blue: b, alpha: 1.0)
    }

    enum MikaPlus {
        public static let tealPrimary    = NSColor(hex: "#1D9E75")
        public static let tealLight      = NSColor(hex: "#5DCAA5")
        public static let tealLightest   = NSColor(hex: "#9FE1CB")
        public static let tealSurface    = NSColor(hex: "#E1F5EE")
        public static let darkBg         = NSColor(hex: "#1A1A2E")
        public static let darkBgDeep     = NSColor(hex: "#0F0F1A")
        public static let textPrimary    = NSColor(hex: "#E1F5EE")
        public static let textSecondary  = NSColor(hex: "#9FE1CB")
        public static let destructive    = NSColor(hex: "#E24B4A")
    }
}

public extension Color {
    enum MikaPlus {
        public static let tealPrimary   = Color(nsColor: NSColor.MikaPlus.tealPrimary)
        public static let tealLight     = Color(nsColor: NSColor.MikaPlus.tealLight)
        public static let tealLightest  = Color(nsColor: NSColor.MikaPlus.tealLightest)
        public static let tealSurface   = Color(nsColor: NSColor.MikaPlus.tealSurface)
        public static let darkBg        = Color(nsColor: NSColor.MikaPlus.darkBg)
        public static let darkBgDeep    = Color(nsColor: NSColor.MikaPlus.darkBgDeep)
        public static let textPrimary   = Color(nsColor: NSColor.MikaPlus.textPrimary)
        public static let textSecondary = Color(nsColor: NSColor.MikaPlus.textSecondary)
        public static let destructive   = Color(nsColor: NSColor.MikaPlus.destructive)
    }
}
