// PreferencesContainerView.swift
// MikaGrid
//
// Root SwiftUI view — native macOS System Settings layout.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI

struct PreferencesContainerView: View {
    let appState: AppState
    let onShowOnboarding: () -> Void

    @State private var selectedTab: PreferencesTab = .general

    var body: some View {
        NavigationSplitView {
            List(PreferencesTab.allCases, selection: $selectedTab) { tab in
                Label(tab.label, systemImage: tab.systemImage)
                    .tag(tab)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 140, ideal: 160, max: 180)
        } detail: {
            ScrollView {
                detailContent
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .frame(width: PreferencesWindowController.windowSize.width,
               height: PreferencesWindowController.windowSize.height)
    }

    @ViewBuilder
    private var detailContent: some View {
        switch selectedTab {
        case .general:
            GeneralTabView(appState: appState)
        case .shortcuts:
            ShortcutsTabView(appState: appState)
        case .about:
            AboutTabView(appState: appState, onShowOnboarding: onShowOnboarding)
        }
    }
}
