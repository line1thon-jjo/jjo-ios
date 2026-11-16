//
//  PromptValue.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum PromptValue: Equatable, Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([PromptValue])
    case object([PromptField])
}

nonisolated struct PromptField: Equatable, Sendable {
    var key: String
    var value: PromptValue

    init(_ key: String, _ value: PromptValue) {
        self.key = key
        self.value = value
    }
}

nonisolated extension PromptValue {
    // 서버가 보내던 json.dumps(ensure_ascii=False) 와 글자 하나까지 같은 문자열
    var jsonString: String {
        switch self {
        case .string(let value): Self.quoted(value)
        case .int(let value): String(value)
        case .double(let value): value.description
        case .bool(let value): value ? "true" : "false"
        case .array(let values): "[" + values.map(\.jsonString).joined(separator: ", ") + "]"
        case .object(let fields):
            "{" + fields.map { Self.quoted($0.key) + ": " + $0.value.jsonString }.joined(separator: ", ") + "}"
        }
    }

    subscript(key: String) -> PromptValue? {
        guard case .object(let fields) = self else { return nil }
        return fields.first { $0.key == key }?.value
    }

    private static func quoted(_ text: String) -> String {
        var out = "\""
        for scalar in text.unicodeScalars {
            switch scalar {
            case "\"": out += "\\\""
            case "\\": out += "\\\\"
            case "\n": out += "\\n"
            case "\r": out += "\\r"
            case "\t": out += "\\t"
            case "\u{08}": out += "\\b"
            case "\u{0C}": out += "\\f"
            case _ where scalar.value < 0x20: out += String(format: "\\u%04x", scalar.value)
            default: out.unicodeScalars.append(scalar)
            }
        }
        return out + "\""
    }
}

nonisolated extension PromptValue: Encodable {
    func encode(to encoder: Encoder) throws {
        switch self {
        case .string(let value):
            var container = encoder.singleValueContainer()
            try container.encode(value)
        case .int(let value):
            var container = encoder.singleValueContainer()
            try container.encode(value)
        case .double(let value):
            var container = encoder.singleValueContainer()
            try container.encode(value)
        case .bool(let value):
            var container = encoder.singleValueContainer()
            try container.encode(value)
        case .array(let values):
            var container = encoder.unkeyedContainer()
            for value in values {
                try container.encode(value)
            }
        case .object(let fields):
            var container = encoder.container(keyedBy: PromptKey.self)
            for field in fields {
                try container.encode(field.value, forKey: PromptKey(stringValue: field.key))
            }
        }
    }
}

private nonisolated struct PromptKey: CodingKey {
    let stringValue: String
    let intValue: Int? = nil

    init(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        nil
    }
}
