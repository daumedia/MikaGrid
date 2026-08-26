// SnapPayload.swift
// MikaGridCore
//
// Was die App dem Companion-Kurzbefehl übergibt (Feature 01, T10).
//
// Der Zielrahmen wird **in der App** gerechnet, nicht im Kurzbefehl: Dessen eingebaute
// Vorgaben („Left Half") kennen die 2/3-Aufteilung nicht (AK-09) und richten sich nicht
// nach dem Bildschirm, auf dem das Fenster steht (AK-10). So bleibt
// `SnapAction.targetFrame` die einzige Wahrheit für beide Fassungen — und die vorhandenen
// Tests decken sie mit ab (design.md, Entscheidung 9).
//
// KEIN ANWENDUNGSNAME, KEIN FENSTERTITEL:
// `design.md` sah beide Felder vor, damit der Kurzbefehl das richtige Fenster findet.
// Am System zeigte sich, dass ein Filter auf den Anwendungsnamen nur mit einem FESTEN
// Namen greift — aus einer Variablen findet er nichts (machbarkeit.md). Der Kurzbefehl
// nimmt deshalb das vorderste Fenster, und das ist ohnehin das gemeinte.
//
// Das ist mehr als eine Vereinfachung: Die Nutzlast trägt damit **nichts
// Personenbeziehbares** mehr. AK-23 hatte den Fenstertitel ausdrücklich erlaubt, wenn er
// zur Unterscheidung nötig ist — er ist es nicht. Siehe OF-13.
// Swift 6.0 strict concurrency, macOS 14+

import Foundation

/// Die Nutzlast eines Snap-Aufrufs, als JSON kodiert.
///
/// JSON und nicht ein Text mit Trennzeichen: Kurzbefehle nimmt in seinen Zahlenfeldern
/// nichts an, was nicht schon eine Zahl ist. Aus einem Wörterbuch gelesene Werte lassen
/// sich in eine Zahl wandeln, ein herausgeschnittenes Textstück nicht.
public struct SnapPayload: Equatable, Sendable {
    /// Rohwert der Aktion, etwa `leftHalf`. Dient nur der Protokollierung im Kurzbefehl.
    public let action: String
    /// Linke obere Ecke des Zielrahmens in Bildschirmpunkten.
    public let x: Int
    public let y: Int
    public let width: Int
    public let height: Int
    /// Zufallswert je Aufruf. Die Antwort muss ihn zurückliefern, sonst wird sie verworfen.
    public let nonce: String

    /// Trennt Status und `nonce` in der **Antwort**. Die Nutzlast selbst ist JSON.
    public static let separator = "│"

    public init(action: String, x: Int, y: Int, width: Int, height: Int, nonce: String) {
        self.action = action
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.nonce = nonce
    }

    /// Baut die Nutzlast aus Aktion und Zielrahmen.
    public init(action: SnapAction, targetFrame: CGRect, nonce: String) {
        self.action = action.rawValue
        self.x = Int(targetFrame.origin.x.rounded())
        self.y = Int(targetFrame.origin.y.rounded())
        self.width = Int(targetFrame.width.rounded())
        self.height = Int(targetFrame.height.rounded())
        self.nonce = nonce
    }

    /// Die Textfassung, die der Kurzbefehl als Eingabe erhält.
    ///
    /// Von Hand gebaut statt über `JSONEncoder`: Die Reihenfolge bleibt so stabil und
    /// lesbar, und es sind nur fünf Zahlen und eine UUID — nichts, was Maskierung bräuchte.
    /// Der `nonce` stammt aus `UUID` und enthält weder Anführungszeichen noch Backslashes.
    public var encoded: String {
        """
        {"action":"\(action)","x":\(x),"y":\(y),"width":\(width),"height":\(height),"nonce":"\(nonce)"}
        """
    }

    /// Erzeugt einen Zufallswert für die Zuordnung von Antworten.
    public static func makeNonce() -> String {
        UUID().uuidString
    }
}
