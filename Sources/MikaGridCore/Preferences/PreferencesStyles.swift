// PreferencesStyles.swift
// MikaGrid
//
// Shared types for the preferences window.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI

public enum PreferencesTab: String, CaseIterable, Identifiable, Sendable {
    case general
    case shortcuts
    case about

    public var id: String { rawValue }

    public var systemImage: String {
        switch self {
        case .general:   return "gearshape"
        case .shortcuts: return "keyboard"
        case .about:     return "info.circle"
        }
    }

    public var label: String {
        switch self {
        case .general:   return "General"
        case .shortcuts: return "Shortcuts"
        case .about:     return "About"
        }
    }
}
