// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "FuzzyFind",
    products: [
        .library(
            name: "FuzzyFind",
            targets: ["FuzzyFind"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "FuzzyFind",
            dependencies: []),
        .testTarget(
            name: "FuzzyFindTests",
            dependencies: ["FuzzyFind"]),
    ]
)
