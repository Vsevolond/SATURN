// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "saturn",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "saturn-core", targets: ["saturn-core"]),
        .executable(name: "saturn", targets: ["saturn"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/pointfreeco/swift-parsing", from: "0.13.0"),
        .package(url: "https://github.com/SwiftDocOrg/GraphViz", from: "0.4.1")
    ],
    targets: [
        .target(
            name: "saturn-core",
            dependencies: ["GraphViz"]
        ),
        
        .executableTarget(
            name: "saturn",
            dependencies: [
                "saturn-core",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Parsing", package: "swift-parsing")
            ]
        ),
        
        .testTarget(
            name: "saturn-tests",
            dependencies: ["saturn", "saturn-core"]
        ),
    ]
)
