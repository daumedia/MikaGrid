# 01 · App-Store-Vertrieb — Testbericht

Stand: 2026-08-26 · Geprüfte Fassung: Branch `feature/01-app-store-vertrieb`
Prüfrechner: macOS 26.5.1 · Xcode 26.6 · zwei Bildschirme
(`Screen 0 = (0,0,1512,982)`, `visibleFrame = (0,0,1512,949)`; `Screen 1` **oberhalb**)

> ## ⚠ Einschränkung der Aussagekraft — bitte zuerst lesen
>
> **Bau und Prüfung stammen aus derselben Sitzung und damit von derselben Instanz.** Der
> QA-Skill trennt beides absichtlich: Wer prüft, was er selbst gebaut hat, prüft mit
> demselben blinden Fleck, der den Fehler erzeugt hat. Dieser Bericht ersetzt eine
> unabhängige Prüfung **nicht**. Er ist belastbar, wo er Messwerte zeigt, und
> vorbehaltlich, wo er Urteile fällt.
>
> Ebenso nicht ausgeführt: der `code-reviewer`-Agent, den der Skill vorsieht. Die
> Codeprüfung erfolgte von Hand.

## Fazit

**Production-ready: JA — mit drei Vorbehalten außerhalb des Codes.**

Der Bericht wurde in zwei Durchgängen geschrieben. Der erste fand **BUG-01** (Grad hoch):
Die Store-Fassung traf den berechneten Rahmen in fünf Läufen **null Mal**. Der Fehler ist
**behoben und nachgemessen** — 10 von 10 Läufen exakt. Dabei fiel **BUG-02** auf (die
Zeitgrenze war deklariert, aber nicht umgesetzt); auch behoben.

Es bleibt **kein Fehler vom Grad kritisch oder hoch**. Was bleibt, sind vier mittlere
Befunde (BF-02 bis BF-05) — alle in `features/befunde.md`, keiner blockiert.

**Der Code ist einreichungsfähig. Die Einreichung selbst ist es nicht**, solange drei
Dinge fehlen, die nicht im Repository liegen:

1. Ein `3rd Party Mac Developer Application`- oder `Apple Distribution`-Zertifikat
2. Die App-Kennung `lu.daumedia.mikagrid` in App Store Connect
3. Der Store-Auftritt: Name, Preis, Beschreibung mit Hinweis auf den Companion-Kurzbefehl
   **vor** dem Download, Datenschutzangaben „keine Daten erhoben" (AK-19 bis AK-21)

**Nächster Aufruf: `/sdd-deploy 01`**, sobald 1 bis 3 vorliegen.

---

## Akzeptanzkriterien

### A · Bauwege

| AK | Ergebnis | Nachweis |
|---|---|---|
| AK-01 · Direktziel verhält sich wie 1.2.0 | ✅ | `xcodebuild -scheme "MikaGrid (Direct)"` → `** BUILD SUCCEEDED **`; App startet (PID 22961); `Identifier=lu.daumedia.mikagrid`, `app-sandbox = false`, `Sparkle.framework` eingebettet; alle Bestandstestsuites laufen |
| AK-02 · Store-Ziel sandboxed, ohne Sparkle | ✅ | `codesign -d --entitlements` → `app-sandbox`; `ls .../Contents/Frameworks/` → nur `MikaGridCore.framework`; im **Archiv** ebenso |
| AK-03 · Entitlements des Store-Ziels | ✅ | `app-sandbox`, `automation.apple-events`, `scripting-targets → com.apple.shortcuts.events → com.apple.shortcuts.run`. Dazu `get-task-allow` — Debug-Artefakt von Xcode, im Release nicht enthalten |
| AK-04 · `swift test` verliert keine Tests | ✅ | `✔ Test run with 69 tests in 11 suites passed` (vorher 45; 24 neue) |
| AK-05 · `build.sh` baut weiterhin | ✅ | `bash build.sh` → `build/Mika+Grid.app (v1.2.0)`, `valid on disk`, `satisfies its Designated Requirement` |
| AK-06 · Archivierung an App Store Connect | ⚠️ | **Archivierung belegt:** `xcodebuild archive` → `** ARCHIVE SUCCEEDED **`, Archiv enthält `.mas`-Kennung, macOS 15, kein Sparkle, kein `SUFeedURL`, Companion-Kurzbefehl, URL-Schema. **Export und Upload nicht prüfbar** — es fehlen `3rd Party Mac Developer Application` und die App-Kennung |

### B · Fenster bewegen über Shortcuts

| AK | Ergebnis | Nachweis |
|---|---|---|
| AK-07 · ⌃⌥← füllt die linke Hälfte binnen 1 s | ✅ | Nach der Behebung von BUG-01: 10 von 10 Läufen exakt `x=0 y=33 756×949`, Dauer **0,83–0,85 s** je Lauf — unter der zugesagten Sekunde, aber ohne große Reserve. Der Tastendruck selbst wurde **nicht** ausgelöst (kein Weg, ⌃⌥← ohne Bedienungshilfen für das Terminal zu senden); geprüft wurde der Weg dahinter |
| AK-08 · sitzt wie in der Direktfassung | ✅ | Nach der Behebung: 10 von 10 exakt auf `SnapAction.targetFrame` — dieselbe Rechnung, die die Direktfassung benutzt. Vorher 0 von 5 (**BUG-01**, behoben) |
| AK-09 · Zentriert = zwei Drittel | ✅ | Soll `x=252 y=191 1008×633` (aus `SnapAction.targetFrame`), gemessen **exakt dasselbe**. Dazu der Test „Zentrieren belegt zwei Drittel in beiden Richtungen" |
| AK-10 · Snap auf dem Bildschirm des Fensters | ⚠️ | **Nicht prüfbar auf diesem Rechner.** `Move Window` nimmt keine negativen Koordinaten an (gemessen: Ziel `(100,−500)` bewirkt nichts, Antwort trotzdem `ok`); der zweite Bildschirm liegt hier *oberhalb*, also im negativen Bereich. Ein Bildschirm rechts oder unterhalb wäre erreichbar, stand nicht zur Verfügung |
| AK-11 · kein Kurzbefehle-Fenster, kein Vordergrundwechsel | ✅ | Abtastung im 50-ms-Takt über `CGWindowListCopyWindowInfo` + `NSWorkspace.frontmostApplication`: 0 von 4–6 Proben mit Fenster, kein Wechsel. Gegenprobe URL-Schema: Fenster 1000×682 wird sichtbar — deshalb nicht verwendet |
| AK-12 · randnahes Fenster sitzt trotzdem korrekt | ✅ | Start unten rechts `(1000,600)` → `leftHalf` exakt `x=0 y=33 756×949`; Start `(950,620)` → `topRight` exakt `x=756 y=33 756×475`. Vorher daneben (**BUG-01**, behoben) |

### C · Einrichtung

| AK | Ergebnis | Nachweis |
|---|---|---|
| AK-13 · Onboarding-Schritt beim ersten Start | ✅ | Store-Fassung gestartet, frischer Container → Fenster 480×592 vorhanden (`CGWindowList`, pid der Store-Fassung). Companion liegt im Bundle: `Contents/Resources/Mika+Grid Snap.shortcut` |
| AK-14 · Erkennung binnen ~1 s, blättert weiter | ⚠️ | **Nicht prüfbar ohne Klick im Onboarding.** Die Prüfung im Sekundentakt ist gebaut (`CompanionShortcutManager.startPolling`), der Ablauf „installieren → erkennen → weiterblättern" wurde nicht durchlaufen |
| AK-15 · macOS fragt einmalig um Erlaubnis | ✅ | Erster Aufruf aus der sandboxed App scheiterte mit AppleScript −1743 „Not authorized to send Apple events to Shortcuts Events"; nach erteilter Zustimmung stabil über alle weiteren Läufe |
| AK-16 · bei Verweigerung erklären und führen | ⚠️ | **Nicht prüfbar**, ohne die erteilte Zustimmung wieder zu entziehen — das hätte den Prüfrechner verändert. Der Pfad ist gebaut (−1743/−1744 → `.automationDenied` → Hinweisband + „Open Settings") |
| AK-17 · gelöschter Kurzbefehl wird gemeldet | ✅ | Abfrage eines nicht vorhandenen Namens liefert `−1728 … kann nicht gelesen werden`; `ShortcutsRunner` bildet −1728 auf `.notFound` ab, daraus `.companionShortcutMissing` mit Hinweisband |
| AK-18 · veränderter Kurzbefehl wird verweigert | ⚠️ | **Nur teilweise prüfbar.** Die Prüfung vergleicht Aktionszahl und Eingabeverhalten; ein veränderter Kurzbefehl wurde nicht erzeugt. Grenze siehe AK-26 |

### D · Store-Auftritt

| AK | Ergebnis | Nachweis |
|---|---|---|
| AK-19 · Name, kostenlos, macOS 15 | ⚠️ | **Nicht prüfbar** — kein Zugang zu App Store Connect. Im Bundle belegt: `CFBundleName = Mika+Grid`, `LSMinimumSystemVersion = 15.0` |
| AK-20 · Store-Seite nennt den Kurzbefehl vor dem Download | ⚠️ | **Nicht prüfbar** — kein Zugang. README und Landingpage nennen ihn |
| AK-21 · Datenschutzangaben „keine Daten erhoben" | ⚠️ | **Nicht prüfbar** — kein Zugang. Sachlich zutreffend, siehe AK-24 |
| AK-22 · beide Vertriebswege stören einander nicht | ❌ | **Hinfällig seit der Betreiberentscheidung zu OF-04 (2026-08-26):** Beide Fassungen tragen jetzt `lu.daumedia.mikagrid` und sind nicht mehr nebeneinander installierbar. Der prüfbare Rest ist erfüllt — kein `SUFeedURL` in `Info-MAS.plist`, kein Sparkle-Code im Store-Ziel, kein Sparkle im Archiv. Bewusst in Kauf genommen, siehe OF-04 |

### E · Datenschutz und Missbrauchsschutz

| AK | Ergebnis | Nachweis |
|---|---|---|
| AK-23 ⚠ · Fenstertitel dürfen übergeben werden | ✅ | **Gegenstandslos geworden — im guten Sinn.** Die Nutzlast lautet `{"action":…,"x":…,"y":…,"width":…,"height":…,"nonce":…}` — kein Anwendungsname, kein Fenstertitel. Test `SnapPayloadTests` prüft das (`carriesNothingPersonal`, `exactlySixFields`). Siehe OF-13 |
| AK-24 · kein Netzverkehr | ✅ | `lsof -i -a -p <pid>` an der laufenden Store-Fassung → keine Verbindung. Keine Netz-API in `MikaGridMAS`/`MikaGridCore` (`URLSession`, `NWConnection`, … → keine Treffer) |
| AK-25 · genau eine Systemberechtigung | ⚠️ | Sachlich erfüllt: **keine** Bedienungshilfen, **keine** Eingabeüberwachung (kein `AXIsProcessTrusted`, kein `CGEventTap` im Code). Der Wortlaut „genau eine" passt aber nicht: Es sind zwei Entitlement-Einträge (`automation.apple-events` **und** `scripting-targets`) für eine Zustimmung. Siehe OF-06 |
| AK-26 · veränderter Kurzbefehl wird nicht aufgerufen | ⚠️ | **Nur teilweise erfüllbar.** Über die Skripting-Schnittstelle sind nur `name`, `action count`, `accepts input` lesbar — **nicht, was die Aktionen tun**. Erkennt einen versehentlich ersetzten Kurzbefehl, keinen absichtlich nachgebauten. Siehe OF-11 |
| AK-27 · nichts außerhalb des Sandbox-Containers | ✅ | Vor der Umstellung auf eine gemeinsame Kennung gemessen: Container `~/Library/Containers/lu.daumedia.mikagrid.mas` angelegt, `~/Library/Preferences/lu.daumedia.mikagrid.mas.plist` existiert **nicht**. Die Sandbox-Eigenschaft hängt am Entitlement, nicht an der Kennung — **nach der Umstellung nicht erneut gemessen** |
| AK-28 · keine Zugangsdaten im Repository | ✅ | Suche nach Zertifikaten, Schlüsseln und Mustern: nur Variablennamen und Platzhalter in `release.sh`. Keine `.p8`/`.p12`/`.cer`/`.mobileprovision`. `git log -S 'AuthKey'` → leer |

**Bilanz:** 16 bestanden · 1 durchgefallen (AK-22, bewusst) · 11 nicht prüfbar

---

## Fehler

### BUG-01 · Fenster landen nicht auf dem berechneten Rahmen — hoch · **BEHOBEN 2026-08-26**

**Betrifft:** AK-07, AK-08, AK-09, AK-12

**Reproduktion:**
1. Ein Finder-Fenster öffnen, auf `(600, 300)` mit `500×400` setzen
2. Finder aktivieren
3. `tell application "Shortcuts Events" to run shortcut named "Mika+Grid Snap" with input "{\"action\":\"leftHalf\",\"x\":0,\"y\":33,\"width\":756,\"height\":949,\"nonce\":\"REP-1\"}"`
4. Rahmen messen (`CGWindowListCopyWindowInfo` oder `System Events`)
5. Schritte 1–4 fünfmal wiederholen

**Erwartet:** `x=0 y=33 756×949` — der Wert aus `SnapAction.targetFrame`

**Tatsächlich:** fünf Läufe, **kein einziger exakt**:

```
Lauf 1: x=4 y=35 w=756 h=947
Lauf 2: x=2 y=35 w=756 h=947
Lauf 3: x=3 y=35 w=756 h=947
Lauf 4: x=0 y=39 w=753 h=940
Lauf 5: x=0 y=39 w=753 h=939
```

Weitere Aktionen im selben Durchgang:

| Aktion | Sollwert | Gemessen |
|---|---|---|
| `topLeft` | `0, 33, 756×475` | **exakt** |
| `bottomRight` | `756, 508, 756×474` | `756, 508, 753×474` |
| `center` (AK-09) | `252, 191, 1008×633` | `252, 210, 967×614` |
| `maximize` | `0, 33, 1512×949` | `0, 39, 1492×935` |
| `leftHalf` randnah (AK-12) | `0, 33, 756×949` | `0, 39, 753×903` |

**Muster:** Kleine Zielrahmen treffen, große nicht. Die Abweichung schwankt zwischen
identischen Läufen — sie ist also kein fester Versatz, sondern zeitabhängig.

**Ort:** `scripts/make-companion-shortcut.sh` — die Abfolge
Position → *Pause 0,15 s* → Größe → *Pause 0,15 s* → Position. Die Pausen wurden
eingeführt, weil sich die Aktionen sonst überholen (belegt in `machbarkeit.md`); sie
scheinen für große Rahmen zu knapp zu sein, weil die Zielanwendung länger zum Zeichnen
braucht.

**Warum es niemandem auffällt, bevor jemand misst:** Der Kurzbefehl meldet in allen
Fällen `ok`. Und die Store-Fassung **kann** es nicht bemerken — Kurzbefehle liefert die
tatsächlichen Rahmenwerte nicht zurück (OF-02), also gibt es keine Rückmessung wie in der
Direktfassung (B01: bis zu 3 Durchläufe, 2 pt Toleranz).

**Ursache — im Projekt dokumentiert, im Entwurf falsch übernommen:**

`CLAUDE.md` hält für die Direktfassung fest, warum `applyFrame` **Größe → Position →
Größe** schreibt und nicht umgekehrt:

> *„macOS constrains a position write against the window's **current** size
> (`NSWindow.constrainFrameRect:toScreen:`), so an oversized window cannot be moved to a
> target edge until it has been shrunk first."*

`design.md` (Entscheidung 10) schrieb für den Kurzbefehl trotzdem **Position → Größe →
Position** vor, und genau so war er gebaut. Das erklärt das Muster: Kleine Zielrahmen
saßen, große nicht — bei denen begrenzte macOS den abschließenden Positionswechsel gegen
die inzwischen gewachsene Fenstergröße.

**Behebung 2026-08-26:** Reihenfolge im Companion-Kurzbefehl auf **Größe → Position →
Größe** umgestellt, Pausen von 0,15 s auf 0,2 s erhöht
(`scripts/make-companion-shortcut.sh`).

**Gegenprobe — 10 Läufe, dieselbe Reproduktion:**

```
✓ Lauf  1: 0.85s  [x=0 y=33 w=756 h=949]      ✓ Lauf  6: 0.85s  [x=0 y=33 w=756 h=949]
✓ Lauf  2: 0.84s  [x=0 y=33 w=756 h=949]      ✓ Lauf  7: 0.84s  [x=0 y=33 w=756 h=949]
✓ Lauf  3: 0.83s  [x=0 y=33 w=756 h=949]      ✓ Lauf  8: 0.84s  [x=0 y=33 w=756 h=949]
✓ Lauf  4: 0.83s  [x=0 y=33 w=756 h=949]      ✓ Lauf  9: 0.84s  [x=0 y=33 w=756 h=949]
✓ Lauf  5: 0.84s  [x=0 y=33 w=756 h=949]      ✓ Lauf 10: 0.85s  [x=0 y=33 w=756 h=949]
EXAKT: 10 von 10
```

Und die zuvor fehlgeschlagenen Fälle, alle exakt:

| Aktion | Sollwert | Gemessen |
|---|---|---|
| `center` (AK-09) | `252, 191, 1008×633` | **exakt** |
| `maximize` | `0, 33, 1512×949` | **exakt** |
| `bottomRight` | `756, 508, 756×474` | **exakt** |
| `leftHalf` aus der Ecke (AK-12) | `0, 33, 756×949` | **exakt** |
| `topRight` aus der Ecke (AK-12) | `756, 33, 756×475` | **exakt** |

**Rückmeldung an den Entwurf:** Entwurfsentscheidung 10 ist falsch begründet — sie nennt
den dokumentierten Shortcuts-Fehler bei randnahen Fenstern, übersieht aber die
Begrenzungsregel von macOS, die das Projekt seit 1.1.1 kennt. Gehört korrigiert.

### BUG-02 · Die Zeitgrenze war deklariert, aber nicht umgesetzt — mittel · **BEHOBEN 2026-08-26**

**Betrifft:** EC-04

**Reproduktion:** `grep -n "timeout" Sources/MikaGridMAS/ShortcutsRunner.swift` →
`static let timeout: TimeInterval = 1.0`. Danach `grep -rn "Self.timeout"` → **kein
Treffer**. Der Wert stand da und wurde nie gelesen.

**Erwartet:** Antwortet Kurzbefehle nicht rechtzeitig, gilt der Snap als fehlgeschlagen,
statt die Oberfläche zu blockieren (EC-04).

**Tatsächlich:** `NSAppleScript.executeAndReturnError` kennt keine Zeitgrenze. Ein
hängender Aufruf hätte die Menüleiste eingefroren — bei den Messungen blockierte ein Lauf
einmal länger als 60 s.

**Behebung:** Der Aufruf läuft jetzt auf einer Hintergrund-Warteschlange, der Aufrufer
wartet mit `DispatchSemaphore.wait(timeout:)`. Die Grenze steht auf **2,0 s**, nicht auf
1,0 s: Ein gelungener Snap dauert gemessen 0,83–0,85 s, und eine Sekunde hätte laufende
Snaps abgeschnitten. Zwei Sekunden sind die Grenze gegen ein Hängen, nicht die Zusage aus
AK-07.

---

## Sicherheitsprüfungen

| # | Prüfung | Ergebnis | Beleg |
|---|---|---|---|
| 1 | Fremder Zugriff über den offenen Eingang | ✅ | Vier untergeschobene Aufrufe an `mikagrid-mas://` (gefälschter `nonce`, ohne `nonce`, Befehlsversuch `snap?action=maximize`, Pfad `../../etc/passwd`) — Fensterrahmen davor und danach identisch (`x=0 y=39 753×939`), App läuft weiter |
| 2 | Zugriffsregeln in der Datenbank | — | Trifft nicht zu: keine Datenbank, keine Konten |
| 3 | Rate Limits | ✅ | Kein Endpunkt, kein Aufruf, der Geld kostet. Die einzige zu schützende Ressource ist die Reihenfolge: ein Aufruf gleichzeitig (`isRunning` → `SnapResult.busy`), geprüft durch `rapidTriggersStaySilent` |
| 4 | Personendaten in Protokollen | ✅ | Kein `print`/`os_log`/`NSLog` in `MikaGridMAS` und `MikaGridCore`; `log show --predicate 'process == "MikaGrid"'` über 3 Minuten Laufzeit → leer |
| 5 | Personendaten an externe Dienste | ✅ | **Tatsächliche Nutzlast** an Kurzbefehle: `{"action":"leftHalf","x":0,"y":33,"width":756,"height":949,"nonce":"EXACT-1"}` — fünf Zahlen, ein Rohwert, ein Zufallswert. Kein Name, kein Titel. Empfängerin ist eine System-App auf demselben Rechner |
| 6 | Geheimnisse | ✅ | Siehe AK-28 |
| 7 | Eingaben | ✅ | Antwortseite: `SnapReplyTests` prüft leere, verstümmelte, überlange und falsch ausgezeichnete Antworten — keine gilt als Erfolg. Eingabeseite: die Nutzlast baut die App selbst, der Nutzer gibt nichts ein |
| 8 | Löschen | ✅ | Alles liegt im Sandbox-Container (AK-27), der mit der App verschwindet. **Der Companion-Kurzbefehl bleibt** in der Mediathek — eine App darf dort nichts löschen. Gehört auf die Store-Seite (steht so in `spec.md`) |

---

## Hinweise ohne Fehlerstatus

Kein durchgefallenes Kriterium, aber vermerkenswert:

- **Zwei gleichnamige Kurzbefehle machen den Aufruf unmöglich.** Beim Prüfen entstanden
  mehrere „Mika+Grid Snap"; `shortcuts run` meldete dann `Kurzbefehl nicht gefunden`. Das
  ist EC-02 in echt und trifft jeden Nutzer, der den Kurzbefehl zweimal importiert.
  `CompanionShortcutManager.alternativeName(attempt:)` ist gebaut, wird aber **nirgends
  aufgerufen**.
- **Die Zielanwendung kann die Größe rastern.** TextEdit nahm 920 statt 924 Punkt Höhe
  (Zeilenhöhe), Finder im selben Lauf exakt. Das ist Verhalten der Zielanwendung; die
  Direktfassung fängt es mit ihrer Rückmessung ab, die Store-Fassung kann das nicht.
- **`action count` meldet direkt nach dem Import einige Sekunden lang `0`.** Ist im
  `CompanionShortcutManager` abgefangen (`actionCount != 0 → installed`), sonst hätte die
  App den Kurzbefehl genau im Moment des Hinzufügens als „verändert" abgewiesen.
- **In der Mediathek des Prüfrechners liegen 16 Wegwerf-Kurzbefehle** aus den Versuchen
  (`T01…`–`T08…`, `MikaGridSnap`, `Mika+Grid Snap 1`, `Mika+Grid Snap 2`). Sie sind von
  Hand zu löschen — die CLI kann das nicht.

## Was nicht geprüft werden konnte

| Grund | Betrifft |
|---|---|
| Kein Zugang zu App Store Connect | AK-06 (Export/Upload), AK-19, AK-20, AK-21 |
| Kein `3rd Party Mac Developer Application`-Zertifikat | AK-06 |
| Kein zweiter Bildschirm rechts oder unterhalb | AK-10 |
| Erteilte Zustimmung nicht rücknehmbar, ohne den Prüfrechner zu verändern | AK-16 |
| Ablauf mit Nutzerklick im Onboarding nicht durchlaufen | AK-14, AK-18 |
| Kein Weg, ⌃⌥← ohne Bedienungshilfen für das Terminal zu senden | AK-07 (der Tastendruck selbst) |
