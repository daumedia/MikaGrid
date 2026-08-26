#!/usr/bin/env bash
#
# Erzeugt den Companion-Kurzbefehl der App-Store-Fassung und signiert ihn (Feature 01, T06).
#
# Ergebnis: "Resources/Mika+Grid Snap.shortcut" — mit `--mode anyone` signiert, damit er
# sich importieren lässt, OHNE dass der Nutzer „Nicht vertrauenswürdige Kurzbefehle
# erlauben" umlegen muss. Am System geprüft (machbarkeit.md).
#
# Der DATEINAME ist der Anzeigename in der Mediathek — Kurzbefehle liest ihn nicht aus der
# Datei. Als „MikaGridSnap.shortcut" hieß der Kurzbefehl „MikaGridSnap", und die App fand
# ihn nie. Deshalb heißt die Datei wie der Kurzbefehl.
#
# ---------------------------------------------------------------------------------------
# AUFBAU — jeder Schritt ist am laufenden System erzwungen worden, keiner ist Geschmack:
#
#   1. Eingabe entgegennehmen, JSON in ein Wörterbuch wandeln
#   2. jeden Zahlenwert durch „Zahl" schicken        ← ohne das kommt NICHTS an
#   3. vor JEDER Fensteraktion neu suchen            ← das Fensterobjekt veraltet
#   4. Größe → Position → Größe, mit Pausen          ← Reihenfolge UND Pausen sind nötig
#   5. Antwort mit dem `nonce` aus der Nutzlast
#
# Was zuvor scheiterte, mit Messung in machbarkeit.md:
#   · Werte als Text mit Trennzeichen → Zahlenfelder blieben leer, Antwort trotzdem „ok"
#   · Wörterbuchwerte direkt in die Zahlenfelder → ebenso wirkungslos
#   · Filter auf den Anwendungsnamen aus einer Variablen → findet kein Fenster; mit
#     `VariableOverrides` wurde der Kurzbefehl sogar unlesbar (0 Aktionen)
#   · alle Aktionen ohne Pause hintereinander → mal wirkte nur Move, mal nur Resize
#
# KEIN FILTER, KEIN ANWENDUNGSNAME: `Find Windows` liefert ohne Filter das vorderste
# Fenster — und genau das ist gemeint, wenn der Nutzer ein Kürzel drückt. Nebenwirkung,
# die zählt: Die Nutzlast trägt weder Anwendungsnamen noch Fenstertitel, also nichts
# Personenbeziehbares (siehe AK-23).
#
# Nutzlast:
#   {"action":"leftHalf","x":0,"y":25,"width":756,"height":924,"nonce":"…"}
#
# Aufruf:
#   bash scripts/make-companion-shortcut.sh
#
set -euo pipefail

cd "$(dirname "$0")/.."

SHORTCUT_NAME="Mika+Grid Snap"
OUT_DIR="Resources"
UNSIGNED="$(mktemp -t mikagrid-companion).shortcut"
SIGNED="$OUT_DIR/$SHORTCUT_NAME.shortcut"

command -v shortcuts >/dev/null || { echo "FEHLER: 'shortcuts' nicht gefunden (macOS 12+)."; exit 1; }
command -v python3   >/dev/null || { echo "FEHLER: python3 nicht gefunden."; exit 1; }

echo "==> Companion-Kurzbefehl bauen: $SHORTCUT_NAME"

python3 - "$UNSIGNED" <<'PYEOF'
import plistlib
import sys
import uuid

out_path = sys.argv[1]
PLACEHOLDER = "￼"          # belegt genau ein Zeichen, wo eine Variable steht

# Feste Kennungen: Ein Kurzbefehl, der bei jedem Bau anders aussieht, ließe sich nicht
# gegen einen erwarteten Aufbau prüfen (T11).
U_IN = "A0000000-0000-4000-8000-000000000001"
U_DICT = "A0000000-0000-4000-8000-000000000002"
U_NONCE = "A0000000-0000-4000-8000-000000000003"
RAW = {k: f"A0000000-0000-4000-8000-00000000001{i}" for i, k in enumerate("xywh")}
NUM = {k: f"A0000000-0000-4000-8000-00000000002{i}" for i, k in enumerate("xywh")}
FIND = [f"A0000000-0000-4000-8000-00000000003{i}" for i in range(3)]


def ao(out_uuid: str, name: str) -> dict:
    """Verweis auf die Ausgabe einer früheren Aktion."""
    return {
        "Value": {"OutputUUID": out_uuid, "OutputName": name, "Type": "ActionOutput"},
        "WFSerializationType": "WFTextTokenAttachment",
    }


def dict_value(key: str, uuid_: str, name: str) -> dict:
    return {
        "WFWorkflowActionIdentifier": "is.workflow.actions.getvalueforkey",
        "WFWorkflowActionParameters": {
            "UUID": uuid_,
            "WFInput": ao(U_DICT, "Dictionary"),
            "WFDictionaryKey": key,
            "WFGetDictionaryValueType": "Value",
            "CustomOutputName": name,
        },
    }


def to_number(src: str, src_name: str, uuid_: str, name: str) -> dict:
    """Aus dem Wörterbuchwert eine echte Zahl machen.

    OHNE DIESEN SCHRITT PASSIERT NICHTS: `Move Window` und `Resize Window` nehmen in ihren
    Zahlenfeldern nichts an, was nicht schon eine Zahl ist. Der Kurzbefehl läuft dann
    fehlerfrei durch, meldet „ok" und lässt das Fenster stehen, wo es war.
    """
    return {
        "WFWorkflowActionIdentifier": "is.workflow.actions.number",
        "WFWorkflowActionParameters": {
            "UUID": uuid_,
            "WFNumberActionNumber": ao(src, src_name),
            "CustomOutputName": name,
        },
    }


def find_frontmost(uuid_: str, name: str) -> dict:
    """Das vorderste Fenster — ohne Filter.

    Ein Filter auf den Anwendungsnamen greift nur mit einem FESTEN Namen; aus einer
    Variablen findet er nichts. Gebraucht wird er auch nicht: Wer ein Kürzel drückt, meint
    das Fenster, das gerade vorne liegt.
    """
    return {
        "WFWorkflowActionIdentifier": "is.workflow.actions.filter.windows",
        "WFWorkflowActionParameters": {
            "UUID": uuid_,
            "CustomOutputName": name,
            "WFContentItemLimitEnabled": True,
            "WFContentItemLimitNumber": 1,
        },
    }


def wait(seconds: float) -> dict:
    """Kurz warten. Ohne Pause überholen sich die Fensteraktionen: Mal wirkte nur das
    Verschieben, mal nur das Skalieren — je nachdem, welche Aktion zuerst kam."""
    return {
        "WFWorkflowActionIdentifier": "is.workflow.actions.delay",
        "WFWorkflowActionParameters": {"UUID": str(uuid.uuid4()).upper(), "WFDelayTime": seconds},
    }


def move(find_uuid: str, find_name: str) -> dict:
    return {
        "WFWorkflowActionIdentifier": "is.workflow.actions.movewindow",
        "WFWorkflowActionParameters": {
            "UUID": str(uuid.uuid4()).upper(),
            "WFWindow": ao(find_uuid, find_name),
            "WFPosition": "Coordinates",
            "WFXCoordinate": ao(NUM["x"], "NumX"),
            "WFYCoordinate": ao(NUM["y"], "NumY"),
            "WFBringToFront": False,
        },
    }


def resize(find_uuid: str, find_name: str) -> dict:
    return {
        "WFWorkflowActionIdentifier": "is.workflow.actions.resizewindow",
        "WFWorkflowActionParameters": {
            "UUID": str(uuid.uuid4()).upper(),
            "WFWindow": ao(find_uuid, find_name),
            "WFConfiguration": "Dimensions",
            "WFWidth": ao(NUM["w"], "NumW"),
            "WFHeight": ao(NUM["h"], "NumH"),
            "WFBringToFront": False,
        },
    }


actions = [
    # 1) Eingabe entgegennehmen
    {
        "WFWorkflowActionIdentifier": "is.workflow.actions.gettext",
        "WFWorkflowActionParameters": {
            "UUID": U_IN,
            "CustomOutputName": "Payload",
            "WFTextActionText": {
                "Value": {
                    "string": PLACEHOLDER,
                    "attachmentsByRange": {"{0, 1}": {"Type": "ExtensionInput"}},
                },
                "WFSerializationType": "WFTextTokenString",
            },
        },
    },
    # 2) JSON in ein Wörterbuch
    {
        "WFWorkflowActionIdentifier": "is.workflow.actions.detect.dictionary",
        "WFWorkflowActionParameters": {
            "UUID": U_DICT,
            "WFInput": ao(U_IN, "Payload"),
            "CustomOutputName": "Dictionary",
        },
    },
    # 3) Werte holen und in Zahlen wandeln
    dict_value("x", RAW["x"], "RawX"), to_number(RAW["x"], "RawX", NUM["x"], "NumX"),
    dict_value("y", RAW["y"], "RawY"), to_number(RAW["y"], "RawY", NUM["y"], "NumY"),
    dict_value("width", RAW["w"], "RawW"), to_number(RAW["w"], "RawW", NUM["w"], "NumW"),
    dict_value("height", RAW["h"], "RawH"), to_number(RAW["h"], "RawH", NUM["h"], "NumH"),
    dict_value("nonce", U_NONCE, "Nonce"),

    # 4) GRÖSSE → POSITION → GRÖSSE, vor jedem Schritt neu gesucht.
    #
    #    NICHT Position → Größe → Position, wie design.md (Entscheidung 10) es vorsah.
    #    macOS begrenzt einen Positionswechsel gegen die AKTUELLE Größe des Fensters
    #    (`NSWindow.constrainFrameRect:toScreen:`) — ein zu großes Fenster lässt sich nicht
    #    an den Rand schieben, bevor es geschrumpft wurde. Die Direktfassung schreibt
    #    deshalb seit 1.1.1 size → position → size (CLAUDE.md, „Snap write sequence").
    #
    #    Mit der umgekehrten Reihenfolge traf der Kurzbefehl in 5 von 5 Läufen daneben:
    #    kleine Zielrahmen saßen, große nicht — genau das Muster, das die Begrenzung
    #    erzeugt (BUG-01 im qa-report).
    find_frontmost(FIND[0], "Win1"),
    resize(FIND[0], "Win1"),
    wait(0.2),
    find_frontmost(FIND[1], "Win2"),
    move(FIND[1], "Win2"),
    wait(0.2),
    find_frontmost(FIND[2], "Win3"),
    resize(FIND[2], "Win3"),

    # 5) Antwort. Der `nonce` geht zurück, damit die App eine verspätete Antwort einem
    #    früheren Aufruf zuordnen und verwerfen kann (design.md, Missbrauchsschutz).
    #
    #    Die tatsächlichen Rahmenwerte kann der Kurzbefehl NICHT liefern — `Find Windows`
    #    gibt sie nicht her (OF-02). Eine Rückmessung wie in der Direktfassung ist damit
    #    nicht baubar; siehe OF-07.
    {
        "WFWorkflowActionIdentifier": "is.workflow.actions.gettext",
        "WFWorkflowActionParameters": {
            "UUID": str(uuid.uuid4()).upper(),
            "WFTextActionText": {
                "Value": {
                    "string": "ok│" + PLACEHOLDER,
                    "attachmentsByRange": {
                        "{3, 1}": {"Type": "ActionOutput", "OutputUUID": U_NONCE, "OutputName": "Nonce"}
                    },
                },
                "WFSerializationType": "WFTextTokenString",
            },
        },
    },
]

plistlib.dump(
    {
        "WFWorkflowClientVersion": "3100.0.2.1",
        "WFWorkflowMinimumClientVersion": 900,
        "WFWorkflowMinimumClientVersionString": "900",
        "WFWorkflowIcon": {
            "WFWorkflowIconStartColor": 1943041535,   # Mika+ Teal
            "WFWorkflowIconGlyphNumber": 59511,
        },
        "WFWorkflowImportQuestions": [],
        "WFWorkflowTypes": ["NCWidget", "WatchKit"],
        "WFWorkflowInputContentItemClasses": ["WFStringContentItem"],
        "WFWorkflowHasShortcutInputVariables": True,
        "WFWorkflowActions": actions,
    },
    open(out_path, "wb"),
)
print(f"    {len(actions)} Aktionen geschrieben")
print(f"    -> CompanionShortcutManager.expectedActionCount muss {len(actions) + 1} sein")
print(f"       (Kurzbefehle meldet reproduzierbar eine Aktion mehr als die Datei enthält)")
PYEOF

mkdir -p "$OUT_DIR"

echo "==> Signieren (--mode anyone)"
shortcuts sign --mode anyone --input "$UNSIGNED" --output "$SIGNED"
rm -f "$UNSIGNED"

echo "==> Fertig: $SIGNED ($(stat -f%z "$SIGNED") Bytes)"
echo
echo "    Installieren kann ihn nur der Nutzer — ein Klick auf „Kurzbefehl hinzufügen\","
echo "    der sich nicht umgehen lässt (AK-13/AK-14)."
