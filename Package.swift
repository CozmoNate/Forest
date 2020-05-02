// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Forest",
    platforms: [
        .iOS(.v10),
        .macOS(.v10_13)
    ],
    products: [
        .library(name: "ForestCore", targets: ["ForestCore"]),
        .library(name: "ForestReachability", targets: ["ForestReachability"]),
        .library(name: "ForestProto", targets: ["ForestProto"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.8.0"),
    ],
    targets: [
        .target(name: "ForestCore", dependencies: [], path: "Forest/Core"),
        .target(name: "ForestReachability", dependencies: ["ForestCore"], path: "Forest/Reachability"),
        .target(name: "ForestProto", dependencies: ["ForestCore", "SwiftProtobuf"], path: "Forest/Protobuf"),
    ],
    swiftLanguageVersions: [.v5]
)
