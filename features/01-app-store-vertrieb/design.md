# 01 · App-Store-Vertrieb — Systemdesign

Status: `architected` · Stand: 2026-08-25 · Stack-Profil: `swiftui-macos`

**Kein Code in diesem Dokument.** Es wird gelesen und freigegeben, nicht ausgeführt.

## Überblick

Aus einem Quelltext entstehen zwei Apps. Der gesamte gemeinsame Teil — Zielgeometrie,
Tastenkürzel, Popover, Einstellungen, Onboarding — wandert in eine Bibliothek, die beide
benutzen. Was sich unterscheidet, ist genau eine Stelle: **wie ein Fenster tatsächlich
bewegt wird.**

Die Direktfassung schreibt den Rahmen wie bisher selbst über die Accessibility-API. Die
Store-Fassung darf das nicht und lässt es Apples Shortcuts-App tun: Sie berechnet
denselben Zielrahmen, verpackt ihn als Nutzlast und ruft einen mitgelieferten
Companion-Shortcut auf, der `Find Windows`, `Move Window` und `Resize Window` ausführt.

Beide Fassungen sprechen dieselbe Schnittstelle an. Für alles oberhalb dieser Naht ist
nicht erkennbar, welche der beiden läuft — deshalb bleiben Popover, Kürzel und
Fehlermeldungen unverändert und müssen nicht doppelt gepflegt werden.

## Ziele, Schemata, Einstiegspunkte

Die Vorlage sieht hier Seiten und Routen vor; eine Menüleisten-App hat keine. An ihre
Stelle treten die beiden Bauziele und die Wege, auf denen sie angesprochen werden.

| Ziel | Bundle-Bezeichner | Sandbox | Fenster bewegt | Mindestsystem | Updates |
|---|---|---|---|---|---|
| **MikaGrid (Direct)** | `lu.daumedia.mikagrid` | nein | selbst, über die Accessibility-API | macOS 14 | Sparkle |
| **MikaGrid (App Store)** | `lu.daumedia.mikagrid.mas` | ja | über Shortcuts | macOS 15 | App Store |

Getrennte Bezeichner, weil ein Nutzer beide installieren kann und sie sonst einander
überschreiben, Einstellungen teilen und sich beim Anmeldeobjekt in die Quere kommen
(löst OF-04 der Spezifikation).

| Einstieg | Gilt für | Wirkung |
|---|---|---|
| ⌃⌥ + Taste | beide | löst eine Snap-Aktion aus (B03, unverändert) |
| Rasterzone im Popover | beide | dieselbe Aktion (B04, unverändert) |
| `mikagrid-mas://snap-done?…` | nur Store | Rückmeldung des Shortcuts an die App |
| `mikagrid-mas://snap-failed?…` | nur Store | Fehlermeldung des Shortcuts an die App |

Das eigene URL-Schema existiert ausschließlich, um die Antwort des Shortcuts
entgegenzunehmen. Es nimmt keine Befehle von außen an — siehe *Zugriffsregeln*.

## Komponentenstruktur

```
MikaGridCore                          Bibliothek — alles, was beide Fassungen teilen
├── SnapAction                        elf Aktionen, Zielgeometrie, Vorschau   (B01)
├── SnapResult                        sechs Ergebnisfälle                     (B01)
├── SnapHistory / WindowKey           Positionshistorie                       (B02)
├── HotkeyManager                     Carbon-Kürzel — auch in der Sandbox nutzbar (B03)
├── AppPreferences                    Einstellungen                           (B07)
├── WindowSnapping  «Schnittstelle»   die einzige Naht zwischen den Fassungen
│   ├── snap(action) -> SnapResult
│   └── isReady -> Bereitschaft + Grund, falls nicht
└── Oberfläche                        Popover, Einstellungen, Onboarding  (B04, B06, B07)

MikaGrid (Direct)                     App-Ziel, nicht sandboxed
├── AccessibilityWindowSnapper        erfüllt WindowSnapping über AXUIElement (B01)
├── AccessibilityManager              Berechtigung                            (B05)
└── SparkleUpdater                    Selbstaktualisierung                    (B08)

MikaGrid (App Store)                  App-Ziel, sandboxed
├── ShortcutsWindowSnapper            erfüllt WindowSnapping über Shortcuts
│   ├── Nutzlast bauen                Zielrahmen + Bildschirm + Aktion
│   ├── Shortcut aufrufen             Apple Events, Rückfall URL-Schema
│   └── Antwort auswerten             Erfolg, Fehler, Zeitüberschreitung
├── CompanionShortcutManager
│   ├── Vorhandensein prüfen          liegt der Shortcut in der Mediathek?
│   ├── Integrität prüfen             stimmt der Aufbau mit dem erwarteten überein?
│   └── Installation anstoßen         signierte Datei aus dem Bundle öffnen
└── AutomationPermission              Zustimmung zur Steuerung von Shortcuts
```

Nicht aufgeführt sind Komponenten, die es bereits gibt — sie werden unverändert
übernommen. Neu sind ausschließlich die drei unter *App Store*, dazu die Schnittstelle
`WindowSnapping` und die Aufteilung in Bibliothek und Ziele.

### Zustände je Bildschirm

| Bildschirm | leer | ladend | Fehler | gefüllt |
|---|---|---|---|---|
| Onboarding-Schritt „Shortcut" | Anleitung, Schaltfläche „Shortcut installieren" | „Warte auf Installation…" mit laufender Prüfung | „Konnte nicht geöffnet werden" mit Wiederholung | grünes Häkchen, blättert nach ~1 s weiter |
| Popover | wie heute | — (ein Snap dauert unter 1 s) | Grund im bestehenden Hinweisband (B04) | wie heute |
| Einstellungen → Allgemein | — | — | „Companion-Shortcut fehlt oder wurde verändert" mit Schaltfläche | Zeile „Shortcut: eingerichtet" |

Der Fehlerzustand benutzt dasselbe Hinweisband, das seit v1.2.0 fehlgeschlagene Snaps
meldet. Ein zweiter Meldeweg wäre eine zweite Fehlerbehandlung in derselben Oberfläche.

## Datenmodell

Es gibt keine Datenbank. Auf Feldebene beschreibbar sind drei Dinge: die Nutzlast an den
Shortcut, seine Antwort und die zusätzlichen Einstellungen.

### Nutzlast an den Companion-Shortcut

Ein Textwert, den der Shortcut als Eingabe erhält.

| Feld | Typ | Pflicht | Bedeutung |
|---|---|---|---|
| `action` | Text | ja | Rohwert der Aktion, etwa `leftHalf` — dient nur der Protokollierung im Shortcut |
| `x`, `y` | Zahl | ja | linke obere Ecke des Zielrahmens in Bildschirmpunkten |
| `width`, `height` | Zahl | ja | Zielgröße in Bildschirmpunkten |
| `appName` | Text | ja | Name der Zielanwendung, für `Find Windows` |
| `windowTitle` | Text | **nein** | Titel des Zielfensters, nur wenn zur Unterscheidung nötig |
| `windowIndex` | Zahl | nein | Position in der Fensterliste, wenn kein Titel benutzt wird |
| `nonce` | Text | ja | Zufallswert je Aufruf; die Antwort muss ihn zurückliefern |

`windowTitle` ist das Feld mit Personenbezug (AK-23). Es wird **nur** gefüllt, wenn
`appName` allein mehrdeutig ist — also wenn die Zielanwendung mehr als ein Fenster hat.
Der Regelfall bleibt titelfrei. Näheres unter *Externe Dienste*.

`nonce` verhindert, dass eine verspätete Antwort einem späteren Aufruf zugeordnet wird —
bei einem Aufrufweg, der über URL-Schemata zurückkommt, ist das sonst nicht
auszuschließen.

### Antwort des Shortcuts

| Feld | Typ | Bedeutung |
|---|---|---|
| `nonce` | Text | derselbe Wert wie im Aufruf, sonst wird die Antwort verworfen |
| `status` | Text | `ok`, `no-window`, `not-resizable`, `error` |
| `actualX/Y/Width/Height` | Zahl | tatsächlicher Rahmen nach dem Setzen, für die Nachprüfung |

Die vier `actual`-Felder sind der Ersatz für die Rückmessung, die die Direktfassung
selbst vornimmt (B01). Ohne sie könnte die Store-Fassung nicht erkennen, dass eine
Anwendung den Rahmen beschnitten hat.

### Zusätzliche Einstellungen (nur Store-Ziel)

| Schlüssel | Typ | Standard | Bedeutung |
|---|---|---|---|
| `companionShortcutInstalled` | Wahrheitswert | `false` | zuletzt bestätigter Einrichtungsstand — nur eine Abkürzung, geprüft wird trotzdem |
| `companionShortcutFingerprint` | Text | *leer* | Prüfwert des erwarteten Aufbaus, für die Integritätsprüfung |

**Änderung an bestehenden Einstellungen:** keine. Die Schlüssel aus `docs/datenmodell.md`
bleiben unverändert; die beiden neuen kommen nur im Store-Ziel vor und liegen wegen des
abweichenden Bundle-Bezeichners ohnehin in einer eigenen Ablage.

**Löschregel:** Beide verschwinden mit dem Sandbox-Container beim Entfernen der App. Der
Companion-Shortcut selbst bleibt in der Mediathek des Nutzers — eine App darf dort nichts
löschen. Das gehört auf die Store-Seite und in die Datenschutzangaben.

## Zugriffsregeln

Rollen gibt es nicht. Die Frage lautet: **wer darf was auslösen, und wodurch wird es
erzwungen?**

| Wer | Darf | Erzwungen durch |
|---|---|---|
| die Store-Fassung | Shortcuts steuern | Entitlement **und** Zustimmung des Nutzers (TCC), einmalig abgefragt |
| die Store-Fassung | Fenster fremder Apps bewegen | **nur mittelbar** — der Shortcut tut es, nicht die App |
| die Store-Fassung | außerhalb ihres Containers schreiben | **nein** — Sandbox |
| ein fremder Prozess | über `mikagrid-mas://` einen Snap auslösen | **nein** — das Schema nimmt nur Antworten entgegen und verwirft jede ohne gültigen `nonce` |
| ein veränderter Shortcut | unter dem Namen der App laufen | **nein** — Integritätsprüfung vor jedem Aufruf |

Die dritte Zeile ist die eigentliche Pointe des Entwurfs: Die Store-Fassung erhält nie
Zugriff auf fremde Fenster. Sie bittet eine Systemkomponente, die der Nutzer ausdrücklich
autorisiert hat. Genau deshalb ist sie im Store zulässig.

Die vorletzte Zeile ist wichtiger, als sie aussieht: Ein URL-Schema ist ein offener
Eingang. Ohne `nonce`-Prüfung könnte jede Webseite `mikagrid-mas://snap-done?...` öffnen.
Da das Schema ausschließlich Antworten annimmt und eine Antwort ohne passenden,
unmittelbar zuvor erzeugten `nonce` verworfen wird, lässt sich darüber nichts auslösen.

### Entitlements des Store-Ziels

| Entitlement | Wert | Wofür |
|---|---|---|
| `com.apple.security.app-sandbox` | `true` | Pflicht für jede Neueinreichung |
| `com.apple.security.automation.apple-events` | `true` | Apple Events senden bei aktivem Hardened Runtime |
| `com.apple.security.temporary-exception.apple-events` | `com.apple.shortcuts` | Sandbox-Ausnahme für genau diese eine Ziel-App |

Zur dritten Zeile gehört eine Einschränkung, die im Entwurf stehen muss: Apple bezeichnet
diese Ausnahme ausdrücklich als **vorübergehend** und rät, stattdessen
`com.apple.security.scripting-targets` zu benutzen, sobald die Ziel-App Zugriffsgruppen
anbietet. Shortcuts bietet derzeit keine. Apple warnt zudem, dass eine solche Ausnahme
für **Finder und System Events** in der Prüfung meist abgelehnt wird — Shortcuts wird
dort nicht genannt, und drei Apps im Store benutzen genau diesen Weg.
*(developer.apple.com/library/archive/qa/qa1888, gelesen 2026-08-25)*

Das Direktziel behält seine heutigen Entitlements unverändert: Sandbox aus, keine
Library-Validation-Ausnahme (seit v1.2.0).

## Missbrauchsschutz

| Fläche | Grenze | Verhalten bei Überschreitung | Wo festgelegt |
|---|---|---|---|
| Aufruf des Shortcuts | ein laufender Aufruf gleichzeitig | weitere Auslösungen werden verworfen, nicht gestapelt | `ShortcutsWindowSnapper` |
| Antwortfenster | 1 s | gilt als `SnapResult.timedOut`, Systemton und Meldung | `ShortcutsWindowSnapper` |
| Antworten über das URL-Schema | nur mit gültigem, unverbrauchtem `nonce` | stillschweigend verworfen | `ShortcutsWindowSnapper` |
| Integrität des Shortcuts | Prüfwert muss übereinstimmen | Aufruf unterbleibt, Hinweis auf Neueinrichtung | `CompanionShortcutManager` |
| Aufruffrequenz | keine | begrenzt durch Tastendrücke; jeder Aufruf ist lokal und kostenlos | — |

Ein Rate Limit im üblichen Sinn gibt es nicht: Es existiert kein Endpunkt und kein
Aufruf, der Geld kostet. Die einzige Ressource, die geschützt werden muss, ist die
Reihenfolge — deshalb die erste Zeile.

## Externe Dienste

| Dienst | Wofür | Was geht hin | Was wird vorher entfernt |
|---|---|---|---|
| **Shortcuts** (System-App, lokal) | Fenster bewegen | Aktion, Zielrahmen, Name der Zielanwendung, `nonce` — **und der Fenstertitel nur dann, wenn die Zielanwendung mehr als ein Fenster hat** | bei genau einem Fenster: der Titel. Bei mehreren wird er übertragen, weil `appName` allein nicht unterscheidet |
| **App Store Connect** | Einreichung, Auslieferung | Programmdateien, Store-Texte, Datenschutzangaben | keine Nutzerdaten — die App sendet nichts an Apple |

Shortcuts ist kein Auftragsverarbeiter: Die Daten verlassen das Gerät nicht, und die
Empfängerin ist Teil des Betriebssystems. Übertragen wird trotzdem etwas, das
personenbeziehbar sein kann, und genau deshalb steht die Bedingung in der dritten Spalte
prüfbar da statt als „minimiert".

**Datenschutzstufe:** bleibt A. Es entstehen keine Datensätze, nichts wird gespeichert,
nichts verlässt das Gerät. Die Aussage „Fenstertitel werden gar nicht gelesen" gilt
künftig aber nur noch für die Direktfassung — PRD, `docs/datenschutz.md` und die
öffentliche Datenschutzseite sind vor der Auslieferung zu präzisieren (Folgeaufträge der
Spezifikation).

## Technische Entscheidungen

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| 1 | **Eine Schnittstelle `WindowSnapping`, zwei Erfüllungen** | Bedingte Übersetzung mit `#if APP_STORE` im vorhandenen `WindowManager` | Bedingte Übersetzung verstreut den Unterschied über die ganze Datei und lässt sich nicht testen: Es liefe immer nur ein Zweig. Eine Schnittstelle macht den Unterschied zu genau einer austauschbaren Stelle — und beide Erfüllungen sind einzeln prüfbar |
| 2 | **Gemeinsame Bibliothek `MikaGridCore`** | alles im App-Ziel lassen und Dateien in beide Ziele aufnehmen | Doppelte Dateizugehörigkeit ist die klassische Quelle für „im einen Ziel gebaut, im anderen vergessen". Nebenwirkung: Die Tests hängen künftig an der Bibliothek statt am ausführbaren Ziel — sauberer als heute |
| 3 | **XcodeGen mit `project.yml`** | `.xcodeproj` von Hand pflegen · Tuist · beim SPM bleiben | Das Ökosystem nutzt es bereits (`swiftui-ios`-Profil, AperoDrop): `project.yml` ist die Wahrheit, `.xcodeproj` wird erzeugt und ignoriert. Das erspart Zusammenführungskonflikte in einer XML-Datei, die niemand liest. Reines SPM reicht nicht, weil die Archivierung für App Store Connect ein Projekt braucht. Löst OF-03 der Spezifikation |
| 4 | **Apple Events als Aufrufweg, URL-Schema als Rückfall** | nur `shortcuts://x-callback-url/…` | Das URL-Schema käme ohne jedes Sonderrecht aus und liefert über `x-success` sogar ein Ergebnis — aber es lässt macOS die Shortcuts-App öffnen, und ob sie dabei in den Vordergrund tritt, ist nicht belegt. AK-11 verlangt genau das Gegenteil. Für Apple Events ist der unsichtbare Ablauf durch drei Apps im Store bezeugt. **Der erste Bauschritt entscheidet das am Versuch**, siehe Risiken |
| 5 | **Getrennte Bundle-Bezeichner** | derselbe für beide Fassungen | Sonst überschreiben sich beide Installationen, teilen Einstellungen und streiten um das Anmeldeobjekt |
| 6 | **Companion-Shortcut mitliefern, signiert** | iCloud-Link · zur Laufzeit erzeugen | `shortcuts sign --mode anyone` erzeugt eine Datei, die sich **ohne** „Nicht vertrauenswürdige Kurzbefehle erlauben" importieren lässt — am System geprüft. Ein iCloud-Link wäre eine Abhängigkeit von einer gehosteten Adresse; eine zur Laufzeit erzeugte Datei wäre unsigniert und verlangte, dass der Nutzer eine Sicherheitseinstellung umlegt |
| 7 | **Antwort über Rahmenwerte statt nur Erfolgsmeldung** | nur `ok`/`error` | Die Direktfassung misst nach dem Schreiben nach (B01). Ohne die tatsächlichen Werte könnte die Store-Fassung nicht erkennen, dass eine Anwendung den Rahmen beschnitten hat — und AK-08 wäre nicht prüfbar |
| 8 | **Fenstertitel nur bei Mehrdeutigkeit** | immer mitschicken · nie mitschicken | „Immer" verletzt die Datensparsamkeit ohne Gewinn, „nie" macht die Zuordnung bei mehreren Fenstern derselben Anwendung unmöglich. Die Bedingung ist prüfbar formuliert und damit nachweisbar |
| 9 | **Zielrahmen in der App rechnen, nicht im Shortcut** | Shortcuts-Vorgaben („Left Half") benutzen | Die Vorgaben kennen die 2/3-Aufteilung nicht (AK-09) und richten sich nicht nach dem Bildschirm, auf dem das Fenster steht (AK-10). Rechnet die App, bleibt `SnapAction.targetFrame` die einzige Wahrheit für beide Fassungen — und die 45 vorhandenen Tests decken sie mit ab |
| 10 | **Randnahe Fenster zuerst versetzen** | direkt auf das Ziel setzen | Für Shortcuts ist ein Fehler dokumentiert, bei dem Fenster nahe am rechten oder unteren Rand nicht korrekt skaliert werden. Der Shortcut setzt deshalb erst die Position, dann die Größe, dann die Position erneut — dasselbe Muster, das die Direktfassung seit 1.1.1 benutzt, aus demselben Grund |

## Risiken

| Risiko | Auswirkung | Umgang |
|---|---|---|
| Shortcuts wird beim Aufruf sichtbar | AK-11 nicht erfüllbar, der Weg wäre unbrauchbar | **Erster Bauschritt vor allem anderen:** ein Wegwerf-Versuch, der beide Aufrufwege misst. Fällt er negativ aus, ist das Feature hinfällig, bevor Xcode-Umbau und Onboarding Arbeit gekostet haben |
| `Find Windows` liefert keine Rahmenwerte zurück | „Wiederherstellen" im Store-Ziel nicht möglich (OF-02 der Spezifikation) | Im selben Versuch mitprüfen. Fällt es weg, ist es eine Aktion weniger im Store-Ziel — kein Grund, das Feature zu beerdigen |
| Apple lehnt die Ausnahme-Entitlement ab | keine Store-Fassung | OF-01 der Spezifikation: eine minimale Fassung früh einreichen |
| Apple führt Zugriffsgruppen für Shortcuts ein | die Ausnahme wird unnötig | Dann auf `scripting-targets` wechseln — kleinere Rechte bei gleicher Funktion |

## Abdeckung der Akzeptanzkriterien

Aus `spec.md` der Reihe nach abgegangen, nicht aus dem Gedächtnis.

| AK | Erfüllt durch | Anmerkung |
|---|---|---|
| AK-01 | `project.yml`, Schema „MikaGrid (Direct)" → `AccessibilityWindowSnapper` | Verhalten unverändert, weil dieselbe Erfüllung wie heute |
| AK-02 | Schema „MikaGrid (App Store)", Sandbox-Entitlement, Sparkle nicht im Zielbestand | |
| AK-03 | Entitlement-Tabelle unter *Zugriffsregeln* | |
| AK-04 | Tests hängen an `MikaGridCore` statt am ausführbaren Ziel | Entscheidung 2 |
| AK-05 | `scripts/build.sh` baut weiterhin das Direktziel | Skript ruft künftig `xcodebuild` statt `swift build` |
| AK-06 | XcodeGen-Schema mit Archivierungskonfiguration; `scripts/release.sh` um einen Store-Zweig erweitert | Konfigurationsaufgabe, kein App-Code |
| AK-07 | `ShortcutsWindowSnapper` + Companion-Shortcut | |
| AK-08 | `SnapAction.targetFrame` als gemeinsame Quelle beider Fassungen | Entscheidung 9 |
| AK-09 | Zielrahmen wird in der App gerechnet, nicht aus Shortcuts-Vorgaben genommen | Entscheidung 9 |
| AK-10 | Bildschirmwahl bleibt in `MikaGridCore` (B01), das Ergebnis geht als Punktwert in die Nutzlast | |
| AK-11 | Apple Events statt URL-Schema | **Risikobehaftet** — Entscheidung 4, erster Bauschritt |
| AK-12 | Position → Größe → Position im Companion-Shortcut | Entscheidung 10 |
| AK-13 | `CompanionShortcutManager`, Onboarding-Schritt | erweitert B06 |
| AK-14 | Prüfung im Sekundentakt, wie bei der Berechtigung in B05 | bestehendes Muster |
| AK-15 | Zustimmung zur Automatisierung, vom System einmalig abgefragt | Plattformverhalten, kein App-Code |
| AK-16 | `AutomationPermission` → `SnapResult` → bestehendes Hinweisband (B04) | |
| AK-17 | Vorhandensein wird vor jedem Aufruf geprüft | |
| AK-18 | Integritätsprüfung vor jedem Aufruf | Entscheidung 6 |
| AK-19 | Store-Eintrag: Name, Preis, Mindestsystem | Konfigurationsaufgabe in App Store Connect |
| AK-20 | Store-Beschreibung nennt den Companion-Shortcut vor dem Download | Konfigurationsaufgabe |
| AK-21 | Datenschutzangaben im Store: „keine Daten erhoben" | Konfigurationsaufgabe |
| AK-22 | Getrennte Bundle-Bezeichner; Sparkle nur im Direktziel | Entscheidung 5 |
| AK-23 ⚠ | Feld `windowTitle` der Nutzlast, bedingt gefüllt | Entscheidung 8; Folgeaufträge in PRD und Datenschutz |
| AK-24 | Kein Netzaufruf in beiden Erfüllungen von `WindowSnapping` | |
| AK-25 | **teilweise** — siehe offene Frage OF-06 | Der URL-Rückfall käme ohne jede Berechtigung aus, was den Wortlaut „genau eine" verletzte, obwohl es strenger wäre |
| AK-26 | Integritätsprüfung, Aufruf unterbleibt bei Abweichung | |
| AK-27 | Sandbox; die zwei neuen Einstellungen liegen im Container | |
| AK-28 | Zugangsdaten in App Store Connect bzw. der Schlüsselbund, nie im Repository; `project.yml` enthält keine Signaturangaben | wie bei B09 |

28 von 28 Kriterien zugeordnet. Eines (AK-25) ist nur teilweise erfüllbar und geht als
offene Frage zurück in die Spezifikation — der Entwurf lässt es nicht still fallen.

## Rückmeldungen an die Spezifikation

Nach Regel „keine neuen Anforderungen" gehören diese Punkte zurück in `spec.md`, nicht
in den Entwurf:

- **OF-06 (neu)** · AK-25 verlangt „genau eine Berechtigung: Automatisierung von
  Shortcuts". Sollte sich im ersten Bauschritt der URL-Weg als tauglich erweisen, bräuchte
  die App **gar keine** Berechtigung. Das wäre besser als gefordert, verletzt aber den
  Wortlaut. Das Kriterium ist entsprechend umzuformulieren. — *Betreiber.*
- **OF-02 (bestätigt)** · Ob `Find Windows` Rahmenwerte **ausliest** oder nur filtert, ist
  weiterhin unbelegt und wird im ersten Bauschritt mitgeprüft.
- **OF-03 (gelöst)** · XcodeGen, wie im Ökosystem üblich. Entscheidung 3.
- **OF-04 (gelöst)** · Getrennte Bundle-Bezeichner. Entscheidung 5.

## Quellen

- Entitlements für Apple Events aus der Sandbox, Unterschied `scripting-targets` zur
  vorübergehenden Ausnahme, Warnung zu Finder und System Events:
  <https://developer.apple.com/library/archive/qa/qa1888/_index.html> (gelesen 2026-08-25)
- Ablehnung der `automation.apple-events`-Entitlement durch App Store Connect war ein
  behobener Prüffehler von 2018, kein Grundsatzproblem:
  <https://developer.apple.com/forums/thread/108526> (gelesen 2026-08-25)
- `x-callback-url` in Shortcuts mit `x-success`, `x-error` und `result`:
  <https://support.apple.com/guide/shortcuts-mac/use-x-callback-url-apdcd7f20a6f/mac>
  (gelesen 2026-08-25)
- `shortcuts sign --mode anyone` — am System geprüft, macOS 26, 2026-08-25
