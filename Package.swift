// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RaycastLike",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "RaycastCore", targets: ["RaycastCore"]),
        .executable(name: "RaycastLikeApp", targets: ["RaycastLikeApp"])
    ],
    targets: [
        .target(
            name: "RaycastCore",
            dependencies: []
        ),
        .executableTarget(
            name: "RaycastLikeApp",
            dependencies: ["RaycastCore"]
        ),
        .testTarget(
            name: "RaycastCoreTests",
            dependencies: ["RaycastCore"]
        )
    ]
)
