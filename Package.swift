// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WindowsMac",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "WindowsMac", targets: ["WindowsMac"])
    ],
    targets: [
        .executableTarget(
            name: "WindowsMac"
        ),
        .testTarget(
            name: "WindowsMacTests",
            dependencies: ["WindowsMac"]
        )
    ]
)
