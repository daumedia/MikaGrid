// GeneralTabView.swift
// MikaGrid
//
// General preferences: Launch at Login, accessibility status, updates.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI

public struct GeneralTabView: View {
    public let appState: AppState

    @State private var launchAtLogin = false

    public var body: some View {
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

                    // Bereitschaft der jeweiligen Fassung: Bedienungshilfen beim
                    // Direktvertrieb, Companion-Shortcut und Automatisierung im App Store.
                    // Symbol UND Farbe — ein reiner Farbwechsel ist bei Rot-Grün-Schwäche
                    // nicht lesbar (design-system.md).
                    HStack {
                        Label(
                            appState.readiness.isReady ? "Ready to snap windows" : appState.readiness.headline,
                            systemImage: appState.readiness.isReady ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(appState.readiness.isReady ? .green : .orange)

                        Spacer()

                        if let actionTitle = appState.readiness.actionTitle {
                            Button(actionTitle) {
                                appState.snapper?.performReadinessAction()
                            }
                        }
                    }

                    if !appState.readiness.isReady {
                        Text(appState.readiness.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(4)
            }

            // Nur im Direktvertrieb: Die Store-Fassung wird über den App Store
            // aktualisiert und liefert Sparkle gar nicht erst mit (AK-02, AK-22).
            if let updater = appState.updater {
                GroupBox("Updates") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Check for updates automatically", isOn: Binding(
                        get: { updater.automaticallyChecksForUpdates },
                        set: { updater.automaticallyChecksForUpdates = $0 }
                    ))

                    // Zweite Stufe: Bis 1.1.1 zeigte die App nur den Schalter darüber, während
                    // Sparkle Updates im Hintergrund bereits selbsttätig INSTALLIERTE. Wer das
                    // abstellen wollte, fand in der App keinen Weg dazu.
                    Toggle("Install updates automatically", isOn: Binding(
                        get: { updater.automaticallyDownloadsUpdates },
                        set: { updater.automaticallyDownloadsUpdates = $0 }
                    ))
                    .disabled(!updater.automaticallyChecksForUpdates)

                    Divider()

                    HStack {
                        if let lastCheck = updater.lastUpdateCheckDate {
                            Text("Last checked: \(lastCheck, style: .relative) ago")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Check Now") {
                            updater.checkForUpdates()
                        }
                        .disabled(!updater.canCheckForUpdates)
                    }

                    if let error = updater.lastCheckError {
                        Label("Update check failed: \(error)", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                .padding(4)
                }
            }

            Spacer()
        }
        .onAppear {
            launchAtLogin = appState.launchAtLoginManager.isEnabled
            appState.snapper?.refreshReadiness()
        }
    }
}
