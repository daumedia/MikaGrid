// PermissionScreen.swift
// MikaGrid
//
// Onboarding screen 2: Accessibility permission request.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI

struct PermissionScreen: View {
    let appState: AppState
    let onNext: () -> Void

    /// Sorgt dafür, dass nach erteilter Berechtigung **genau einmal** weitergeblättert wird.
    /// Bis 1.1.1 legte jeder Taktschlag eine weitere Verzögerungsaufgabe an, ohne die vorherige
    /// abzubrechen — es wurde mehrfach weitergeschaltet.
    @State private var hasAdvanced = false
    @State private var advanceTask: Task<Void, Never>?

    private var isGranted: Bool { appState.accessibilityManager.isGranted }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: isGranted ? "checkmark.circle.fill" : "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(isGranted ? Color.green : Color.MikaPlus.tealPrimary)
                .transition(.scale.combined(with: .opacity))
                .accessibilityHidden(true)

            Text("Accessibility Permission")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.MikaPlus.textPrimary)

            Text("Mika+Grid needs Accessibility access to move and resize windows. Your data stays on your Mac.")
                .font(.system(size: 13))
                .foregroundStyle(Color.MikaPlus.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)

            if !isGranted {
                Button {
                    appState.accessibilityManager.openSystemSettings()
                } label: {
                    Text("Open System Settings")
                        .onboardingPrimaryButton()
                }
                .buttonStyle(.plain)
            } else {
                Text("Granted — continuing…")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.MikaPlus.tealLight)
            }

            Spacer()

            if !isGranted {
                Button("Skip for now") {
                    appState.preferences.permissionSkipped = true
                    onNext()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(Color.MikaPlus.tealLight.opacity(0.5))
            }

            Spacer()
                .frame(height: 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut, value: isGranted)
        .onAppear {
            // Ein einziger Takt — der des Managers. Bis 1.1.1 lief hier ein zweiter daneben.
            appState.accessibilityManager.startPolling()
        }
        .onDisappear {
            appState.accessibilityManager.stopPolling()
            advanceTask?.cancel()
        }
        .onChange(of: isGranted) { _, granted in
            guard granted, !hasAdvanced else { return }
            hasAdvanced = true
            advanceTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                onNext()
            }
        }
    }
}

// MARK: - Shared button shape

extension View {
    /// Der Primärbutton des Onboardings — einmal definiert statt dreimal kopiert.
    func onboardingPrimaryButton() -> some View {
        self
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: 200, height: 40)
            .background(Color.MikaPlus.tealPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
