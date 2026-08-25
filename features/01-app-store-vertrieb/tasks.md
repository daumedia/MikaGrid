# 01 · App-Store-Vertrieb — Aufgabenplan

Status: `tasked` · Stand: 2026-08-25 · Stack-Profil: `swiftui-macos`

Ebenen laufen in Reihenfolge. `[P]` heißt: innerhalb dieser Ebene unabhängig von den
anderen `[P]`-Aufgaben, darf parallel an einen Subagenten gehen.

Nach jeder Ebene läuft der Verifikationsbefehl. **Rot heißt anhalten.**

> **T01 entscheidet über alles Weitere.** Der Entwurf nennt ein Risiko, das den gesamten
> Weg trägt: Wird die Shortcuts-App beim Aufruf sichtbar, ist AK-11 nicht erfüllbar. T01
> misst das an einer Wegwerf-Fassung, **bevor** Xcode-Umbau und Oberfläche Arbeit kosten.
> Fällt T01 negativ aus, endet der Plan dort — und das Feature geht mit dem Messergebnis
> zurück an den Betreiber, nicht weiter in Ebene 2.

## Ebene 1 · Fundament — Projektstruktur und Konfiguration

- [ ] **T01** · **Machbarkeitsversuch, Wegwerf-Code außerhalb von `Sources/`.** Eine
      minimale sandboxed App, die einen Testfenster-Snap auf beiden Wegen auslöst:
      (a) Apple Events an `com.apple.shortcuts`, (b) `shortcuts://x-callback-url/…`.
      Gemessen wird je Weg: Wird die Shortcuts-App sichtbar? Wechselt der Vordergrund?
      Wie lange dauert der Lauf? Zusätzlich prüfen, ob `Find Windows` die Rahmenwerte
      eines Fensters **ausliest** oder nur filtert. Ergebnis als Notiz in
      `features/01-app-store-vertrieb/machbarkeit.md`.
      — Grundlage für T02 bis T23; klärt AK-11 und OF-02
- [ ] **T02** · `project.yml` für XcodeGen: Bibliotheksziel `MikaGridCore`, App-Ziele
      „MikaGrid (Direct)" (`lu.daumedia.mikagrid`) und „MikaGrid (App Store)"
      (`lu.daumedia.mikagrid.mas`), Mindestsysteme 14.0 bzw. 15.0, Sparkle nur im
      Direktziel. `.xcodeproj` in `.gitignore`. — `AK-01, AK-02, AK-22`
- [ ] **T03** · `Package.swift` umbauen: `MikaGridCore` als Bibliotheksziel, Testziel
      hängt daran statt am ausführbaren Ziel. — `AK-04`
- [ ] **T04** · Gemeinsame Quellen nach `Sources/MikaGridCore/` verschieben; im Direktziel
      verbleiben `AccessibilityManager`, `SparkleUpdater` und die AX-Umsetzung.
      — Grundlage für T09
- [ ] **T05** `[P]` · Zwei Entitlement-Dateien: Direktziel unverändert; Store-Ziel mit
      `app-sandbox`, `automation.apple-events` und
      `temporary-exception.apple-events` = `com.apple.shortcuts`.
      — `AK-03, AK-25, AK-27`
- [ ] **T06** `[P]` · `scripts/make-companion-shortcut.sh`: erzeugt den Companion-Shortcut
      (Find Windows → Move → Resize → Move, Antwort als Text), signiert ihn mit
      `shortcuts sign --mode anyone` und legt ihn unter `Resources/` ab.
      — `AK-07, AK-12`
- [ ] **T07** `[P]` · `scripts/build.sh` auf `xcodegen generate` + `xcodebuild` umstellen;
      Verhalten und Ausgaben bleiben gleich, Ad-hoc-Rückfall bleibt erhalten. — `AK-05`
- [ ] **T08** `[P]` · `scripts/release.sh` um einen Store-Zweig erweitern: Archivieren des
      Store-Ziels, Export mit App-Store-Profil, Übergabe an App Store Connect. Zugangsdaten
      ausschließlich aus dem Schlüsselbund. — `AK-06, AK-28`

**Verifikation:** `xcodegen generate && xcodebuild -scheme "MikaGrid (Direct)" build && swift test`

## Ebene 2 · Logik

- [ ] **T09** · Schnittstelle `WindowSnapping` (`snap(action) -> SnapResult`, `isReady`)
      in `MikaGridCore`; `AccessibilityWindowSnapper` im Direktziel erfüllt sie mit dem
      vorhandenen Code. Verhalten der Direktfassung bleibt unverändert. — `AK-01`
- [ ] **T10** `[P]` · Nutzlast-Aufbau: Aktion, Zielrahmen aus
      `SnapAction.targetFrame`, Name der Zielanwendung, `nonce`. `windowTitle` wird
      **nur** gefüllt, wenn die Zielanwendung mehr als ein Fenster hat. Mit Tests für
      beide Fälle. — `AK-08, AK-09, AK-10, AK-23`
- [ ] **T11** `[P]` · `CompanionShortcutManager`: Vorhandensein des Shortcuts prüfen,
      Aufbau gegen den erwarteten Prüfwert vergleichen, Installation der mitgelieferten
      Datei anstoßen. — `AK-17, AK-18, AK-26`
- [ ] **T12** · `ShortcutsWindowSnapper`: Aufruf über den in T01 bestimmten Weg,
      ein Aufruf gleichzeitig, Zeitgrenze 1 s, Antwort über `nonce` zuordnen. Kein
      Netzzugriff. — `AK-07, AK-11, AK-24`
- [ ] **T13** · Rückmessung aus den `actual`-Werten der Antwort auswerten und in
      `SnapResult` übersetzen, einschließlich `no-window` und `not-resizable`. Mit Tests
      für jeden Antwortfall. — `AK-08`

**Verifikation:** `swift test && xcodebuild -scheme "MikaGrid (App Store)" build`

## Ebene 3 · Außenkanten

- [ ] **T14** · URL-Schema `mikagrid-mas://` im Store-Ziel registrieren und Antworten
      entgegennehmen. Jede Antwort ohne gültigen, unverbrauchten `nonce` wird verworfen —
      das Schema nimmt keine Befehle an. Mit Test für eine untergeschobene Antwort.
      — `AK-11`, Zugriffsregel aus `design.md`
- [ ] **T15** · Zustimmung zur Automatisierung: Zustand ermitteln, bei Verweigerung
      `SnapResult` mit Grund liefern und den Weg in die Systemeinstellungen anbieten.
      — `AK-15, AK-16`

**Verifikation:** `swift test && xcodebuild -scheme "MikaGrid (App Store)" build`

## Ebene 4 · Oberfläche

Jede Ansicht braucht vier Zustände: leer, ladend, Fehler, gefüllt.

- [ ] **T16** `[P]` · Onboarding-Schritt „Companion-Shortcut" im Store-Ziel: Anleitung
      und Schaltfläche (leer), „Warte auf Installation…" mit Prüfung im Sekundentakt
      (ladend), Fehlermeldung mit Wiederholung (Fehler), Häkchen und Weiterblättern nach
      ~1 s (gefüllt). Nutzt das Muster aus B05. — `AK-13, AK-14`
- [ ] **T17** `[P]` · Einstellungen → Allgemein: Zeile „Shortcut: eingerichtet" bzw.
      „fehlt oder wurde verändert" mit Schaltfläche zur Neueinrichtung. Nur im Store-Ziel
      sichtbar. — `AK-17, AK-18`
- [ ] **T18** `[P]` · Popover: die neuen Fehlerfälle im bestehenden Hinweisband aus
      v1.2.0 darstellen — kein zweiter Meldeweg. — `AK-16, AK-17`

**Verifikation:** `swift test && xcodebuild -scheme "MikaGrid (App Store)" build && open` beider Fassungen

## Ebene 5 · Feinschliff

- [ ] **T19** · Randfälle: Shortcuts entfernt oder deaktiviert, fremder Shortcut gleichen
      Namens (abweichenden Namen anbieten), zwei Fenster mit gleichem Titel, Zeitüberschreitung,
      zwei Auslösungen kurz hintereinander. — `EC-01, EC-02, EC-03, EC-04, EC-05`
- [ ] **T20** `[P]` · Barrierefreiheit der neuen Oberflächenteile: Beschriftungen und
      Hinweise am Onboarding-Schritt und an der Einstellungszeile, Zustand nicht allein
      über Farbe. Folgt `docs/design-system.md`. — `EC-01`, Muster aus B04
- [ ] **T21** `[P]` · App Store Connect einrichten: Name „Mika+Grid", Preis kostenlos,
      Mindestsystem macOS 15, Beschreibung nennt den Companion-Shortcut **vor** dem
      Download, Datenschutzangaben „keine Daten erhoben". Keine Codeänderung.
      — `AK-19, AK-20, AK-21`
- [ ] **T22** `[P]` · Folgeaufträge aus `spec.md` umsetzen: `docs/prd.md`,
      `docs/datenschutz.md` und `web/app/privacy/page.tsx` um die Fenstertitel-Regel und
      die getrennten Vertriebswege ergänzen. — `AK-23`
- [ ] **T23** · `CHANGELOG.md`, `README.md` und `CLAUDE.md` auf zwei Fassungen umstellen;
      `scripts/check-web-sync.mjs` um das zweite Mindestsystem erweitern. — `AK-19`

**Verifikation:** `swift test && bash scripts/release.sh --check && node scripts/check-web-sync.mjs`

## Abdeckung

| AK | Aufgaben |
|---|---|
| AK-01 | T02, T09 |
| AK-02 | T02 |
| AK-03 | T05 |
| AK-04 | T03 |
| AK-05 | T07 |
| AK-06 | T08 |
| AK-07 | T06, T12 |
| AK-08 | T10, T13 |
| AK-09 | T10 |
| AK-10 | T10 |
| AK-11 | T01, T12, T14 |
| AK-12 | T06 |
| AK-13 | T16 |
| AK-14 | T16 |
| AK-15 | T15 |
| AK-16 | T15, T18 |
| AK-17 | T11, T17, T18 |
| AK-18 | T11, T17 |
| AK-19 | T21, T23 |
| AK-20 | T21 |
| AK-21 | T21 |
| AK-22 | T02 |
| AK-23 | T10, T22 |
| AK-24 | T12 |
| AK-25 | T05 |
| AK-26 | T11 |
| AK-27 | T05 |
| AK-28 | T08 |

**AK ohne Aufgabe:** keine — alle 28 sind zugeordnet.

**Aufgabe ohne AK:** drei, alle zulässig:
- **T01** (Machbarkeitsversuch) — Grundlage für den gesamten Plan; klärt AK-11 und OF-02,
  bevor daran gebaut wird
- **T04** (Quellen verschieben) — Grundlage für T09; reine Umstellung ohne
  Verhaltensänderung
- **T20** (Barrierefreiheit) — verweist auf `EC-01` und das Muster aus B04, wie es die
  Ebene 5 vorsieht

**Anmerkung zu AK-25:** Das Kriterium verlangt „genau eine Berechtigung". Erweist sich in
T01 der URL-Weg als tauglich, bräuchte die App **gar keine** — dann ist AK-25
umzuformulieren, siehe OF-06 in `spec.md`. T05 setzt zunächst die Entitlements aus dem
Entwurf; die endgültige Fassung hängt am Ergebnis von T01.

## Parallelisierung

**Ebene 1:** T05, T06, T07, T08 laufen gleichzeitig, nachdem T02 bis T04 seriell
durchgelaufen sind.

| Aufgabe | Berührt |
|---|---|
| T05 | `Resources/MikaGrid.entitlements`, `Resources/MikaGridMAS.entitlements` |
| T06 | `scripts/make-companion-shortcut.sh`, `Resources/CompanionShortcut.shortcut` |
| T07 | `scripts/build.sh` |
| T08 | `scripts/release.sh` |

Keine gemeinsame Datei. T02 muss vorher liegen, weil `project.yml` auf die
Entitlement-Dateien und das Bundle verweist; T03 und T04 verschieben Quellen, auf die
alles Spätere zeigt.

**Ebene 2:** T10 und T11 laufen gleichzeitig, nach T09.

| Aufgabe | Berührt |
|---|---|
| T10 | `Sources/MikaGridCore/SnapPayload.swift`, `Tests/…/SnapPayloadTests.swift` |
| T11 | `Sources/MikaGridMAS/CompanionShortcutManager.swift`, `Tests/…/CompanionShortcutTests.swift` |

T09 muss vorher liegen (beide Fassungen erfüllen die dort definierte Schnittstelle),
T12 danach (braucht Nutzlast **und** Schnittstelle), T13 nach T12.

**Ebene 4:** T16, T17, T18 laufen gleichzeitig.

| Aufgabe | Berührt |
|---|---|
| T16 | `Sources/MikaGridMAS/Onboarding/CompanionShortcutScreen.swift`, `OnboardingView.swift` |
| T17 | `Sources/MikaGridCore/Preferences/GeneralTabView.swift` |
| T18 | `Sources/MikaGridCore/PopoverGridView.swift` |

Drei verschiedene Ansichten in drei Dateien. **Achtung bei T16:** Es ergänzt einen Schritt
in `OnboardingView.swift` — sollte eine andere Aufgabe dieselbe Datei anfassen müssen,
entfällt dort das `[P]`.

**Ebene 5:** T20, T21, T22 laufen gleichzeitig — Oberfläche, App Store Connect (kein
Code) und Dokumentation berühren einander nicht. T19 und T23 laufen seriell, weil sie
quer über bereits geänderte Dateien gehen.

## Vor dem Bauen

- [ ] Feature-Branch: `git checkout -b feature/01-app-store-vertrieb`
- [ ] XcodeGen vorhanden: `brew install xcodegen`
- [ ] Signaturidentitäten prüfen: Für den Store wird **`3rd Party Mac Developer
      Application`** und ein Provisioning-Profil gebraucht — das vorhandene
      `Developer ID Application` (Team `CWJM4J4HFN`) genügt dafür **nicht**
- [ ] App-Kennung `lu.daumedia.mikagrid.mas` in App Store Connect anlegen
- [ ] `NOTARY_PROFILE` für den Direktvertrieb hinterlegt (offener Punkt aus B09)
- [ ] Keine Zugangsdaten im Repository — sie liegen im Schlüsselbund

**Zuerst T01, dann entscheiden.** Erst wenn der Machbarkeitsversuch beide Fragen
beantwortet hat, lohnt sich die Einrichtung der Store-Kennung und der Zertifikate.
