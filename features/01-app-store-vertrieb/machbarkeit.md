# 01 · App-Store-Vertrieb — Machbarkeitsversuch (T01)

Stand: 2026-08-25 · Aufgabe: `T01` · Wegwerf-Code, **nicht** in `Sources/`

Gemessen an einer minimalen **sandboxed** App (`lu.daumedia.mikagrid.t01probe`,
Developer-ID-signiert, Hardened Runtime) auf macOS 26.5.1 / Xcode 26.6 gegen vier eigens
gebaute Test-Shortcuts. Der Wegwerf-Code liegt unter
`<scratchpad>/t01/` und gehört nicht ins Repository.

## Das Ergebnis in einem Satz

**Der Weg trägt.** Ein Snap über Apples Shortcuts läuft aus einer sandboxed App in
**0,21–0,32 s**, **ohne** dass ein Fenster der Shortcuts-App sichtbar wird und **ohne**
Vordergrundwechsel — aber nur über `Shortcuts Events`, nicht über das URL-Schema, und
die Rückmessung aus dem Entwurf ist so nicht baubar.

## AK-11 · Wird die Shortcuts-App sichtbar?

Gemessen wurde im 50-ms-Takt über `CGWindowListCopyWindowInfo`
(`.optionOnScreenOnly`), zusätzlich `NSWorkspace.frontmostApplication` vor und nach dem
Aufruf. Ein Fenster zählt nur, wenn es **vor** dem Aufruf nicht da war.

| Weg | Dauer | Fenster sichtbar | Vordergrundwechsel | Ergebnis |
|---|---|---|---|---|
| **A1 · Apple Events an `Shortcuts Events`** | **0,21–0,32 s** | **nein** (0 von 4–6 Proben) | **nein** | **erfüllt** |
| A2 · Apple Events an `Shortcuts` | 4,5 s | nein | nein | **Fehler −600**, „Application isn't running" |
| **B · `shortcuts://x-callback-url/…`** | 2,5 s+ | **JA** — 1000×682 auf Ebene 0 | nein | **verletzt AK-11** |

Weg B öffnet nachweislich das Fenster „Alle Kurzbefehle" und anschließend einen
Datenschutz-Dialog. **Entwurfsentscheidung 4 ist damit am Versuch bestätigt:** Apple
Events, nicht URL-Schema.

Weg A2 scheitert, weil eine sandboxed App die Shortcuts-App nicht starten darf. Das ist
kein Mangel — es zwingt auf den richtigen Weg.

### Warum A1 funktioniert

Apple dokumentiert es im Skripting-Wörterbuch selbst
(`/System/Library/CoreServices/Shortcuts Events.app/Contents/Resources/Shortcuts.sdef`):

> *„Run a shortcut. To run a shortcut in the background, **without opening the Shortcuts
> app**, tell 'Shortcuts Events' instead of 'Shortcuts'."*

`Shortcuts Events.app` trägt `LSUIElement = 1` — kein Dock-Icon, keine Oberfläche.

## OF-02 · Liest `Find Windows` Rahmenwerte aus? — **Nein**

`is.workflow.actions.filter.windows` liefert ein `WFWindowContentItem`, dessen
Textdarstellung **nur den Namen der Anwendung** enthält:

```
$ shortcuts run "T01Windows" --output-type public.plain-text
WIN:super.engineering
```

Zusätzlich belegt: Es gibt **keine** `is.workflow.actions.properties.windows` —
also keine „Get Details of Windows"-Aktion. Geprüft wurden alle 130
`Metadata.appintents`-Bundles des Systems und der dyld-Cache; `WFWindowContentItem`
kommt genau einmal vor, ohne Eigenschaftsliste.

**Zwei Folgen, die über OF-02 hinausgehen:**

1. **„Position wiederherstellen" (B02) ist im Store-Ziel nicht baubar.** Ohne Auslesen
   der Rahmenwerte gibt es nichts zu merken. Das ist genau der Fall, den die
   Risikotabelle des Entwurfs vorgesehen hat („kein Grund, das Feature zu beerdigen").
2. **Die Rückmessung aus Entwurfsentscheidung 7 ist nicht baubar.** `design.md` sieht in
   der Antwort `actualX/Y/Width/Height` vor. Diese Werte kann der Shortcut nicht
   liefern. **AK-08 ist in seiner heutigen Fassung nicht prüfbar** — siehe *Was
   entschieden werden muss*.

## Was tatsächlich funktioniert

Die drei Fensteraktionen sind vorhanden und aus dem dyld-Cache verifiziert (nicht
geraten):

| Aktion | Identifier | Wichtige Parameter |
|---|---|---|
| Find Windows | `is.workflow.actions.filter.windows` | `WFContentItemFilter`, `WFContentItemLimitNumber` |
| Move Window | `is.workflow.actions.movewindow` | `WFPosition` = `Coordinates`, `WFXCoordinate`, `WFYCoordinate` |
| Resize Window | `is.workflow.actions.resizewindow` | `WFConfiguration` = `Dimensions`, `WFWidth`, `WFHeight` |

**`Coordinates` und `Dimensions` erlauben freie Pixelmaße** — AK-09 (Zentriert, 2/3) ist
damit baubar, und Entwurfsentscheidung 9 (Zielrahmen in der App rechnen) trägt.

Praxistest, Filter auf `Name = TextEdit`, Aufruf über `Shortcuts Events` aus der
sandboxed App, drei Läufe hintereinander:

| Lauf | vorher | nachher | Ausgabe | Dauer |
|---|---|---|---|---|
| 1 | 500×400 | **800×600** | `MOVED` | 0,23 s |
| 2 | 500×400 | **800×600** | `MOVED` | 0,23 s |
| 3 | 500×400 | **800×600** | `MOVED` | 0,24 s |

Die x-Koordinate wird zuverlässig gesetzt (357 → 100).

## Der Entwurf liegt bei den Entitlements falsch

`design.md` schreibt, Shortcuts biete **keine** Zugriffsgruppen, und wählt deshalb
`com.apple.security.temporary-exception.apple-events` — eine Ausnahme, die Apple selbst
als vorübergehend bezeichnet und die das Prüfungsrisiko trägt.

Das Wörterbuch von `Shortcuts Events` enthält jedoch:

```xml
<access-group identifier="com.apple.shortcuts.run" access="r"/>
<access-group identifier="com.apple.shortcuts.organize" access="rw"/>
```

Die Messung lief mit dem **saubereren** Satz — und funktionierte:

```xml
<key>com.apple.security.app-sandbox</key><true/>
<key>com.apple.security.automation.apple-events</key><true/>
<key>com.apple.security.scripting-targets</key>
<dict>
  <key>com.apple.shortcuts.events</key>
  <array><string>com.apple.shortcuts.run</string></array>
</dict>
</dict>
```

Das ist enger als gefordert (nur „ausführen", nicht „organisieren"), vermeidet die
missbilligte Ausnahme und senkt damit das größte Risiko des Features — die Ablehnung
durch die Prüfung. **T05 ist entsprechend zu bauen, `design.md` an dieser Stelle falsch.**

## Signierung und Import des Companion-Shortcuts

`shortcuts sign --mode anyone` erzeugt aus einer plist eine 21-KB-Datei, die sich
**ohne** die Einstellung „Nicht vertrauenswürdige Kurzbefehle erlauben" importieren
lässt. Der Import-Dialog zeigt nur Name, Symbol und „Kurzbefehl hinzufügen" — keine
Sicherheitswarnung. **Entwurfsentscheidung 6 ist am System bestätigt.**

Der Import verlangt **genau einen Klick des Nutzers** und lässt sich nicht umgehen. Für
AK-13/AK-14 heißt das: Das Onboarding kann die Datei öffnen und danach im Sekundentakt
prüfen, ob sie in der Mediathek angekommen ist — mehr nicht. Genau so beschreibt es der
Entwurf.

## Der erste Zugriff schlägt still fehl

Reproduzierbares Muster, dreimal beobachtet: Der **jeweils erste** Aufruf einer neuen
Fähigkeit (Fenster suchen, Fenster verändern) liefert eine **leere Antwort ohne
Fehlermeldung**; ab dem zweiten Aufruf läuft dieselbe Aktion stabil. Auslöser ist eine
einmalige Zustimmung, die macOS bei einem unsichtbaren Aufruf nicht erfragen kann.

**Folge für den Bau:** Eine leere Antwort darf nicht als Erfolg gelten. Sie ist der
Fall, der auf die Zustimmung hinweisen muss (AK-15, AK-16) — der Entwurf sieht dafür
`SnapResult` und das Hinweisband aus B04 vor, was passt. Für das Onboarding empfiehlt
sich ein einmaliger Probelauf, damit der Nutzer die Zustimmung erteilt, solange er
geführt wird, und nicht beim ersten echten Tastendruck.

## Die Koordinaten — nachgemessen

Ein erster Messdurchgang legte nahe, `WFYCoordinate` werde ignoriert. **Das war ein
Messartefakt.** Der damalige Test-Shortcut führte drei Aktionen hintereinander aus
(Move → Resize → Move); gemessen wurde der Endzustand, nicht die Wirkung des Move.

Mit einem Shortcut, der **nur** verschiebt (`Move Window` auf `(200, 500)`, kein Resize),
trifft die Aktion exakt — unabhängig von der Fenstergröße:

| Fensterhöhe | vorher | nachher | Sollwert |
|---|---|---|---|
| 339 | x=800 y=33 | **x=200 y=500** | x=200 y=500 ✓ |
| 482 | x=800 y=60 | **x=200 y=500** | ✓ |
| 482 | x=800 y=60 | **x=200 y=500** | ✓ |

**`Move Window` setzt die linke obere Ecke exakt, im selben Koordinatensystem wie
`CGWindowListCopyWindowInfo`** — Ursprung oben links am Hauptbildschirm. Damit ist die
Umrechnung aus `SnapAction.targetFrame` geradlinig, und AK-07 ist erfüllbar.

**Für T12 folgt daraus eine Vorgabe:** Die Abfolge aus Entwurfsentscheidung 10
(Position → Größe → Position) ist einzeln nachzumessen. `Resize Window` verschiebt das
Fenster, und der abschließende Move muss das korrigieren — im Messdurchgang tat er es
nicht zuverlässig.

## AK-10 · Zweiter Bildschirm — **eingeschränkt**

Der Prüfrechner hat zwei Bildschirme: `Screen 0 = (0, 0, 1512, 982)` und
`Screen 1 = (−141, 982, 1920, 1080)` in Cocoa-Koordinaten — Screen 1 liegt **oberhalb**,
in CG-Koordinaten also bei y = −1080 bis 0.

Ein `Move Window` auf `(100, −500)` — mitten auf Screen 1 — **bewirkt nichts.** Das
Fenster bleibt stehen, obwohl der Shortcut fehlerfrei durchläuft und `S2` zurückgibt.
Gemessen über beide Aufrufwege, CLI und Apple Events.

**`Move Window` nimmt keine negativen Koordinaten an.** Was das für AK-10 heißt:

- Ein Bildschirm **oberhalb oder links** des Hauptbildschirms ist über freie Koordinaten
  **nicht erreichbar**.
- Ein Bildschirm **rechts oder unterhalb** hätte positive Werte und ist **ungetestet** —
  der übliche Fall, aber nicht belegt.
- `Move Window` besitzt einen eigenen `Display`-Parameter („The display to move the
  window to"). Er ist der vorgesehene Weg für die Bildschirmwahl und **wurde nicht
  getestet**; das Werteformat des Display-Pickers ist unbekannt.

AK-10 ist damit **nicht widerlegt, aber auch nicht belegt**. Zu klären, bevor T12
gebaut wird — über den `Display`-Parameter, nicht über negative Koordinaten.

## Offen geblieben

- **Randnahe Fenster (AK-12)** wurden nicht gemessen. Die Abfolge Position → Größe →
  Position aus Entwurfsentscheidung 10 ist im Test-Shortcut angelegt, aber ihre
  Zuverlässigkeit ist offen (siehe oben).
- **Die Messreihe wurde zwischenzeitlich instabil.** Nach mehrfachem Setzen der
  Fensterposition über `System Events` wirkte derselbe Shortcut nicht mehr, und ein
  CLI-Lauf blockierte länger als 60 s ohne sichtbaren Dialog. Ursache ungeklärt. Für den
  Bau heißt das: Die Zeitgrenze von 1 s aus dem Entwurf ist **notwendig**, nicht
  vorsorglich (EC-04).

## Nachtrag 2026-08-26 · Der Zielrahmen kommt an — nach vier Anläufen

Beim Bau des Companion-Kurzbefehls (T06/T12) stellte sich heraus, dass die Übergabe des
gerechneten Zielrahmens vier Hürden hat. Alle vier sind genommen; jede war nur am
laufenden System zu finden, keine steht in einer Dokumentation.

### 1 · Zahlenfelder nehmen keinen Text an

`Move Window` und `Resize Window` ignorieren alles, was nicht schon eine Zahl ist. Der
Kurzbefehl läuft dabei fehlerfrei durch und meldet „ok" — das Fenster bleibt stehen.

| Übergabeweg | Ergebnis |
|---|---|
| Text mit Trennzeichen → „Objekt aus Liste" | wirkungslos |
| dasselbe als `WFTextTokenString` | wirkungslos |
| JSON → Wörterbuch → „Wert holen", direkt ins Feld | wirkungslos |
| **JSON → Wörterbuch → „Wert holen" → „Zahl" → Feld** | **wirkt** |

**Die Aktion `is.workflow.actions.number` ist der Schlüssel.** Sie macht aus dem gelesenen
Wert eine echte Zahl, und erst die kommt im Feld an.

### 2 · Der Filter greift nur mit einem festen Namen

`Find Windows` mit einem Anwendungsnamen aus einer Variablen findet **kein** Fenster —
auch nicht über `VariableOverrides` (damit wurde der Kurzbefehl sogar unlesbar,
`action count = 0`). Mit einem fest eingetragenen Namen greift derselbe Filter.

**Gelöst durch Weglassen:** Ohne Filter liefert `Find Windows` das vorderste Fenster, und
genau das ist gemeint, wenn jemand ein Kürzel drückt.

**Das ist mehr als ein Umweg — es macht AK-23 gegenstandslos.** Ohne Filter braucht die
Nutzlast weder Anwendungsnamen noch Fenstertitel. Sie trägt jetzt fünf Zahlen und einen
Zufallswert, also **nichts Personenbeziehbares** (siehe OF-13).

### 3 · Das Fensterobjekt veraltet

Wird dasselbe Ergebnis von `Find Windows` für mehrere Aktionen benutzt, wirkt nur die
erste. Vor **jeder** Fensteraktion muss neu gesucht werden.

### 4 · Die Aktionen überholen sich

Ohne Pause dazwischen wirkte mal nur das Verschieben, mal nur das Skalieren — abhängig
davon, welche Aktion zuerst kam. Zwei Pausen von je 0,15 s lösen das.

### Der Aufbau, der funktioniert

```
Eingabe → Wörterbuch
  → Wert holen → Zahl        (je x, y, width, height)
  → Fenster suchen → bewegen
  → 0,15 s warten
  → Fenster suchen → skalieren
  → 0,15 s warten
  → Fenster suchen → bewegen
  → Antwort "ok│<nonce>"
```

Gemessen mit dem ausgelieferten Kurzbefehl, aufgerufen über Apple Events an
`Shortcuts Events` — also genau dem Weg, den die App nimmt.

**Mit dem echten Zielrahmen aus `SnapAction.targetFrame`** (linke Hälfte auf einem
Bildschirm mit `frame = (0, 0, 1512, 982)` und `visibleFrame = (0, 0, 1512, 949)`, also
`x=0 y=33 756×949`):

| | Sollwert | Ergebnis |
|---|---|---|
| x | 0 | **0** |
| y | 33 | **33** |
| Breite | 756 | **756** |
| Höhe | 949 | **949** |

**Exakt, alle vier Werte.** Antwort `ok│EXACT-1` — der `nonce` kommt zurück.

**AK-07 und AK-08 sind damit erfüllt:** Das Fenster sitzt genau dort, wo
`SnapAction.targetFrame` es berechnet — und das ist dieselbe Rechnung, die die
Direktfassung benutzt.

### Eine gemeldete Abweichung, die keine war

Ein früherer Durchgang zeigte kleine Abweichungen (y um 8 daneben, Höhe um 4). Sie kamen
**aus der Testnutzlast, nicht aus dem Code**: Dort stand `y=25`, von Hand geschätzt. Der
nutzbare Bereich beginnt aber erst bei `y=33` — darüber liegt die Menüleiste. macOS hat
das Fenster korrekt nach unten begrenzt.

Zwei Dinge, die dabei nebenbei sichtbar wurden und für die QA taugen:

- **Die Zielanwendung kann die Größe rastern.** TextEdit nahm 920 statt 924 Punkt Höhe
  (Zeilenhöhe), Finder im selben Lauf exakt 924. Das ist Verhalten der Zielanwendung,
  nicht des Kurzbefehls — die Direktfassung hat dasselbe (B01, Rückmessung mit 2 pt
  Toleranz).
- **Wer den Zielrahmen von Hand baut, baut ihn falsch.** Die Rechnung gehört in
  `SnapAction.targetFrame` und nirgendwo sonst.

### Das vorderste Fenster ist nicht immer das gemeinte

Weil der Kurzbefehl ohne Filter arbeitet, trifft er das Fenster, das gerade vorne liegt.
Beim Tastenkürzel ist das von selbst die Zielanwendung. **Beim Klick auf eine Rasterzone
im Popover ist es Mika+Grid selbst** — das Popover im Stil `.window` holt die eigene App
nach vorn (B01). Ohne Gegenmaßnahme würde also das Popover gesnappt.

`ShortcutsWindowSnapper` bringt deshalb die zuletzt aktive fremde Anwendung nach vorn,
bevor er den Kurzbefehl ruft — aber nur dann, wenn Mika+Grid selbst vorne ist.

*(Fiel beim Testen aus dem Terminal auf: Dort ist das Terminal vorne, und der Kurzbefehl
ließ TextEdit unberührt. Kein Fehler im Kurzbefehl — ein Fehler im Testaufbau, der auf
einen echten Fehlerfall zeigte.)*

### Zwei Fallen für den Bau

- **Der Anzeigename kommt vom Dateinamen.** Als `MikaGridSnap.shortcut` hieß der
  Kurzbefehl in der Mediathek „MikaGridSnap" — die App suchte „Mika+Grid Snap" und fand
  ihn nie. Die Datei heißt deshalb wie der Kurzbefehl.
- **`action count` meldet direkt nach dem Import einige Sekunden lang `0`**, danach den
  richtigen Wert. Wer das als „verändert" wertet, weist den Nutzer genau in dem Moment ab,
  in dem er den Kurzbefehl gerade hinzugefügt hat. Und: Der gemeldete Wert liegt
  reproduzierbar **um eins über** der Zahl der Aktionen in der Datei.

## Was entschieden werden muss, bevor Ebene 2 beginnt

1. **AK-08 ist in seiner heutigen Fassung nicht baubar.** Es verlangt den Vergleich mit
   der Direktfassung; der Entwurf löst das über `actual`-Werte, die Shortcuts nicht
   liefert. Entweder wird AK-08 auf „ohne Rückmessung" umformuliert, oder das Feature
   verzichtet auf die Erfolgskontrolle.
2. **B02 „Position wiederherstellen" entfällt im Store-Ziel.** Decision Log 4 der
   Spezifikation („mitnehmen, mit dokumentierter Einschränkung") ist nicht haltbar — es
   sind zehn von elf Aktionen, nicht elf.
3. **AK-25 ist umzuformulieren.** Der gemessene Weg braucht `automation.apple-events`
   **und** `scripting-targets` — zwei Einträge für eine Berechtigung. Der Wortlaut
   „genau eine" passt darauf nicht. Das ist OF-06, jetzt entscheidbar.

## Verwendete Test-Shortcuts

`T01Echo`, `T01Windows`, `T01Count`, `T01Move` — in der Mediathek des Prüfrechners.
**Sie sind Wegwerf und von Hand zu löschen**; die `shortcuts`-CLI kann das nicht.
