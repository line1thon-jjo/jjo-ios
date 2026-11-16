//
//  ScalarText.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

// 글자 번호(idx)는 서버(Python)와 같이 유니코드 코드 포인트 기준이라 Character 가 아닌 scalar 로 다룬다
nonisolated struct ScalarText: Sendable {
    let scalars: [Unicode.Scalar]

    init(_ string: String) {
        scalars = Array(string.unicodeScalars)
    }

    var count: Int {
        scalars.count
    }

    subscript(index: Int) -> Unicode.Scalar {
        scalars[index]
    }

    func checked(_ index: Int) throws -> Unicode.Scalar {
        let resolved = index < 0 ? index + count : index
        guard scalars.indices.contains(resolved) else { throw ScalarTextError.indexOutOfRange }
        return scalars[resolved]
    }

    func string(from start: Int, to end: Int) -> String {
        String(scalars: scalars[bounds(start, end)])
    }

    func firstIndex(of scalar: Unicode.Scalar, from start: Int, to end: Int) -> Int? {
        scalars[bounds(start, end)].firstIndex(of: scalar)
    }

    func lastIndex(of scalar: Unicode.Scalar, from start: Int, to end: Int) -> Int? {
        scalars[bounds(start, end)].lastIndex(of: scalar)
    }

    private func bounds(_ start: Int, _ end: Int) -> Range<Int> {
        let lower = clamped(start)
        return lower..<max(lower, clamped(end))
    }

    private func clamped(_ index: Int) -> Int {
        min(max(index < 0 ? index + count : index, 0), count)
    }
}

nonisolated enum ScalarTextError: Error {
    case indexOutOfRange
}
