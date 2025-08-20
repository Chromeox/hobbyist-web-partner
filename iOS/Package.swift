// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HobbyistSwiftUI",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "HobbyistSwiftUI",
            targets: ["HobbyistSwiftUI"]
        )
    ],
    dependencies: [
        // Supabase Swift SDK
        .package(
            url: "https://github.com/supabase/supabase-swift.git",
            from: "2.5.1"
        ),
        // Stripe iOS SDK
        .package(
            url: "https://github.com/stripe/stripe-ios.git",
            from: "23.27.0"
        ),
        // Kingfisher for image loading
        .package(
            url: "https://github.com/onevcat/Kingfisher.git",
            from: "7.10.0"
        ),
        // Firebase for Crashlytics
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            from: "10.20.0"
        )
    ],
    targets: [
        .target(
            name: "HobbyistSwiftUI",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "StripePaymentSheet", package: "stripe-ios"),
                .product(name: "Kingfisher", package: "Kingfisher"),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk")
            ],
            path: "HobbyistSwiftUI"
        )
    ]
)