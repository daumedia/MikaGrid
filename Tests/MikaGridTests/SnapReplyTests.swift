// SnapReplyTests.swift
// MikaGridTests
//
// Die Antwort des Companion-Kurzbefehls ist die einzige Rückmeldung, die die Store-Fassung
// bekommt. Wird sie falsch gedeutet, meldet die App einen Snap, der nie stattfand — genau
// der stille Fehlschlag, den B01/B05 in der Direktfassung abgeschafft haben.

import Testing
import Foundation
@testable import MikaGridCore

@MainActor
struct SnapReplyTests {

    private let nonce = "abc-123"
    private func reply(_ status: String, nonce: String) -> String {
        "\(status)\(SnapPayload.separator)\(nonce)"
    }

    // MARK: - Die vier Antwortfälle

    @Test("ok bedeutet: das Fenster sitzt")
    func statusOK() {
        #expect(SnapReply.interpret(reply("ok", nonce: nonce), expecting: nonce) == .applied)
    }

    @Test("no-window meldet ein fehlendes Zielfenster")
    func statusNoWindow() {
        #expect(SnapReply.interpret(reply("no-window", nonce: nonce), expecting: nonce) == .noFocusedWindow)
    }

    @Test("not-resizable meldet ein unbewegliches Fenster")
    func statusNotResizable() {
        #expect(SnapReply.interpret(reply("not-resizable", nonce: nonce), expecting: nonce) == .windowNotMovable)
    }

    @Test("Ein unbekannter Status gilt nicht als Erfolg")
    func unknownStatus() {
        let result = SnapReply.interpret(reply("error", nonce: nonce), expecting: nonce)
        #expect(result != .applied)
    }

    // MARK: - nonce

    @Test("Eine Antwort mit fremdem nonce gilt nicht als Erfolg")
    func mismatchedNonce() {
        // Der Fall einer verspäteten Antwort auf einen früheren Aufruf. Würde sie als
        // Erfolg durchgehen, meldete die App einen Snap, der gerade nicht stattfand.
        let result = SnapReply.interpret(reply("ok", nonce: "ein-anderer"), expecting: nonce)
        #expect(result == .timedOut)
        #expect(result != .applied)
    }

    @Test("Auch ein leerer nonce wird abgewiesen")
    func emptyNonce() {
        #expect(SnapReply.interpret(reply("ok", nonce: ""), expecting: nonce) != .applied)
    }

    // MARK: - Unfug als Eingabe

    @Test("Verstümmelte Antworten gelten nie als Erfolg")
    func malformedRepliesNeverSucceed() {
        // Der Rückweg ist ein offener Eingang; alles, was nicht dem Aufbau entspricht,
        // muss abgewiesen werden statt „irgendwie" gedeutet.
        let junk = ["", "ok", "│", "ok│", "│abc-123", "ok│abc-123│extra│felder",
                    "OK│abc-123", "  ", "ok\nabc-123"]
        for input in junk where input != "ok│abc-123│extra│felder" {
            #expect(SnapReply.interpret(input, expecting: nonce) != .applied,
                    "»\(input)« hätte nicht als Erfolg gelten dürfen")
        }
    }

    @Test("Zusätzliche Felder ändern nichts, solange Status und nonce stimmen")
    func extraFieldsTolerated() {
        // Vorwärtskompatibel: Käme der Kurzbefehl später mit mehr Feldern zurück, soll ein
        // gelungener Snap nicht plötzlich als Fehler zählen.
        let result = SnapReply.interpret("ok│abc-123│extra", expecting: nonce)
        #expect(result == .applied)
    }

    @Test("Umgebende Leerzeichen und Zeilenenden stören nicht")
    func trimsWhitespace() {
        #expect(SnapReply.interpret("  ok│abc-123\n", expecting: nonce) == .applied)
    }
}
