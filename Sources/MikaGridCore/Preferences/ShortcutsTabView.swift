// ShortcutsTabView.swift
// MikaGrid
//
// Shortcuts preferences: hotkey list with inline recorder.
// Swift 6.0 strict concurrency, macOS 14+

import SwiftUI
import Carbon

public struct ShortcutsTabView: View {
    public let appState: AppState

    @State private var bindings: [SnapAction: HotkeyBinding] = [:]
    @State private var recordingAction: SnapAction?
    @State private var conflictMessage: String?

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Shortcuts")
                .font(.title2.bold())

            GroupBox {
                VStack(spacing: 0) {
                    ForEach(Array(SnapAction.allCases.enumerated()), id: \.element.id) { index, action in
                        if index > 0 {
                            Divider()
                        }
                        HStack {
                            Label(action.label, systemImage: action.systemImage)

                            // Vom System nicht vergeben — meist hält eine andere Anwendung die
                            // Kombination bereits. Bis 1.1.1 blieb das unsichtbar, und das
                            // Kürzel wurde weiterhin als aktiv angezeigt.
                            if appState.hotkeyManager?.failedRegistrations.contains(action) == true {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.orange)
                                    .help("Already in use by another app — this shortcut is inactive")
                            }

                            Spacer()
                            ShortcutRecorderView(
                                binding: bindings[action] ?? action.defaultBinding,
                                isRecording: recordingAction == action,
                                onStartRecording: {
                                    recordingAction = action
                                    conflictMessage = nil
                                },
                                onRecord: { newBinding in
                                    recordBinding(newBinding, for: action)
                                },
                                onCancel: {
                                    recordingAction = nil
                                }
                            )
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                    }
                }
            }

            if let conflict = conflictMessage {
                Label(conflict, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(Color.MikaPlus.destructive)
                    .font(.caption)
            }

            if let failed = appState.hotkeyManager?.failedRegistrations, !failed.isEmpty {
                Label(
                    failed.count == 1
                        ? "1 shortcut is already in use by another app and stays inactive."
                        : "\(failed.count) shortcuts are already in use by other apps and stay inactive.",
                    systemImage: "exclamationmark.triangle"
                )
                .foregroundStyle(.orange)
                .font(.caption)
            }

            HStack {
                Spacer()
                Button {
                    restoreDefaults()
                } label: {
                    Label("Restore Defaults", systemImage: "arrow.counterclockwise")
                }
            }
        }
        .onAppear {
            bindings = appState.hotkeyManager?.currentBindings ?? HotkeyManager.defaultBindings()
        }
        .onChange(of: appState.hotkeyManager?.currentBindings ?? [:]) { _, updated in
            // Etwa nach „Reset All Settings" im Bereich About
            bindings = updated
        }
    }

    private func recordBinding(_ binding: HotkeyBinding, for action: SnapAction) {
        // Systemkürzel sperren: Wer sich ⌘Q auf „Maximieren" legt, kann anschließend kein
        // Programm mehr beenden — die App fängt die Kombination systemweit ab.
        guard !binding.isReserved else {
            conflictMessage = "\(binding.displayString) is reserved by macOS"
            recordingAction = nil
            return
        }

        for (otherAction, otherBinding) in bindings where otherAction != action {
            if otherBinding == binding {
                conflictMessage = "Conflict with \"\(otherAction.label)\""
                recordingAction = nil
                return
            }
        }

        bindings[action] = binding
        recordingAction = nil
        conflictMessage = nil
        appState.hotkeyManager?.reRegisterAll(bindings: bindings)
    }

    private func restoreDefaults() {
        conflictMessage = nil
        appState.hotkeyManager?.restoreDefaults()
        bindings = appState.hotkeyManager?.currentBindings ?? HotkeyManager.defaultBindings()
    }
}

// MARK: - ShortcutRecorderView

public struct ShortcutRecorderView: View {
    public let binding: HotkeyBinding
    public let isRecording: Bool
    public let onStartRecording: () -> Void
    public let onRecord: (HotkeyBinding) -> Void
    public let onCancel: () -> Void

    @State private var keyMonitor: Any?

    public var body: some View {
        Button {
            if isRecording {
                onCancel()
            } else {
                onStartRecording()
            }
        } label: {
            Text(isRecording ? "Press shortcut..." : binding.displayString)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(isRecording ? Color.accentColor : Color.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .frame(minWidth: 100)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(.quaternary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(
                                    isRecording ? Color.accentColor : Color.clear,
                                    lineWidth: 1.5
                                )
                        )
                )
        }
        .buttonStyle(.plain)
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                startMonitoring()
            } else {
                stopMonitoring()
            }
        }
        // Ohne das bliebe der Tastatur-Beobachter bestehen, wenn das Fenster während einer
        // laufenden Aufnahme geschlossen wird — er schluckte weiterhin Tastendrücke.
        .onDisappear {
            stopMonitoring()
        }
    }

    private func startMonitoring() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            if event.keyCode == 53 {
                onCancel()
                return nil
            }

            let carbonModifiers = carbonModifiersFromNSEvent(event.modifierFlags)
            let hasCmdOrCtrl = event.modifierFlags.contains(.command) || event.modifierFlags.contains(.control)
            guard hasCmdOrCtrl else { return nil }

            let newBinding = HotkeyBinding(
                keyCode: UInt32(event.keyCode),
                modifiers: carbonModifiers
            )
            onRecord(newBinding)
            return nil
        }
    }

    private func stopMonitoring() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }

    private func carbonModifiersFromNSEvent(_ flags: NSEvent.ModifierFlags) -> UInt32 {
        var carbon: UInt32 = 0
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        if flags.contains(.shift)   { carbon |= UInt32(shiftKey) }
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        if flags.contains(.option)  { carbon |= UInt32(optionKey) }
        return carbon
    }
}
