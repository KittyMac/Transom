// swift-tools-version: 5.6

import PackageDescription

// When runnning "make release" to build the binary tools change this to true
// Otherwise always set it to false
#if false
let productsTarget: [PackageDescription.Product] = [
    
]
let pluginTarget: [PackageDescription.Target] = [
    .executableTarget(
        name: "TransomTool-focal",
        dependencies: [
            "Hitch",
            "TransomFramework",
            .product(name: "ArgumentParser", package: "swift-argument-parser")
        ]
    ),
    .plugin(
        name: "TransomPlugin",
        capability: .buildTool(),
        dependencies: ["TransomTool-focal"]
    ),
]
#else
let productsTarget: [PackageDescription.Product] = [
    .library(name: "TransomTool", targets: [
        "TransomTool-focal",
        "TransomTool-amazonlinux2",
        "TransomTool-fedora",
        "TransomTool-fedora38",
    ]),
]
let pluginTarget: [PackageDescription.Target] = [
    .binaryTarget(name: "TransomTool-focal",
                  path: "dist/TransomTool-focal.zip"),
    .binaryTarget(name: "TransomTool-amazonlinux2",
                  path: "dist/TransomTool-amazonlinux2.zip"),
    .binaryTarget(name: "TransomTool-fedora",
                  path: "dist/TransomTool-fedora.zip"),
    .binaryTarget(name: "TransomTool-fedora38",
                  path: "dist/TransomTool-fedora38.zip"),
    .plugin(
        name: "TransomPlugin",
        capability: .buildTool(),
        dependencies: [
            "TransomTool-focal",
            "TransomTool-amazonlinux2",
            "TransomTool-fedora",
            "TransomTool-fedora38",
        ]
    ),
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
