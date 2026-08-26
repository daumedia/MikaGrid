// HotkeyTests.swift
// MikaGridTests
//
// Laden, Speichern und Prüfen der Tastenbelegung — der Teil von B03, der ohne Fenster
// und ohne Carbon auskommt.

import Testing
import Carbon
import Foundation
@testable import MikaGridCore

struct HotkeyBindingTests {

    @Test("Die Anzeige setzt Umschalttasten in der üblichen Reihenfolge")
    func displayStringOrdersModifiers() {
        let binding = HotkeyBinding(keyCode: 0x7B, modifiers: UInt32(controlKey | optionKey))
        #expect(binding.displayString == "⌃⌥←")
    }

    @Test("Alle vier Umschalttasten erscheinen in fester Reihenfolge")
    func allModifiers() {
        let all = UInt32(controlKey | optionKey | shiftKey | cmdKey)
        #expect(HotkeyBinding(keyCode: 0x00, modifiers: all).displayString == "⌃⌥⇧⌘A")
    }

    @Test("Ein unbekannter Tastencode fällt auf eine lesbare Ersatzdarstellung zurück")
    func unknownKeyCode() {
        #expect(HotkeyBinding(keyCode: 0xFE, modifiers: 0).displayString == "Key254")
    }

    @Test("Speichern und Laden verändert die Belegung nicht")
    func codableRoundTrip() throws {
        let original = HotkeyBinding(keyCode: 0x24, modifiers: UInt32(controlKey | optionKey))
        let data = try JSONEncoder().encode(original)
        #expect(try JSONDecoder().decode(HotkeyBinding.self, from: data) == original)
    }

    @Test("Reservierte Systemkürzel werden erkannt")
    func reservedShortcutsAreRejected() {
        #expect(HotkeyBinding(keyCode: 0x0C, modifiers: UInt32(cmdKey)).isReserved, "⌘Q")
        #expect(HotkeyBinding(keyCode: 0x0D, modifiers: UInt32(cmdKey)).isReserved, "⌘W")
        #expect(HotkeyBinding(keyCode: 0x31, modifiers: UInt32(cmdKey)).isReserved, "⌘Leertaste")
    }

    @Test("Die Standardbelegungen sind nicht reserviert")
    @MainActor
    func defaultsAreNotReserved() {
        for action in SnapAction.allCases {
            #expect(!action.defaultBinding.isReserved, "\(action.label) kollidiert mit dem System")
        }
    }
}

@MainActor
struct SnapActionBindingTests {

    @Test("Jede Aktion hat eine eigene Kennzahl für den Carbon-Rückruf")
    func hotkeyIDsAreUnique() {
        let ids = SnapAction.allCases.map(\.hotkeyID)
        #expect(Set(ids).count == SnapAction.allCases.count, "Zwei Aktionen teilen sich eine Kennzahl")
    }

    @Test("Keine zwei Aktionen tragen dieselbe Standardbelegung")
    func defaultBindingsAreUnique() {
        let bindings = SnapAction.allCases.map(\.defaultBinding)
        for (i, a) in bindings.enumerated() {
            for b in bindings[(i + 1)...] {
                #expect(a != b, "Doppelte Standardbelegung: \(a.displayString)")
            }
        }
    }

    @Test("Alle Standardbelegungen benutzen ⌃⌥")
    func defaultsUseControlOption() {
        let expected = UInt32(controlKey | optionKey)
        for action in SnapAction.allCases {
            #expect(action.defaultBinding.modifiers == expected, "\(action.label)")
        }
    }

    @Test("Es gibt genau elf Aktionen")
    func elevenActions() {
        #expect(SnapAction.allCases.count == 11)
    }
}

@MainActor
struct HotkeyPersistenceTests {

    /// Eigene Suite je Testlauf, damit die echten Einstellungen unberührt bleiben.
    private func makeDefaults(_ name: String) -> UserDefaults {
        let defaults = UserDefaults(suiteName: "lu.daumedia.mikagrid.tests.\(name)")!
        defaults.removePersistentDomain(forName: "lu.daumedia.mikagrid.tests.\(name)")
        return defaults
    }

    @Test("Ohne gespeicherten Stand gelten die Standardbelegungen")
    func emptyStoreYieldsDefaults() {
        let loaded = HotkeyManager.loadBindings(from: makeDefaults("empty"))
        #expect(loaded.count == SnapAction.allCases.count)
        #expect(loaded[.leftHalf] == SnapAction.leftHalf.defaultBinding)
    }

    @Test("Eine gespeicherte Belegung wird übernommen")
    func storedBindingIsUsed() throws {
        let defaults = makeDefaults("stored")
        let custom = HotkeyBinding(keyCode: 0x11, modifiers: UInt32(cmdKey | shiftKey))
        let data = try JSONEncoder().encode(["leftHalf": custom])
        defaults.set(data, forKey: "hotkeyBindings")
        defaults.set(HotkeyManager.schemaVersion, forKey: "hotkeyBindingsSchemaVersion")

        let loaded = HotkeyManager.loadBindings(from: defaults)
        #expect(loaded[.leftHalf] == custom)
    }

    @Test("Fehlende Aktionen bekommen ihren Standard nachgezogen")
    func missingActionsAreBackfilled() throws {
        // Genau der Fall, der eine in einem künftigen Release ergänzte Aktion bis 1.1.1
        // per Tastatur tot gelassen hätte: Sie fehlt im gespeicherten Stand und bekam
        // keinen Standardwert — registriert wurde sie deshalb nie.
        let defaults = makeDefaults("partial")
        let custom = HotkeyBinding(keyCode: 0x11, modifiers: UInt32(cmdKey))
        let data = try JSONEncoder().encode(["leftHalf": custom])
        defaults.set(data, forKey: "hotkeyBindings")
        defaults.set(HotkeyManager.schemaVersion, forKey: "hotkeyBindingsSchemaVersion")

        let loaded = HotkeyManager.loadBindings(from: defaults)
        #expect(loaded.count == SnapAction.allCases.count, "Nicht alle Aktionen haben eine Belegung")
        #expect(loaded[.leftHalf] == custom, "Die gespeicherte Belegung ging verloren")
        #expect(loaded[.maximize] == SnapAction.maximize.defaultBinding, "Standard nicht nachgezogen")
    }

    @Test("Unbekannte Aktionen im gespeicherten Stand werden übergangen")
    func unknownActionIsIgnored() throws {
        let defaults = makeDefaults("unknown")
        let data = try JSONEncoder().encode([
            "leftHalf": HotkeyBinding(keyCode: 0x11, modifiers: UInt32(cmdKey)),
            "thirdsLeft": HotkeyBinding(keyCode: 0x12, modifiers: UInt32(cmdKey)),
        ])
        defaults.set(data, forKey: "hotkeyBindings")
        defaults.set(HotkeyManager.schemaVersion, forKey: "hotkeyBindingsSchemaVersion")

        let loaded = HotkeyManager.loadBindings(from: defaults)
        #expect(loaded.count == SnapAction.allCases.count)
    }

    @Test("Ein Stand aus einer neueren Formatfassung wird verworfen")
    func futureSchemaFallsBackToDefaults() throws {
        let defaults = makeDefaults("future")
        let custom = HotkeyBinding(keyCode: 0x11, modifiers: UInt32(cmdKey))
        let data = try JSONEncoder().encode(["leftHalf": custom])
        defaults.set(data, forKey: "hotkeyBindings")
        defaults.set(HotkeyManager.schemaVersion + 1, forKey: "hotkeyBindingsSchemaVersion")

        let loaded = HotkeyManager.loadBindings(from: defaults)
        #expect(loaded[.leftHalf] == SnapAction.leftHalf.defaultBinding,
                "Ein unlesbarer Stand darf nicht halb übernommen werden")
    }

    @Test("Beschädigte Daten führen zur Standardbelegung, nicht zu einer leeren")
    func corruptDataYieldsDefaults() {
        let defaults = makeDefaults("corrupt")
        defaults.set(Data([0x00, 0x01, 0x02]), forKey: "hotkeyBindings")
        defaults.set(HotkeyManager.schemaVersion, forKey: "hotkeyBindingsSchemaVersion")

        let loaded = HotkeyManager.loadBindings(from: defaults)
        #expect(loaded.count == SnapAction.allCases.count)
    }

    @Test("Die Standardbelegung deckt alle Aktionen ab")
    func defaultBindingsAreComplete() {
        #expect(HotkeyManager.defaultBindings().count == SnapAction.allCases.count)
    }
}
