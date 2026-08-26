// AboutTabView.swift
// MikaGrid
//
// About tab in preferences: version info, reset, show onboarding.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI

public struct AboutTabView: View {
    public let appState: AppState
    public let onShowOnboarding: () -> Void

    @State private var showResetConfirmation = false

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("About")
                .font(.title2.bold())

            GroupBox {
                VStack(spacing: 16) {
                    // App Icon
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.MikaPlus.tealPrimary)

                    Text("Mika+Grid")
                        .font(.system(size: 18, weight: .semibold))

                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    Text("Part of the Mika+ ecosystem")
                        .font(.system(size: 11).italic())
                        .foregroundStyle(Color.MikaPlus.tealLight)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        onShowOnboarding()
                    } label: {
                        Label("Show Onboarding Again", systemImage: "arrow.clockwise")
                    }

                    Divider()

                    Button {
                        NotificationCenter.default.post(name: .showAbout, object: nil)
                    } label: {
                        Label("About Mika+Grid", systemImage: "info.circle")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label("Reset All Settings", systemImage: "trash")
                            .foregroundStyle(Color.MikaPlus.destructive)
                    }
                }
                .padding(4)
            }
            .alert("Reset All Settings?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    // Ein Aufruf für alles — Einstellungen, Anmeldeobjekt, Historie und Kürzel.
                    // Bis 1.1.1 lag die Fachlogik auf zwei Stellen verteilt, und wer das
                    // Zurücksetzen anderswo aufrief, vergaß die Kürzel.
                    appState.resetEverything()
                }
            } message: {
                Text("This will reset all shortcuts and preferences to their defaults.")
            }

            Spacer()
        }
    }
}
