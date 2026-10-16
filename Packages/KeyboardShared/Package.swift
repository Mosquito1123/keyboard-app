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
        .target(
            name: "KeyboardShared",
            swiftSettings: [
                // Uncomment to force in-process UserDefaults even when an App Group
                // container exists. The Xcode setting KEYBOARD_APP_GROUP_ENABLED=NO
                // already does this for the app and the keyboard via Info.plist.
                // .define("KEYBOARD_APP_GROUP_DISABLED"),
            ]
        ),
        .testTarget(
            name: "KeyboardSharedTests",
            dependencies: ["KeyboardShared"]
        )
    ]
)
