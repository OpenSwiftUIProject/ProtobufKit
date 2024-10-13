// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "benchmarks",
    platforms: [
        .macOS(.v13),
    ],
    dependencies: [
        .package(path: "../"),
        .package(url: "https://github.com/ordo-one/package-benchmark.git", from: "1.27.2"),
        .package(url: "https://github.com/apple/swift-protobuf.git", exact: "1.28.2"),

    ],
    targets: [
        .target(
            name: "BenchmarkHelper",
            dependencies: [
                .product(name: "Benchmark", package: "package-benchmark"),
            ],
            path: "Benchmarks/BenchmarkHelper"
        ),
        .executableTarget(
            name: "ProtobufKitBenchmarks",
            dependencies: [
                "BenchmarkHelper",
                .product(name: "Benchmark", package: "package-benchmark"),
                .product(name: "ProtobufKit", package: "ProtobufKit"),
            ],
            path: "Benchmarks/ProtobufKitBenchmarks",
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
            ]
        ),
        .executableTarget(
            name: "SwiftProtobufBenchmarks",
            dependencies: [
                "BenchmarkHelper",
                .product(name: "Benchmark", package: "package-benchmark"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
            ],
            path: "Benchmarks/SwiftProtobufBenchmarks",
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
            ]
        ),
    ]
)
