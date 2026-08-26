#!/usr/bin/env swift
// make-wallpaper.swift — erzeugt den Schreibtischgrund für die Store-Aufnahmen.
//
// Warum überhaupt: Auf jeder Aufnahme ist der Schreibtisch zu sehen, und das private
// Hintergrundbild des Betreibers gehört nicht in den Store. `capture.sh` setzt für die
// Dauer der Aufnahme dieses Bild und stellt danach das alte zurück.
//
// Dieselbe Handschrift wie die fertigen Store-Bilder: der Verlauf und das Punktraster
// stammen aus compose.swift, die Farben aus Sources/MikaGridCore/MikaPlusColors.swift.
//
//     swift AppStore/tools/make-wallpaper.swift [Breite Höhe]

import AppKit

let werkzeuge = URL(fileURLWithPath: CommandLine.arguments[0])
    .deletingLastPathComponent().standardizedFileURL
let ziel = werkzeuge.deletingLastPathComponent()
    .appendingPathComponent("screenshots/raw/wallpaper.png")

let breite = CommandLine.arguments.count > 2 ? Int(CommandLine.arguments[1]) ?? 3024 : 3024
let hoehe  = CommandLine.arguments.count > 2 ? Int(CommandLine.arguments[2]) ?? 1964 : 1964

let teal       = NSColor(srgbRed: 0x1D/255.0, green: 0x9E/255.0, blue: 0x75/255.0, alpha: 1)
let dunkelOben = NSColor(srgbRed: 0x1A/255.0, green: 0x1A/255.0, blue: 0x2E/255.0, alpha: 1)
let dunkelUnten = NSColor(srgbRed: 0x0F/255.0, green: 0x0F/255.0, blue: 0x1A/255.0, alpha: 1)

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: breite, pixelsHigh: hoehe,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
else { fatalError("Leinwand ließ sich nicht anlegen") }
rep.size = NSSize(width: breite, height: hoehe)

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

let w = CGFloat(breite), h = CGFloat(hoehe)
NSGradient(colors: [dunkelOben, dunkelUnten])?
    .draw(in: NSRect(x: 0, y: 0, width: w, height: h), angle: -90)

// Weicher Schein, damit die Fläche nicht flach wirkt.
NSGradient(colors: [teal.withAlphaComponent(0.13), teal.withAlphaComponent(0)])?
    .draw(in: NSRect(x: w/2 - w*0.5, y: h*0.18, width: w, height: h*0.86),
          relativeCenterPosition: .zero)

// Punktraster wie in compose.swift.
teal.withAlphaComponent(0.07).setFill()
let schritt = round(w * 0.025)
var y = schritt / 2
while y < h {
    var x = schritt / 2
    while x < w {
        NSBezierPath(ovalIn: NSRect(x: x, y: y, width: w*0.0017, height: w*0.0017)).fill()
        x += schritt
    }
    y += schritt
}

NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("Kodierung fehlgeschlagen")
}
try? FileManager.default.createDirectory(at: ziel.deletingLastPathComponent(),
                                         withIntermediateDirectories: true)
do { try png.write(to: ziel) } catch { fatalError("Schreiben fehlgeschlagen: \(error)") }
print("✓ \(ziel.path) — \(breite)×\(hoehe), \(png.count / 1024) KB")
