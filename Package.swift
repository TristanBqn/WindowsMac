// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WindowsMac",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "WindowsMacCore", targets: ["WindowsMacCore"]),
        .executable(name: "WindowsMac", targets: ["WindowsMac"])
    ],
    targets: [
        .target(
            name: "WindowsMacCore"
        ),
        .executableTarget(
            name: "WindowsMac",
            dependencies: ["WindowsMacCore"]
        ),
        .testTarget(
            name: "WindowsMacTests",
            dependencies: ["WindowsMacCore"],
            path: "Tests/WindowsMacTests"
        )
    ]
)
