// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WalletCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "WalletCore", targets: ["WalletCore"])],
    targets: [
        .target(name: "WalletCore"),
        .testTarget(name: "WalletCoreTests", dependencies: ["WalletCore"]),
    ]
)
