// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ServiceKit",
    products: [
        .library(
            name: "ServiceKit",
            targets: ["ServiceKit"]),
	.executable(
	    name: "Demo",
	    targets: ["Demo"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-log", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "ServiceKit",
            dependencies: ["NIO", "NIOHTTP1", "Logging"]),
        .testTarget(
            name: "ServiceKitTests",
            dependencies: ["ServiceKit"]),
        .target(
            name: "Demo",
            dependencies: ["ServiceKit"]),
    ]
)
