// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Brewery",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "Brewery", targets: ["Brewery"]),
        .library(name: "BreweryCore", targets: ["BreweryCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.4")
    ],
    targets: [
        .target(
            name: "BreweryCore"
        ),
        .executableTarget(
            name: "Brewery",
            dependencies: [
                "BreweryCore",
                .product(name: "Sparkle", package: "Sparkle")
            ],
            exclude: [
                "Brewery.entitlements"
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "BreweryCoreTests",
            dependencies: ["BreweryCore"],
            resources: [
                .process("Fixtures")
            ]
        )
    ]
)
