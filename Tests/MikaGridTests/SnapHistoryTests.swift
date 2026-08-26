// SnapHistoryTests.swift
// MikaGridTests
//
// Die Positionshistorie und ihr Schlüssel. Bis 1.1.1 war der Schlüssel "<PID>_<Fenstertitel>":
// Er brach bei jeder Titeländerung, ließ alle titellosen Fenster einer App kollidieren und
// legte nebenbei Fenstertitel im Arbeitsspeicher ab.

import Testing
import ApplicationServices
import Foundation
@testable import MikaGridCore

@MainActor
struct SnapHistoryTests {

    /// Ein gültiges, eindeutiges AX-Element je Kennzahl — ohne echtes Fenster.
    private func element(_ pid: pid_t) -> AXUIElement {
        AXUIElementCreateApplication(pid)
    }

    @Test("Ein gesicherter Rahmen kommt unverändert zurück")
    func savesAndReads() {
        let history = SnapHistory()
        let key = WindowKey(element(1234))
        let frame = CGRect(x: 10, y: 20, width: 300, height: 400)

        history.savePosition(frame, for: key)
        #expect(history.getPosition(for: key) == frame)
    }

    @Test("Für ein unbekanntes Fenster gibt es nichts zurückzugeben")
    func unknownKeyReturnsNil() {
        let history = SnapHistory()
        #expect(history.getPosition(for: WindowKey(element(999))) == nil)
    }

    @Test("Zwei Referenzen auf dasselbe Element ergeben denselben Schlüssel")
    func sameElementSameKey() {
        // Genau das leistet CFEqual — und genau deshalb überlebt der Schlüssel eine
        // Titeländerung, an der die alte Lösung zerbrach.
        let a = WindowKey(element(4242))
        let b = WindowKey(element(4242))
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)

        let history = SnapHistory()
        let frame = CGRect(x: 1, y: 2, width: 3, height: 4)
        history.savePosition(frame, for: a)
        #expect(history.getPosition(for: b) == frame, "Derselbe Fenster­schlüssel findet den Eintrag nicht")
    }

    @Test("Verschiedene Fenster teilen sich keinen Eintrag")
    func differentElementsDoNotCollide() {
        let history = SnapHistory()
        let first = CGRect(x: 0, y: 0, width: 100, height: 100)
        let second = CGRect(x: 500, y: 500, width: 200, height: 200)

        history.savePosition(first, for: WindowKey(element(1)))
        history.savePosition(second, for: WindowKey(element(2)))

        #expect(history.getPosition(for: WindowKey(element(1))) == first)
        #expect(history.getPosition(for: WindowKey(element(2))) == second)
    }

    @Test("Ein erneutes Sichern überschreibt den bisherigen Rahmen")
    func saveOverwrites() {
        let history = SnapHistory()
        let key = WindowKey(element(7))
        history.savePosition(CGRect(x: 0, y: 0, width: 10, height: 10), for: key)
        let newer = CGRect(x: 5, y: 5, width: 50, height: 50)
        history.savePosition(newer, for: key)
        #expect(history.getPosition(for: key) == newer)
    }

    @Test("Die Historie wächst nicht über ihre Obergrenze hinaus")
    func historyIsBounded() {
        // Ohne Obergrenze hinterließ jedes je gesnappte Fenster dauerhaft einen Eintrag —
        // bei einer App, die monatelang läuft, ein unbegrenzter Bestand.
        let history = SnapHistory()
        for pid in 1...150 {
            history.savePosition(CGRect(x: CGFloat(pid), y: 0, width: 10, height: 10),
                                 for: WindowKey(element(pid_t(pid))))
        }
        #expect(history.count <= 100, "Die Historie ist auf \(history.count) Einträge gewachsen")
    }

    @Test("Bei Überlauf verschwinden die ältesten Einträge, die jüngsten bleiben")
    func oldestEntriesAreEvicted() {
        let history = SnapHistory()
        for pid in 1...120 {
            history.savePosition(CGRect(x: CGFloat(pid), y: 0, width: 10, height: 10),
                                 for: WindowKey(element(pid_t(pid))))
        }
        #expect(history.getPosition(for: WindowKey(element(1))) == nil, "Ältester Eintrag lebt noch")
        #expect(history.getPosition(for: WindowKey(element(120))) != nil, "Jüngster Eintrag fehlt")
    }

    @Test("clearAll leert die Historie vollständig")
    func clearAllEmptiesHistory() {
        let history = SnapHistory()
        let key = WindowKey(element(3))
        history.savePosition(CGRect(x: 0, y: 0, width: 1, height: 1), for: key)
        history.clearAll()
        #expect(history.count == 0)
        #expect(history.getPosition(for: key) == nil)
    }
}

struct SnapResultTests {

    @Test("Nur ein angewendeter Snap gilt als Erfolg")
    func onlyAppliedSucceeds() {
        #expect(SnapResult.applied.isSuccess)
        for result: SnapResult in [.missingPermission, .noTargetApp, .noFocusedWindow,
                                   .windowNotMovable, .nothingToRestore] {
            #expect(!result.isSuccess, "\(result) sollte kein Erfolg sein")
        }
    }

    @Test("Jeder Fehlschlag trägt einen Grund, der Erfolg nicht")
    func everyFailureExplainsItself() {
        // Bis 1.1.1 endeten alle sechs Abbruchpfade mit einem stillen return: Aus Nutzersicht
        // waren sehr verschiedene Ursachen nicht zu unterscheiden.
        #expect(SnapResult.applied.message == nil)
        for result: SnapResult in [.missingPermission, .noTargetApp, .noFocusedWindow,
                                   .windowNotMovable, .nothingToRestore] {
            #expect(result.message?.isEmpty == false, "\(result) hat keinen Grund")
        }
    }
}
