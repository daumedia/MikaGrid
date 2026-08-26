// OnboardingView.swift
// MikaGrid
//
// SwiftUI container for onboarding flow with paged navigation.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI

public struct OnboardingView: View {
    let appState: AppState
    /// Wird gerufen, wenn der Nutzer den Ablauf **abgeschlossen** hat („Done").
    let onFinish: () -> Void
    /// Wird gerufen, wenn er ihn abbricht — Esc oder Fenstertaste.
    let onCancel: () -> Void
    /// Der Einrichtungsschritt der jeweiligen Fassung: Bedienungshilfen beim
    /// Direktvertrieb (B05), Companion-Shortcut im App Store (T16). Er fällt weg, sobald
    /// die Fassung bereit ist — deshalb reicht die Bibliothek ihn durch, statt ihn zu kennen.
    let setupStep: (@escaping () -> Void) -> AnyView

    @State private var currentPage = 0

    public init(
        appState: AppState,
        onFinish: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        setupStep: @escaping (@escaping () -> Void) -> AnyView
    ) {
        self.appState = appState
        self.onFinish = onFinish
        self.onCancel = onCancel
        self.setupStep = setupStep
    }

    /// Wird laufend ausgewertet, nicht einmalig beim Aufbau: Wird die Fassung bereit,
    /// während Schritt 1 sichtbar ist, verschwindet Schritt 2 sofort aus dem Ablauf.
    private var needsSetup: Bool {
        !appState.readiness.isReady
    }

    private var pageCount: Int { needsSetup ? 3 : 2 }
    private var shortcutsPage: Int { needsSetup ? 2 : 1 }

    public var body: some View {
        VStack(spacing: 0) {
            // Eigene Umschaltung statt TabView: Auf macOS zeichnet TabView im Standardstil eine
            // Reiterleiste, für die es hier keine Beschriftungen gibt.
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)

            HStack(spacing: 12) {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation { currentPage -= 1 }
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.MikaPlus.tealLight.opacity(0.7))
                }

                Spacer()

                HStack(spacing: 8) {
                    ForEach(0 ..< pageCount, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.MikaPlus.tealPrimary : Color.gray.opacity(0.5))
                            .frame(width: 8, height: 8)
                    }
                }

                Spacer()

                // Platzhalter, damit die Punkte mittig bleiben
                if currentPage > 0 {
                    Text("Back")
                        .font(.system(size: 12))
                        .opacity(0)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Step \(currentPage + 1) of \(pageCount)")
        }
        .frame(width: OnboardingWindowController.windowSize.width,
               height: OnboardingWindowController.windowSize.height)
        .background(
            LinearGradient(
                colors: [Color.MikaPlus.darkBgDeep, Color.MikaPlus.darkBg],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onKeyPress(.escape) {
            onCancel()
            return .handled
        }
        .onChange(of: needsSetup) { _, stillNeeded in
            // Fällt Schritt 2 weg, während er sichtbar ist, nicht ins Leere zeigen
            if !stillNeeded, currentPage >= shortcutsPage + 1 {
                currentPage = shortcutsPage
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch currentPage {
        case 0:
            WelcomeScreen { withAnimation { currentPage = 1 } }
        case 1 where needsSetup:
            setupStep { withAnimation { currentPage = 2 } }
        default:
            ShortcutsScreen(appState: appState, onDone: onFinish)
        }
    }
}
