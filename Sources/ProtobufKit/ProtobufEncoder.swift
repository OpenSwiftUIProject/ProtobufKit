//
//  ProtobufEncoder.swift
//  ProtobufKit

import Foundation

public struct ProtobufEncoder {
    public enum EncodingError: Error {
        case failed
    }
    public typealias Field = ProtobufFormat.Field
    public typealias WireType = ProtobufFormat.WireType
    
    var buffer: UnsafeMutableRawPointer!
    var size: Int = 0
    var capacity: Int = 0
    var stack: [Int] = []
    public var userInfo: [CodingUserInfoKey: Any] = [:]
    
    private func takeData() -> Data {
        if let buffer {
            Data(bytes: buffer, count: size)
        } else {
            Data()
        }
    }
    
    public static func encoding(_ body: (inout ProtobufEncoder) throws -> Void) rethrows -> Data {
        var encoder = ProtobufEncoder()
        try body(&encoder)
        defer { free(encoder.buffer) }
        return encoder.takeData()
    }
    
    public static func encoding<T>(_ value: T) throws -> Data where T: ProtobufEncodableMessage {
        try encoding { encoder in
            try value.encode(to: &encoder)
        }
    }
    
    private mutating func growBufferSlow(to newSize: Int) -> UnsafeMutableRawPointer {
        #if canImport(Darwin)
        let idealSize = malloc_good_size(max(newSize, 0x80))
        #else
        func roundUpToPowerOfTwo(_ value: Int) -> Int {
            guard value > 0 else { return 1 }

            var v = value
            v -= 1
            v |= v >> 1
            v |= v >> 2
            v |= v >> 4
            v |= v >> 8
            v |= v >> 16
            v |= v >> 32 // For 64-bit systems
            v += 1

            return v
        }
        let idealSize = roundUpToPowerOfTwo(max(newSize, 0x80))
        #endif
        guard let newBuffer = realloc(buffer, idealSize) else {
            preconditionFailure("memory allocation failed")
        }
        let oldSize = size
        buffer = newBuffer
        size = newSize
        capacity = idealSize
        return newBuffer + oldSize
    }
    
    private mutating func endLengthDelimited() {
        let lengthPosition = stack.removeLast()
        let length = size - (lengthPosition + 1)
        let highBit = 64 - (length | 1).leadingZeroBitCount
        let count = (highBit + 6) / 7
        let oldSize = size
        let newSize = size - 1 + count
        var pointer: UnsafeMutableRawPointer
        if capacity < newSize {
            pointer = growBufferSlow(to: newSize)
        } else {
            size = newSize
            pointer = buffer.advanced(by: oldSize)
        }
        let firstLengthBytePointer = pointer.advanced(by: -(length + 1))
        if count != 1 {
            memmove(firstLengthBytePointer.advanced(by: count), firstLengthBytePointer.advanced(by: 1), length)
        }
        var currentPointer = firstLengthBytePointer
        var currentValue = length
        while currentValue >= 0x80 {
            currentPointer.storeBytes(of: UInt8(currentValue & 0x7F) | 0x80, as: UInt8.self)
            currentPointer += 1
            currentValue >>= 7
        }
        currentPointer.storeBytes(of: UInt8(currentValue), as: UInt8.self)
    }
}

extension ProtobufEncoder {
    @inline(__always)
    public mutating func boolField(_ tag: UInt, _ value: Bool, defaultValue: Bool? = false) {
        guard value != defaultValue else { return }
        let field = Field(tag, wireType: .varint)
        encodeVarint(field.rawValue)
        encodeVarint(value ? 1 : 0)
    }
    
    @inline(__always)
    public mutating func uintField(_ tag: UInt, _ value: UInt, defaultValue: UInt? = 0) {
        guard value != defaultValue else { return }
        let field = Field(tag, wireType: .varint)
        encodeVarint(field.rawValue)
        encodeVarint(value)
    }

    @inline(__always)
    public mutating func enumField<T>(_ tag: UInt, _ value: T, defaultValue: T?) where T: Equatable, T: ProtobufEnum {
        guard value != defaultValue else { return }
        enumField(tag, value)
    }
    
    @inline(__always)
    public mutating func enumField<T>(_ tag: UInt, _ value: T) where T: ProtobufEnum {
        let field = Field(tag, wireType: .varint)
        encodeVarint(field.rawValue)
        encodeVarint(value.protobufValue)
    }
    
    @inline(__always)
    public mutating func uint64Field(_ tag: UInt, _ value: UInt64, defaultValue: UInt64? = 0) {
        guard value != defaultValue else { return }
        let field = Field(tag, wireType: .varint)
        encodeVarint(field.rawValue)
        encodeVarint64(value)
    }
    
    @inline(__always)
    public mutating func intField(_ tag: UInt, _ value: Int, defaultValue: Int? = 0) {
        guard value != defaultValue else { return }
        let field = Field(tag, wireType: .varint)
        encodeVarint(field.rawValue)
        encodeVarintZZ(value)
    }
    
    @inline(__always)
    public mutating func int64Field(_ tag: UInt, _ value: Int64, defaultValue: Int64? = 0) {
        guard value != defaultValue else { return }
        let field = Field(tag, wireType: .varint)
        encodeVarint(field.rawValue)
        encodeVarint64ZZ(value)
    }
    
    @inline(__always)
    public mutating func fixed32Field(_ tag: UInt, _ value: UInt32, defaultValue: UInt32? = 0) {
        guard value != defaultValue else { return }
        let field = Field(tag, wireType: .fixed32)
        encodeVarint(field.rawValue)
        encodeFixed32(value)
    }
    
    @inline(__always)
    public mutating func fixed64Field(_ tag: UInt, _ value: UInt64, defaultValue: UInt64? = 0) {
        guard value != defaultValue else { return }
        let field = Field(tag, wireType: .fixed64)
        encodeVarint(field.rawValue)
        encodeFixed64(value)
    }
    
    @inline(__always)
    public mutating func floatField(_ tag: UInt, _ value: Float, defaultValue: Float? = 0) {
        guard value != defaultValue else { return }
        let field = Field(tag, wireType: .fixed32)
        encodeVarint(field.rawValue)
        encodeFloat(value)
    }
    
    @inline(__always)
    public mutating func doubleField(_ tag: UInt, _ value: Double, defaultValue: Double? = 0) {
        guard value != defaultValue else { return }
        let field = Field(tag, wireType: .fixed64)
        encodeVarint(field.rawValue)
        encodeBitwiseCopyable(value)
    }
    
    @inline(__always)
    public mutating func cgFloatField(_ tag: UInt, _ value: CGFloat, defaultValue: CGFloat? = 0) {
        guard value != defaultValue else { return }
        let field = Field(tag, wireType: value < 65536.0 ? .fixed32 : .fixed64)
        encodeVarint(field.rawValue)
        if value < 65536.0 {
            encodeFloat(Float(value))
        } else {
            encodeDouble(Double(value))
        }
    }
    
    public mutating func dataField(_ tag: UInt, _ value: Data) {
        value.withUnsafeBytes { buffer in
            dataField(tag, buffer)
        }
    }
    
    public mutating func dataField(_ tag: UInt, _ value: UnsafeRawBufferPointer) {
        guard !value.isEmpty else {
            return
        }
        let field = Field(tag, wireType: .lengthDelimited)
        encodeVarint(field.rawValue)
        encodeData(value)
    }
    
    @inline(__always)
    public mutating func packedField(_ tag: UInt, _ body: (inout ProtobufEncoder) -> Void) {
        let field = Field(tag, wireType: .lengthDelimited)
        encodeVarint(field.rawValue)
        stack.append(size)
        size += 1
        body(&self)
        endLengthDelimited()
    }
    
    @inline(__always)
    public mutating func messageField(_ tag: UInt, _ body: (inout ProtobufEncoder) throws -> Void) rethrows {
        let field = Field(tag, wireType: .lengthDelimited)
        encodeVarint(field.rawValue)
        stack.append(size)
        size += 1
        try body(&self)
        endLengthDelimited()
    }
    
    @inline(__always)
    public mutating func messageField<T>(_ tag: UInt, _ value: T, defaultValue: T) throws where T: Equatable, T: ProtobufEncodableMessage {
        guard value != defaultValue else { return }
        try messageField(tag, value)
    }
    
    public mutating func messageField<T>(_ tag: UInt, _ value: T) throws where T: ProtobufEncodableMessage {
        let field = Field(tag, wireType: .lengthDelimited)
        encodeVarint(field.rawValue)
        try encodeMessage(value)
    }
    
    private mutating func stringFieldAlways(_ tag: UInt, _ value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw EncodingError.failed
        }
        dataField(tag, data)
    }
    
    @inline(__always)
    public mutating func stringField(_ tag: UInt, _ value: String, defaultValue: String? = "") throws {
        guard value != defaultValue else { return }
        try stringFieldAlways(tag, value)
    }
    
    func binaryPlistData<T>(for value: T) throws -> Data where T: Encodable {
        #if os(WASI)
        fatalError("PropertyListEncoder is not avaiable on WASI")
        #else
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        encoder.userInfo = userInfo
        return try encoder.encode([value])
        #endif
    }
    
    @inline(__always)
    public mutating func codableField<T>(_ tag: UInt, _ value: T, defaultValue: T) throws where T: Encodable, T: Equatable {
        guard value != defaultValue else { return }
        try codableField(tag, value)
    }
    
    public mutating func codableField<T>(_ tag: UInt, _ value: T) throws where T: Encodable {
        let field = Field(tag, wireType: .lengthDelimited)
        encodeVarint(field.rawValue)
        let data = try binaryPlistData(for: value)
        data.withUnsafeBytes { buffer in
            encodeData(buffer)
        }
    }
    
    public mutating func emptyField(_ tag: UInt) {
        let field = Field(tag, wireType: .lengthDelimited)
        encodeVarint(field.rawValue)
        stack.append(size)
        size += 1
        endLengthDelimited()
    }
}


extension ProtobufEncoder {
    @inline(__always)
    public mutating func boolField<T>(_ tag: T, _ value: Bool, defaultValue: Bool? = false) where T: ProtobufTag {
        boolField(tag.rawValue, value, defaultValue: defaultValue)
    }
    
    @inline(__always)
    public mutating func uintField<T>(_ tag: T, _ value: UInt, defaultValue: UInt? = 0) where T: ProtobufTag {
        uintField(tag.rawValue, value, defaultValue: defaultValue)
    }
    
    @inline(__always)
    public mutating func enumField<T, U>(_ tag: T, _ value: U, defaultValue: U?) where T: ProtobufTag, U: Equatable, U: ProtobufEnum {
        enumField(tag.rawValue, value, defaultValue: defaultValue)
    }
    
    @inline(__always)
    public mutating func enumField<T, U>(_ tag: T, _ value: U) where T: ProtobufTag, U: ProtobufEnum {
        enumField(tag.rawValue, value)
    }
    
    @inline(__always)
    public mutating func uint64Field<T>(_ tag: T, _ value: UInt64, defaultValue: UInt64? = 0) where T: ProtobufTag {
        uint64Field(tag.rawValue, value, defaultValue: defaultValue)
    }
    
    @inline(__always)
    public mutating func intField<T>(_ tag: T, _ value: Int, defaultValue: Int? = 0) where T: ProtobufTag {
        intField(tag.rawValue, value, defaultValue: defaultValue)
    }
    
    @inline(__always)
    public mutating func int64Field<T>(_ tag: T, _ value: Int64, defaultValue: Int64? = 0) where T: ProtobufTag {
        int64Field(tag.rawValue, value, defaultValue: defaultValue)
    }
    
    @inline(__always)
    public mutating func fixed32Field<T>(_ tag: T, _ value: UInt32, defaultValue: UInt32? = 0) where T: ProtobufTag {
        fixed32Field(tag.rawValue, value, defaultValue: defaultValue)
    }
    
    @inline(__always)
    public mutating func fixed64Field<T>(_ tag: T, _ value: UInt64, defaultValue: UInt64? = 0) where T: ProtobufTag {
        fixed64Field(tag.rawValue, value, defaultValue: defaultValue)
    }
    
    @inline(__always)
    public mutating func floatField<T>(_ tag: T, _ value: Float, defaultValue: Float? = 0) where T: ProtobufTag {
        floatField(tag.rawValue, value, defaultValue: defaultValue)
    }
    
    @inline(__always)
    public mutating func doubleField<T>(_ tag: T, _ value: Double, defaultValue: Double? = 0) where T: ProtobufTag {
        doubleField(tag.rawValue, value, defaultValue: defaultValue)
    }
    
    @inline(__always)
    public mutating func cgFloatField<T>(_ tag: T, _ value: CGFloat, defaultValue: CGFloat? = 0) where T: ProtobufTag {
        cgFloatField(tag.rawValue, value, defaultValue: defaultValue)
    }
    
    @inline(__always)
    public mutating func dataField<T>(_ tag: T, _ value: Data) where T: ProtobufTag {
        dataField(tag.rawValue, value)
    }
    
    @inline(__always)
    public mutating func dataField<T>(_ tag: T, _ value: UnsafeRawBufferPointer) where T: ProtobufTag {
        dataField(tag.rawValue, value)
    }
    
    @inline(__always)
    public mutating func packedField<T>(_ tag: T, _ body: (inout ProtobufEncoder) -> Void) where T: ProtobufTag {
        packedField(tag.rawValue, body)
    }
    
    @inline(__always)
    public mutating func messageField<T>(_ tag: T, _ body: (inout ProtobufEncoder) throws -> Void) rethrows where T: ProtobufTag {
        try messageField(tag.rawValue, body)
    }
    
    @inline(__always)
    public mutating func messageField<T, U>(_ tag: T, _ value: U, defaultValue: U) throws where T: ProtobufTag, U: Equatable, U: ProtobufEncodableMessage {
        try messageField(tag.rawValue, value, defaultValue: defaultValue)
    }
    
    @inline(__always)
    public mutating func messageField<T>(_ tag: T, _ value: ProtobufEncodableMessage) throws where T: ProtobufTag {
        try messageField(tag.rawValue, value)
    }
    
    @inline(__always)
    public mutating func stringField<T>(_ tag: T, _ value: String, defaultValue: String? = "") throws where T: ProtobufTag {
        try stringField(tag.rawValue, value, defaultValue: defaultValue)
    }
    
    @inline(__always)
    public mutating func codableField<T>(_ tag: T, _ value: T, defaultValue: T) throws where T: ProtobufTag, T: Encodable, T: Equatable {
        try codableField(tag.rawValue, value, defaultValue: defaultValue)
    }
    
    @inline(__always)
    public mutating func codableField<T>(_ tag: T, _ value: T) throws where T: ProtobufTag, T: Encodable {
        try codableField(tag.rawValue, value)
    }
}

extension ProtobufEncoder {
    public mutating func encodeVarint(_ value: UInt) {
        let highBit = 64 - (value | 1).leadingZeroBitCount
        let count = (highBit + 6) / 7
        let oldSize = size
        let newSize = size + count
        var pointer: UnsafeMutableRawPointer

        if capacity < newSize {
            pointer = growBufferSlow(to: newSize)
        } else {
            size = newSize
            pointer = buffer.advanced(by: oldSize)
        }

        var currentValue = value
        while currentValue >= 0x80 {
            pointer.storeBytes(of: UInt8(currentValue & 0x7F) | 0x80, as: UInt8.self)
            pointer += 1
            currentValue >>= 7
        }
        pointer.storeBytes(of: UInt8(currentValue), as: UInt8.self)
    }
    
    public mutating func encodeVarint64(_ value: UInt64) {
        encodeVarint(UInt(value))
    }
    
    // (n << 1) ^ (n >> 63)
    // See https://protobuf.dev/programming-guides/encoding/#signed-ints
    public mutating func encodeVarintZZ(_ value: Int) {
        encodeVarint(UInt(bitPattern: (value << 1) ^ (value >> 63)))
    }
    
    public mutating func encodeVarint64ZZ(_ value: Int64) {
        encodeVarintZZ(Int(value))
    }
    
    #if compiler(>=6.0)
    @inline(__always)
    private mutating func encodeBitwiseCopyable<T>(_ value: T) where T: BitwiseCopyable {
        let oldSize = size
        let newSize = oldSize + MemoryLayout<T>.size
        if capacity < newSize {
            growBufferSlow(to: newSize).storeBytes(of: value, as: T.self)
        } else {
            size = newSize
            buffer.advanced(by: oldSize).storeBytes(of: value, as: T.self)
        }
    }
    #else // FIXME: Remove this after we drop WASI 5.10 support
    @inline(__always)
    private mutating func encodeBitwiseCopyable<T>(_ value: T) {
        let oldSize = size
        let newSize = oldSize + MemoryLayout<T>.size
        if capacity < newSize {
            growBufferSlow(to: newSize).storeBytes(of: value, as: T.self)
        } else {
            size = newSize
            buffer.advanced(by: oldSize).storeBytes(of: value, as: T.self)
        }
    }
    #endif
    
    public mutating func encodeBool(_ value: Bool) {
        encodeBitwiseCopyable(value)
    }
    
    public mutating func encodeFixed32(_ value: UInt32) {
        encodeBitwiseCopyable(value)
    }
    
    public mutating func encodeFixed64(_ value: UInt64) {
        encodeBitwiseCopyable(value)
    }
    
    public mutating func encodeFloat(_ value: Float) {
        encodeBitwiseCopyable(value)
    }
    
    private mutating func encodeDouble(_ value: Double) {
        encodeBitwiseCopyable(value)
    }
    
    private mutating func encodeData(_ dataBuffer: UnsafeRawBufferPointer) {
        // Encode LEN
        let dataBufferCount = dataBuffer.count
        encodeVarint(UInt(bitPattern: dataBufferCount))
        guard let baseAddress = dataBuffer.baseAddress,
              !dataBuffer.isEmpty else {
            return
        }
        let oldSize = size
        let newSize = size + dataBufferCount
        
        let pointer: UnsafeMutableRawPointer
        if capacity < newSize {
            pointer = growBufferSlow(to: newSize)
        } else {
            size = newSize
            pointer = buffer.advanced(by: oldSize)
        }
        memcpy(pointer, baseAddress, dataBufferCount)
    }
    
    private mutating func encodeMessage<T>(_ value: T) throws where T: ProtobufEncodableMessage {
        stack.append(size)
        size += 1
        try value.encode(to: &self)
        endLengthDelimited()
    }
}
