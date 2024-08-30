// swift-tools-version: 5.6
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
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.1.0"),
        .package(url: "https://github.com/ProcedureKit/ProcedureKit.git", from: "5.2.0")
    ],
    targets: [
        .target(
            name: "FirebaseIdentity",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "ProcedureKit", package: "ProcedureKit")
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
