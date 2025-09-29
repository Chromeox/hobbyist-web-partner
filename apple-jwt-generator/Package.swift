// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "AppleJWTGenerator",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/jwt-kit.git", from: "4.0.0")
    ],
    targets: [
        .executableTarget(
            name: "AppleJWTGenerator",
            dependencies: [
                .product(name: "JWTKit", package: "jwt-kit")
            ]
        )
    ]
)