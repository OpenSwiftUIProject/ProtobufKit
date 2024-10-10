# ProtobufKit

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FOpenSwiftUIProject%2FProtobufKit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/OpenSwiftUIProject/ProtobufKit) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FOpenSwiftUIProject%2FProtobufKit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/OpenSwiftUIProject/ProtobufKit) [![codecov](https://codecov.io/gh/OpenSwiftUIProject/ProtobufKit/graph/badge.svg?token=VDKQVOP20I)](https://codecov.io/gh/OpenSwiftUIProject/ProtobufKit)

ProtobufKit is a lightweight[^1] replacement of [swift-protobuf](https://github.com/apple/swift-protobuf) for working with Protocol Buffers in Swift.

## Overview

ProtobufKit is cross-platform Swift package on Darwin platform (without OS version limitation) and Linux.[^2]

| **Workflow** | **CI Status** |
|-|:-|
| **Compatibility Test** | [![Compatibility tests](https://github.com/OpenSwiftUIProject/ProtobufKit/actions/workflows/compatibility_tests.yml/badge.svg)](https://github.com/OpenSwiftUIProject/ProtobufKit/actions/workflows/compatibility_tests.yml) |
| **macOS Unit Test** | [![macOS](https://github.com/OpenSwiftUIProject/ProtobufKit/actions/workflows/macos.yml/badge.svg)](https://github.com/OpenSwiftUIProject/ProtobufKit/actions/workflows/macos.yml) |
| **iOS Unit Test** | [![iOS](https://github.com/OpenSwiftUIProject/ProtobufKit/actions/workflows/ios.yml/badge.svg)](https://github.com/OpenSwiftUIProject/ProtobufKit/actions/workflows/ios.yml) |
| **Ubuntu 22.04 Unit Test** | [![Ubuntu](https://github.com/OpenSwiftUIProject/ProtobufKit/actions/workflows/ubuntu.yml/badge.svg)](https://github.com/OpenSwiftUIProject/ProtobufKit/actions/workflows/ubuntu.yml) |

ProtobufKit is compatible with SwiftUI's internal Protobuf implementation so that you can use it to decode some internal binary data of SwiftUI (eg. ArchivedView).

The core design of ProtobufKit is `ProtobufMessage` which is similar to `Codable` and easy to customize.

```swift
public protocol ProtobufEncodableMessage {
    func encode(to encoder: inout ProtobufEncoder) throws
}
public protocol ProtobufDecodableMessage {
    init(from decoder: inout ProtobufDecoder) throws
}

public typealias ProtobufMessage = ProtobufDecodableMessage & ProtobufEncodableMessage
```

You can also use it with Codable by conforming your message type to `CodaleByProtobuf` or annoate your message instance with `ProtobufCodable` propertyWrapper.

## Getting Started

In your `Package.swift` file, add the following dependency to your `dependencies` argument:

```swift
.package(url: "https://github.com/OpenSwiftUIProject/ProtobufKit.git", from: "0.1.0"),
```

Then add the dependency to any targets you've declared in your manifest:

```swift
.target(
    name: "MyTarget", 
    dependencies: [
        .product(name: "ProtobufKit", package: "ProtobufKit"),
    ]
),
```

To make a type conform to `ProtobufMessage`, you need to implement the `init(from:)` and `encode(to:)` methods the same as `Codable` usage.

But instead of using `CodingKeys`, we use `ProtobufTag` or `UInt` here to define the field number.

```swift
import ProtobufKit

struct SimpleMessage: ProtobufMessage {
    let value: Bool
    init(from decoder: inout ProtobufDecoder) throws {
        while let field = try decoder.nextField() {
            switch field.tag {
            case 1:
                value = try decoder.boolField(field)
                return
            default: try decoder.skipField(field)
            }
        }
        value = false
    }
    func encode(to encoder: inout ProtobufEncoder) throws {
        encoder.boolField(1, value)
    }
}
```

Please see ProtobufKit [documentation site](https://swiftpackageindex.com/OpenSwiftUIProject/ProtobufKit/main/documentation/protobufkit)
for more detailed information about the library.

## Future work

ProtobufKit does not have compiler build-in support like Codable`'s `Codable` protocol, so you have to write the encode and decode logic by yourself. This can be improved by future macro API support.

## License

See LICENSE file - MIT

## Related Projects

- https://github.com/OpenSwiftUIProject/OpenSwiftUI

## Star History

<a href="https://star-history.com/#OpenSwiftUIProject/ProtobufKit&Date">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=OpenSwiftUIProject/ProtobufKit&type=Date&theme=dark" />
    <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=OpenSwiftUIProject/ProtobufKit&type=Date" />
    <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=OpenSwiftUIProject/ProtobufKit&type=Date" />
  </picture>
</a>

[^1]: Under macOS + Build for profiling option, ProtobufKit's ProtobufKit.o is 142KB while [swift-protobuf](https://github.com/apple/swift-protobuf)'s SwiftProtobuf.o is 5.7MB
[^2]: WASI support will be added in the future
