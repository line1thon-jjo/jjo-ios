//
//  UtteranceNarration.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum UtteranceNarration {
    nonisolated struct Passage: Equatable, Sendable, Identifiable {
        var id: Int
        var segment: Int
        var text: String
        var notes: [String]

        var label: String {
            notes.isEmpty ? text : "\(text) \(notes.joined(separator: ", "))"
        }
    }

    static func passages(_ glyphs: [Glyph]) -> [Passage] {
        var groups: [[Glyph]] = []
        for glyph in glyphs {
            if let last = groups.last?.last, last.segment == glyph.segment {
                groups[groups.count - 1].append(glyph)
            } else {
                groups.append([glyph])
            }
        }

        return groups.enumerated().compactMap { offset, group in
            let text = String(scalars: group.map(\.scalar)).pythonSplit().joined(separator: " ")
            guard !text.isEmpty, let first = group.first else { return nil }
            return Passage(id: offset, segment: first.segment, text: text, notes: notes(for: group))
        }
    }

    private static func notes(for glyphs: [Glyph]) -> [String] {
        var notes: [String] = []
        if glyphs.contains(where: { $0.pace == .fast }) { notes.append("빠름") }
        if glyphs.contains(where: { $0.pace == .slow }) { notes.append("느림") }

        for glyph in glyphs {
            var parts: [String] = []
            if let pitch = ReportCopy.pitch(glyph.pitch) { parts.append(pitch) }
            if glyph.stretch > 1 { parts.append(ReportCopy.stretch(glyph.stretch)) }
            if !parts.isEmpty {
                notes.append("‘\(glyph.char)’ \(parts.joined(separator: ", "))")
            }
            if glyph.pauseMs > 0, glyph.scalar != " " {
                notes.append("‘\(glyph.char)’ 뒤 쉼 \(ReportCopy.pause(glyph.pauseMs))")
            }
        }
        return notes
    }
}
