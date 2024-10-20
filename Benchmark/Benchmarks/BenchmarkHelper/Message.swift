import Foundation

package enum Command: CaseIterable {
    case unknown
    case add
    case sub
    case mul
    case div
}

package struct Message {
    package var command: Command
    package var id: String
    package var value1: Int64
    package var value2: Int64
    
    package init(command: Command, id: String, value1: Int64, value2: Int64) {
        self.command = command
        self.id = id
        self.value1 = value1
        self.value2 = value2
    }
}

extension Message {
    package static func random() -> Self {
        .init(
            command: Command.allCases.randomElement() ?? .unknown,
            id: UUID().uuidString,
            value1: Int64.random(in: 0...100),
            value2: Int64.random(in: 0...100)
        )
    }
}
