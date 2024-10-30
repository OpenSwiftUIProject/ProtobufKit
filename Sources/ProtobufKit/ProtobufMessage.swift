//
//  ProtobufMessage.swift
//  ProtobufKit

import Foundation

// MARK: - ProtobufMessage

/// A type that can encode itself to a protobuf representation.
public protocol ProtobufEncodableMessage {
    /// Encodes this value into the given encoder.
    ///
    /// If the value fails to encode anything, `encoder` will encode an empty
    /// keyed container in its place.
    ///
    /// This function throws an error if any values are invalid for the given
    /// encoder's format.
    ///
    /// - Parameter encoder: The encoder to write data to.
    func encode(to encoder: inout ProtobufEncoder) throws
}

/// A  type that can decode itself from a protobuf representation.
public protocol ProtobufDecodableMessage {
    /// Creates a new instance by decoding from the given decoder.
    ///
    /// This initializer throws an error if reading from the decoder fails, or
    /// if the data read is corrupted or otherwise invalid.
    ///
    /// - Parameter decoder: The decoder to read data from.
    init(from decoder: inout ProtobufDecoder) throws
}


/// A type that can convert itself into and out of a protobuf representation.
///
/// `ProtobufMessage` is a type alias for the `ProtobufEncodableMessage` and `ProtobufDecodableMessage` protocols.
/// When you use `ProtobufMessage` as a type or a generic constraint, it matches
/// any type that conforms to both protocols.
public typealias ProtobufMessage = ProtobufDecodableMessage & ProtobufEncodableMessage

// MARK: - ProtobufEnum

/// A type that can be represented as a protobuf enum.
public protocol ProtobufEnum {
    /// The value of the enum as a protobuf enum.
    var protobufValue: UInt { get }

    /// Creates an instance from a protobuf enum value.
    init?(protobufValue: UInt)
}

extension ProtobufEnum where Self: RawRepresentable, RawValue: BinaryInteger {
    /// The value of the enum as a protobuf enum.
    public var protobufValue: UInt {
        UInt(rawValue)
    }
    
    /// Creates an instance from a protobuf enum value.
    public init?(protobufValue: UInt) {
        self.init(rawValue: RawValue(protobufValue))
    }
}

// MARK: - ProtobufTag

/// A protocol representing a tag in protobuf encoding.
///
/// Conforms to `Equatable` to allow comparison of tags.
public protocol ProtobufTag: Equatable {
    /// The raw value of the tag.
    var rawValue: UInt { get }

    /// Creates an instance from a raw value.
    init(rawValue: UInt)
}

// MARK: - ProtobufFormat

/// A type representing the format of a protobuf encoding.
public enum ProtobufFormat {
    /// A type representing the wire type of a protobuf encoding.
    public struct WireType: Equatable {
        /// The raw value of the wire type.
        public let rawValue: UInt
        
        /// Creates an instance from a raw value.
        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }
        
        /// A wire type representing a varint.
        public static var varint: ProtobufFormat.WireType { WireType(rawValue: 0) }
        
        /// A wire type representing a fixed 64-bit value.
        public static var fixed64: ProtobufFormat.WireType { WireType(rawValue: 1) }
        
        /// A wire type representing a length-delimited value.
        public static var lengthDelimited: ProtobufFormat.WireType { WireType(rawValue: 2) }
        
        /// A wire type representing a fixed 32-bit value.
        public static var fixed32: ProtobufFormat.WireType { WireType(rawValue: 5) }
    }

    /// A type representing a field in a protobuf encoding.
    public struct Field: Equatable {
        /// The raw value of the field.
        public var rawValue: UInt

        /// Creates an instance from a raw value.
        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }
        
        // field = (field_number << 3) | wire_type
        // See https://protobuf.dev/programming-guides/encoding/

        /// Creates an instance from a tag and wire type.
        public init(_ tag: UInt, wireType: WireType) {
            rawValue = (tag << 3) | wireType.rawValue
        }
        
        /// The tag of the field.
        public var tag: UInt {
            rawValue >> 3
        }
        
        /// The wire type of the field.
        public var wireType: WireType {
            WireType(rawValue: rawValue & 7)
        }
        
        /// Converts the tag to a specific type.
        @inline(__always)
        public func tag<T>(as: T.Type = T.self) -> T where T: ProtobufTag {
            T(rawValue: tag)
        }
    }
}

// MARK: - CoddleByProtobuf

/// A type that can be encoded and decoded using protobuf.
public protocol CodaleByProtobuf: Codable, ProtobufMessage {}

extension CodaleByProtobuf {
    /// Encodes the value to a protobuf representation.
    public func encode(to encoder: any Encoder) throws {
        let data = try ProtobufEncoder.encoding { protobufEncoder in
            protobufEncoder.userInfo = encoder.userInfo
            try encode(to: &protobufEncoder)
        }
        var container = encoder.singleValueContainer()
        try container.encode(data)
    }
    
    /// Creates an instance from a decoder.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        var protobufDecoder = ProtobufDecoder(data)
        protobufDecoder.userInfo = decoder.userInfo
        self = try Self(from: &protobufDecoder)
    }
}

// MARK: - ProtobufCodable

/// A property wrapper that encodes and decodes a value using protobuf.
@propertyWrapper
public struct ProtobufCodable<Value>: Codable where Value: ProtobufMessage {
    /// The wrapped value.
    public var wrappedValue: Value
    
    /// Creates an instance with a wrapped value.
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    /// Encodes the wrapped value to a protobuf representation.
    public func encode(to encoder: any Encoder) throws {
        let data = try ProtobufEncoder.encoding { protobufEncoder in
            protobufEncoder.userInfo = encoder.userInfo
            try wrappedValue.encode(to: &protobufEncoder)
        }
        var container = encoder.singleValueContainer()
        try container.encode(data)
    }

    /// Creates an instance from a decoder.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        var protobufDecoder = ProtobufDecoder(data)
        protobufDecoder.userInfo = decoder.userInfo
        wrappedValue = try Value(from: &protobufDecoder)
    }
}

extension ProtobufCodable: Equatable where Value: Equatable {
    /// Compares two instances of `ProtobufCodable`.
    public static func == (lhs: ProtobufCodable<Value>, rhs: ProtobufCodable<Value>) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}
