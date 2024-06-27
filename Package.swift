// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "Transom",
    platforms: [
        .macOS(.v10_13), .iOS(.v11)
    ],
    products: [
        .plugin(name: "TransomPlugin", targets: ["TransomPlugin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/KittyMac/Pamphlet.git", from: "0.3.5"),
        .package(url: "https://github.com/KittyMac/Jib.git", from: "0.0.2"),
		.package(url: "https://github.com/KittyMac/Hitch.git", from: "0.4.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "TransomTool",
            dependencies: [
                "Hitch",
                "TransomFramework",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .plugin(
            name: "TransomPlugin",
            capability: .buildTool(),
            dependencies: ["TransomTool"]
        ),
        .target(
            name: "TransomFramework",
            dependencies: [
                "Hitch",
                "Jib"
            ],
            plugins: [
                .plugin(name: "PamphletReleaseOnlyPlugin", package: "Pamphlet")
            ]
        ),
        .testTarget(
            name: "TransomFrameworkTests",
            dependencies: [
                "TransomFramework"
            ],
            plugins: [
                .plugin(name: "TransomPlugin")
            ]
        )
    ]
)
