//
//  Unicode.Scalar+Python.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated extension Unicode.Scalar {
    var isHangulSyllable: Bool { value >= 0xAC00 && value <= 0xD7A3 }

    var hasBatchim: Bool { isHangulSyllable && (value - 0xAC00) % 28 != 0 }

    var isPythonSpace: Bool {
        switch value {
        case 0x09...0x0D, 0x1C...0x20, 0x85, 0xA0, 0x1680, 0x2000...0x200A, 0x2028, 0x2029, 0x202F, 0x205F, 0x3000:
            true
        default:
            false
        }
    }

    var isPythonLineBreak: Bool {
        switch value {
        case 0x0A...0x0D, 0x1C...0x1E, 0x85, 0x2028, 0x2029: true
        default: false
        }
    }

    var isPythonWord: Bool {
        if self == "_" || properties.numericType != nil { return true }
        return switch properties.generalCategory {
        case .uppercaseLetter, .lowercaseLetter, .titlecaseLetter, .modifierLetter, .otherLetter: true
        default: false
        }
    }

    var isTrailingPunctuation: Bool {
        switch properties.generalCategory {
        case .closePunctuation, .finalPunctuation, .otherPunctuation: true
        default: false
        }
    }

    var isPythonDecimal: Bool { properties.generalCategory == .decimalNumber }

    var isPythonDigit: Bool {
        switch properties.numericType {
        case .decimal?, .digit?: true
        default: false
        }
    }

    var isPythonAlnum: Bool {
        switch properties.generalCategory {
        case .uppercaseLetter, .lowercaseLetter, .titlecaseLetter, .modifierLetter, .otherLetter, .decimalNumber:
            true
        default:
            properties.numericType != nil
        }
    }

    var isPunctuationSymbolOrControl: Bool {
        switch properties.generalCategory {
        case .connectorPunctuation, .dashPunctuation, .openPunctuation, .closePunctuation, .initialPunctuation,
             .finalPunctuation, .otherPunctuation, .mathSymbol, .currencySymbol, .modifierSymbol, .otherSymbol,
             .spaceSeparator, .lineSeparator, .paragraphSeparator, .control, .format, .surrogate, .privateUse,
             .unassigned:
            true
        default:
            false
        }
    }
}

nonisolated extension Sequence where Element == Unicode.Scalar {
    var text: String {
        var view = String.UnicodeScalarView()
        view.append(contentsOf: self)
        return String(view)
    }
}

nonisolated extension Array where Element == Unicode.Scalar {
    func hasSuffix(_ suffix: String) -> Bool {
        let other = Array(suffix.unicodeScalars)
        return count >= other.count && self[(count - other.count)...].elementsEqual(other)
    }
}
