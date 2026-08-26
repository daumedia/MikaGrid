// MikaGridApp.swift
// MikaGrid
//
// @main App with MenuBarExtra and AppDelegate for window management.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI
import MikaGridCore

@main
struct MikaGridApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

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
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    /// Stark gehalten: `AppState` kennt den Snapper nur über die Schnittstelle, aber das
    /// Onboarding braucht den `AccessibilityManager` dahinter.
    private var snapper: AccessibilityWindowSnapper?

    private var preferencesController: PreferencesWindowController?
    private var onboardingController: OnboardingWindowController?
    private var aboutController: AboutWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Die Direktfassung bewegt Fenster selbst über die Accessibility-API und
        // aktualisiert sich über Sparkle. Beides gibt es nur hier — welche Fassung läuft,
        // weiß seit Feature 01 nur noch das App-Ziel.
        let snapper = AccessibilityWindowSnapper(
            snapHistory: appState.snapHistory,
            preferences: appState.preferences
        )
        self.snapper = snapper
        appState.setup(snapper: snapper, updater: SparkleUpdater())

        // Onboarding erscheint, bis der Nutzer es tatsächlich abgeschlossen hat. Ein Abbruch
        // per Esc oder Fenstertaste zählt seit 1.2.0 nicht mehr als Abschluss.
        if !appState.preferences.hasCompletedOnboarding {
            showOnboarding()
        } else if !appState.preferences.permissionSkipped,
                  !snapper.accessibilityManager.checkPermission() {
            snapper.accessibilityManager.requestPermission()
        }

        // Listen for notifications from popover
        NotificationCenter.default.addObserver(
            forName: .showPreferences, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.showPreferences()
            }
        }

        NotificationCenter.default.addObserver(
            forName: .showAbout, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.showAbout()
            }
        }
    }

    private func showOnboarding() {
        let controller = OnboardingWindowController(appState: appState) { [weak self] onNext in
            guard let self, let snapper = self.snapper else { return AnyView(EmptyView()) }
            return AnyView(
                PermissionScreen(
                    accessibilityManager: snapper.accessibilityManager,
                    preferences: self.appState.preferences,
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
                onShowOnboarding: { [weak self] in
                    self?.showOnboarding()
                }
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
