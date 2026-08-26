// swift-tools-version: 6.0
import PackageDescription

// Zwei Vertriebswege, ein Quelltext (Feature 01).
//
// `MikaGridCore` trägt alles, was beide Fassungen teilen. Die Tests hängen an der
// Bibliothek statt am ausführbaren Ziel — ein ausführbares Ziel lässt sich nicht sauber
// testen, und genau daran wäre die Umstellung auf zwei Ziele sonst gescheitert (AK-04).
//
// Das Store-Ziel entsteht nicht hier, sondern über `project.yml`/XcodeGen: Die
// Archivierung für App Store Connect braucht ein Xcode-Projekt (AK-06). `swift build`
// baut weiterhin die Direktfassung.
let package = Package(
    name: "MikaGrid",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "MikaGridCore", targets: ["MikaGridCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0"),
    ],
    targets: [
        .target(
            name: "MikaGridCore",
            path: "Sources/MikaGridCore",
            linkerSettings: [
                .linkedFramework("Carbon"),
                .linkedFramework("ApplicationServices"),
            ]
        ),
        .executableTarget(
            name: "MikaGrid",
            dependencies: [
                "MikaGridCore",
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "Sources/MikaGrid",
            linkerSettings: [
                .linkedFramework("Carbon"),
                .linkedFramework("ApplicationServices"),
            ]
        ),
        .testTarget(
            name: "MikaGridTests",
            dependencies: ["MikaGridCore"],
            path: "Tests/MikaGridTests"
        ),
    ]
)
