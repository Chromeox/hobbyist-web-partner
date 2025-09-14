// swift-tools-version: 5.9
// HobbyistSwiftUI iOS App Dependencies
// This Package.swift file defines dependencies for the iOS app.
// The Xcode project will integrate these dependencies through Swift Package Manager.

import PackageDescription

let package = Package(
    name: "HobbyistSwiftUIDependencies",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        // Products define the executables and libraries a package produces
        .library(
            name: "HobbyistSwiftUIDependencies",
            targets: ["HobbyistSwiftUIDependencies"]
        )
    ],
    dependencies: [
        // Supabase Swift SDK - Latest stable version with TestFlight compatibility
        .package(
            url: "https://github.com/supabase/supabase-swift.git",
            exact: "2.31.2"
        ),
        // Stripe iOS SDK - Latest stable version with security patches
        .package(
            url: "https://github.com/stripe/stripe-ios.git",
            exact: "24.15.0"
        ),
        // Kingfisher for efficient image loading and caching
        .package(
            url: "https://github.com/onevcat/Kingfisher.git",
            exact: "8.5.0"
        ),
        // Sentry for crash reporting and performance monitoring
        .package(
            url: "https://github.com/getsentry/sentry-cocoa.git",
            exact: "8.36.0"
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package
        .target(
            name: "HobbyistSwiftUIDependencies",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "Auth", package: "supabase-swift"),
                .product(name: "StripePaymentSheet", package: "stripe-ios"),
                .product(name: "StripePayments", package: "stripe-ios"),
                .product(name: "Kingfisher", package: "Kingfisher"),
                .product(name: "Sentry", package: "sentry-cocoa")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "HobbyistSwiftUIDependenciesTests",
            dependencies: ["HobbyistSwiftUIDependencies"],
            path: "Tests"
        )
    ]
)