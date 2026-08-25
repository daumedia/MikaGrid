// PopoverGridView.swift
// MikaGrid
//
// Main popover UI: visual snap grid with monitor previews.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI

struct PopoverGridView: View {
    let appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            headerView
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

            if !appState.accessibilityManager.isGranted {
                accessibilityWarning
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            }

            if let feedback = appState.snapFeedback {
                feedbackBanner(feedback)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            }

            Divider()
                .padding(.horizontal, 12)

            snapGrid
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            Divider()
                .padding(.horizontal, 12)

            footerView
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
        }
        .frame(width: 280)
        .animation(.easeInOut(duration: 0.15), value: appState.snapFeedback)
        .animation(.easeInOut(duration: 0.15), value: appState.accessibilityManager.isGranted)
        .onAppear {
            appState.accessibilityManager.checkPermission()
            // Solange das Popover sichtbar ist, folgt die Ampel dem System. Ohne den Takt bliebe
            // sie orange, wenn der Nutzer die Berechtigung nebenan gerade erteilt.
            appState.accessibilityManager.startPolling()
        }
        .onDisappear {
            appState.accessibilityManager.stopPolling()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 8) {
            Image(systemName: "square.grid.3x3.fill")
                .font(.system(size: 16))
                .foregroundStyle(Color.MikaPlus.tealPrimary)

            Text("Mika+Grid")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)

            Spacer()

            // Symbol UND Farbe: Ein reiner Farbpunkt ist bei Rot-Grün-Schwäche nicht lesbar.
            Image(systemName: appState.accessibilityManager.isGranted
                  ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 11))
                .foregroundStyle(appState.accessibilityManager.isGranted ? Color.green : Color.orange)
                .accessibilityLabel(appState.accessibilityManager.isGranted
                                    ? "Accessibility permission granted"
                                    : "Accessibility permission missing")
        }
    }

    // MARK: - Banner

    private var accessibilityWarning: some View {
        Button {
            appState.accessibilityManager.openSystemSettings()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.orange)
                Text("Accessibility permission required")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "arrow.right.circle")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(8)
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Accessibility permission required. Opens System Settings.")
    }

    /// Grund des letzten fehlgeschlagenen Snaps. Bis 1.1.1 endeten alle Fehlerpfade still —
    /// aus Nutzersicht war „keine Berechtigung" von „kein Fenster" nicht zu unterscheiden.
    private func feedbackBanner(_ message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 11))
                .foregroundStyle(Color.MikaPlus.tealLight)
            Text(message)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(8)
        .background(Color.MikaPlus.tealPrimary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .transition(.opacity)
        .accessibilityLabel(message)
    }

    // MARK: - Snap Grid

    private var snapGrid: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                SnapZoneButton(action: .leftHalf, appState: appState)
                SnapZoneButton(action: .rightHalf, appState: appState)
            }
            HStack(spacing: 8) {
                SnapZoneButton(action: .topHalf, appState: appState)
                SnapZoneButton(action: .bottomHalf, appState: appState)
            }
            HStack(spacing: 8) {
                SnapZoneButton(action: .topLeft, appState: appState)
                SnapZoneButton(action: .topRight, appState: appState)
            }
            HStack(spacing: 8) {
                SnapZoneButton(action: .bottomLeft, appState: appState)
                SnapZoneButton(action: .bottomRight, appState: appState)
            }
            HStack(spacing: 8) {
                SnapZoneButton(action: .maximize, appState: appState)
                SnapZoneButton(action: .center, appState: appState)
                SnapZoneButton(action: .restore, appState: appState)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Snap zones")
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack {
            // ⌘, und ⌘Q gibt es sonst nirgends: Eine App mit `LSUIElement` hat kein
            // Programmmenü. Solange das Popover offen ist, greifen die gewohnten Kürzel
            // wenigstens hier.
            footerButton("Preferences") {
                NotificationCenter.default.post(name: .showPreferences, object: nil)
            }
            .keyboardShortcut(",", modifiers: .command)

            Spacer()

            footerButton("Updates") {
                appState.sparkleUpdater.checkForUpdates()
            }

            Spacer()

            // Seit 1.1.0 gab es keinen Weg mehr zum Über-Fenster: Die Schaltfläche wurde durch
            // „Updates" ersetzt, der Empfänger blieb stehen. Jetzt hängt es wieder am Menü.
            footerButton("About") {
                NotificationCenter.default.post(name: .showAbout, object: nil)
            }

            Spacer()

            footerButton("Quit") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
    }

    private func footerButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.plain)
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .accessibilityLabel(title)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let showPreferences = Notification.Name("showPreferences")
    static let showAbout = Notification.Name("showAbout")
}
