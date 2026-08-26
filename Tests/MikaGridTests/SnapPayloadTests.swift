// SnapPayloadTests.swift
// MikaGridTests
//
// Die Nutzlast an den Companion-Kurzbefehl. Zwei Dinge werden hier festgehalten:
//
//  1. Sie enthält **nichts Personenbeziehbares** — keinen Anwendungsnamen, keinen
//     Fenstertitel. AK-23 hatte den Titel erlaubt, falls er zur Unterscheidung nötig ist;
//     er ist es nicht, weil der Kurzbefehl das vorderste Fenster nimmt.
//  2. Sie ist gültiges JSON. Ein Text mit Trennzeichen ginge nicht: Kurzbefehle nimmt in
//     seinen Zahlenfeldern nichts an, was nicht schon eine Zahl ist.

import Testing
import Foundation
@testable import MikaGridCore

@MainActor
struct SnapPayloadTests {

    private func payload(_ action: SnapAction = .leftHalf,
                         frame: CGRect = CGRect(x: 0, y: 25, width: 756, height: 957)) -> SnapPayload {
        SnapPayload(action: action, targetFrame: frame, nonce: "N-1")
    }

    // MARK: - Datensparsamkeit

    @Test("Die Nutzlast trägt weder Anwendungsnamen noch Fenstertitel")
    func carriesNothingPersonal() {
        let encoded = payload().encoded
        for key in ["appName", "windowTitle", "windowIndex"] {
            #expect(!encoded.contains(key), "»\(key)« gehört nicht mehr in die Nutzlast")
        }
    }

    @Test("Genau sechs Felder — mehr braucht der Kurzbefehl nicht")
    func exactlySixFields() {
        let json = try! JSONSerialization.jsonObject(with: Data(payload().encoded.utf8))
        let dict = json as! [String: Any]
        #expect(Set(dict.keys) == ["action", "x", "y", "width", "height", "nonce"])
    }

    // MARK: - Aufbau

    @Test("Die Nutzlast ist gültiges JSON")
    func isValidJSON() {
        // Der Kurzbefehl wandelt sie über „Wörterbuch aus Eingabe" um. Ist sie kein
        // gültiges JSON, bleibt das Wörterbuch leer und nichts wirkt — ohne Fehlermeldung.
        for action in SnapAction.allCases {
            let data = Data(payload(action).encoded.utf8)
            #expect(throws: Never.self) {
                try JSONSerialization.jsonObject(with: data)
            }
        }
    }

    @Test("Zahlen stehen als Zahlen im JSON, nicht als Text")
    func numbersAreNumbers() {
        // Der springende Punkt: Ein Textstück lässt sich in den Zahlenfeldern von
        // „Fenster bewegen" nicht verwenden. Stünde hier "x":"0", käme nichts an.
        let dict = try! JSONSerialization.jsonObject(with: Data(payload().encoded.utf8)) as! [String: Any]
        for key in ["x", "y", "width", "height"] {
            #expect(dict[key] is NSNumber, "»\(key)« muss eine Zahl sein, kein Text")
        }
        #expect(dict["nonce"] is String)
        #expect(dict["action"] is String)
    }

    @Test("Der Zielrahmen kommt unverändert an")
    func frameSurvivesEncoding() {
        let dict = try! JSONSerialization.jsonObject(
            with: Data(payload(.leftHalf, frame: CGRect(x: 12, y: 34, width: 560, height: 780)).encoded.utf8)
        ) as! [String: Any]
        #expect(dict["x"] as? Int == 12)
        #expect(dict["y"] as? Int == 34)
        #expect(dict["width"] as? Int == 560)
        #expect(dict["height"] as? Int == 780)
    }

    @Test("Gebrochene Rahmenwerte werden gerundet, nicht abgeschnitten")
    func fractionalFrameIsRounded() {
        // `visibleFrame` ist auf Bildschirmen mit Notch nicht ganzzahlig. Abschneiden
        // ließe zwischen zwei Hälften einen Spalt stehen — derselbe Fehler, den B01 in
        // der Direktfassung schon einmal hatte.
        let p = SnapPayload(
            action: .rightHalf,
            targetFrame: CGRect(x: 755.5, y: 24.7, width: 756.5, height: 956.4),
            nonce: "N-2"
        )
        #expect(p.x == 756)
        #expect(p.y == 25)
        #expect(p.width == 757)
        #expect(p.height == 956)
    }

    // MARK: - nonce

    @Test("Jeder Aufruf bekommt einen eigenen nonce")
    func nonceIsUnique() {
        // Ohne das ließe sich eine verspätete Antwort einem späteren Aufruf zuordnen.
        #expect(Set((0 ..< 50).map { _ in SnapPayload.makeNonce() }).count == 50)
    }

    @Test("Der nonce bricht weder JSON noch die Antwort")
    func nonceIsSafeToEmbed() {
        for _ in 0 ..< 20 {
            let n = SnapPayload.makeNonce()
            #expect(!n.contains(SnapPayload.separator))
            #expect(!n.contains("\""))
            #expect(!n.contains("\\"))
        }
    }
}
