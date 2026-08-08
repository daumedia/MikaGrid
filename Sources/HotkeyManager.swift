// HotkeyManager.swift
// MikaGrid
//
// Carbon RegisterEventHotKey-based global hotkey manager.
// Adapted from MikaScreenSnap with SnapAction integration.
// Swift 6.0 strict concurrency, macOS 14+

import Carbon
import AppKit

// MARK: - Hotkey Types

struct HotkeyBinding: Codable, Equatable, Sendable {
    let keyCode: UInt32
    let modifiers: UInt32

    var displayString: String {
        let mods = hotkeyModifiersToSymbols(modifiers)
        let key = hotkeyKeyCodeToString(keyCode)
        return mods + key
    }
}

private func hotkeyKeyCodeToString(_ keyCode: UInt32) -> String {
    let map: [UInt32: String] = [
        0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F", 0x04: "H", 0x05: "G",
        0x06: "Z", 0x07: "X", 0x08: "C", 0x09: "V", 0x0B: "B", 0x0C: "Q",
        0x0D: "W", 0x0E: "E", 0x0F: "R", 0x10: "Y", 0x11: "T", 0x12: "1",
        0x13: "2", 0x14: "3", 0x15: "4", 0x16: "6", 0x17: "5", 0x18: "=",
        0x19: "9", 0x1A: "7", 0x1B: "-", 0x1C: "8", 0x1D: "0", 0x1E: "]",
        0x1F: "O", 0x20: "U", 0x21: "[", 0x22: "I", 0x23: "P", 0x25: "L",
        0x26: "J", 0x27: "'", 0x28: "K", 0x29: ";", 0x2A: "\\", 0x2B: ",",
        0x2C: "/", 0x2D: "N", 0x2E: "M", 0x2F: ".",
        0x24: "↩", 0x30: "⇥", 0x31: "Space", 0x33: "⌫", 0x35: "⎋",
        0x7A: "F1", 0x78: "F2", 0x63: "F3", 0x76: "F4", 0x60: "F5",
        0x61: "F6", 0x62: "F7", 0x64: "F8", 0x65: "F9", 0x6D: "F10",
        0x67: "F11", 0x6F: "F12",
        0x7B: "←", 0x7C: "→", 0x7D: "↓", 0x7E: "↑",
    ]
    return map[keyCode] ?? "Key\(keyCode)"
}

private func hotkeyModifiersToSymbols(_ modifiers: UInt32) -> String {
    var result = ""
    if modifiers & UInt32(controlKey) != 0 { result += "⌃" }
    if modifiers & UInt32(optionKey) != 0  { result += "⌥" }
    if modifiers & UInt32(shiftKey) != 0   { result += "⇧" }
    if modifiers & UInt32(cmdKey) != 0     { result += "⌘" }
    return result
}

// MARK: - HotkeyManager

@MainActor
final class HotkeyManager {
    nonisolated(unsafe) private var hotKeyRefs: [EventHotKeyRef?] = []
    /// Der Carbon-Handler wird GENAU EINMAL installiert. `reRegisterAll` tauscht nur die Hotkeys aus —
    /// würde hier jedes Mal ein weiterer Handler installiert, löste ein Tastendruck nach N Änderungen
    /// in den Einstellungen N+1-mal aus (und zerstörte dabei die Restore-Historie).
    nonisolated(unsafe) private var eventHandlerRef: EventHandlerRef?
    private var onSnap: @MainActor (SnapAction) -> Void

    nonisolated(unsafe) private static var instance: HotkeyManager?
    private(set) var currentBindings: [SnapAction: HotkeyBinding]

    init(onSnap: @escaping @MainActor (SnapAction) -> Void, savedBindings: [SnapAction: HotkeyBinding]? = nil) {
        self.onSnap = onSnap

        // Load saved bindings or use defaults
        if let saved = savedBindings {
            self.currentBindings = saved
        } else if let data = UserDefaults.standard.data(forKey: "hotkeyBindings"),
                  let decoded = try? JSONDecoder().decode([String: HotkeyBinding].self, from: data) {
            var bindings: [SnapAction: HotkeyBinding] = [:]
            for (key, value) in decoded {
                if let action = SnapAction(rawValue: key) {
                    bindings[action] = value
                }
            }
            self.currentBindings = bindings
        } else {
            var defaults: [SnapAction: HotkeyBinding] = [:]
            for action in SnapAction.allCases {
                defaults[action] = action.defaultBinding
            }
            self.currentBindings = defaults
        }

        HotkeyManager.instance = self
        registerHotkeys()
    }

    deinit {
        let refs = hotKeyRefs
        for ref in refs {
            if let ref {
                UnregisterEventHotKey(ref)
            }
        }
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
        }
    }

    // MARK: - Public

    func unregisterAll() {
        for ref in hotKeyRefs {
            if let ref {
                UnregisterEventHotKey(ref)
            }
        }
        hotKeyRefs.removeAll()
    }

    func reRegisterAll(bindings: [SnapAction: HotkeyBinding]) {
        unregisterAll()
        currentBindings = bindings
        saveBindings()
        registerHotkeys()
    }

    static func keyCodeToString(_ keyCode: UInt32) -> String {
        hotkeyKeyCodeToString(keyCode)
    }

    static func modifiersToSymbols(_ modifiers: UInt32) -> String {
        hotkeyModifiersToSymbols(modifiers)
    }

    // MARK: - Private

    private func saveBindings() {
        var dict: [String: HotkeyBinding] = [:]
        for (action, binding) in currentBindings {
            dict[action.rawValue] = binding
        }
        if let data = try? JSONEncoder().encode(dict) {
            UserDefaults.standard.set(data, forKey: "hotkeyBindings")
        }
    }

    private func registerHotkeys() {
        // Der Handler ist zustandslos und dispatcht über die hotKeyID — eine Installation reicht für
        // alle folgenden Re-Registrierungen.
        if eventHandlerRef == nil {
            var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

            let handler: EventHandlerUPP = { _, event, _ -> OSStatus in
                var hotKeyID = EventHotKeyID()
                GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)

                DispatchQueue.main.async { @MainActor in
                    guard let manager = HotkeyManager.instance else { return }
                    for action in SnapAction.allCases {
                        if action.hotkeyID == hotKeyID.id {
                            manager.onSnap(action)
                            break
                        }
                    }
                }

                return noErr
            }

            InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, nil, &eventHandlerRef)
        }

        // Signature: "MKGD" (MiKaGriD)
        let signature: OSType = 0x4D4B4744

        for action in SnapAction.allCases {
            guard let binding = currentBindings[action] else { continue }
            var ref: EventHotKeyRef?
            let hotkeyID = EventHotKeyID(signature: signature, id: action.hotkeyID)
            let status = RegisterEventHotKey(binding.keyCode, binding.modifiers, hotkeyID, GetApplicationEventTarget(), 0, &ref)

            if status == noErr {
                hotKeyRefs.append(ref)
            } else {
                print("Failed to register hotkey \(action.rawValue): \(status)")
            }
        }
    }
}
