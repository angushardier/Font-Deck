// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "FontDeckApp",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "FontDeckApp", targets: ["FontDeckApp"])
    ],
    targets: [
        .executableTarget(
            name: "FontDeckApp",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "FontDeckAppTests",
            dependencies: ["FontDeckApp"]
        )
    ]
)
