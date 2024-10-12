// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

func envEnable(_ key: String, default defaultValue: Bool = false) -> Bool {
    guard let value = Context.environment[key] else {
        return defaultValue
    }
    if value == "1" {
        return true
    } else if value == "0" {
        return false
    } else {
        return defaultValue
    }
}

let testTarget = Target.testTarget(name: "ProtobufKitTests")

let compatibilityTestCondition = envEnable("PROTOBUFKIT_SWIFTUI_COMPATIBILITY_TEST")
if compatibilityTestCondition {
    var swiftSettings: [SwiftSetting] = (testTarget.swiftSettings ?? [])
    swiftSettings.append(.define("PROTOBUFKIT_SWIFTUI_COMPATIBILITY_TEST"))
    testTarget.swiftSettings = swiftSettings
} else {
    testTarget.dependencies.append("ProtobufKit")
}

let libraryType: Product.Library.LibraryType?
switch Context.environment["PROTOBUFKIT_LIBRARY_TYPE"] {
case "dynamic":
    libraryType = .dynamic
case "static":
    libraryType = .static
default:
    libraryType = nil
}

let package = Package(
    name: "ProtobufKit",
    products: [
        .library(name: "ProtobufKit", type: libraryType, targets: ["ProtobufKit"]),
    ],
    targets: [
        .target(name: "ProtobufKit"),
        testTarget,    
    ]
)
