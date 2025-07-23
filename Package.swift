// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "ocrs",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.92.0"),
        .package(url: "https://github.com/vapor/multipart-kit.git", from: "4.5.0")
    ],
    targets: [
        .executableTarget(
            name: "ocrs",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "MultipartKit", package: "multipart-kit")
            ]
        )
    ]
)
