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
    targets: [
        .target(
            name: "BreweryCore"
        ),
        .executableTarget(
            name: "Brewery",
            dependencies: ["BreweryCore"],
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
