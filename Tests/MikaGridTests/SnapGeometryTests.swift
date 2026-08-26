// SnapGeometryTests.swift
// MikaGridTests
//
// Die Zielgeometrie ist reine Rechnung ohne Systemzugriff — und damit genau die Sorte Logik,
// deren Fehler bis 1.1.1 erst beim Nutzer auffielen: fehlende Kantenrundung ließ Hälften mit
// einem Spalt nebeneinander stehen.

import Testing
import Foundation
@testable import MikaGridCore

@MainActor
struct SnapGeometryTests {

    /// Ein typischer Bildschirm mit Menüleiste oben und Dock unten, in Cocoa-Koordinaten.
    private let visible = CGRect(x: 0, y: 70, width: 1512, height: 892)
    private let primaryHeight: CGFloat = 982

    private func frame(_ action: SnapAction) -> CGRect {
        guard let f = action.targetFrame(visibleFrame: visible, primaryHeight: primaryHeight) else {
            Issue.record("\(action.label) liefert keinen Zielrahmen")
            return .zero
        }
        return f
    }

    @Test("Restore hat keinen berechneten Zielrahmen")
    func restoreHasNoTarget() {
        #expect(SnapAction.restore.targetFrame(visibleFrame: visible, primaryHeight: primaryHeight) == nil)
    }

    @Test("Alle übrigen Aktionen liefern einen Zielrahmen")
    func allOthersHaveTarget() {
        for action in SnapAction.allCases where action != .restore {
            #expect(action.targetFrame(visibleFrame: visible, primaryHeight: primaryHeight) != nil,
                    "\(action.label)")
        }
    }

    @Test("Maximieren füllt den nutzbaren Bereich vollständig")
    func maximizeFillsVisibleArea() {
        let f = frame(.maximize)
        #expect(f.width == visible.width)
        #expect(f.height == visible.height)
        #expect(f.minX == visible.minX)
        // AX zählt von oben: obere Kante = primaryHeight − maxY
        #expect(f.minY == primaryHeight - visible.maxY)
    }

    @Test("Linke und rechte Hälfte stoßen lückenlos aneinander")
    func halvesTileWithoutGap() {
        let left = frame(.leftHalf), right = frame(.rightHalf)
        #expect(left.maxX == right.minX, "Spalt oder Überlappung zwischen den Hälften")
        #expect(left.width + right.width == visible.width)
    }

    @Test("Obere und untere Hälfte stoßen lückenlos aneinander")
    func verticalHalvesTileWithoutGap() {
        let top = frame(.topHalf), bottom = frame(.bottomHalf)
        #expect(top.maxY == bottom.minY)
        #expect(top.height + bottom.height == visible.height)
    }

    @Test("Die vier Viertel decken die Fläche vollständig und überlappen nicht")
    func quartersTileExactly() {
        let quarters = [frame(.topLeft), frame(.topRight), frame(.bottomLeft), frame(.bottomRight)]
        let area = quarters.reduce(0) { $0 + $1.width * $1.height }
        #expect(area == visible.width * visible.height, "Vierteln deckt die Fläche nicht exakt ab")

        for (i, a) in quarters.enumerated() {
            for b in quarters[(i + 1)...] {
                #expect(a.intersection(b).isEmpty, "Zwei Viertel überlappen sich")
            }
        }
    }

    @Test("Viertel stoßen exakt an die zugehörigen Hälften")
    func quartersAlignWithHalves() {
        #expect(frame(.topLeft).minX == frame(.leftHalf).minX)
        #expect(frame(.topLeft).maxX == frame(.leftHalf).maxX)
        #expect(frame(.topRight).minX == frame(.rightHalf).minX)
        #expect(frame(.bottomLeft).maxY == frame(.leftHalf).maxY)
    }

    @Test("Zentrieren belegt zwei Drittel in beiden Richtungen")
    func centerIsTwoThirds() {
        let f = frame(.center)
        #expect(abs(f.width - visible.width * 2 / 3) <= 1)
        #expect(abs(f.height - visible.height * 2 / 3) <= 1)
    }

    @Test("Zentrieren sitzt mittig im nutzbaren Bereich")
    func centerIsCentred() {
        let f = frame(.center), full = frame(.maximize)
        #expect(abs(f.midX - full.midX) <= 1)
        #expect(abs(f.midY - full.midY) <= 1)
    }

    @Test("Gebrochene Bildschirmmaße erzeugen keinen Spalt zwischen den Hälften",
          arguments: [1512.5, 1439.7, 2056.3, 1280.25])
    func fractionalWidthsStillTile(width: CGFloat) {
        let odd = CGRect(x: 0, y: 70.5, width: width, height: 891.3)
        let left = SnapAction.leftHalf.targetFrame(visibleFrame: odd, primaryHeight: 982.7)!
        let right = SnapAction.rightHalf.targetFrame(visibleFrame: odd, primaryHeight: 982.7)!
        #expect(left.maxX == right.minX, "Bei Breite \(width) klafft ein Spalt")
    }

    @Test("Zielrahmen liegen auf ganzen Punkten")
    func targetsAreWholePoints() {
        let odd = CGRect(x: 0.3, y: 70.5, width: 1512.5, height: 891.3)
        for action in SnapAction.allCases where action != .restore {
            let f = action.targetFrame(visibleFrame: odd, primaryHeight: 982.7)!
            #expect(f.minX == f.minX.rounded(), "\(action.label): x nicht ganzzahlig")
            #expect(f.minY == f.minY.rounded(), "\(action.label): y nicht ganzzahlig")
        }
    }

    @Test("Ein zweiter Bildschirm mit negativem Ursprung wird korrekt umgerechnet")
    func secondaryScreenWithNegativeOrigin() {
        // Bildschirm links neben dem Hauptbildschirm
        let secondary = CGRect(x: -1920, y: 0, width: 1920, height: 1080)
        let f = SnapAction.leftHalf.targetFrame(visibleFrame: secondary, primaryHeight: 982)!
        #expect(f.minX == -1920)
        #expect(f.width == 960)
    }
}

@MainActor
struct SnapPreviewTests {

    @Test("Die Vorschau der zentrierten Zone zeigt zwei Drittel — nicht mehr")
    func centerPreviewIsTwoThirds() {
        // Bis 1.1.1 zeichnete das Popover diese Zone mit rund 80 % × 69 %, weil die Vorschau
        // von Hand nachgebaut war statt aus der Zielgeometrie abgeleitet.
        let rect = SnapAction.center.previewRect!
        #expect(abs(rect.width - 2.0 / 3.0) < 0.001)
        #expect(abs(rect.height - 2.0 / 3.0) < 0.001)
    }

    @Test("Jede Vorschau liegt im Einheitsquadrat")
    func previewsStayInUnitSquare() {
        for action in SnapAction.allCases where action != .restore {
            let r = action.previewRect!
            #expect(r.minX >= 0 && r.minY >= 0, "\(action.label) ragt oben/links heraus")
            #expect(r.maxX <= 1.0001 && r.maxY <= 1.0001, "\(action.label) ragt unten/rechts heraus")
        }
    }

    @Test("Restore hat keine Vorschaufläche")
    func restoreHasNoPreview() {
        #expect(SnapAction.restore.previewRect == nil)
    }

    @Test("Vorschau und Zielrahmen beschreiben dieselbe Aufteilung")
    func previewMatchesTarget() {
        let visible = CGRect(x: 0, y: 0, width: 1000, height: 1000)
        for action in SnapAction.allCases where action != .restore {
            let target = action.targetFrame(visibleFrame: visible, primaryHeight: 1000)!
            let preview = action.previewRect!
            #expect(abs(target.width / 1000 - preview.width) < 0.01, "\(action.label): Breite weicht ab")
            #expect(abs(target.height / 1000 - preview.height) < 0.01, "\(action.label): Höhe weicht ab")
        }
    }
}

struct RectProximityTests {
    @Test("isNear akzeptiert Abweichungen innerhalb der Toleranz")
    func withinTolerance() {
        let a = CGRect(x: 0, y: 0, width: 100, height: 100)
        let b = CGRect(x: 1.5, y: -1.5, width: 101, height: 99)
        #expect(a.isNear(b, tolerance: 2))
    }

    @Test("isNear meldet Abweichungen jenseits der Toleranz")
    func beyondTolerance() {
        let a = CGRect(x: 0, y: 0, width: 100, height: 100)
        #expect(!a.isNear(CGRect(x: 3, y: 0, width: 100, height: 100), tolerance: 2))
        #expect(!a.isNear(CGRect(x: 0, y: 0, width: 105, height: 100), tolerance: 2))
    }
}
