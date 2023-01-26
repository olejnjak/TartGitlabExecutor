// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "TartGitlabExecutor",
    platforms: [.macOS(.v13)],
    products: [
        .executable(
            name: "TartGitlabExecutor",
            targets: ["TartGitlabExecutor"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/CombineCommunity/CombineExt",
            .upToNextMajor(from: "1.8.1")
        ),
        .package(
            url: "https://github.com/apple/swift-argument-parser",
            .upToNextMajor(from: "1.2.1")
        ),
        .package(
            url: "https://github.com/apple/swift-tools-support-core",
            .upToNextMajor(from: "0.4.0")
        )
    ],
    targets: [
        .executableTarget(
            name: "TartGitlabExecutor",
            dependencies: [
                .target(name: "ExecutorCore")
            ]
        ),
        .target(
            name: "ExecutorCore",
            dependencies: [
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                ),
                .target(name: "System"),
            ]
        ),
        .target(
            name: "System",
            dependencies: [
                .product(
                    name: "TSCBasic",
                    package: "swift-tools-support-core"
                ),
                .product(
                    name: "CombineExt",
                    package: "CombineExt"
                ),
            ]
        ),
        .testTarget(
            name: "TartGitlabExecutorTests",
            dependencies: ["TartGitlabExecutor"]
        ),
    ]
)
