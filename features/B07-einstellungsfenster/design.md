# B07 · Einstellungsfenster — Systemdesign

Status: `rekonstruiert` · Stand: 2026-08-25 · Stack-Profil: `swiftui-macos`

**Kein Code in diesem Dokument.**

## Überblick

Ein Fensterhalter erzeugt bei Bedarf ein Fenster und setzt eine Ansicht mit Seitenleiste
hinein. Drei Bereiche teilen sich den Inhaltsbereich; welcher gezeigt wird, entscheidet
eine Auswahl in der Seitenleiste. Die Bereiche halten keinen eigenen dauerhaften Zustand —
sie lesen beim Anzeigen aus den zuständigen Verwaltern und schreiben unmittelbar zurück.

Das Fenster ist zugleich der einzige Ort, an dem sich das Onboarding erneut aufrufen und
alle Einstellungen zurücksetzen lassen.

## Seiten und Routen

Keine Routen. Drei Bereiche in einem Fenster:

| Bereich | Zeigt | Schreibt |
|---|---|---|
| General | Anmeldeschalter · Berechtigungszustand · Update-Schalter, letzte Prüfung, „Check Now" | Anmeldeobjekt (System), Update-Schalter (B08) |
| Shortcuts | elf Kürzelfelder, Konfliktmeldung, „Restore Defaults" | Kürzelbelegung (B03) |
| About | Symbol, Name, Version · „Show Onboarding Again" · „Reset All Settings" | alle Einstellungen |

## Komponentenstruktur

```
AppDelegate
└── PreferencesWindowController          einmal angelegt, Fenster bei Bedarf neu
    ├── NSWindow 580×420, titled + closable
    ├── windowWillClose → Fenster freigeben
    └── PreferencesContainerView          Maß ein ZWEITES Mal festgelegt (FB-06)
        ├── NavigationSplitView
        │   ├── Seitenleiste  140…180 pt
        │   └── Inhaltsbereich, scrollend
        ├── GeneralTabView
        │   ├── Toggle „Launch at login"   ← System als Wahrheit
        │   │   └── onAppear liest den Zustand · onChange schreibt (EC-03)
        │   ├── Statuszeile Berechtigung   Symbol UND Text (besser als B04/FB-03)
        │   └── GroupBox „Updates" → B08
        ├── ShortcutsTabView → B03
        └── AboutTabView
            ├── Versionsanzeige aus dem Bundle
            ├── „Show Onboarding Again" → Rückruf → AppDelegate → B06
            └── „Reset All Settings" → Rückfrage
                ├── alle Einstellungen zurücksetzen
                └── elf Standardkürzel sofort neu anmelden

AboutWindowController + AboutView         VORHANDEN, ABER UNERREICHBAR (FB-04)
```

## Datenmodell

Das Fenster besitzt keine eigenen Daten. Es bearbeitet fremde:

| Einstellung | Wohnt in | Wahrheit ist |
|---|---|---|
| Start bei der Anmeldung | Systemdienst für Anmeldeobjekte | das System — kein Spiegel |
| Automatische Update-Prüfung | Sparkle-Schlüssel in den Einstellungen | Sparkle |
| Kürzelbelegung | eigener Schlüssel in den Einstellungen | der Kürzelverwalter |
| Berechtigung | TCC des Systems | das System, nur lesbar |
| Version | `Info.plist` des Bundles | fest |

### Was „Reset All Settings" tatsächlich tut

| Schritt | Wirkung |
|---|---|
| vier Schlüssel löschen | `hasCompletedOnboarding`, `permissionSkipped`, `animationsEnabled` (verwaist), `hotkeyBindings` |
| Anmeldeobjekt entfernen | über einen **neu erzeugten** Verwalter (FB-05) |
| `hasCompletedOnboarding` = **true** | ← setzt den eben gelöschten Wert wieder (FB-01) |
| `permissionSkipped` = false | |
| elf Standardkürzel neu anmelden | vom Aufrufer in der Ansicht, nicht vom Zurücksetzen selbst |
| **nicht angetastet** | sämtliche Sparkle-Schlüssel (FB-02) |

Die dritte Zeile ist der Grund, warum das Zurücksetzen nicht in den Auslieferungszustand
führt.

## Zugriffsregeln

| Wer | Darf | Erzwungen durch |
|---|---|---|
| jeder Nutzer am Gerät | alle Einstellungen ändern | keine Beschränkung — es gibt keine Konten |
| die Ansicht | Anmeldeobjekt setzen | Systemdienst; kann fehlschlagen und tut es unbemerkt (FB-03) |
| die Ansicht | Berechtigung ändern | **nein** — nur anzeigen und in die Systemeinstellungen führen |

## Missbrauchsschutz

| Fläche | Grenze | Bewertung |
|---|---|---|
| Zurücksetzen | Rückfrage vor der Ausführung | greift ✅ |
| Anmeldeobjekt | vom System verwaltet | Fehlschlag unsichtbar ❌ |
| Kürzel ändern | Konfliktprüfung in B03 | nur innerhalb der App |
| Zweites Fenster | Prüfung auf ein sichtbares Fenster | greift ✅ |

## Externe Dienste

Keine unmittelbar. Der Bereich „Allgemein" löst über B08 Verbindungen zu GitHub aus.

## Erkennbare Entscheidungen

Die sechs tragenden stehen im Decision Log der Spezifikation. Ergänzend:

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| 7 | `NSWindow` von Hand statt `Settings`-Szene | SwiftUI-Einstellungsszene | Die Einstellungsszene braucht ein Programmmenü, das eine reine Menüleisten-App nicht hat |
| 8 | Zustände beim Anzeigen lesen | dauerhaft beobachten | Sparsam; das Fenster ist selten offen |
| 9 | Kürzel nach dem Zurücksetzen aus der Ansicht heraus neu anmelden | im Zurücksetzen selbst erledigen | **Grund nicht erkennbar.** Die Fachlogik liegt dadurch geteilt an zwei Stellen — wer das Zurücksetzen künftig anderswo aufruft, vergisst die Kürzel |
| 10 | Bereichsauswahl nicht gespeichert | letzte Auswahl merken | Bewusst schlicht; AK-12 beschreibt es als erwartetes Verhalten |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch | Anmerkung |
|---|---|---|
| AK-01 | Fensterhalter + Ansicht mit Seitenleiste | |
| AK-02 | Aufzählungstyp der drei Bereiche | |
| AK-03 | Prüfung auf ein sichtbares Fenster | |
| AK-04 | Lesen des Systemzustands beim Anzeigen | |
| AK-05 | Zustandsänderung → Systemdienst | Fehlschlag unsichtbar — FB-03 |
| AK-06 | Statuszeile mit Symbol und Text | |
| AK-07 | Update-Bereich → B08 | |
| AK-08 | Versionsanzeige aus dem Bundle | |
| AK-09 | Rückruf → B06 | |
| AK-10 | Rückfragedialog | |
| AK-11 | Zurücksetzen + sofortiges Neuanmelden | |
| AK-12 | Anfangswert der Bereichsauswahl | |
| AK-13 ⚠ | ausdrückliches Wiedersetzen des Abschlusskennzeichens | offen als OF-01 |
| AK-14 ⚠ | verschluckter Fehler im Anmeldeverwalter | offen als OF-02 |
| AK-15 ⚠ | **nichts sendet die Nachricht** für das Über-Fenster | offen als OF-03 |
| AK-16 | Löschliste der vier Schlüssel | |
| AK-17 ⚠ | Löschliste enthält keine Sparkle-Schlüssel | offen als OF-04 |

Ohne Kriterium bleiben `AboutWindowController` und `AboutView` — sie erfüllen kein
einziges, weil sie nicht erreichbar sind. Genau dafür ist diese Spalte da.
