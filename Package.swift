// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JSONKit",
    products: [
        .library(
            name: "JSONKit",
            targets: ["JSONKit"]
        ),
    ],
    targets: [
        .target(
            name: "JSONKit"
        ),
        .testTarget(
            name: "JSONKitTests",
            dependencies: ["JSONKit"]
        ),
    ]
)
