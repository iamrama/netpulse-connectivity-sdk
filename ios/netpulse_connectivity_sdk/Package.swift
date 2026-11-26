// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "netpulse_connectivity_sdk",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "netpulse-connectivity-sdk", targets: ["netpulse_connectivity_sdk"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "netpulse_connectivity_sdk",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
