//
//  AlignmentRefinement.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum AlignmentRefinement {
    static func valleyCost(_ db: [Double], width: Int = 6, capDb: Double = 10.0) -> [Double] {
        let count = db.count
        return (0..<count).map { frame in
            let leftMax = db[max(0, frame - width)...frame].max() ?? db[frame]
            let rightMax = db[frame...min(count - 1, frame + width)].max() ?? db[frame]
            let depth = min(max(min(leftMax, rightMax) - db[frame], 0.0), capDb)
            return 1.0 - depth / capDb
        }
    }

    static func splitByEnergy(
        _ boundaryCost: ArraySlice<Double>,
        weights: [Double],
        lambda: Double,
        minLength: Int = 2
    ) -> [Int] {
        let count = weights.count
        let frames = boundaryCost.count
        if count <= 1 { return [0, frames] }
        let totalWeight = PyNumber.sum(weights)
        let expected = weights.map { Double(frames) * $0 / totalWeight }
        let even = (0...count).map {
            PyNumber.round(Double(frames) * PyNumber.sum(Array(weights[..<$0])) / totalWeight)
        }
        if frames < count * minLength { return even }

        let infinity = 1e18
        let width = frames + 1
        var best = [Double](repeating: infinity, count: (count + 1) * width)
        var back = [Int](repeating: 0, count: (count + 1) * width)
        best[0] = 0
        let costBase = boundaryCost.startIndex
        for k in 1...count {
            let ends = k < count ? Array((k * minLength)...(frames - (count - k) * minLength)) : [frames]
            let length = expected[k - 1]
            for end in ends {
                let firstStart = (k - 1) * minLength
                let lastStart = end - minLength
                if lastStart < firstStart { continue }
                var bestCost = Double.infinity
                var bestStart = firstStart
                for start in firstStart...lastStart {
                    let deviation = (Double(end - start) - length) / length
                    let cost = best[(k - 1) * width + start] + lambda * (deviation * deviation)
                    if cost < bestCost {
                        bestCost = cost
                        bestStart = start
                    }
                }
                best[k * width + end] = bestCost + (k < count ? boundaryCost[costBase + end] : 0.0)
                back[k * width + end] = bestStart
            }
        }
        if best[count * width + frames] >= infinity { return even }
        var bounds = [frames]
        var end = frames
        for k in stride(from: count, to: 0, by: -1) {
            end = back[k * width + end]
            bounds.append(end)
        }
        return bounds.reversed()
    }

    static func cutDetachedSound(
        db: [Double],
        from: Int,
        to: Int,
        threshold: Double,
        config: SpeechConfig,
        minKeepFrames: Int = 0
    ) -> (start: Int, end: Int) {
        let voiced = db[from..<to].map { $0 > threshold }
        var runs: [Alignment.Segment] = []
        var start: Int?
        for (index, isVoiced) in voiced.enumerated() {
            if isVoiced && start == nil {
                start = index
            } else if !isVoiced, let begun = start {
                runs.append((begun, index))
                start = nil
            }
        }
        if let start { runs.append((start, voiced.count)) }
        if runs.count < 2 { return (from, to) }

        let gap = config.frame(ms: Double(config.detachGapMs))
        var merged = [runs[0]]
        for run in runs.dropFirst() {
            if run.start - merged[merged.count - 1].end < gap {
                merged[merged.count - 1].end = run.end
            } else {
                merged.append(run)
            }
        }
        if merged.count < 2 { return (from, to) }

        let voicedLengths = merged.map { voiced[$0.start..<$0.end].count(where: { $0 }) }
        var main = 0
        for index in voicedLengths.indices where voicedLengths[index] > voicedLengths[main] { main = index }
        let minLength = config.frame(ms: Double(config.strayMinMs))
        let (low, high) = merged[main]
        let leftExtra = voicedLengths[..<main].reduce(0, +)
        let rightExtra = voicedLengths[(main + 1)...].reduce(0, +)
        // 한 음절도 안 되는 짧은 소리가 쉼을 건너 붙어 있으면 이웃 어절의 시작소리가 섞인 것이라 잘라낸다.
        let syllableFrames = config.frame(ms: Double(config.minSyllableMs))
        let pauseFrames = config.frame(ms: Double(config.pauseMinMs))
        let leftGap = main > 0 ? merged[main].start - merged[main - 1].end : 0
        let rightGap = main + 1 < merged.count ? merged[main + 1].start - merged[main].end : 0
        let (bigLeft, bigRight) = (leftExtra >= minLength, rightExtra >= minLength)
        let cutLeft = bigLeft || (0 < leftExtra && leftExtra < syllableFrames && leftGap >= pauseFrames)
        let cutRight = bigRight || (0 < rightExtra && rightExtra < syllableFrames && rightGap >= pauseFrames)
        let newStart = cutLeft ? from + low : from
        let newEnd = cutRight ? from + high : to
        // 자르고 남는 소리가 글자 수에 비해 너무 짧으면 떨어진 소리도 이 어절의 일부다(문장 끝 "…었어~요").
        if (cutLeft && bigLeft) || (cutRight && bigRight) {
            let keptVoiced = db[newStart..<newEnd].count(where: { $0 > threshold })
            if keptVoiced < minKeepFrames { return (from, to) }
        }
        return (newStart, newEnd)
    }

    static func refineGroups(_ syllables: [TimedSyllable], db: [Double], config: SpeechConfig) {
        guard config.refineByEnergy, !db.isEmpty else { return }
        let threshold = AcousticFeatures.speechThreshold(db)
        let valley = valleyCost(db)
        let extend = config.frame(ms: Double(config.edgeExtendMs))
        let frameCount = db.count
        let hop = config.hopMs

        var groups: [[Int]] = []
        for (index, syllable) in syllables.enumerated() {
            guard syllable.aligned, let group = syllable.group else { continue }
            if let last = groups.last?.last, syllables[last].group == group, index == last + 1 {
                groups[groups.count - 1].append(index)
            } else {
                groups.append([index])
            }
        }

        func frame(_ time: PyNumber) -> Int {
            config.frame(ms: time.value)
        }

        let perChar = groups.filter { $0.count >= 2 }.map {
            Double(frame(syllables[$0[$0.count - 1]].endMs) - frame(syllables[$0[0]].startMs)) / Double($0.count)
        }
        let typicalCharFrames = perChar.isEmpty
            ? Double(config.frame(ms: Double(config.defaultSyllableMs)))
            : NumPy.median(perChar)
        let minSplit = max(2, config.frame(ms: Double(config.minSyllableMs)))

        var previousEnd = 0
        for (groupIndex, group) in groups.enumerated() {
            let first = group[0]
            let last = group[group.count - 1]
            var a = max(0, min(frameCount - 1, frame(syllables[first].startMs)))
            var b = max(a + 1, min(frameCount, frame(syllables[last].endMs)))
            var upper = groupIndex + 1 < groups.count
                ? min(frameCount, frame(syllables[groups[groupIndex + 1][0]].startMs))
                : frameCount
            upper = max(upper, b)

            let localThreshold = max(threshold, (db[a..<b].max() ?? threshold) - config.edgeTrimDb)
            let leftOpen = first == 0 || syllables[first - 1].aligned
            let rightOpen = last == syllables.count - 1 || syllables[last + 1].aligned

            var (trimmedA, trimmedB) = (a, b)
            while trimmedA < trimmedB && db[trimmedA] <= localThreshold { trimmedA += 1 }
            while trimmedB > trimmedA && db[trimmedB - 1] <= localThreshold { trimmedB -= 1 }
            if trimmedA >= trimmedB {
                previousEnd = b
                continue
            }
            (a, b) = cutDetachedSound(
                db: db,
                from: trimmedA,
                to: trimmedB,
                threshold: localThreshold,
                config: config,
                minKeepFrames: Int(config.keepCharRatio * typicalCharFrames * Double(group.count))
            )

            var extended = 0
            while leftOpen && a - 1 >= previousEnd && db[a - 1] > localThreshold && extended < extend {
                a -= 1
                extended += 1
            }
            extended = 0
            while rightOpen && b < upper && db[b] > localThreshold && extended < extend {
                b += 1
                extended += 1
            }
            previousEnd = b

            let bounds: [Int]
            if group.count == 1 {
                bounds = [0, b - a]
            } else {
                let weights = group.map { 1.0 + (syllables[$0].unit.hasBatchim ? config.batchimWeight : 0.0) }
                bounds = splitByEnergy(
                    valley[a..<b],
                    weights: weights,
                    lambda: config.refineLambda,
                    minLength: minSplit
                )
            }
            for (position, index) in group.enumerated() {
                syllables[index].startMs = PyNumber((a + bounds[position]) * hop)
                syllables[index].endMs = PyNumber((a + bounds[position + 1]) * hop)
            }
        }
    }
}
