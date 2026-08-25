// OnboardingView.swift
// MikaGrid
//
// SwiftUI container for onboarding flow with paged navigation.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI

struct OnboardingView: View {
    let appState: AppState
    /// Wird gerufen, wenn der Nutzer den Ablauf **abgeschlossen** hat („Done").
    let onFinish: () -> Void
    /// Wird gerufen, wenn er ihn abbricht — Esc oder Fenstertaste.
    let onCancel: () -> Void

    @State private var currentPage = 0

    /// Wird laufend ausgewertet, nicht einmalig beim Aufbau: Erteilt der Nutzer die Berechtigung,
    /// während Schritt 1 sichtbar ist, verschwindet Schritt 2 sofort aus dem Ablauf.
    private var needsPermission: Bool {
        !appState.accessibilityManager.isGranted
    }

    private var pageCount: Int { needsPermission ? 3 : 2 }
    private var shortcutsPage: Int { needsPermission ? 2 : 1 }

    var body: some View {
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
        .onChange(of: needsPermission) { _, stillNeeded in
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
        case 1 where needsPermission:
            PermissionScreen(appState: appState) { withAnimation { currentPage = 2 } }
        default:
            ShortcutsScreen(appState: appState, onDone: onFinish)
        }
    }
}
