// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KeyboardShared",
    platforms: [
        .iOS(.v17),
        // macOS is listed so `swift test` can exercise the demo engines.
        // The app and the keyboard extension remain iOS-only.
        .macOS(.v14)
    ],
    products: [
        .library(name: "KeyboardShared", targets: ["KeyboardShared"])
    ],
    targets: [
        .target(name: "KeyboardShared"),
        .testTarget(
            name: "KeyboardSharedTests",
            dependencies: ["KeyboardShared"]
        )
    ]
)
