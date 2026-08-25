// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MikaGrid",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0"),
    ],
    targets: [
        .executableTarget(
            name: "MikaGrid",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "Sources",
            linkerSettings: [
                .linkedFramework("Carbon"),
                .linkedFramework("ApplicationServices"),
            ]
        ),
        .testTarget(
            name: "MikaGridTests",
            dependencies: ["MikaGrid"],
            path: "Tests/MikaGridTests"
        ),
    ]
)
