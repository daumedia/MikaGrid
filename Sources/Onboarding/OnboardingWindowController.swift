// OnboardingWindowController.swift
// MikaGrid
//
// Window controller for the first-launch onboarding flow.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI

@MainActor
final class OnboardingWindowController: NSObject, NSWindowDelegate {
    /// Einzige Quelle für das Fenstermaß — bis 1.1.1 stand es zusätzlich im SwiftUI-Rahmen,
    /// und eine Änderung an nur einer Stelle beschnitt den Inhalt.
    static let windowSize = NSSize(width: 480, height: 560)

    private var window: NSWindow?
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func showWindow() {
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: Self.windowSize),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.delegate = self

        let contentView = OnboardingView(
            appState: appState,
            onFinish: { [weak self] in
                // NUR hier gilt der Ablauf als abgeschlossen. Bis 1.1.1 setzte auch jedes
                // Wegklicken das Kennzeichen — wer das Fenster schloss, um es später anzusehen,
                // bekam es nie wieder zu Gesicht.
                self?.appState.preferences.hasCompletedOnboarding = true
                self?.close()
            },
            onCancel: { [weak self] in self?.close() }
        )
        window.contentView = NSHostingView(rootView: contentView)
        window.center()

        self.window = window

        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    func close() {
        window?.close()
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}
