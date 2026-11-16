//
//  String+Python.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated extension String {
    init(scalars: some Sequence<Unicode.Scalar>) {
        var view = String.UnicodeScalarView()
        view.append(contentsOf: scalars)
        self.init(view)
    }

    var scalarCount: Int {
        unicodeScalars.count
    }

    func scalarPrefix(_ maxLength: Int) -> String {
        String(scalars: unicodeScalars.prefix(maxLength))
    }

    func pythonStripped(where shouldStrip: (Unicode.Scalar) -> Bool = \.isPythonSpace) -> String {
        let scalars = Array(unicodeScalars)
        guard let first = scalars.firstIndex(where: { !shouldStrip($0) }),
              let last = scalars.lastIndex(where: { !shouldStrip($0) })
        else { return "" }
        return String(scalars: scalars[first...last])
    }

    func pythonTrailingStripped() -> String {
        let scalars = Array(unicodeScalars)
        guard let last = scalars.lastIndex(where: { !$0.isPythonSpace }) else { return "" }
        return String(scalars: scalars[...last])
    }

    func pythonSplit() -> [String] {
        unicodeScalars.split(whereSeparator: \.isPythonSpace).map { String(scalars: $0) }
    }

    func pythonSplitLines() -> [String] {
        var lines: [String] = []
        var current: [Unicode.Scalar] = []
        var previous: Unicode.Scalar?
        for scalar in unicodeScalars {
            defer { previous = scalar }
            if scalar == "\n", previous == "\r" { continue }
            if scalar.isPythonLineBreak {
                lines.append(String(scalars: current))
                current = []
            } else {
                current.append(scalar)
            }
        }
        if !current.isEmpty {
            lines.append(String(scalars: current))
        }
        return lines
    }

    func containsScalars(of other: String) -> Bool {
        let haystack = Array(unicodeScalars)
        let needle = Array(other.unicodeScalars)
        guard !needle.isEmpty else { return true }
        guard haystack.count >= needle.count else { return false }
        return (0...(haystack.count - needle.count)).contains { start in
            haystack[start..<(start + needle.count)].elementsEqual(needle)
        }
    }

    func hasSameScalars(as other: String) -> Bool {
        unicodeScalars.elementsEqual(other.unicodeScalars)
    }
}
