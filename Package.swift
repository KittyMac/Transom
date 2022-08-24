// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "Transom",
    platforms: [
        .macOS(.v10_13), .iOS(.v11)
    ],
    products: [
        .executable(name: "Transom", targets: ["Transom"]),
        .library(name: "TransomFramework", targets: ["TransomFramework"]),
    ],
    dependencies: [
        .package(url: "https://github.com/KittyMac/Pamphlet.git", from: "0.3.5"),
        .package(url: "https://github.com/KittyMac/Jib.git", from: "0.0.2"),
		.package(url: "https://github.com/KittyMac/Hitch.git", from: "0.4.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "Transom",
            dependencies: [
                "Hitch",
                "TransomFramework",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .plugin(
            name: "TransomPlugin",
            capability: .buildTool(),
            dependencies: [
                "Transom"
            ]
        ),
        .target(
            name: "TransomFramework",
            dependencies: [
                "Hitch",
                "Jib",
                "Pamphlet",
                .product(name: "PamphletFramework", package: "Pamphlet")
            ],
            plugins: [
                .plugin(name: "PamphletPlugin", package: "Pamphlet")
            ]
        ),
        .testTarget(
            name: "TransomFrameworkTests",
            dependencies: [
                "TransomFramework"
            ],
            exclude: [
                "Tests"
            ],
            plugins: [
                .plugin(name: "TransomPlugin")
            ]
        ),
    ]
)
