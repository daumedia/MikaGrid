// MikaGridMASApp.swift
// MikaGrid (App Store)
//
// Einstiegspunkt der App-Store-Fassung (Feature 01).
//
// Bis auf zwei Stellen ist alles dasselbe wie im Direktvertrieb: Fenster bewegt hier der
// `ShortcutsWindowSnapper` statt der Accessibility-API, und der Einrichtungsschritt im
// Onboarding zeigt den Companion-Kurzbefehl statt der Bedienungshilfen. Popover,
// Tastenkürzel, Einstellungen und Über-Fenster kommen unverändert aus `MikaGridCore`.
// Swift 6.0 strict concurrency, macOS 15+

import AppKit
import SwiftUI
import MikaGridCore

@main
struct MikaGridMASApp: App {
    @NSApplicationDelegateAdaptor(MASAppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            PopoverGridView(appState: appDelegate.appState)
        } label: {
            Image(systemName: "square.grid.3x3")
                .accessibilityLabel("Mika+Grid")
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - AppDelegate

@MainActor
final class MASAppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()

    private var companion: CompanionShortcutManager?
    private var snapper: ShortcutsWindowSnapper?

    private var preferencesController: PreferencesWindowController?
    private var onboardingController: OnboardingWindowController?
    private var aboutController: AboutWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let runner = ShortcutsRunner()
        let companion = CompanionShortcutManager(runner: runner)
        let snapper = ShortcutsWindowSnapper(
            runner: runner,
            companion: companion,
            snapHistory: appState.snapHistory
        )
        self.companion = companion
        self.snapper = snapper

        // Kein Aktualisierer: Updates kommen aus dem App Store, Sparkle liegt dieser
        // Fassung gar nicht bei (AK-02, AK-22).
        appState.setup(snapper: snapper, updater: nil)
        companion.refresh()

        // Das Popover macht die eigene App zur vordersten. Ohne diese Notiz wüsste der
        // Snapper danach nicht mehr, welches Fenster gemeint war (B01).
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil, queue: .main
        ) { [weak self] note in
            guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            else { return }
            Task { @MainActor in self?.snapper?.noteActivation(of: app) }
        }

        if !appState.preferences.hasCompletedOnboarding {
            showOnboarding()
        }

        NotificationCenter.default.addObserver(
            forName: .showPreferences, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.showPreferences() }
        }
        NotificationCenter.default.addObserver(
            forName: .showAbout, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.showAbout() }
        }
    }

    // MARK: - URL-Schema (T14)

    /// Nimmt die Antwort des Kurzbefehls entgegen — und **nur** die.
    ///
    /// Ein URL-Schema ist ein offener Eingang: Ohne Prüfung könnte jede Webseite
    /// `mikagrid-mas://…` öffnen. Deshalb wird jede Anfrage verworfen, die keinen
    /// gültigen, unmittelbar zuvor erzeugten `nonce` mitbringt — und es gibt keinen
    /// Befehl, den man darüber auslösen könnte, nur Antworten auf einen laufenden Aufruf.
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            guard url.scheme == "mikagrid-mas" else { continue }
            let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
            let nonce = items?.first { $0.name == "nonce" }?.value
            guard let nonce, let expected = snapper?.pendingNonce, nonce == expected else {
                // Stillschweigend verwerfen: Eine Meldung wäre für den Nutzer sinnlos und
                // für einen Angreifer eine Rückmeldung.
                continue
            }
            // Der Aufruf läuft synchron über Apple Events und wertet seine Antwort selbst
            // aus. Hier ist nichts weiter zu tun — der Eingang bleibt bewusst wirkungslos.
        }
    }

    // MARK: - Fenster

    private func showOnboarding() {
        let controller = OnboardingWindowController(appState: appState) { [weak self] onNext in
            guard let self, let companion = self.companion else { return AnyView(EmptyView()) }
            return AnyView(
                CompanionShortcutScreen(
                    companion: companion,
                    snapper: self.snapper,
                    onNext: onNext
                )
            )
        }
        self.onboardingController = controller
        controller.showWindow()
    }

    private func showPreferences() {
        if preferencesController == nil {
            preferencesController = PreferencesWindowController(
                appState: appState,
                onShowOnboarding: { [weak self] in self?.showOnboarding() }
            )
        }
        preferencesController?.showWindow()
    }

    private func showAbout() {
        if aboutController == nil {
            aboutController = AboutWindowController()
        }
        aboutController?.showWindow()
    }
}
