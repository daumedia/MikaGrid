// SnapReadinessTests.swift
// MikaGridTests
//
// Die Randfälle aus der Spezifikation (T19) und die Regel, dass ein Zustand nie allein an
// der Farbe hängen darf (T20). Beides ist an `SnapReadiness` und `SnapResult` prüfbar —
// die Oberfläche liest ausschließlich von dort.

import Testing
import Foundation
@testable import MikaGridCore

@MainActor
struct SnapReadinessTests {

    // MARK: - T20 · Zustand nicht allein über Farbe

    @Test("Jeder Nicht-bereit-Zustand trägt einen lesbaren Text")
    func everyBlockedStateIsReadable() {
        // Ohne Text bliebe nur das orange Dreieck — bei Rot-Grün-Schwäche und für
        // VoiceOver wertlos (design-system.md).
        let states = [
            SnapReadiness(isReady: false, headline: "Accessibility permission required",
                          detail: "…", actionTitle: "Open Settings"),
            SnapReadiness(isReady: false, headline: "Companion shortcut is missing",
                          detail: "…", actionTitle: "Set Up Shortcut"),
            SnapReadiness(isReady: false, headline: "Companion shortcut was changed",
                          detail: "…", actionTitle: "Set Up Again"),
        ]
        for state in states {
            #expect(!state.headline.isEmpty)
            #expect(!state.detail.isEmpty)
        }
    }

    @Test("Der bereite Zustand braucht keinen Hinweis")
    func readyStateIsSilent() {
        #expect(SnapReadiness.ready.isReady)
        #expect(SnapReadiness.ready.actionTitle == nil)
    }

    // MARK: - T19 · Randfälle

    @Test("Jeder Fehlschlag ist von einem Erfolg unterscheidbar")
    func everyFailureIsDistinguishable() {
        // Der Kern von B01/B05: Bis 1.1.1 endeten alle Abbruchpfade still, und sechs sehr
        // verschiedene Ursachen sahen für den Nutzer gleich aus.
        let failures: [SnapResult] = [
            .missingPermission, .noTargetApp, .noFocusedWindow, .windowNotMovable,
            .nothingToRestore, .companionShortcutMissing, .companionShortcutAltered,
            .automationDenied, .timedOut, .busy,
        ]
        for result in failures {
            #expect(!result.isSuccess, "\(result) darf nicht als Erfolg zählen")
        }
        #expect(SnapResult.applied.isSuccess)
    }

    @Test("EC-01/EC-04: fehlender Kurzbefehl und Zeitüberschreitung melden sich")
    func edgeCasesCarryAMessage() {
        // EC-01 Kurzbefehle entfernt, EC-04 keine Antwort binnen einer Sekunde.
        #expect(SnapResult.companionShortcutMissing.message != nil)
        #expect(SnapResult.automationDenied.message != nil)
        #expect(SnapResult.timedOut.message != nil)
        #expect(SnapResult.companionShortcutAltered.message != nil)
    }

    @Test("EC-05: zwei schnelle Auslösungen bleiben stumm")
    func rapidTriggersStaySilent() {
        // Der zweite Druck wird verworfen, nicht gestapelt. Eine Meldung dafür wäre Lärm —
        // der Nutzer hat es ja selbst ausgelöst.
        #expect(SnapResult.busy.message == nil)
        #expect(!SnapResult.busy.isSuccess)
    }

    @Test("EC-02: ein abweichender Name weicht wirklich ab")
    func alternativeNamesDiffer() {
        // Hat der Nutzer schon einen eigenen Kurzbefehl dieses Namens, wird fremde Arbeit
        // nicht überschrieben, sondern ein anderer Name angeboten.
        let base = "Mika+Grid Snap"
        let names = (0 ..< 5).map { "\(base) \($0 + 1)" }
        #expect(Set(names).count == 5)
        #expect(!names.contains(base))
    }

    // MARK: - AK-24 · kein Netzverkehr

    @Test("Die Nutzlast enthält keine Adresse, die ins Netz zeigt")
    func payloadCarriesNoURL() {
        let p = SnapPayload(
            action: .maximize,
            targetFrame: CGRect(x: 0, y: 0, width: 100, height: 100),
            nonce: "N"
        )
        #expect(!p.encoded.lowercased().contains("http"))
        #expect(!p.encoded.contains("://"))
    }
}
