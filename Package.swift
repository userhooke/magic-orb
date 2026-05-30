// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "magic-orb",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "magic-orb", targets: ["MagicOrb"])
    ],
    targets: [
        .executableTarget(
            name: "MagicOrb",
             dependencies: ["MagicOrbCore"]
        ),
        .target(name: "MagicOrbCore"),
    ]
)
