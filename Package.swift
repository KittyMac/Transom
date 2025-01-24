// swift-tools-version: 5.6

import PackageDescription

// When runnning "make release" to build the binary tools change this to true
// Otherwise always set it to false
// NOTE: currently does not build with Xcode 15
#if false
let productsTarget: [PackageDescription.Product] = [
    
]
let pluginTarget: [PackageDescription.Target] = [
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
]
#else

var plugins = [
    "TransomTool-focal-571",
    "TransomTool-focal-592",
    "TransomTool-fedora38-573",
]

#if os(Windows)
plugins += [
    "TransomTool-windows-592",
]
#endif

var productsTarget: [PackageDescription.Product] = [
    .library(name: "TransomTool", targets: plugins),
]
var pluginTarget: [PackageDescription.Target] = [
    .binaryTarget(name: "TransomTool-focal-571",
                  path: "dist/TransomTool-focal-571.zip"),
    .binaryTarget(name: "TransomTool-focal-592",
                  path: "dist/TransomTool-focal-592.zip"),
    .binaryTarget(name: "TransomTool-fedora38-573",
                  path: "dist/TransomTool-fedora38-573.zip"),
    .plugin(
        name: "TransomPlugin",
        capability: .buildTool(),
        dependencies: plugins.map({ Target.Dependency(stringLiteral: $0) })
    ),
]

#if os(Windows)
pluginTarget += [
    .binaryTarget(name: "TransomTool-windows-592",
                  path: "dist/TransomTool-windows-592.zip"),
]
#endif

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
            ]
            // NOTE: for some reason swift 5.9.2 refuses to run the build tool, so
            // we geenrate it manually using make pamphlet
            //plugins: [
            //    .plugin(name: "PamphletPlugin", package: "Pamphlet")
            //]
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
