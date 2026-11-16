//
//  AudioDecoder.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import AVFAudio
import Foundation

nonisolated enum AudioDecoder {
    static let sampleRate: Double = 16_000

    static func samples(from url: URL) throws -> [Float] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AnalysisError(code: .audioNotFound, message: "녹음 파일을 찾을 수 없습니다: \(url.lastPathComponent)")
        }
        do {
            return try decode(url)
        } catch let error as AnalysisError {
            throw error
        } catch {
            throw AnalysisError(
                code: .audioDecodeFailed,
                message: "오디오를 읽을 수 없습니다: \(error.localizedDescription)"
            )
        }
    }

    private static func decode(_ url: URL) throws -> [Float] {
        let file = try AVAudioFile(forReading: url)
        let source = file.processingFormat
        guard
            let target = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: sampleRate,
                channels: 1,
                interleaved: false
            ),
            let converter = AVAudioConverter(from: source, to: target),
            let input = AVAudioPCMBuffer(pcmFormat: source, frameCapacity: 16_384),
            let output = AVAudioPCMBuffer(pcmFormat: target, frameCapacity: 16_384)
        else {
            throw AnalysisError(code: .audioDecodeFailed, message: "오디오 형식을 변환할 수 없습니다.")
        }

        var samples: [Float] = []
        samples.reserveCapacity(Int(Double(file.length) * sampleRate / source.sampleRate) + 1024)
        var readError: Error?

        while true {
            var conversionError: NSError?
            let status = converter.convert(to: output, error: &conversionError) { _, inputStatus in
                guard file.framePosition < file.length else {
                    inputStatus.pointee = .endOfStream
                    return nil
                }
                do {
                    try file.read(into: input)
                } catch {
                    readError = error
                    inputStatus.pointee = .endOfStream
                    return nil
                }
                guard input.frameLength > 0 else {
                    inputStatus.pointee = .endOfStream
                    return nil
                }
                inputStatus.pointee = .haveData
                return input
            }
            if let failure = conversionError ?? readError.map({ $0 as NSError }), status == .error || readError != nil {
                throw failure
            }
            if let channel = output.floatChannelData?.pointee, output.frameLength > 0 {
                samples.append(contentsOf: UnsafeBufferPointer(start: channel, count: Int(output.frameLength)))
            }
            if status == .endOfStream || status == .error || output.frameLength == 0 { break }
        }

        return samples.map { $0.isFinite ? $0 : 0 }
    }
}
