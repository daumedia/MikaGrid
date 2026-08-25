# B03 · Globale Tastenkürzel — Systemdesign

Status: `rekonstruiert` · Stand: 2026-08-25 · Stack-Profil: `swiftui-macos`

**Kein Code in diesem Dokument.**

## Überblick

Beim Start meldet die App elf Tastenkombinationen bei Carbon an — der einzigen
Schnittstelle, über die eine App systemweite Kürzel bekommt, ohne die Tastatur
mitzulesen. Carbon ruft bei jedem Treffer eine C-Funktion auf, die nur eine Kennzahl
mitbekommt; über eine statische Referenz findet sie zurück in die Swift-Welt und löst
die passende Aktion aus.

Die Belegung liegt als JSON in den Einstellungen und wird beim Start geladen — oder,
wenn nichts gespeichert ist, aus den Standardwerten aufgebaut. Die Oberfläche zum Ändern
ist ein Feld je Aktion, das während der Aufnahme alle Tastendrücke der App abfängt.

## Einstiegspunkte

| Ort | Tut |
|---|---|
| App-Start | registriert alle elf Kürzel |
| Einstellungen → Shortcuts → Kürzelfeld | nimmt eine neue Kombination auf |
| Einstellungen → Shortcuts → „Restore Defaults" | setzt alle elf zurück |
| Einstellungen → About → „Reset All Settings" | ebenfalls (B07) |
| Popover-Rasterzone | **zeigt** das Kürzel an, ändert es nicht (B04) |

## Komponentenstruktur

```
HotkeyBinding                       Codable, Equatable, Sendable
├── keyCode: UInt32                 Carbon-Tastencode
├── modifiers: UInt32               Carbon-Maske
└── displayString                   "⌃⌥←" — aus zwei Umsetzungstabellen

HotkeyManager                       @MainActor
├── currentBindings                 [SnapAction: HotkeyBinding]
├── hotKeyRefs                      Handles zum Abmelden
├── eventHandlerRef                 GENAU EINMAL belegt — der Fix von 1.1.1
├── static instance                 Brücke für den C-Rückruf
├── init                            laden: übergeben → gespeichert → Standard
├── registerHotkeys()               Behandler (einmalig) + alle Kürzel anmelden
├── unregisterAll()                 alle Kürzel abmelden
├── reRegisterAll(bindings:)        abmelden → übernehmen → speichern → anmelden
├── saveBindings()                  JSON in die Einstellungen
└── deinit                          abmelden + Behandler entfernen (läuft praktisch nie)

ShortcutsTabView
├── bindings                        Arbeitskopie, bei onAppear geladen
├── recordingAction                 welches Feld nimmt gerade auf
├── conflictMessage                 rote Zeile unter der Liste
├── recordBinding(_:for:)           Konfliktprüfung → übernehmen → neu anmelden
└── restoreDefaults()

ShortcutRecorderView                ein Feld
├── keyMonitor                      lokaler Tastatur-Beobachter
├── onChange(isRecording)           an: anmelden · aus: abmelden
│                                   ← KEIN onDisappear (FB-05)
└── Auswertung                      Esc → Abbruch · ohne ⌘/⌃ → schlucken · sonst übernehmen
```

## Der Weg eines Tastendrucks

```
Nutzer drückt ⌃⌥←  (in irgendeiner App)
└── Carbon erkennt das angemeldete Kürzel
    └── C-Rückruf, bekommt nur die Kennzahl
        ├── Kennzahl aus dem Ereignis lesen
        └── auf den Hauptstrang reihen
            ├── statische Instanz holen  (nil → nichts tun)
            ├── Aktion mit passender Kennzahl suchen (1…11)
            └── Rückruf auslösen → WindowManager.snapFrontmostWindow  (B01)
```

Der Behandler ist bewusst zustandslos: Er kennt keine Belegung, sondern nur Kennzahlen.
Deshalb genügt **eine** Installation für alle künftigen Neuregistrierungen — und genau
deshalb war die doppelte Installation von 1.1.0 so schädlich.

## Datenmodell

### In den Einstellungen

| Schlüssel | Typ | Aufbau |
|---|---|---|
| `hotkeyBindings` | JSON in `Data` | `{"leftHalf": {"keyCode": 123, "modifiers": 6144}, …}` |

Der Wörterbuchschlüssel ist der Rohwert der Aktion. Der Wert trägt Tastencode und
Umschaltmaske als Zahlen.

**Wird erst geschrieben, wenn der Nutzer etwas ändert.** Auf einem System, auf dem nie
ein Kürzel geändert wurde, existiert der Schlüssel nicht — am laufenden System bestätigt.

### Standardbelegung (im Code, nicht in den Daten)

| Aktion | Kürzel | Code | Aktion | Kürzel | Code |
|---|---|---|---|---|---|
| Linke Hälfte | ⌃⌥← | `0x7B` | Unten links | ⌃⌥J | `0x26` |
| Rechte Hälfte | ⌃⌥→ | `0x7C` | Unten rechts | ⌃⌥K | `0x28` |
| Obere Hälfte | ⌃⌥↑ | `0x7E` | Maximieren | ⌃⌥↩ | `0x24` |
| Untere Hälfte | ⌃⌥↓ | `0x7D` | Zentrieren | ⌃⌥C | `0x08` |
| Oben links | ⌃⌥U | `0x20` | Zurücksetzen | ⌃⌥⌫ | `0x33` |
| Oben rechts | ⌃⌥I | `0x22` | | | |

Die Kennzahlen 1…11 sind fest an die Aktionen gebunden und dürfen sich nie ändern —
sie sind das einzige, was der C-Rückruf zu sehen bekommt.

## Zugriffsregeln

| Wer | Darf | Erzwungen durch |
|---|---|---|
| Mika+Grid | die elf angemeldeten Kombinationen empfangen | Carbon meldet ausschließlich diese |
| Mika+Grid | **keine** anderen Tastendrücke sehen | Plattform — es gibt keinen Ereignisabgriff |
| der Aufnahme-Beobachter | Tastendrücke sehen, die an Fenster dieser App gehen | lokaler Beobachter, nicht global |

Die mittlere Zeile ist der wichtigste Satz dieses Entwurfs: Die App verlangt **keine**
Eingabeüberwachung und kann keine Tastatur mitschneiden. Ein globaler Ereignisabgriff
hätte die Kürzel ebenfalls ermöglicht — und wäre eine ganz andere Zusage an den Nutzer
gewesen.

## Missbrauchsschutz

| Fläche | Grenze | Bewertung |
|---|---|---|
| Anmeldung eines Kürzels | System vergibt exklusiv, erster Anmelder gewinnt | Fehlschlag bleibt unsichtbar — FB-01 |
| Doppelbelegung innerhalb der App | Prüfung beim Aufnehmen | greift ✅ |
| Belegung reservierter Systemkürzel | **keine** | FB-04 |
| Aufnahme-Beobachter | nur lokal, endet beim Zustandswechsel | endet nicht beim Schließen — FB-05 |

## Externe Dienste

Keine.

## Erkennbare Entscheidungen

Die sieben tragenden stehen im Decision Log der Spezifikation. Ergänzend:

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| 8 | Zwei Umsetzungstabellen für die Anzeige | Systemschnittstelle zur Tastaturbelegung befragen | Einfach und ohne Abhängigkeit — dafür falsch bei nicht-amerikanischen Belegungen: Der Tastencode `0x0C` heißt hier immer „Q", auf einer französischen Tastatur liegt dort „A" |
| 9 | Arbeitskopie in der Ansicht statt direktem Zugriff | direkt auf dem Verwalter arbeiten | Erlaubt Konfliktprüfung vor der Übernahme |
| 10 | Kennzahlen fest im Code | fortlaufend erzeugen | Der C-Rückruf sieht nur die Zahl; sie muss über Neustarts hinweg stabil sein |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch | Anmerkung |
|---|---|---|
| AK-01 | Carbon-Anmeldung + Rückruf → B01 | |
| AK-02 | Standardbelegung im Aktions-Aufzählungstyp | |
| AK-03 | Kürzelfeld + lokaler Beobachter | |
| AK-04 | Auswertung von Tastencode 53 | |
| AK-05 | Prüfung auf Befehls- oder Steuerungstaste | |
| AK-06 | Vergleich gegen die übrigen Belegungen | |
| AK-07 | Speichern in `reRegisterAll` + Laden im `init` | |
| AK-08 | „Restore Defaults" → `reRegisterAll` | |
| AK-09 | Rasterzone liest `currentBindings` | B04 |
| AK-10 | einmalige Installation des Behandlers | der Fix von 1.1.1 |
| AK-11 ⚠ | **nichts** — Rückgabewert der Anmeldung wird verworfen | offen als OF-01 |
| AK-12 ⚠ | **nichts** — keine Sperrliste | offen als OF-02 |
| AK-13 ⚠ | **nichts** — kein `onDisappear` | offen als OF-03 |
| AK-14 | Beschränkung auf Carbon statt Ereignisabgriff | |
| AK-15 | lokaler statt globaler Beobachter | |
| AK-16 | Aufbau der gespeicherten Struktur | |

Drei Kriterien ohne erfüllende Komponente (AK-11 bis AK-13) — sie beschreiben Verhalten,
das aus einer **fehlenden** Zeile folgt. Genau dafür ist diese Spalte da.
