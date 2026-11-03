// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GasCoKit",
    defaultLocalization: "pl",
    platforms: [.iOS(.v18), .watchOS(.v11), .macOS(.v15)],
    products: [
        .library(name: "GasCoKit", targets: ["GasCoKit"])
    ],
    targets: [
        .target(name: "GasCoKit", resources: [.process("Resources")]),
        .testTarget(name: "GasCoKitTests", dependencies: ["GasCoKit"])
    ]
)
