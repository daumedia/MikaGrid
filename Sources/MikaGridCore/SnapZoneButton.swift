// SnapZoneButton.swift
// MikaGrid
//
// Individual clickable snap zone with miniature monitor preview.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI

public struct SnapZoneButton: View {
    public let action: SnapAction
    public let appState: AppState

    @State private var isHovering = false

    private static let monitorWidth: CGFloat = 40
    private static let monitorHeight: CGFloat = 26

    public var body: some View {
        Button {
            appState.performSnap(action)
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.secondary.opacity(0.4), lineWidth: 1)
                    highlightedZone
                }
                .frame(width: Self.monitorWidth, height: Self.monitorHeight)

                Text(action.label)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)

                if let binding = appState.hotkeyManager?.currentBindings[action] {
                    Text(binding.displayString)
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(Color.MikaPlus.tealLight.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovering ? Color.MikaPlus.tealPrimary.opacity(0.15) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Snaps the frontmost window")
    }

    private var accessibilityLabel: String {
        guard let binding = appState.hotkeyManager?.currentBindings[action] else {
            return action.label
        }
        return "\(action.label), \(binding.displayString)"
    }

    /// Die eingefärbte Zielfläche — **abgeleitet aus `SnapAction.previewRect`**, nicht von Hand
    /// nachgebaut. Bis 1.1.1 war das eine eigene Verzweigung über elf Fälle, und die zentrierte
    /// Zone wurde dabei mit rund 80 % × 69 % statt 67 % × 67 % gezeichnet: Vorschau und Wirkung
    /// konnten beliebig auseinanderlaufen, ohne dass es auffiel.
    @ViewBuilder
    private var highlightedZone: some View {
        let color = isHovering ? Color.MikaPlus.tealPrimary : Color.MikaPlus.tealPrimary.opacity(0.4)

        if let unit = action.previewRect {
            color
                .frame(width: Self.monitorWidth * unit.width,
                       height: Self.monitorHeight * unit.height)
                .position(x: Self.monitorWidth * unit.midX,
                          y: Self.monitorHeight * unit.midY)
        } else {
            // `.restore` hat keine feste Zielfläche
            Image(systemName: "arrow.uturn.backward")
                .font(.system(size: 12))
                .foregroundStyle(color)
        }
    }
}
