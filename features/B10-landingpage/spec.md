# B10 · Landingpage — Spezifikation

Status: `rekonstruiert` · Stand: 2026-08-25 · Erfasst aus: v1.1.1 · Repariert in: v1.2.0

> **Rückerfassung, danach repariert.** Erfasst aus v1.1.1, überarbeitet in **v1.2.0**
> (2026-08-25). Die Kriterien beschreiben den Stand **nach** der Reparatur; was vorher
> anders war, steht in Klammern dabei. ⚠ markiert die Punkte, die **nicht** aus dem
> Repository heraus lösbar sind. *Behobener Fehlbestand* führt jede geschlossene Lücke mit
> ihrer Fundstelle — eine Rekonstruktion, die verschweigt, was falsch war, ist wertlos.

## Zweck

Eine einzelne öffentliche Seite erklärt, was Mika+Grid ist, zeigt das Raster in Aktion
und führt zum Download. Sie ist zugleich die Referenzarbeit, mit der Daumedia auf
Auftragsarbeit aufmerksam macht — der Zweck, den das PRD unter Monetarisierung nennt.

## Abhängigkeiten

| Braucht | Status | Warum |
|---|---|---|
| B09 | rekonstruiert | Die Seite verlinkt das DMG aus dem GitHub-Release und nennt dessen Größe |

## User Stories

- **US-01** · Als Interessent möchte ich in dreißig Sekunden verstehen, was die App tut,
  damit ich entscheiden kann, ob sich der Download lohnt.
- **US-02** · Als Interessent möchte ich vor dem Download wissen, worauf ich mich
  einlasse — Berechtigungen, Signaturlage, Kosten.
- **US-03** · Als potenzieller Auftraggeber möchte ich sehen, wer dahintersteht.

## Nicht im Scope

- **Mehrere Seiten.** Es gibt genau eine Route.
- **Download-Zählung, Newsletter, Kontaktformular.** Nichts davon existiert — und ohne
  sie braucht die Seite keine Einwilligung.
- **Mehrsprachigkeit.** Ausschließlich Englisch, obwohl der Anbieter in Luxemburg sitzt.

## Akzeptanzkriterien

- **AK-01** · Angenommen, das Verzeichnis `web/` ist eingerichtet, wenn `npm run build`
  läuft, dann geht der Build ohne Fehler durch und erzeugt ausschließlich statisch
  vorgerenderte Routen.
  *(Nachweis 2026-08-25: bestanden — 6 Routen, alle als „Static" ausgewiesen.)*
- **AK-02** · Angenommen, die Seite wird geladen, wenn sie betrachtet wird, dann zeigt
  sie Kopfleiste, Aufmacher mit Rasterdarstellung, Funktionsliste, Kürzelübersicht,
  Ablauferklärung, Kennzahlen, häufige Fragen und Fußzeile.
- **AK-03** · Angenommen, die Seite ist geladen, wenn die Download-Schaltfläche betrachtet
  wird, dann nennt sie Version, Dateiformat, Größe in MB, Mindestsystem und Lizenz.
- **AK-04** · Angenommen, die Download-Schaltfläche wird angeklickt, dann führt sie zum
  DMG des passenden GitHub-Releases.
  *(Nachweis 2026-08-25: die hinterlegte Adresse liefert HTTP 200.)*
- **AK-05** · Angenommen, die Seite nennt eine Dateigröße, wenn sie mit dem Artefakt
  verglichen wird, dann stimmt sie.
  *(Nachweis: angegeben 2,5 MB, tatsächlich 2 543 170 Bytes = 2,54 MB.)*
- **AK-06** · Angenommen, die Seite nennt eine Version, wenn sie mit `Info.plist`
  verglichen wird, dann stimmt sie. *(Nachweis: beide 1.1.1.)*
- **AK-07** · Angenommen, die Kürzelübersicht wird betrachtet, wenn sie mit dem
  Aktions-Aufzählungstyp der App verglichen wird, dann stimmen Beschriftungen und
  Standardbelegungen aller elf Aktionen überein.
- **AK-08** · Angenommen, die Rasterdarstellung zeigt die zentrierte Zone, wenn ihre
  Maße geprüft werden, dann belegt sie zwei Drittel in Breite und Höhe.
  *(Bemerkenswert: Die **Website** stellt diese Zone korrekt dar; die **App** zeigt im
  Popover rund 80 % × 69 % — siehe B04.)*
- **AK-09** · Angenommen, die Seite wird geladen, wenn der Netzwerkverkehr betrachtet
  wird, dann geht **kein** Aufruf an einen Drittanbieter — auch nicht für Schriften.
  *(Die drei Schriften werden zur Bauzeit heruntergeladen und mitgeliefert; zur Laufzeit
  gibt es keine Verbindung zu Google.)*
- **AK-10** · Angenommen, die Seite wird besucht, wenn Speicher und Verlauf geprüft
  werden, dann setzt sie keine Cookies, schreibt nichts in den lokalen Speicher und
  überträgt keine Nutzungsdaten. *(Nachgewiesen: kein Analysewerkzeug in den
  Abhängigkeiten, keine Fundstelle für Cookies, lokalen Speicher oder Formulare.)*
- **AK-11** · Angenommen, die Seite behauptet „0 Trackers or analytics", wenn das geprüft
  wird, dann trifft die Aussage zu.
- **AK-12** · Angenommen, ein Interessent ruft die im Quelltext hinterlegte Adresse
  `https://grid.daumedia.lu` auf, dann erhält er die Landingpage.
  *(Nachgemessen am 2026-09-03: HTTP 200 unter `/` und unter `/privacy` — letztere ist die
  Datenschutz-Adresse des Store-Eintrags. Bis 2026-08-25 stand im Quelltext
  `https://mikagrid.vercel.app` und antwortete mit HTTP 404 und
  `x-vercel-error: DEPLOYMENT_NOT_FOUND`; mit dem Store-Paket wurde `APP.siteUrl` auf die
  eigene Domain umgestellt, seither ist ein Produktivstand darunter erreichbar. Der
  ⚠-Marker ist damit hinfällig. Siehe FB-02.)*
- **AK-13** · Angenommen, ein Besucher klickt in der Fußzeile auf „MIT Licence", dann
  erreicht er die Lizenzdatei im Repository.
  *(Bis 1.1.1 führte der Link auf `…/blob/master/LICENSE` ins Leere: Die Datei existierte
  nicht. Seit 1.2.0 gibt es sie, und der Link zeigt auf `/blob/HEAD/`, folgt also dem
  Standardzweig statt einem fest verdrahteten.)*

### Datenschutz und Missbrauchsschutz

Geprüft gegen `~/.claude/sdd/sicherheit.md`.

- **AK-14** · Angenommen, die Seite ist erreichbar, wenn ein Besucher sie aufruft, dann
  verarbeitet der Betreiber mittelbar dessen IP-Adresse — über die Zugriffsprotokolle
  von Vercel. Eigene Verarbeitung findet nicht statt.
- **AK-15** · Angenommen, ein Besucher sucht die Datenschutzerklärung oder das Impressum,
  dann findet er beides in der Fußzeile verlinkt, unter `/privacy` und `/legal`.
  *(Bis 1.1.1 gab es weder das eine noch das andere — bei einer Seite, die ausdrücklich als
  Werbeträger für Auftragsarbeit dient, der einzige Befund der ganzen Erfassung mit
  rechtlicher Tragweite.)*
- **Besondere Kategorien, Uploads, Rollen, Rate Limits:** treffen nicht zu — die Seite
  nimmt keine Eingaben entgegen.
- **Geheimnisse:** keine. Die Seite ist vollständig statisch; es gibt keine
  Umgebungsvariablen und keine serverseitige Logik.

## Edge Cases

- **EC-01** · Ein neues Release erscheint, ohne dass `web/lib/app.ts` angepasst wird →
  die Seite bewirbt weiterhin die alte Version und verlinkt ein älteres DMG. Nichts
  verhindert das; `CLAUDE.md` nennt die Pflicht zur Handpflege ausdrücklich.
- **EC-02** · Eine Snap-Aktion wird in der App umbenannt oder ergänzt → die Spiegeldatei
  `web/lib/snapActions.ts` weicht ab, bis jemand sie nachzieht.
- **EC-03** · Das GitHub-Release wird gelöscht → die Download-Schaltfläche führt ins Leere.
- **EC-04** · Besucher mit deaktiviertem JavaScript → die Seite ist statisch
  vorgerendert und bleibt vollständig lesbar; nur die animierte Vorführung steht still.

## Behobener Fehlbestand

- **FB-01 ✅ Weder Impressum noch Datenschutzerklärung.**
  **Behoben:** `/legal` (Anbieterkennzeichnung nach dem luxemburgischen Gesetz vom
  14. August 2000 über den elektronischen Geschäftsverkehr) und `/privacy` (Information
  nach Art. 13 DSGVO, einschließlich der Zugriffsprotokolle des Hosters). Beide sind in
  der Fußzeile verlinkt und stehen in der Sitemap. Dazu `docs/datenschutz.md` als interne
  Fassung.
- **FB-02 ✅ Die Seite war nicht erreichbar.**
  **Behoben außerhalb des Repositories** (2026-09-03 nachgemessen). Bei der Erfassung
  existierte das Vercel-Projekt bereits und war mit dem Repository verbunden — es hatte für
  Pull Request #7 selbsttätig ein Vorschau-Deployment gebaut (`daumedia/mikaplus-grid`).
  Es fehlte nicht die Verbindung, sondern ein **Produktiv-Deployment** unter einer
  erreichbaren Adresse; `mikagrid.vercel.app`, `mikaplus-grid.vercel.app` und
  `mikaplusgrid.vercel.app` antworteten alle mit 404.
  Ausgespielt wird jetzt unter `https://grid.daumedia.lu` — der Adresse, die `APP.siteUrl`,
  die kanonische Adresse, `sitemap.xml`, die strukturierten Daten und
  `AppStore/metadata/en-US/*_url.txt` ohnehin nennen. Ein Nachziehen entfiel deshalb.
  **Damit ist dieses Feature vollständig.**
- **FB-03 ✅ Der Lizenzlink der Fußzeile war tot.**
  **Behoben:** `LICENSE` existiert jetzt im Repository, und `APP.licenseUrl` zeigt auf
  `/blob/HEAD/LICENSE` — das folgt immer dem Standardzweig.
- **FB-04 ✅ Der Zweig `master` steckte fest verdrahtet in der Fußzeile.**
  **Behoben** mit FB-03.
- **FB-05 ✅ Kein Abgleich mit dem Bestand.**
  **Behoben:** `scripts/check-web-sync.mjs` vergleicht Version, Mindestsystem,
  Download-Adresse, DMG-Größe sowie Anzahl und Beschriftungen der Snap-Aktionen gegen
  `Info.plist`, `appcast.xml` und `SnapAction.swift`. Läuft in der CI und über
  `npm run check`.
- **FB-06 ✅ Keine Angabe zur Signaturlage im Aufmacher.**
  **Behoben:** Unter der Download-Schaltfläche steht jetzt ein Hinweis mit Verweis auf die
  ausführliche Antwort in den häufigen Fragen.
- **FB-07 ✅ Kein Test, kein Prüflauf.**
  **Behoben:** `.github/workflows/ci.yml` baut die Seite bei jedem Push und führt die
  Abgleichprüfung aus.

## Entschiedene Fragen

- **OF-01 ✅ Die Seite ist live** — unter `https://grid.daumedia.lu`, am 2026-09-03 mit
  HTTP 200 nachgemessen. Alles, was der Veröffentlichung im Weg stand, war zuvor beseitigt:
  Der Bau ist grün, Impressum und Datenschutzerklärung liegen vor, der Lizenzlink stimmt.
  Gefehlt hatte nur der Anstoß im Vercel-Konto (Root Directory `web`). Siehe FB-02.
- **OF-02 ✅ `LICENSE` ist ergänzt** — MIT, wie an vier Stellen zugesagt.
- **OF-03 ✅ Impressum und Datenschutzerklärung sind ergänzt.** Bei „Visitenkarte für
  Auftragsarbeit" als erklärtem Zweck ist die Seite kein rein privates Angebot; die
  Angaben gehören dazu, sobald sie erreichbar ist.

## Decision Log

| # | Frage | Entscheidung | Begründung |
|---|---|---|---|
| 1 | Technischer Unterbau | Next.js 15 mit App Router, Tailwind 4 | Statische Ausgabe ohne Server; die Wahl passt zum Umfang einer einzelnen Seite |
| 2 | Hosting | Vercel, Wurzelverzeichnis `web` | Ohne weitere Einrichtung lauffähig |
| 3 | Schriften | über `next/font` eingebunden | Werden zur Bauzeit heruntergeladen und mitgeliefert — kein Aufruf an Google beim Besucher. Bewusst datenschutzfreundlich |
| 4 | Analyse | keine | Deckungsgleich mit der Zusage „0 Trackers" auf der Seite selbst |
| 5 | Sprache | nur Englisch | Zielgruppe des Produkts; der Anbieter sitzt allerdings in Luxemburg |
| 6 | Produktdaten an einer Stelle | `lib/app.ts` als einzige Quelle | Richtig gedacht — nur wird die Quelle selbst von Hand gepflegt (FB-05) |
| 7 | Farben aus dem Bestand gespiegelt | `@theme` in `globals.css` | Deckungsgleich mit der Palette der App, geprüft |
| 8 | Nur dunkle Darstellung | `color-scheme: dark` | Entspricht dem Erscheinungsbild der Marke |
