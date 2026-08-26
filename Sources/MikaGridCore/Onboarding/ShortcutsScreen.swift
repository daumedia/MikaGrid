// ShortcutsScreen.swift
// MikaGrid
//
// Onboarding screen 3: Keyboard shortcuts overview and launch-at-login toggle.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI

public struct ShortcutsScreen: View {
    public let appState: AppState
    public let onDone: () -> Void

    @State private var launchAtLogin = false

    /// Die **tatsächliche** Belegung, nicht eine fest hinterlegte Liste. Bis 1.1.1 standen hier
    /// elf hartkodierte Paare: Wer seine Kürzel geändert hatte und das Onboarding erneut aufrief,
    /// bekam die Standardwerte gezeigt — eine zweite Wahrheit für dieselbe Sache.
    private var shortcuts: [(action: SnapAction, keys: String)] {
        let bindings = appState.hotkeyManager?.currentBindings ?? HotkeyManager.defaultBindings()
        return SnapAction.allCases.map { action in
            (action, (bindings[action] ?? action.defaultBinding).displayString)
        }
    }

    public var body: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 8)

            Text("Keyboard Shortcuts")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.MikaPlus.textPrimary)

            ScrollView {
                VStack(spacing: 6) {
                    ForEach(shortcuts, id: \.action) { shortcut in
                        HStack {
                            Text(shortcut.keys)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundStyle(Color.MikaPlus.tealLight)
                                .frame(width: 80, alignment: .trailing)
                            Text(shortcut.action.label)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.MikaPlus.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(shortcut.action.label), \(shortcut.keys)")
                    }
                }
                .padding(.horizontal, 40)
            }
            .frame(maxHeight: 300)

            Spacer()

            Toggle("Launch Mika+Grid at login", isOn: $launchAtLogin)
                .toggleStyle(.checkbox)
                .font(.system(size: 13))
                .foregroundStyle(Color.MikaPlus.textPrimary)
                .padding(.horizontal, 40)
                // Sofort anwenden statt erst bei „Done": Der Schalter zeigt damit immer den
                // wirklichen Systemzustand, auch wenn das Fenster anders verlassen wird.
                .onChange(of: launchAtLogin) { _, newValue in
                    appState.launchAtLoginManager.setEnabled(newValue)
                    launchAtLogin = appState.launchAtLoginManager.isEnabled
                }

            Button {
                onDone()
            } label: {
                Text("Done").onboardingPrimaryButton()
            }
            .buttonStyle(.plain)

            Spacer()
                .frame(height: 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // Den echten Zustand lesen, statt „an" zu behaupten.
            launchAtLogin = appState.launchAtLoginManager.isEnabled
        }
    }
}
