//
//  ProtobufDecoder.swift
//  ProtobufKit

import Foundation

public struct ProtobufDecoder {
    public enum DecodingError: Error {
        case failed
    }
    
    public typealias Field = ProtobufFormat.Field
    public typealias WireType = ProtobufFormat.WireType
    
    var data: NSData
    var ptr: UnsafeRawPointer
    var end: UnsafeRawPointer
    var packedField: Field = Field(rawValue: 0)
    var packedEnd: UnsafeRawPointer
    var stack: [UnsafeRawPointer] = []
    public var userInfo: [CodingUserInfoKey : Any] = [:]
    
    public init(_ data: Data) {
        let nsData = data as NSData
        self.data = nsData
        let ptr = nsData.bytes
        self.ptr = ptr
        self.end = ptr + nsData.length
        self.packedEnd = ptr
    }
}

extension ProtobufDecoder {
    public mutating func nextField() throws -> ProtobufDecoder.Field? {
        guard ptr < end else {
            packedField = Field(rawValue: 0)
            return nil
        }
        if packedField.rawValue != 0 {
            if ptr < packedEnd {
                return packedField
            } else if packedEnd < ptr {
                throw DecodingError.failed
            }
        }
        let result = try decodeVariant()
        let field = Field(rawValue: result)
        guard field.tag > 0 else {
            throw DecodingError.failed
        }
        return field
    }
    
    public mutating func skipField(_ field: ProtobufDecoder.Field) throws {
        switch field.wireType {
        case .varint:
            _ = try decodeVariant()
        case .fixed64:
            let newPtr = ptr.advanced(by: 8)
            guard newPtr <= end else {
                return
            }
            ptr = newPtr
        case .lengthDelimited:
            _ = try decodeDataBuffer()
        case .fixed32:
            let newPtr = ptr.advanced(by: 4)
            guard newPtr <= end else {
                return
            }
            ptr = newPtr
        default:
            throw DecodingError.failed
        }
    }
    
    public mutating func boolField(_ field: ProtobufDecoder.Field) throws -> Bool {
        switch field.wireType {
        case .varint:
            break
        case .lengthDelimited:
            let offset = try decodeVariant()
            let offsetPtr = ptr.advanced(by: Int(offset))
            guard offsetPtr <= end else {
                throw DecodingError.failed
            }
            packedField = Field(field.tag, wireType: .varint)
            packedEnd = offsetPtr
        default:
            throw DecodingError.failed
        }
        return try decodeVariant() != 0
    }
    
    public mutating func uintField(_ field: ProtobufDecoder.Field) throws -> UInt {
        switch field.wireType {
        case .varint:
            break
        case .lengthDelimited:
            let offset = try decodeVariant()
            let offsetPtr = ptr.advanced(by: Int(offset))
            guard offsetPtr <= end else {
                throw DecodingError.failed
            }
            packedField = Field(field.tag, wireType: .varint)
            packedEnd = offsetPtr
        default:
            throw DecodingError.failed
        }
        return try decodeVariant()
    }
    
    public mutating func enumField<T>(_ field: ProtobufDecoder.Field) throws -> T? where T: ProtobufEnum {
        try T(protobufValue: uintField(field))
    }
    
    public mutating func uint8Field(_ field: ProtobufDecoder.Field) throws -> UInt8 {
        try UInt8(uintField(field))
    }
    
    public mutating func uint16Field(_ field: ProtobufDecoder.Field) throws -> UInt16 {
        try UInt16(uintField(field))
    }
    
    public mutating func uint32Field(_ field: ProtobufDecoder.Field) throws -> UInt32 {
        try UInt32(uintField(field))
    }
    
    public mutating func uint64Field(_ field: ProtobufDecoder.Field) throws -> UInt64 {
        try UInt64(uintField(field))
    }
    
    public mutating func intField(_ field: ProtobufDecoder.Field) throws -> Int {
        let value = Int(bitPattern: try uintField(field))
        return Int(bitPattern: UInt(bitPattern: (value >> 1)) ^ UInt(bitPattern: -(value & 1)))
    }
    
    public mutating func fixed32Field(_ field: ProtobufDecoder.Field) throws -> UInt32 {
        switch field.wireType {
        case .lengthDelimited:
            let offset = try decodeVariant()
            let offsetPtr = ptr.advanced(by: Int(offset))
            guard offsetPtr <= end else {
                throw DecodingError.failed
            }
            packedField = Field(field.tag, wireType: .fixed32)
            packedEnd = offsetPtr
        case .fixed32:
            break
        default:
            throw DecodingError.failed
        }
        let newPtr = ptr.advanced(by: 4)
        guard newPtr <= end else {
            throw DecodingError.failed
        }
        let value = ptr.loadUnaligned(as: UInt32.self)
        ptr = newPtr
        return value
    }
    
    public mutating func fixed64Field(_ field: ProtobufDecoder.Field) throws -> UInt64 {
        switch field.wireType {
        case .lengthDelimited:
            let offset = try decodeVariant()
            let offsetPtr = ptr.advanced(by: Int(offset))
            guard offsetPtr <= end else {
                throw DecodingError.failed
            }
            packedField = Field(field.tag, wireType: .fixed64)
            packedEnd = offsetPtr
        case .fixed64:
            break
        default:
            throw DecodingError.failed
        }
        let newPtr = ptr.advanced(by: 8)
        guard newPtr <= end else {
            throw DecodingError.failed
        }
        let value = ptr.loadUnaligned(as: UInt64.self)
        ptr = newPtr
        return value
    }
    
    public mutating func floatField(_ field: ProtobufDecoder.Field) throws -> Float {
        switch field.wireType {
        case .lengthDelimited:
            let offset = try decodeVariant()
            let offsetPtr = ptr.advanced(by: Int(offset))
            guard offsetPtr <= end else {
                throw DecodingError.failed
            }
            packedField = Field(field.tag, wireType: .fixed32)
            packedEnd = offsetPtr
        case .fixed32:
            break
        default:
            throw DecodingError.failed
        }
        let newPtr = ptr.advanced(by: 4)
        guard newPtr <= end else {
            throw DecodingError.failed
        }
        let value = ptr.loadUnaligned(as: UInt32.self)
        ptr = newPtr
        return Float(bitPattern: value)
    }
    
    public mutating func doubleField(_ field: ProtobufDecoder.Field) throws -> Double {
        switch field.wireType {
        case .fixed64:
            break
        case .lengthDelimited:
            let offset = try decodeVariant()
            let offsetPtr = ptr.advanced(by: Int(offset))
            guard offsetPtr <= end else {
                throw DecodingError.failed
            }
            packedField = Field(field.tag, wireType: .fixed64)
            packedEnd = offsetPtr
        case .fixed32:
            let newPtr = ptr.advanced(by: 4)
            guard newPtr <= end else {
                throw DecodingError.failed
            }
            let value = ptr.loadUnaligned(as: UInt32.self)
            ptr = newPtr
            return Double(Float(bitPattern: value))
        default:
            throw DecodingError.failed
        }
        let newPtr = ptr.advanced(by: 8)
        guard newPtr <= end else {
            throw DecodingError.failed
        }
        let value = ptr.loadUnaligned(as: UInt64.self)
        ptr = newPtr
        return Double(bitPattern: value)
    }
    
    @inline(__always)
    public mutating func cgFloatField(_ field: ProtobufDecoder.Field) throws -> CGFloat {
        try doubleField(field)
    }
    
    public mutating func dataBufferField(_ field: ProtobufDecoder.Field) throws -> UnsafeRawBufferPointer {
        switch field.wireType {
        case .lengthDelimited:
            try decodeDataBuffer()
        default:
            throw DecodingError.failed
        }
    }
    
    public mutating func dataField(_ field: ProtobufDecoder.Field) throws -> Data {
        switch field.wireType {
        case .lengthDelimited:
            let buffer = try decodeDataBuffer()
            guard let baseAddress = buffer.baseAddress else {
                return Data()
            }
            let startIndex = baseAddress - data.bytes
            let endIndex = startIndex + buffer.count
            return (data as Data)[startIndex..<endIndex]
        default:
            throw DecodingError.failed
        }
    }
    
    public mutating func messageField<T>(_ field: ProtobufDecoder.Field) throws -> T where T: ProtobufDecodableMessage {
        guard field.wireType == .lengthDelimited else {
            throw DecodingError.failed
        }
        return try decodeMessage()
    }
    
    public mutating func messageField<T>(_ field: ProtobufDecoder.Field, _ body: (inout ProtobufDecoder) throws -> T) throws -> T {
        guard field.wireType == .lengthDelimited else {
            throw DecodingError.failed
        }
        return try decodeMessage(body)
    }
    
    public mutating func stringField(_ field: ProtobufDecoder.Field) throws -> String {
        let data = try dataField(field)
        guard let result = String(data: data, encoding: .utf8) else {
            throw DecodingError.failed
        }
        return result
    }
    
    public mutating func codableField<T>(_ field: ProtobufDecoder.Field) throws -> T where T: Decodable {
        let data = try dataField(field)
        return try value(fromBinaryPlist: data)
    }
}

extension ProtobufDecoder {
    private mutating func decodeVariant() throws -> UInt {
        var value: UInt = 0
        var shift: UInt = 0
        var shouldContinue = false
        repeat {
            guard ptr < end else {
                throw DecodingError.failed
            }
            let byte = ptr.loadUnaligned(as: UInt8.self)
            ptr += 1
            value |= UInt(byte & 0x7f) << shift
            shift += 7
            shouldContinue = (byte & 0x80 != 0)
        } while shouldContinue
        return value
    }
    
    private mutating func decodeDataBuffer() throws -> UnsafeRawBufferPointer {
        let count = try Int(decodeVariant())
        let oldPtr = ptr
        let newPtr = ptr.advanced(by: count)
        guard newPtr <= end else {
            throw DecodingError.failed
        }
        ptr = newPtr
        return UnsafeRawBufferPointer(start: oldPtr, count: count)
    }
    
    private mutating func beginMessage() throws {
        stack.append(end)
        let count = try Int(decodeVariant())
        let newPtr = ptr.advanced(by: count)
        guard newPtr <= end else {
            throw DecodingError.failed
        }
        end = newPtr
    }
    
    private mutating func decodeMessage<T>(_ body: (inout ProtobufDecoder) throws -> T) throws -> T {
        try beginMessage()
        defer { end = stack.removeLast() }
        return try body(&self)
    }
    
    private mutating func decodeMessage<T>() throws -> T where T: ProtobufDecodableMessage {
        try beginMessage()
        defer { end = stack.removeLast() }
        return try T(from: &self)
    }
    
    func value<T>(fromBinaryPlist data: Data, type: T.Type = T.self) throws -> T where T: Decodable {
        #if os(WASI)
        fatalError("PropertyListDecoder is not avaiable on WASI")
        #else
        let decoder = PropertyListDecoder()
        decoder.userInfo = userInfo
        let resuls = try decoder.decode([T].self, from: data)
        guard let result = resuls.first else {
            throw DecodingError.failed
        }
        return result
        #endif
    }
}
