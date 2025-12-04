// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LaunchMe",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "LaunchMe",
            targets: ["LaunchMe"]
        ),
    ],
    dependencies: [
        // Add any external dependencies here
    ],
    targets: [
        .executableTarget(
            name: "LaunchMe",
            dependencies: [],
            path: ".",
            exclude: [
                "README.md",
                "Package.resolved",
                ".git",
                ".DS_Store"
            ],
            sources: [
                "Application",
                "Managers",
                "Models",
                "Services",
                "Utils",
                "ViewModels",
                "Views"
            ]
        ),
        .testTarget(
            name: "LaunchMeTests",
            dependencies: ["LaunchMe"]
        ),
    ]
)