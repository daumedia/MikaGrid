// AboutWindow.swift
// MikaGrid
//
// About window showing app icon, version, and branding.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI

@MainActor
final class AboutWindowController: NSObject, NSWindowDelegate {
    static let windowSize = NSSize(width: 320, height: 400)

    private var window: NSWindow?

    func showWindow() {
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: Self.windowSize),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "About Mika+Grid"
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.contentView = NSHostingView(rootView: AboutView())
        window.center()

        self.window = window

        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "square.grid.3x3.fill")
                .resizable()
                .frame(width: 128, height: 128)
                .foregroundStyle(Color.MikaPlus.tealPrimary)
                .accessibilityHidden(true)

            Text("Mika+Grid")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.MikaPlus.textPrimary)

            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .font(.system(size: 13))
                .foregroundStyle(Color.MikaPlus.textSecondary)

            Text("Part of the Mika+ ecosystem")
                .font(.system(size: 12).italic())
                .foregroundStyle(Color.MikaPlus.tealLight)

            Rectangle()
                .fill(Color.MikaPlus.tealPrimary.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal, 40)

            Text("Built with \u{2665} in Luxembourg")
                .font(.system(size: 11))
                .foregroundStyle(Color.MikaPlus.tealLight.opacity(0.6))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color.MikaPlus.darkBgDeep, Color.MikaPlus.darkBg],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
