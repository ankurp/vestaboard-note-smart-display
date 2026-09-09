// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "vestaboard",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-testing.git", from: "0.10.0")
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
                "VestaboardCore",
                .product(name: "Testing", package: "swift-testing"),
            ]
        ),
    ]
)
