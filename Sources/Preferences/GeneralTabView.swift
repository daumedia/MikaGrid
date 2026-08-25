// GeneralTabView.swift
// MikaGrid
//
// General preferences: Launch at Login, accessibility status, updates.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI

struct GeneralTabView: View {
    let appState: AppState

    @State private var launchAtLogin = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("General")
                .font(.title2.bold())

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Launch Mika+Grid at login", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { oldValue, newValue in
                            // Beim Anzeigen setzt onAppear den Schalter auf den Systemzustand;
                            // das löst onChange aus, ohne dass der Nutzer etwas getan hat.
                            guard oldValue != newValue, newValue != appState.launchAtLoginManager.isEnabled else { return }
                            appState.launchAtLoginManager.setEnabled(newValue)
                            // Zurücklesen: Bei einem Fehlschlag springt der Schalter zurück,
                            // statt einen Zustand zu behaupten, den das System nicht hat.
                            launchAtLogin = appState.launchAtLoginManager.isEnabled
                        }

                    if let error = appState.launchAtLoginManager.lastError {
                        Label("Login item failed: \(error)", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    Divider()

                    // Accessibility status
                    HStack {
                        Label(
                            appState.accessibilityManager.isGranted ? "Accessibility: Granted" : "Accessibility: Not Granted",
                            systemImage: appState.accessibilityManager.isGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(appState.accessibilityManager.isGranted ? .green : .orange)

                        Spacer()

                        if !appState.accessibilityManager.isGranted {
                            Button("Open Settings") {
                                appState.accessibilityManager.openSystemSettings()
                            }
                        }
                    }
                }
                .padding(4)
            }

            GroupBox("Updates") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Check for updates automatically", isOn: Binding(
                        get: { appState.sparkleUpdater.automaticallyChecksForUpdates },
                        set: { appState.sparkleUpdater.automaticallyChecksForUpdates = $0 }
                    ))

                    // Zweite Stufe: Bis 1.1.1 zeigte die App nur den Schalter darüber, während
                    // Sparkle Updates im Hintergrund bereits selbsttätig INSTALLIERTE. Wer das
                    // abstellen wollte, fand in der App keinen Weg dazu.
                    Toggle("Install updates automatically", isOn: Binding(
                        get: { appState.sparkleUpdater.automaticallyDownloadsUpdates },
                        set: { appState.sparkleUpdater.automaticallyDownloadsUpdates = $0 }
                    ))
                    .disabled(!appState.sparkleUpdater.automaticallyChecksForUpdates)

                    Divider()

                    HStack {
                        if let lastCheck = appState.sparkleUpdater.lastUpdateCheckDate {
                            Text("Last checked: \(lastCheck, style: .relative) ago")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Check Now") {
                            appState.sparkleUpdater.checkForUpdates()
                        }
                        .disabled(!appState.sparkleUpdater.canCheckForUpdates)
                    }

                    if let error = appState.sparkleUpdater.lastCheckError {
                        Label("Update check failed: \(error)", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                .padding(4)
            }

            Spacer()
        }
        .onAppear {
            launchAtLogin = appState.launchAtLoginManager.isEnabled
            appState.accessibilityManager.checkPermission()
        }
    }
}
