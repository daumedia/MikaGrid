// WelcomeScreen.swift
// MikaGrid
//
// Onboarding screen 1: Welcome with app icon and tagline.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI

public struct WelcomeScreen: View {
    public let onNext: () -> Void

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "square.grid.3x3.fill")
                .resizable()
                .frame(width: 120, height: 120)
                .foregroundStyle(Color.MikaPlus.tealPrimary)
                .accessibilityHidden(true)

            Text("Welcome to Mika+Grid")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.MikaPlus.textPrimary)

            Text("Snap. Organize. Focus.")
                .font(.system(size: 14))
                .foregroundStyle(Color.MikaPlus.tealLight)

            Spacer()

            Button(action: onNext) {
                Text("Get Started").onboardingPrimaryButton()
            }
            .buttonStyle(.plain)

            Spacer()
                .frame(height: 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
