# Mika+Grid — Datenmodell

Stand: 2026-08-25 · Stufe Datenschutz: A · Artefaktpfad: `docs/`

> **Rekonstruktion aus dem Bestand (Version 1.1.1).** Beschrieben ist, was die App
> tatsächlich speichert — nachgeprüft am Code *und* an der `UserDefaults`-Datei der
> installierten App (`defaults read lu.daumedia.mikagrid`, gelesen am 2026-08-25).

## Die kurze Fassung

**Es gibt keine Datenbank, keinen Server, keine Dateien.** Weder `FileManager`- noch
Keychain-Zugriffe existieren im Quelltext. Alles Dauerhafte liegt in genau einer Datei:

```
~/Library/Preferences/lu.daumedia.mikagrid.plist    (265 Bytes, Rechte 0600)
```

Der Rest lebt im Arbeitsspeicher und ist beim Beenden weg. Ein Datenmodell im üblichen
Sinn — Entitäten, Beziehungen, Fremdschlüssel — hat diese App nicht. Was sie hat, sind
**vier Speicherorte mit sehr unterschiedlicher Lebensdauer**.

| Ort | Lebensdauer | Inhalt | Personenbezug |
|---|---|---|---|
| `UserDefaults` (Suite `lu.daumedia.mikagrid`) | über Neustarts, überlebt Deinstallation | Einstellungen der App und von Sparkle | nein |
| `SnapHistory` (Dictionary im RAM) | bis zum Beenden | Fensterrahmen je Fenster, **Schlüssel enthält den Fenstertitel** | möglich, siehe unten |
| `HotkeyManager.currentBindings` (RAM) | bis zum Beenden, gespiegelt nach `UserDefaults` | aktive Tastenbelegung | nein |
| macOS-Systemdienste | außerhalb der App | Accessibility-Zustimmung (TCC), Anmeldeobjekt (`SMAppService`), Position des Menüleistensymbols | nein |

## 1 · `UserDefaults` — der einzige dauerhafte Speicher

### Von der App selbst geschrieben

| Schlüssel | Typ | Standard | Geschrieben von | Bemerkung |
|---|---|---|---|---|
| `hasCompletedOnboarding` | Bool | `false` | `AppPreferences.didSet`, `OnboardingWindowController.windowWillClose`, `ShortcutsScreen` („Done") | Steuert, ob das Onboarding beim Start erscheint |
| `permissionSkipped` | Bool | `false` | `AppPreferences.didSet` über `PermissionScreen` („Skip for now") | Unterdrückt die erneute Berechtigungsabfrage beim Start |
| `hotkeyBindings` | `Data` (JSON) | *nicht vorhanden* | `HotkeyManager.saveBindings()` | JSON-Abbild von `[String: HotkeyBinding]`, Schlüssel ist `SnapAction.rawValue` |
| `animationsEnabled` | Bool | — | **niemand mehr** | Verwaist. Die Einstellung wurde in 1.1.1 entfernt; der Schlüssel steht nur noch in der Löschliste von `resetAllPreferences()`, damit Altbestände aufgeräumt werden |

**Beobachtung aus der laufenden Installation:** Nur `hasCompletedOnboarding` ist
tatsächlich vorhanden. `permissionSkipped` und `hotkeyBindings` fehlen — beide werden
erst beim ersten aktiven Eingriff des Nutzers angelegt (Überspringen bzw. Kürzel ändern).
Standardwerte werden nie vorsorglich geschrieben. Das ist beabsichtigt und funktioniert,
hat aber eine Folge, die unter *Fehlbestand* steht.

### Von Sparkle geschrieben (Fremdrahmen, dieselbe Suite)

| Schlüssel | Wert in der Installation | Bedeutung |
|---|---|---|
| `SUEnableAutomaticChecks` | `1` | Automatisch nach Updates suchen. **Der einzige Schalter, den die App selbst anzeigt** (Preferences → General → „Automatic updates") |
| `SUAutomaticallyUpdate` | `1` | Gefundene Updates **automatisch herunterladen und installieren**. Wird von Sparkles eigenem Dialog beim ersten Start gesetzt — die App hat dafür keine Oberfläche |
| `SUSendProfileInfo` | `0` | System-Profiling aus. Bestätigt die Datenschutzaussage im PRD am realen Zustand, nicht nur am fehlenden `Info.plist`-Schlüssel |
| `SULastCheckTime` | Datum | Zeitpunkt der letzten Prüfung; in Preferences als „Last checked" angezeigt |
| `SUHasLaunchedBefore` | `1` | Sparkles eigene Erststart-Erkennung |

### Von AppKit geschrieben

| Schlüssel | Bedeutung |
|---|---|
| `NSStatusItem Preferred Position Item-0` | Vom System gepflegte Position des Menüleistensymbols |

## 2 · `SnapHistory` — flüchtig, aber der einzige Ort mit möglichem Personenbezug

```swift
private var positions: [String: CGRect] = [:]
```

| Feld | Aufbau | Beispiel |
|---|---|---|
| Schlüssel | `"<PID>_<Fenstertitel>"` | `"4711_Quartalsbericht Meier.pdf"` |
| Wert | `CGRect` in AX-Koordinaten (Ursprung oben links) | `{x: 0, y: 25, w: 1280, h: 1415}` |

Geschrieben wird **vor jedem Snap** der Rahmen, den das Fenster in diesem Moment hat;
gelesen wird er von der Aktion `restore`. Fehlt der Titel, tritt `"untitled"` an seine
Stelle.

**Warum das im Datenmodell steht, obwohl nichts gespeichert wird:** Ein Fenstertitel kann
ein Dokumentname, ein E-Mail-Betreff oder eine besuchte Website sein. Der Wert wird nie
auf die Platte geschrieben, nie protokolliert und nie übertragen — aber er ist da, und
wer künftig eine Persistenz der Historie baut (naheliegender Wunsch: „Restore soll einen
Neustart überleben"), macht daraus ohne weiteres Zutun eine dauerhafte, personenbeziehbare
Datei. Diese Zeile ist der Grund, warum das hier auffallen soll.

**Löschregeln:** `clearAll()` existiert, wird aber **von keiner Stelle im Code
aufgerufen**. Es gibt keine Obergrenze, keine Verdrängung und kein Aufräumen beendeter
Prozesse.

## 3 · `HotkeyBinding` — die einzige serialisierte Struktur

```swift
struct HotkeyBinding: Codable, Equatable, Sendable {
    let keyCode: UInt32      // Carbon-Tastencode, z. B. 0x7B = Pfeil links
    let modifiers: UInt32    // Carbon-Maske: controlKey | optionKey | shiftKey | cmdKey
}
```

Persistiert als JSON-Wörterbuch unter `hotkeyBindings`, Schlüssel ist der
`SnapAction.rawValue` (`"leftHalf"`, `"maximize"`, …). Elf Einträge im Vollausbau.
Die Standardbelegung steht nicht in den Daten, sondern im Code
(`SnapAction.defaultBinding`) und wird nur bei fehlendem oder unlesbarem Datensatz
herangezogen.

## 4 · Zustand außerhalb der App

| Was | Wo | Wer ist die Wahrheit |
|---|---|---|
| Accessibility-Zustimmung | macOS TCC-Datenbank | Das System. Die App liest nur (`AXIsProcessTrusted()`), sie kann nichts setzen |
| Start bei der Anmeldung | `SMAppService.mainApp` | Das System — bewusst kein Spiegel in `UserDefaults` (`LaunchAtLoginManager`: „System is source of truth") |

## Fehlbestand

Lücken, keine Kriterien. Was hier steht, ist **nicht** als beabsichtigt zu lesen.

- **Keine Schemaversion, kein Aufstiegspfad.** Die `UserDefaults` tragen keine
  Versionsnummer. Das Stack-Profil `swiftui-macos` benennt genau das als Pflicht:
  „Steht keiner in `design.md`, verliert der Nutzer beim Update seine Konfiguration."
- **Ein fehlgeschlagenes Decoding verwirft alle Anpassungen stillschweigend.**
  `try? JSONDecoder().decode(...)` fällt bei jedem Formatfehler auf den `else`-Zweig und
  damit auf die Standardbelegung zurück. Der Nutzer erhält keinen Hinweis; seine elf
  angepassten Kürzel sind ohne Meldung weg. Erweitert je ein künftiges Release die
  Struktur `HotkeyBinding` um ein Feld, tritt genau das bei allen Bestandsnutzern ein.
- **Eine neu hinzugefügte Aktion bekommt bei Bestandsnutzern kein Kürzel.** Beim Laden
  wird nur übernommen, was in der Datei steht; für Aktionen, die dort fehlen, wird
  *kein* Standard nachgezogen. `registerHotkeys()` überspringt sie per
  `guard let binding = currentBindings[action] else { continue }`. Ergebnis: Die neue
  Aktion ist per Tastatur tot, bis der Nutzer von sich aus „Restore Defaults" drückt.
  Dasselbe passiert, wenn ein `SnapAction`-Fall je umbenannt wird.
- **`SnapHistory` wächst unbegrenzt.** Kein Limit, keine Verdrängung, kein Aufräumen bei
  Prozessende. Jedes je gesnappte Fenster hinterlässt dauerhaft einen Eintrag samt Titel
  im Speicher; `clearAll()` wird nirgends aufgerufen.
- **Der Historien-Schlüssel bricht, sobald sich der Fenstertitel ändert.** Browser-Tab
  gewechselt, Datei gespeichert, Dokument umbenannt — der Schlüssel `"<PID>_<Titel>"`
  passt nicht mehr, und `restore` findet nichts und tut kommentarlos gar nichts. Für
  Fenster ohne Titel kollidieren umgekehrt **alle** Fenster derselben App auf
  `"<PID>_untitled"` und überschreiben sich gegenseitig.
- **`SUAutomaticallyUpdate` wird gesetzt, aber nie angezeigt.** Auf dem geprüften System
  steht der Wert auf `1`: Updates installieren sich selbsttätig. Die Oberfläche der App
  kennt nur „Automatic updates" (`SUEnableAutomaticChecks`) und erweckt damit den
  Eindruck, es gäbe nur eine Stufe. Wer die automatische Installation abschalten will,
  findet in der App keinen Weg dazu.
- **Deinstallation hinterlässt alles.** Es gibt keine Aufräumroutine: Die `plist` bleibt
  liegen, der Accessibility-Eintrag bleibt in den Systemeinstellungen stehen, ein
  gesetztes Anmeldeobjekt bleibt registriert. Bei Stufe A ist das kein Datenschutzproblem,
  aber es ist unaufgeräumt und gehört benannt.
- **`resetAllPreferences()` setzt `hasCompletedOnboarding` auf `true`, nicht auf
  `false`.** „Alle Einstellungen zurücksetzen" führt also **nicht** in den Auslieferungs-
  zustand zurück — das Onboarding erscheint danach nicht erneut. Ob das gewollt ist
  (der Nutzer kennt die App ja bereits) oder ein Versehen, entscheidet die Rückerfassung
  von B07; hier steht nur, was der Code tut.
