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

    /// Kombinationen, die macOS für sich beansprucht. Wer sich ⌘Q auf „Maximieren" legt, kann
    /// anschließend kein Programm mehr beenden — die App würde das Kürzel systemweit abfangen.
    private static let reserved: [(keyCode: UInt32, modifiers: UInt32)] = [
        (0x0C, UInt32(cmdKey)),                        // ⌘Q  beenden
        (0x0D, UInt32(cmdKey)),                        // ⌘W  schließen
        (0x30, UInt32(cmdKey)),                        // ⌘⇥  Programmwechsler
        (0x31, UInt32(cmdKey)),                        // ⌘Leertaste  Spotlight
        (0x2F, UInt32(cmdKey)),                        // ⌘.  abbrechen
        (0x35, UInt32(cmdKey)),                        // ⌘⎋
        (0x0C, UInt32(cmdKey | optionKey)),            // ⌥⌘Q  abmelden
        (0x35, UInt32(cmdKey | optionKey)),            // ⌥⌘⎋  Sofort beenden
    ]

    /// Ist diese Kombination dem System vorbehalten?
    var isReserved: Bool {
        Self.reserved.contains { $0.keyCode == keyCode && $0.modifiers == modifiers }
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
@Observable
final class HotkeyManager {
    /// Fassung des Speicherformats von `hotkeyBindings`. Wird erhöht, sobald sich der Aufbau
    /// von `HotkeyBinding` ändert. Ohne sie verwirft ein Formatfehler stillschweigend die
    /// gesamte Belegung des Nutzers und niemand erfährt davon.
    static let schemaVersion = 1
    private static let schemaVersionKey = "hotkeyBindingsSchemaVersion"
    private static let bindingsKey = "hotkeyBindings"

    // `nonisolated(unsafe)` statt `nonisolated`: Der Makro-Ausbau von @Observable erlaubt
    // `nonisolated` auf veränderlichen gespeicherten Eigenschaften nicht. Der Zugriff erfolgt
    // ausschließlich aus `deinit` und vom MainActor.
    nonisolated(unsafe) private var hotKeyRefs: [EventHotKeyRef?] = []
    /// Der Carbon-Handler wird GENAU EINMAL installiert. `reRegisterAll` tauscht nur die Hotkeys aus —
    /// würde hier jedes Mal ein weiterer Handler installiert, löste ein Tastendruck nach N Änderungen
    /// in den Einstellungen N+1-mal aus (und zerstörte dabei die Restore-Historie).
    nonisolated(unsafe) private var eventHandlerRef: EventHandlerRef?
    private var onSnap: @MainActor (SnapAction) -> Void

    nonisolated(unsafe) private static var instance: HotkeyManager?
    private(set) var currentBindings: [SnapAction: HotkeyBinding]

    /// Aktionen, deren Kürzel das System nicht vergeben hat — meist, weil eine andere Anwendung
    /// die Kombination bereits hält. Die Einstellungen zeigen das an, statt ein totes Kürzel
    /// weiterhin als aktiv auszugeben.
    private(set) var failedRegistrations: Set<SnapAction> = []

    init(onSnap: @escaping @MainActor (SnapAction) -> Void, savedBindings: [SnapAction: HotkeyBinding]? = nil) {
        self.onSnap = onSnap

        self.currentBindings = savedBindings ?? Self.loadBindings()

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

    /// Setzt alle elf Kürzel auf ihren Standard zurück und meldet sie sofort neu an.
    func restoreDefaults() {
        reRegisterAll(bindings: Self.defaultBindings())
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
            UserDefaults.standard.set(data, forKey: Self.bindingsKey)
            UserDefaults.standard.set(Self.schemaVersion, forKey: Self.schemaVersionKey)
        }
    }

    /// Die Standardbelegung aller elf Aktionen.
    static func defaultBindings() -> [SnapAction: HotkeyBinding] {
        var defaults: [SnapAction: HotkeyBinding] = [:]
        for action in SnapAction.allCases {
            defaults[action] = action.defaultBinding
        }
        return defaults
    }

    /// Lädt die gespeicherte Belegung und **füllt fehlende Aktionen mit ihrem Standard auf**.
    ///
    /// Ohne das Auffüllen bekäme eine in einem künftigen Release ergänzte Aktion bei allen
    /// Bestandsnutzern gar kein Kürzel: `registerHotkeys()` überspringt Aktionen ohne Belegung,
    /// und die neue Funktion wäre per Tastatur tot, bis jemand „Restore Defaults" drückt.
    ///
    /// Stammt der gespeicherte Stand aus einer neueren Fassung des Formats, wird er verworfen —
    /// besser die Standardbelegung als eine halb gelesene.
    static func loadBindings(from defaults: UserDefaults = .standard) -> [SnapAction: HotkeyBinding] {
        var bindings = defaultBindings()

        let storedVersion = defaults.integer(forKey: schemaVersionKey)
        guard storedVersion <= schemaVersion else { return bindings }

        guard let data = defaults.data(forKey: bindingsKey),
              let decoded = try? JSONDecoder().decode([String: HotkeyBinding].self, from: data)
        else { return bindings }

        for (key, value) in decoded {
            guard let action = SnapAction(rawValue: key) else { continue }
            bindings[action] = value
        }
        return bindings
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

        var failed: Set<SnapAction> = []
        for action in SnapAction.allCases {
            guard let binding = currentBindings[action] else { continue }
            var ref: EventHotKeyRef?
            let hotkeyID = EventHotKeyID(signature: signature, id: action.hotkeyID)
            let status = RegisterEventHotKey(binding.keyCode, binding.modifiers, hotkeyID, GetApplicationEventTarget(), 0, &ref)

            if status == noErr {
                hotKeyRefs.append(ref)
            } else {
                // Meist bereits von einer anderen Anwendung belegt. Das Kürzel bleibt wirkungslos —
                // die Einstellungen zeigen das an, statt es weiter als aktiv auszugeben.
                failed.insert(action)
            }
        }
        failedRegistrations = failed
    }
}
