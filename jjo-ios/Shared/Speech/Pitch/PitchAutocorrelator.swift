//
//  PitchAutocorrelator.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Accelerate
import Foundation

nonisolated final class PitchAutocorrelator {
    let length: Int
    private let halfLength: Int
    private let logLength: vDSP_Length
    private let setup: FFTSetupD
    private let real: UnsafeMutablePointer<Double>
    private let imaginary: UnsafeMutablePointer<Double>

    init?(length: Int) {
        guard length >= 4, length & (length - 1) == 0 else { return nil }
        let logLength = vDSP_Length(length.trailingZeroBitCount)
        guard let setup = vDSP_create_fftsetupD(logLength, FFTRadix(kFFTRadix2)) else { return nil }
        self.length = length
        self.halfLength = length / 2
        self.logLength = logLength
        self.setup = setup
        real = .allocate(capacity: length / 2)
        imaginary = .allocate(capacity: length / 2)
    }

    deinit {
        vDSP_destroy_fftsetupD(setup)
        real.deallocate()
        imaginary.deallocate()
    }

    func transform(_ buffer: UnsafeMutablePointer<Double>) {
        var split = DSPDoubleSplitComplex(realp: real, imagp: imaginary)
        buffer.withMemoryRebound(to: DSPDoubleComplex.self, capacity: halfLength) {
            vDSP_ctozD($0, 2, &split, 1, vDSP_Length(halfLength))
        }
        vDSP_fft_zripD(setup, &split, 1, logLength, FFTDirection(kFFTDirection_Forward))
        // vDSP 는 0번 칸에 DC(실수부)와 나이퀴스트(허수부)를 함께 담는다.
        real[0] *= real[0]
        imaginary[0] *= imaginary[0]
        for bin in 1..<halfLength {
            real[bin] = real[bin] * real[bin] + imaginary[bin] * imaginary[bin]
            imaginary[bin] = 0
        }
        vDSP_fft_zripD(setup, &split, 1, logLength, FFTDirection(kFFTDirection_Inverse))
        buffer.withMemoryRebound(to: DSPDoubleComplex.self, capacity: halfLength) {
            vDSP_ztocD(&split, 1, $0, 2, vDSP_Length(halfLength))
        }
    }
}
