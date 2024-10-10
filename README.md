# ProtobufKit

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FOpenSwiftUIProject%2FProtobufKit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/OpenSwiftUIProject/ProtobufKit) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FOpenSwiftUIProject%2FProtobufKit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/OpenSwiftUIProject/ProtobufKit)

ProtobufKit is a lightweight Swift library for working with Protocol Buffers.

It is cross-platform and compatible with SwiftUI's internal Protobuf implementation.

## Getting Started Using ProtobufMessage

In your `Package.swift` Swift Package Manager manifest, add the following dependency to your `dependencies` argument:

```swift
.package(url: "https://github.com/OpenSwiftUIProject/ProtobufKit.git", from: "0.1.0"),
```

Add the dependency to any targets you've declared in your manifest:

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

## Supported platforms

The table below describes the current level of support that `ProtobufKit` has
for various platforms:

| **Workflow** | **CI Status** |
|-|:-|
| **Compatibility Test** | [![Compatibility tests](https://github.com/OpenSwiftUIProject/ProtobufKit/actions/workflows/compatibility_tests.yml/badge.svg)](https://github.com/OpenSwiftUIProject/ProtobufKit/actions/workflows/compatibility_tests.yml) |
| **macOS Unit Test** | [![macOS](https://github.com/OpenSwiftUIProject/ProtobufKit/actions/workflows/macos.yml/badge.svg)](https://github.com/OpenSwiftUIProject/ProtobufKit/actions/workflows/macos.yml) |
| **iOS Unit Test** | [![iOS](https://github.com/OpenSwiftUIProject/ProtobufKit/actions/workflows/ios.yml/badge.svg)](https://github.com/OpenSwiftUIProject/ProtobufKit/actions/workflows/ios.yml) |
| **Ubuntu 22.04 Unit Test** | [![Ubuntu](https://github.com/OpenSwiftUIProject/ProtobufKit/actions/workflows/ubuntu.yml/badge.svg)](https://github.com/OpenSwiftUIProject/ProtobufKit/actions/workflows/ubuntu.yml) |

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
