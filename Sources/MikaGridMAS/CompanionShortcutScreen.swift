// CompanionShortcutScreen.swift
// MikaGrid (App Store)
//
// Der Einrichtungsschritt des Onboardings (Feature 01, T16 · AK-13, AK-14).
//
// Vier Zustände, wie der Entwurf sie vorsieht:
//   leer    Anleitung und Schaltfläche „Set Up Shortcut"
//   ladend  „Waiting for the shortcut…" mit Prüfung im Sekundentakt
//   Fehler  Hinweis mit Wiederholung
//   gefüllt Häkchen, blättert nach ~1 s weiter
//
// Das Muster ist dasselbe wie beim Berechtigungsschritt der Direktfassung (B05): Für die
// Kurzbefehle-Mediathek gibt es keine Benachrichtigung, die man abonnieren könnte —
// abfragen ist der einzige Weg.
// Swift 6.0 strict concurrency, macOS 15+

import SwiftUI
import MikaGridCore

struct CompanionShortcutScreen: View {
    let companion: CompanionShortcutManager
    let snapper: ShortcutsWindowSnapper?
    let onNext: () -> Void

    /// Der Import ließ sich nicht anstoßen — die Datei fehlt im Bundle oder das System
    /// hat sie nicht geöffnet.
    @State private var openFailed = false
    /// Ab dem ersten Klick läuft die Prüfung; vorher wäre „Waiting…" eine Behauptung.
    @State private var isWaiting = false

    private var isInstalled: Bool { companion.state == .installed }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: isInstalled ? "checkmark.circle.fill" : "square.grid.3x3")
                .font(.system(size: 56))
                .foregroundStyle(isInstalled ? Color.green : Color.MikaPlus.tealPrimary)
                .accessibilityHidden(true)

            Text(isInstalled ? "Shortcut ready" : "One shortcut to set up")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.MikaPlus.textPrimary)

            Text(explanation)
                .font(.system(size: 13))
                .foregroundStyle(Color.MikaPlus.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)

            if openFailed {
                // Zustand „Fehler": benannt, mit Weg zurück — nicht wortlos nichts tun.
                Label("The shortcut file could not be opened.", systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.orange)
            }

            if isInstalled {
                Text("Continuing…")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.MikaPlus.textSecondary)
            } else if isWaiting {
                // Zustand „ladend"
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Waiting for the shortcut…")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.MikaPlus.textSecondary)
                }
                Button("Try Again") { install() }
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.MikaPlus.tealLight)
            } else {
                // Zustand „leer"
                Button(action: install) {
                    Text(openFailed ? "Try Again" : "Set Up Shortcut").onboardingPrimaryButton()
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilitySummary)
        .onAppear {
            companion.refresh()
            companion.startPolling()
        }
        .onDisappear { companion.stopPolling() }
        .onChange(of: isInstalled) { _, installed in
            guard installed else { return }
            // Kurz stehen lassen, damit das Häkchen gesehen wird — wie bei der
            // Berechtigung in B05.
            Task {
                try? await Task.sleep(for: .seconds(1))
                snapper?.refreshReadiness()
                onNext()
            }
        }
    }

    private var explanation: String {
        if isInstalled {
            return "Mika+Grid can move your windows now."
        }
        return """
        Mika+Grid asks Apple’s Shortcuts app to move your windows — that is what keeps it \
        inside the App Store rules. Adding the shortcut takes one click.
        """
    }

    /// Der Zustand darf nicht allein an Farbe und Symbol hängen (design-system.md).
    private var accessibilitySummary: String {
        if isInstalled { return "Companion shortcut installed. Continuing automatically." }
        if openFailed { return "The shortcut file could not be opened. Try again." }
        if isWaiting { return "Waiting for you to add the shortcut in the Shortcuts app." }
        return "The companion shortcut is not set up yet. Activate to add it."
    }

    private func install() {
        openFailed = !companion.beginInstallation()
        isWaiting = !openFailed
    }
}
