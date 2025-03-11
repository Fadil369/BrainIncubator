// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BrainIncubator",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "BrainIncubator",
            type: .dynamic,
            targets: ["BrainIncubator"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.21.0")
    ],
    targets: [
        .target(
            name: "BrainIncubator",
            dependencies: [
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk")
            ],
            path: "Sources",
            exclude: ["App/Info.plist"],
            resources: [
                .process("Core/BrainIncubator.xcdatamodeld"),
                .process("App/ar.lproj"),
                .copy("App/PrivacyInfo.xcprivacy")
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .define("RELEASE", .when(configuration: .release)),
                .unsafeFlags(["-framework", "UIKit"])
            ]
        ),
        .testTarget(
            name: "BrainIncubatorTests",
            dependencies: ["BrainIncubator"],
            path: "Tests/BrainIncubatorTests"
        )
    ]
)