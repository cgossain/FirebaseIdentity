// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "firebase-identity",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "FirebaseIdentity",
            targets: ["FirebaseIdentity"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            from: "9.0.0"
        ),
        .package(
            url: "https://github.com/ProcedureKit/ProcedureKit.git",
            from: "5.0.0"
        ),
    ],
    targets: [
        .target(
            name: "FirebaseIdentity",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "ProcedureKit", package: "ProcedureKit"),
            ]
        ),
        .testTarget(
            name: "FirebaseIdentityTests",
            dependencies: [
                "FirebaseIdentity"
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
