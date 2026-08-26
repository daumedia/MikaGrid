// SnapReply.swift
// MikaGridCore
//
// Die Antwort des Companion-Kurzbefehls, übersetzt in ein `SnapResult` (Feature 01, T13).
//
// Liegt in der gemeinsamen Bibliothek, obwohl nur die Store-Fassung sie benutzt: Das ist
// reine Rechnung ohne Systemzugriff — genau die Sorte Logik, deren Fehler sonst erst beim
// Nutzer auffallen. Im App-Ziel wäre sie nicht prüfbar.
//
// WAS HIER FEHLT UND WARUM: `design.md` sieht in der Antwort `actualX/Y/Width/Height` vor,
// damit die Store-Fassung nachmessen kann wie die Direktfassung (Entwurfsentscheidung 7).
// Diese Werte kann Kurzbefehle nicht liefern — `Find Windows` gibt die Rahmenwerte eines
// Fensters nicht her (OF-02, in T01 am System gemessen). Eine Rückmessung ist damit nicht
// baubar, und AK-08 in seiner heutigen Fassung nicht prüfbar (OF-07).
// Swift 6.0 strict concurrency, macOS 14+

import Foundation

public enum SnapReply {
    /// Übersetzt `status│nonce` in ein Ergebnis.
    ///
    /// - Parameter nonce: Der Wert des laufenden Aufrufs. Eine Antwort mit einem anderen
    ///   gehört zu einem früheren Aufruf und wird **nicht** als Erfolg gewertet — sonst
    ///   meldete eine verspätete Antwort einen Snap, der gerade gar nicht stattfand.
    public static func interpret(_ reply: String, expecting nonce: String) -> SnapResult {
        let fields = reply.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: SnapPayload.separator)

        // Weniger als zwei Felder heißt: Das ist nicht unsere Antwort.
        guard fields.count >= 2 else { return .noFocusedWindow }
        guard fields[1] == nonce else { return .timedOut }

        switch fields[0] {
        case "ok":            return .applied
        case "no-window":     return .noFocusedWindow
        case "not-resizable": return .windowNotMovable
        default:              return .noFocusedWindow
        }
    }
}
