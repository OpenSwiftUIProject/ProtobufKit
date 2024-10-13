import Benchmark
import SwiftProtobuf
import BenchmarkHelper
import struct BenchmarkHelper.Message

extension Command: SwiftProtobuf.Enum {
    package init(rawValue: Int) {
        switch rawValue {
        case 0: self = .unknown
        case 1: self = .add
        case 2: self = .sub
        case 3: self = .mul
        case 4: self = .div
        default: self = .unknown
        }
    }
    
    package var rawValue: Int {
        switch self {
        case .unknown: return 0
        case .add: return 1
        case .sub: return 2
        case .mul: return 3
        case .div: return 4
        }
    }
    
    package init() { self = .unknown }
}

extension Message: SwiftProtobuf.Message {
    package init() {
        self.init(command: .unknown, id: "", value1: 0, value2: 0)
    }
    
    package static var protoMessageName: String { "Message" }
    
    package var unknownFields: SwiftProtobuf.UnknownStorage {
        get { fatalError() }
        set(newValue) { fatalError() }
    }
    
    package mutating func decodeMessage<D>(decoder: inout D) throws where D : SwiftProtobuf.Decoder {
        while let fieldNumber = try decoder.nextFieldNumber() {
            // The use of inline closures is to circumvent an issue where the compiler
            // allocates stack space for every case branch when no optimizations are
            // enabled. https://github.com/apple/swift-protobuf/issues/1034
            switch fieldNumber {
            case 1: try { try decoder.decodeSingularEnumField(value: &self.command) }()
            case 2: try { try decoder.decodeSingularStringField(value: &self.id) }()
            case 3: try { try decoder.decodeSingularInt64Field(value: &self.value1) }()
            case 4: try { try decoder.decodeSingularInt64Field(value: &self.value2) }()
            default: break
            }
        }
    }
    
    package func traverse<V>(visitor: inout V) throws where V : SwiftProtobuf.Visitor {
        if self.command != .unknown {
            try visitor.visitSingularEnumField(value: self.command, fieldNumber: 1)
        }
        if !self.id.isEmpty {
            try visitor.visitSingularStringField(value: self.id, fieldNumber: 2)
        }
        if self.value1 != 0 {
            try visitor.visitSingularInt64Field(value: self.value1, fieldNumber: 3)
        }
        if self.value2 != 0 {
            try visitor.visitSingularInt64Field(value: self.value2, fieldNumber: 4)
        }
    }
    
    package func isEqualTo(message: any SwiftProtobuf.Message) -> Bool {
        guard let other = message as? Message else {
            return false
        }
        return self.id == other.id
    }
}

let benchmarks = {
    Benchmark(
        "Message.encode",
        configuration: defaultConfiguration
    ) { benchmark in
        // Elide the cost of the 'Message.init'.
        var messages: [Message] = []
        messages.reserveCapacity(benchmark.scaledIterations.count)
        for _ in 0..<benchmark.scaledIterations.count {
            messages.append(.random())
        }

        benchmark.startMeasurement()
        defer {
            benchmark.stopMeasurement()
        }
        for message in messages {
            _ = try message.serializedData()
        }
    }
    
    Benchmark(
        "Message.decode",
        configuration: defaultConfiguration
    ) { benchmark in
        var messages: [Message] = []
        messages.reserveCapacity(benchmark.scaledIterations.count)
        for _ in 0..<benchmark.scaledIterations.count {
            messages.append(.random())
        }
        let datas = try messages.map { try $0.serializedData() }
        
        benchmark.startMeasurement()
        defer {
            benchmark.stopMeasurement()
        }
        for data in datas {
            _ = try Message(serializedBytes: data)
        }
    }
}
