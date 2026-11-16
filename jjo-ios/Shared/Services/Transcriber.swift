//
//  Transcriber.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import AVFAudio
import CoreMedia
import Foundation
import Speech

nonisolated enum Transcriber {
    static let locale = Locale(identifier: "ko-KR")

    static func isSupported() async -> Bool {
        await SpeechTranscriber.supportedLocales.contains { $0.identifier(.bcp47) == locale.identifier(.bcp47) }
    }

    @concurrent
    static func prepare(onProgress: @Sendable @escaping (Double) -> Void = { _ in }) async throws {
        guard await isSupported() else {
            throw AnalysisError(code: .engineUnavailable, message: "이 기기에서는 한국어 음성 인식을 쓸 수 없습니다.")
        }
        do {
            guard let request = try await AssetInventory.assetInstallationRequest(supporting: [makeTranscriber()])
            else { return }
            let progress = request.progress
            let reporter = Task {
                while !Task.isCancelled {
                    onProgress(progress.fractionCompleted)
                    try? await Task.sleep(for: .milliseconds(300))
                }
            }
            defer { reporter.cancel() }
            try await request.downloadAndInstall()
        } catch {
            throw AnalysisError(
                code: .engineUnavailable,
                message: "음성 인식 모델을 준비하지 못했습니다: \(error.localizedDescription)"
            )
        }
    }

    @concurrent
    static func words(from url: URL) async throws -> [WordTiming] {
        let transcriber = makeTranscriber()
        do {
            let analyzer = SpeechAnalyzer(modules: [transcriber])
            let file = try AVAudioFile(forReading: url)
            let collector = Task { try await collect(from: transcriber) }

            if let last = try await analyzer.analyzeSequence(from: file) {
                try await analyzer.finalizeAndFinish(through: last)
            } else {
                await analyzer.cancelAndFinishNow()
            }
            return try await collector.value
        } catch let error as AnalysisError {
            throw error
        } catch {
            throw AnalysisError(
                code: .engineUnavailable,
                message: "음성 인식을 실행할 수 없습니다: \(error.localizedDescription)"
            )
        }
    }

    private static func makeTranscriber() -> SpeechTranscriber {
        SpeechTranscriber(
            locale: locale,
            transcriptionOptions: [],
            reportingOptions: [],
            attributeOptions: [.audioTimeRange, .transcriptionConfidence]
        )
    }

    private static func collect(from transcriber: SpeechTranscriber) async throws -> [WordTiming] {
        var words: [WordTiming] = []
        for try await result in transcriber.results where result.isFinal {
            for run in result.text.runs {
                guard let range = run.audioTimeRange else { continue }
                let text = cleaned(String(result.text[run.range].characters))
                guard !text.isEmpty else { continue }
                words.append(
                    WordTiming(
                        text: text,
                        start: range.start.seconds,
                        end: range.end.seconds,
                        prob: run.transcriptionConfidence ?? 1.0
                    )
                )
            }
        }
        return words
    }

    // 인식기가 숫자 뒤에 마침표를 끼워 넣는 경우("300.명")가 있어 숫자 읽기 변환이 깨지지 않게 지운다
    static func cleaned(_ raw: String) -> String {
        let characters = Array(raw.trimmingCharacters(in: .whitespacesAndNewlines))
        return String(
            characters.enumerated().compactMap { index, character -> Character? in
                guard character == ".", index > 0, index + 1 < characters.count else { return character }
                let isStray = characters[index - 1].isNumber && isHangul(characters[index + 1])
                return isStray ? nil : character
            }
        )
    }

    private static func isHangul(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy { (0xAC00...0xD7A3).contains($0.value) }
    }
}
