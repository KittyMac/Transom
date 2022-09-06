// swift-tools-version: 5.6

import PackageDescription

// When runnning "make release" to build the binary tools change this to true
// Otherwise always set it to false
#if false
let productsTarget: [PackageDescription.Product] = [
    .executable(name: "TransomTool", targets: ["TransomTool"]),
]
let pluginTarget: [PackageDescription.Target] = [
    .executableTarget(
        name: "TransomTool",
        dependencies: [
            "Hitch",
            "TransomFramework",
            .product(name: "ArgumentParser", package: "swift-argument-parser")
        ]
    )
]
#else
let productsTarget: [PackageDescription.Product] = [
    .library(name: "TransomTool", targets: ["TransomTool"]),
]
let pluginTarget: [PackageDescription.Target] = [
    .binaryTarget(name: "TransomTool",
                  path: "dist/TransomTool.zip"),
]
#endif

let package = Package(
    name: "Transom",
    platforms: [
        .macOS(.v10_13), .iOS(.v11)
    ],
    products: productsTarget + [
        .plugin(name: "TransomPlugin", targets: ["TransomPlugin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/KittyMac/Pamphlet.git", from: "0.3.5"),
        .package(url: "https://github.com/KittyMac/Jib.git", from: "0.0.2"),
		.package(url: "https://github.com/KittyMac/Hitch.git", from: "0.4.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    ],
    targets: pluginTarget + [
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
