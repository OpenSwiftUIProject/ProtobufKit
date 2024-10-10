//
//  ProtobufMessage.swift
//  ProtobufKit

import Foundation

// MARK: - ProtobufMessage

public protocol ProtobufEncodableMessage {
    func encode(to encoder: inout ProtobufEncoder) throws
}
public protocol ProtobufDecodableMessage {
    init(from decoder: inout ProtobufDecoder) throws
}

public typealias ProtobufMessage = ProtobufDecodableMessage & ProtobufEncodableMessage

// MARK: - ProtobufEnum

public protocol ProtobufEnum {
    var protobufValue: UInt { get }
    init?(protobufValue: UInt)
}

extension ProtobufEnum where Self: RawRepresentable, RawValue: BinaryInteger {
    public var protobufValue: UInt {
        UInt(rawValue)
    }
    
    public init?(protobufValue: UInt) {
        self.init(rawValue: RawValue(protobufValue))
    }
}

// MARK: - ProtobufTag

public protocol ProtobufTag: Equatable {
    var rawValue: UInt { get }
    init(rawValue: UInt)
}

// MARK: - ProtobufFormat

public enum ProtobufFormat {
    public struct WireType: Equatable {
        public let rawValue: UInt
        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }
        
        public static var varint: ProtobufFormat.WireType { WireType(rawValue: 0) }
        public static var fixed64: ProtobufFormat.WireType { WireType(rawValue: 1) }
        public static var lengthDelimited: ProtobufFormat.WireType { WireType(rawValue: 2) }
        public static var fixed32: ProtobufFormat.WireType { WireType(rawValue: 5) }
    }
    
    public struct Field: Equatable {
        public var rawValue: UInt
        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }
        
        // field = (field_number << 3) | wire_type
        // See https://protobuf.dev/programming-guides/encoding/
        public init(_ tag: UInt, wireType: WireType) {
            rawValue = (tag << 3) | wireType.rawValue
        }
        
        public var tag: UInt {
            rawValue >> 3
        }
        
        public var wireType: WireType {
            WireType(rawValue: rawValue & 7)
        }
        
        @inline(__always)
        public func tag<T>(as: T.Type = T.self) -> T where T: ProtobufTag {
            T(rawValue: tag)
        }
    }
}

// MARK: - CoddleByProtobuf

public protocol CodaleByProtobuf: Codable, ProtobufMessage {}

extension CodaleByProtobuf {
    func encode(to encoder: any Encoder) throws {
        let data = try ProtobufEncoder.encoding { protobufEncoder in
            protobufEncoder.userInfo = encoder.userInfo
            try encode(to: &protobufEncoder)
        }
        var container = encoder.singleValueContainer()
        try container.encode(data)
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        var protobufDecoder = ProtobufDecoder(data)
        protobufDecoder.userInfo = decoder.userInfo
        self = try Self(from: &protobufDecoder)
    }
}

// MARK: - ProtobufCodable

@propertyWrapper
public struct ProtobufCodable<Value>: Codable where Value: ProtobufMessage {
    public var wrappedValue: Value
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    public func encode(to encoder: any Encoder) throws {
        let data = try ProtobufEncoder.encoding { protobufEncoder in
            protobufEncoder.userInfo = encoder.userInfo
            try wrappedValue.encode(to: &protobufEncoder)
        }
        var container = encoder.singleValueContainer()
        try container.encode(data)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        var protobufDecoder = ProtobufDecoder(data)
        protobufDecoder.userInfo = decoder.userInfo
        wrappedValue = try Value(from: &protobufDecoder)
    }
}

extension ProtobufCodable: Equatable where Value: Equatable {
    public static func == (lhs: ProtobufCodable<Value>, rhs: ProtobufCodable<Value>) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}
