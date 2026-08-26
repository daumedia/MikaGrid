// OnboardingButtonStyle.swift
// MikaGridCore
//
// Die Knopfform des Onboardings. Lag bis Feature 01 in `PermissionScreen`; seit die
// Begrüßung und die Kürzelübersicht in der gemeinsamen Bibliothek liegen, muss sie mit —
// sonst sähen die Schritte je Fassung verschieden aus.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI

public extension View {
    /// Die primäre Schaltfläche eines Onboarding-Schritts (design-system.md).
    func onboardingPrimaryButton() -> some View {
        self
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: 200, height: 40)
            .background(Color.MikaPlus.tealPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
