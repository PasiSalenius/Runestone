// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Runestone",
    defaultLocalization: "en",
    platforms: [.iOS(.v14), .macOS(.v11)],
    products: [
        .library(name: "Runestone", targets: ["Runestone"])
    ],
    dependencies: [
        .package(url: "https://github.com/tree-sitter/tree-sitter.git", .upToNextMinor(from: "0.20.9")),
    ],
    targets: [
        .target(name: "Runestone",
                dependencies: [.product(name: "TreeSitter", package: "tree-sitter")],
                resources: [.process("TextView/Appearance/Theme.xcassets")]),
        .target(name: "TestTreeSitterLanguages", cSettings: [.unsafeFlags(["-w"])]),
        .testTarget(name: "RunestoneTests", dependencies: ["Runestone", "TestTreeSitterLanguages"])
    ]
)
