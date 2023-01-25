// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "TartGitlabExecutor",
    products: [
        .library(
            name: "TartGitlabExecutor",
            targets: ["TartGitlabExecutor"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser",
            .upToNextMajor(from: "1.2.1")
        ),
    ],
    targets: [
        .target(
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
            ]
        ),
        .testTarget(
            name: "TartGitlabExecutorTests",
            dependencies: ["TartGitlabExecutor"]
        ),
    ]
)
