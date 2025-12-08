// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AirNotePersistence",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "AirNotePersistence",
            targets: ["AirNotePersistence"]),
    ],
    dependencies: [],
    targets: [
        // 主 Target，包含所有共享代码
        .target(
            name: "AirNotePersistence",
            dependencies: [],
            path: "Sources"
        ),
        // 测试 Target
        .testTarget(
            name: "AirNotePersistenceTests",
            dependencies: ["AirNotePersistence"]),
    ]
)
