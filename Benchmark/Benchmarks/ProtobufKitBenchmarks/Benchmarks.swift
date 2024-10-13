import Benchmark
import ProtobufKit
import BenchmarkHelper

extension Command: ProtobufEnum {
    package init(protobufValue: UInt) {
        switch protobufValue {
        case 0: self = .unknown
        case 1: self = .add
        case 2: self = .sub
        case 3: self = .mul
        case 4: self = .div
        default: self = .unknown
        }
    }
    
    package var protobufValue: UInt {
        switch self {
        case .unknown: return 0
        case .add: return 1
        case .sub: return 2
        case .mul: return 3
        case .div: return 4
        }
    }
}

extension Message: ProtobufMessage {
    package func encode(to encoder: inout ProtobufEncoder) throws {
        encoder.enumField(1, command)
        try encoder.stringField(2, id)
        encoder.int64Field(3, value1)
        encoder.int64Field(4, value2)
    }
    
    package init(from decoder: inout ProtobufDecoder) throws {
        var command: Command = .add
        var id: String = ""
        var value1: Int64 = 0
        var value2: Int64 = 0
        while let field = try decoder.nextField() {
            switch field.tag {
            case 1:
                if let cmd: Command = try decoder.enumField(field) {
                    command = cmd
                }
            case 2:
                id = try decoder.stringField(field)
            case 3:
                value1 = try Int64(decoder.intField(field))
            case 4:
                value2 = try Int64(decoder.intField(field))
            default:
                try decoder.skipField(field)
            }
        }
        self.init(command: command, id: id, value1: value1, value2: value2)
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
            _ = try ProtobufEncoder.encoding(message)
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
        let datas = try messages.map { try ProtobufEncoder.encoding($0) }
        
        benchmark.startMeasurement()
        defer {
            benchmark.stopMeasurement()
        }
        for data in datas {
            var decoder = ProtobufDecoder(data)
            _ = try Message(from: &decoder)
        }
    }
}
