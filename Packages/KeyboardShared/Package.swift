// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KeyboardShared",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "KeyboardShared", targets: ["KeyboardShared"])
    ],
    targets: [
        .target(name: "KeyboardShared")
    ]
)
