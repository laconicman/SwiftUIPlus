// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftUIPlus",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "SwiftUIPlus",
            targets: ["SwiftUIPlus"]
        ),
    ],
    dependencies: [
        // Pinned to the laconicman/SwiftUIBackports fork because
        // BottomActionSheet's iOS 15-16.3 fallback calls
        // `.backport.presentationBackground(.clear)`, which is not yet in
        // shaps80/SwiftUIBackports. Flip back to
        // `.package(url: "https://github.com/shaps80/SwiftUIBackports", from: "<TAG>")`
        // once the presentationBackground backport lands upstream and a new
        // upstream tag is cut.
        .package(url: "https://github.com/laconicman/SwiftUIBackports", from: "26.1.0")
    ],
    targets: [
        .target(name: "SwiftUIPlus", dependencies: ["SwiftUIBackports"])
    ]
)
