// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Condulet",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(name: "ConduletCore", targets: ["ConduletCore"]),
        .library(name: "ConduletReachability", targets: ["ConduletReachability"]),
        .library(name: "ConduletProto", targets: ["ConduletProto"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.6.0"),
    ],
    targets: [
        .target(name: "ConduletCore", dependencies: [], path: "Condulet/Core"),
        .target(name: "ConduletReachability", dependencies: ["ConduletCore"], path: "Condulet/Reachability"),
        .target(name: "ConduletProto", dependencies: ["ConduletCore", "SwiftProtobuf"], path: "Condulet/Protobuf"),
    ],
    swiftLanguageVersions: [.v5]
)
