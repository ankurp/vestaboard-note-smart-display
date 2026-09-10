// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "vestaboard",
    platforms: [
        .macOS(.v15)
    ],
    targets: [
        // Platform-independent logic (character encoding, board building,
        // weather, and the Vestaboard API client). Runs anywhere and is
        // covered by unit tests.
        .target(
            name: "VestaboardCore"
        ),
        // The macOS executable: the main loop plus native EventKit and
        // Foundation Models integration.
        .executableTarget(
            name: "vestaboard",
            dependencies: ["VestaboardCore"]
        ),
        .testTarget(
            name: "VestaboardCoreTests",
            dependencies: [
                "VestaboardCore"
            ]
        ),
    ]
)
