// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "saturn",
    products: [
        .library(name: "saturn-lib", targets: ["saturn-lib"]),
        .executable(name: "saturn", targets: ["saturn"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")
    ],
    targets: [
        .target(name: "saturn-lib"),
        
        .executableTarget(
            name: "saturn",
            dependencies: [
                "saturn-lib",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        
        .testTarget(name: "saturn-tests", dependencies: ["saturn-lib"]),
    ]
)
