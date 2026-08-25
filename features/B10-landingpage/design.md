# B10 · Landingpage — Systemdesign

Status: `rekonstruiert` · Stand: 2026-08-25 · Stack-Profil: Next.js 15 (abweichend vom Projektprofil)

**Kein Code in diesem Dokument.**

## Überblick

Eine statisch vorgerenderte Einzelseite. Alle Produktangaben — Version, Download-Adresse,
Dateigröße, Mindestsystem, Lizenz — stammen aus einer einzigen Datei, die den Bestand
der App von Hand spiegelt. Dasselbe gilt für die elf Snap-Aktionen mit ihren Kürzeln und
Zielflächen, die eine zweite Spiegeldatei trägt.

Es gibt keinen Server, keine Datenbank, keine Formulare und keine Laufzeit-Aufrufe an
Dritte. Was der Besucher lädt, ist fertiges HTML mit mitgelieferten Schriften.

## Seiten und Routen

| Route | Zweck | Zugang |
|---|---|---|
| `/` | die gesamte Seite | öffentlich |
| `/robots.txt` | erlaubt alles, verweist auf die Sitemap | öffentlich |
| `/sitemap.xml` | ein Eintrag: die Startseite | öffentlich |
| `/opengraph-image` | Vorschaubild für geteilte Verweise | öffentlich |
| `/icon.png` | Symbol im Browser-Tab | öffentlich |

**Nicht vorhanden:** `/privacy`, `/legal`, `/impressum` — siehe FB-01.

**Zustand der Auslieferung:** unter `mikagrid.vercel.app` antwortet Vercel mit
`DEPLOYMENT_NOT_FOUND`. Die Routen existieren im Bau, nicht im Netz (FB-02).

## Komponentenstruktur

```
app/layout.tsx                  Metadaten, drei Schriften, dunkles Farbschema
└── app/page.tsx                strukturierte Daten (JSON-LD) + Seitenaufbau
    ├── Nav                     Kopfleiste mit Sprungmarken und GitHub-Verweis
    ├── Hero                    Titel, Untertitel, Download, Vorführung
    │   ├── DownloadButton      führt zum DMG
    │   ├── DownloadMeta        "v1.1.1 · .dmg · 2.5 MB · macOS 14.0+ · MIT"
    │   ├── KbdCombo            ⌃⌥← als Tastenkappen
    │   └── SnapGridDemo        animierte Rastervorführung
    ├── Features                Kacheln, darunter „11 snap actions"
    ├── Section > ShortcutList  alle elf Kürzel
    ├── HowItWorks              drei Schritte
    ├── Trust                   vier Kennzahlen + Datenschutzabsatz
    ├── Faq                     sechs Fragen
    └── Footer                  Verweise: GitHub · Releases · Issues · MIT Licence ✗
```

## Datenmodell

Keine Datenbank. Zwei Dateien tragen den gesamten Inhalt, der sich ändern kann.

### `web/lib/app.ts` — die Produktangaben

| Feld | Wert | Spiegelt | Geprüft |
|---|---|---|---|
| `version` | `1.1.1` | `Info.plist` | ✅ stimmt |
| `minMacOS` / `minMacOSName` | `14.0` / Sonoma | `Info.plist` | ✅ |
| `dmgUrl` | GitHub-Release v1.1.1 | GitHub | ✅ HTTP 200 |
| `dmgSizeMB` | `2.5` | `appcast.xml` (`length`) | ✅ 2 543 170 B |
| `license` | `MIT` | `LICENSE` | ❌ Datei fehlt |
| `siteUrl` | `mikagrid.vercel.app` | Vercel | ❌ kein Deployment |
| `repo`, `releases`, `vendor`, `vendorUrl` | daumedia | — | ✅ erreichbar |

### `web/lib/snapActions.ts` — die Spiegelung der Aktionen

Elf Einträge mit Kennung, Beschriftung, Tastenfolge und Zielfläche in Prozent. Die
zentrierte Zone wird mit einem Einzug von 16,67 % je Seite berechnet und ergibt damit
exakt zwei Drittel — **genauer als die Vorschau in der App selbst** (siehe B04/FB).

### Marken-Token — `web/app/globals.css`

Sieben Farben, deckungsgleich mit der Palette der App. Dazu drei abgeleitete Flächen für
Linien und erhöhte Bereiche, die es in der App nicht gibt, sowie drei Schriftfamilien —
die App benutzt nur die Systemschrift.

## Zugriffsregeln

| Wer | Darf | Erzwungen durch |
|---|---|---|
| jeder Besucher | die Seite lesen | öffentlich, keine Anmeldung |
| jeder Besucher | Daten hinterlassen: **nichts** | es gibt kein Eingabefeld |
| Suchmaschinen | alles erfassen | `robots.txt` erlaubt es |

Rollen gibt es nicht, weil es keine Konten gibt. Die Frage nach fremden Kennungen (IDOR)
ist gegenstandslos: Es existiert keine Route mit Bezeichner.

## Missbrauchsschutz

| Fläche | Limit | Bewertung |
|---|---|---|
| Seitenaufrufe | Vercels Plattformschutz | ausreichend für statische Auslieferung |
| Eingaben | keine vorhanden | keine Angriffsfläche |
| Kosten je Aufruf | keine bei statischer Auslieferung im Freikontingent | — |

Eine statische Seite ohne Eingabefelder und ohne serverseitige Logik hat schlicht keine
missbrauchbare Fläche. Das ist keine Nachlässigkeit, sondern die Folge der Bauweise.

## Externe Dienste

| Dienst | Wofür | Was geht hin | Was wird vorher entfernt |
|---|---|---|---|
| Vercel | Hosting | IP-Adresse, Zeitpunkt, User-Agent jedes Besuchers — in den Zugriffsprotokollen | nichts; das ist unvermeidbar beim Abruf |
| Google Fonts | Schriften | **nichts zur Laufzeit** — sie werden zur Bauzeit geladen und mitgeliefert | entfällt |
| GitHub | Ziel der Verweise (Download, Quelltext, Fehlerberichte) | erst wenn der Besucher klickt | — |

Vercel ist damit der einzige Auftragsverarbeiter des gesamten Projekts. Ein
Auftragsverarbeitungsvertrag ist nicht dokumentiert; eine Information nach Art. 13 DSGVO
existiert nicht (FB-01).

Die Behandlung der Schriften verdient eine eigene Zeile, weil sie oft falsch gemacht
wird: Eingebunden über `next/font` werden sie beim Bauen heruntergeladen und in die
Auslieferung übernommen. Der Browser des Besuchers spricht **nie** mit Google. Das ist
der Unterschied zwischen der Zusage „0 Trackers" und ihrer Einhaltung.

## Erkennbare Entscheidungen

Die acht tragenden stehen im Decision Log der Spezifikation. Ergänzend:

| # | Entscheidung | Alternative | Warum so |
|---|---|---|---|
| 9 | Strukturierte Daten (JSON-LD) eingebettet | weglassen | Verbessert die Darstellung in Suchergebnissen. Enthält allerdings die Lizenzangabe, die der Bestand nicht deckt |
| 10 | Zielflächen als Prozentwerte gespiegelt | aus der App erzeugen | Keine gemeinsame Quelle zwischen Swift und TypeScript möglich, ohne einen Erzeugungsschritt einzuführen |
| 11 | Vorschaubild aus Code erzeugt | Bilddatei einchecken | Bleibt mit Version und Marke automatisch stimmig |
| 12 | Signaturlage offen in den häufigen Fragen genannt | verschweigen | Ehrlich und richtig — nur steht es weit unten (FB-06) |

## Abdeckung der Akzeptanzkriterien

| AK | Erfüllt durch | Anmerkung |
|---|---|---|
| AK-01 | Next.js-Konfiguration, keine dynamischen Routen | verifiziert |
| AK-02 | Aufbau in `app/page.tsx` | |
| AK-03 | `DownloadMeta` aus `lib/app.ts` | |
| AK-04 | `dmgUrl` | verifiziert |
| AK-05 | `dmgSizeMB` | verifiziert |
| AK-06 | `version` | verifiziert |
| AK-07 | `lib/snapActions.ts` | von Hand gespiegelt — FB-05 |
| AK-08 | Berechnung des Einzugs für die zentrierte Zone | genauer als die App |
| AK-09 | `next/font` statt Einbindung per Verweis | |
| AK-10 | Abwesenheit von Analyse, Cookies, Speicher, Formularen | verifiziert |
| AK-11 | dasselbe | |
| AK-12 ⚠ | **nichts** — es gibt kein Deployment | offen als OF-01 |
| AK-13 ⚠ | Verweis in der Fußzeile auf eine nicht existierende Datei | offen als OF-02 |
| AK-14 | Zugriffsprotokolle von Vercel | ohne Information nach Art. 13 |
| AK-15 ⚠ | **nichts** — es gibt keine Rechtsseiten | offen als OF-03 |

Drei Kriterien ohne erfüllende Komponente. Alle drei beschreiben, was **fehlt** — und
alle drei werden erst in dem Moment wirksam, in dem die Seite live geht.
