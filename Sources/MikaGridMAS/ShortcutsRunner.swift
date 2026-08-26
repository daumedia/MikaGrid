// ShortcutsRunner.swift
// MikaGrid (App Store)
//
// Der Zugang zu Apples Kurzbefehlen (Feature 01, T12).
//
// WARUM „Shortcuts Events" UND NICHT „Shortcuts":
// Apple schreibt es in sein eigenes Skripting-Wörterbuch:
//   „To run a shortcut in the background, without opening the Shortcuts app,
//    tell 'Shortcuts Events' instead of 'Shortcuts'."
// `Shortcuts Events.app` trägt `LSUIElement = 1` — kein Dock-Icon, keine Oberfläche.
// In T01 gemessen: 0,21–0,32 s je Aufruf, kein sichtbares Fenster, kein
// Vordergrundwechsel. Über die Shortcuts-App wäre AK-11 verletzt, über das URL-Schema
// ebenfalls (dort öffnet sich nachweislich das Fenster „Alle Kurzbefehle").
//
// WARUM KEIN URL-SCHEMA ALS RÜCKWEG:
// `design.md` sah `shortcuts://x-callback-url/…` als Rückfall vor. T01 hat das widerlegt.
// Das eigene Schema `mikagrid-mas://` bleibt registriert und nimmt weiterhin nur
// Antworten entgegen, aber der Aufruf läuft nicht darüber (T14).
// Swift 6.0 strict concurrency, macOS 15+

import Foundation

/// Was ein Kurzbefehl über sich preisgibt. Mehr gibt die Schnittstelle nicht her —
/// insbesondere nicht, was seine Aktionen tun.
struct ShortcutDescription: Equatable {
    let name: String
    let actionCount: Int
    let acceptsInput: Bool
}

enum ShortcutsError: Error, Equatable {
    /// Kein Kurzbefehl dieses Namens in der Mediathek.
    case notFound
    /// Der Nutzer hat die Steuerung von Kurzbefehle nicht erlaubt (AppleScript −1743).
    case notAuthorised
    /// Kurzbefehle hat nicht binnen der Frist geantwortet.
    case timedOut
    case other(String)
}

/// Trennt den Systemzugriff von der Logik — sonst wäre weder der
/// `CompanionShortcutManager` noch der `ShortcutsWindowSnapper` prüfbar.
@MainActor
protocol ShortcutsRunning: AnyObject {
    func describeShortcut(named name: String) -> Result<ShortcutDescription, ShortcutsError>
    func run(shortcutNamed name: String, input: String) -> Result<String, ShortcutsError>
}

/// Die echte Umsetzung über Apple Events.
@MainActor
final class ShortcutsRunner: ShortcutsRunning {
    /// Zeitgrenze eines Aufrufs.
    ///
    /// **Nicht eine Sekunde**, obwohl AK-07 das als Zusage nennt: Ein gelungener Snap
    /// dauert gemessen 0,83–0,85 s (der Companion-Kurzbefehl wartet zweimal, damit sich
    /// die Fensteraktionen nicht überholen). Eine Grenze von 1,0 s würde bei der kleinsten
    /// Verzögerung einen laufenden Snap abschneiden und als Fehler melden. Zwei Sekunden
    /// sind die Grenze gegen ein *Hängen*, nicht die Zusage an den Nutzer.
    ///
    /// Die Grenze ist notwendig, nicht vorsorglich: Bei den Messungen blockierte ein Lauf
    /// einmal länger als 60 s, ohne dass ein Dialog sichtbar war.
    static let timeout: TimeInterval = 2.0

    private let target = "Shortcuts Events"

    func describeShortcut(named name: String) -> Result<ShortcutDescription, ShortcutsError> {
        // Nur lesen — dafür genügt die Zugriffsgruppe `com.apple.shortcuts.run`.
        let source = """
        tell application "\(target)"
            set s to shortcut named "\(escape(name))"
            return (action count of s as text) & "|" & (accepts input of s as text)
        end tell
        """
        switch execute(source) {
        case .failure(let error):
            return .failure(error)
        case .success(let raw):
            let parts = raw.components(separatedBy: "|")
            guard parts.count == 2, let count = Int(parts[0].trimmingCharacters(in: .whitespaces)) else {
                return .failure(.other("unexpected reply: \(raw)"))
            }
            let accepts = parts[1].trimmingCharacters(in: .whitespaces).lowercased() == "true"
            return .success(ShortcutDescription(name: name, actionCount: count, acceptsInput: accepts))
        }
    }

    func run(shortcutNamed name: String, input: String) -> Result<String, ShortcutsError> {
        let source = """
        tell application "\(target)"
            run shortcut named "\(escape(name))" with input "\(escape(input))"
        end tell
        """
        return execute(source)
    }

    // MARK: - Intern

    /// AppleScript-Zeichenketten kennen nur `\\` und `"` als Sonderfälle. Fenstertitel
    /// enthalten beides gelegentlich — ohne Maskierung bräche das Skript oder, schlimmer,
    /// führte fremden Text als Code aus.
    private func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    private func execute(_ source: String) -> Result<String, ShortcutsError> {
        // `NSAppleScript` kennt keine Zeitgrenze. Ohne die folgende Konstruktion würde ein
        // hängender Aufruf die Menüleiste einfrieren — dasselbe, was `AXUIElementSet\
        // MessagingTimeout` in der Direktfassung verhindert (B01).
        let box = ReplyBox()
        let done = DispatchSemaphore(value: 0)

        DispatchQueue.global(qos: .userInitiated).async {
            guard let script = NSAppleScript(source: source) else {
                box.finish(result: nil, error: nil, compileFailed: true)
                done.signal()
                return
            }
            var errorInfo: NSDictionary?
            let value = script.executeAndReturnError(&errorInfo)
            box.finish(result: value.stringValue, error: errorInfo, compileFailed: false)
            done.signal()
        }

        guard done.wait(timeout: .now() + Self.timeout) == .success else {
            // Der Aufruf läuft im Hintergrund weiter; sein Ergebnis wird verworfen. Der
            // `nonce` sorgt dafür, dass eine verspätete Antwort keinem späteren Aufruf
            // zugeschlagen wird.
            return .failure(.timedOut)
        }

        if box.compileFailed {
            return .failure(.other("could not compile the script"))
        }
        let errorInfo = box.error
        let resultText = box.result

        if let errorInfo {
            let code = (errorInfo[NSAppleScript.errorNumber] as? Int) ?? 0
            let message = (errorInfo[NSAppleScript.errorMessage] as? String) ?? "unknown"
            switch code {
            case -1743, -1744:
                // Zustimmung fehlt oder wurde verweigert (AK-15, AK-16).
                return .failure(.notAuthorised)
            case -1728:
                // „Can't get shortcut named …" — der Kurzbefehl existiert nicht.
                return .failure(.notFound)
            default:
                // „Can't get shortcut named …" kommt ohne eigene Fehlernummer.
                if message.localizedCaseInsensitiveContains("can't get shortcut")
                    || message.localizedCaseInsensitiveContains("kann kurzbefehl") {
                    return .failure(.notFound)
                }
                return .failure(.other("\(code): \(message)"))
            }
        }

        // Eine leere Antwort ist KEIN Erfolg. Der jeweils erste Zugriff auf eine neue
        // Fähigkeit liefert eine leere Antwort ohne Fehlermeldung — Auslöser ist eine
        // einmalige Zustimmung, die macOS bei einem unsichtbaren Aufruf nicht erfragen kann.
        // Wer das als „gelungen" verbucht, meldet einen Snap, der nie stattfand.
        let text = resultText ?? ""
        if text.isEmpty {
            return .failure(.notAuthorised)
        }
        return .success(text)
    }
}


/// Nimmt das Ergebnis des Hintergrund-Aufrufs entgegen.
///
/// Eigene Klasse statt `inout`-Variablen: Der Aufruf läuft auf einer anderen Warteschlange
/// und kann nach einer Zeitüberschreitung noch schreiben, wenn der Aufrufer längst
/// weitergegangen ist.
private final class ReplyBox: @unchecked Sendable {
    private let lock = NSLock()
    private var _result: String?
    private var _error: NSDictionary?
    private var _compileFailed = false

    func finish(result: String?, error: NSDictionary?, compileFailed: Bool) {
        lock.lock(); defer { lock.unlock() }
        _result = result
        _error = error
        _compileFailed = compileFailed
    }

    var result: String? { lock.lock(); defer { lock.unlock() }; return _result }
    var error: NSDictionary? { lock.lock(); defer { lock.unlock() }; return _error }
    var compileFailed: Bool { lock.lock(); defer { lock.unlock() }; return _compileFailed }
}
