//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Calculates final audio gain for ReplayGain normalization.
///
/// ReplayGain values stored in audio file tags (and exposed via Jellyfin's
/// `normalizationGain` field) represent the dB adjustment needed to bring
/// a track to a target loudness level (typically -18 LUFS or -89 dB SPL).
enum ReplayGainCalculator {

    /// Valid range for VLC gain adjustment in dB.
    /// VLC accepts gain values roughly in this range before clipping occurs.
    static let gainRange: ClosedRange<Float> = -20 ... 20

    /// Calculate the final gain adjustment in dB.
    ///
    /// - Parameters:
    ///   - normalizationGain: The ReplayGain value from Jellyfin API (dB). Nil if unavailable.
    ///   - preAmp: User-configurable adjustment added to the gain (-12 to +12 dB typical).
    ///   - preventClipping: If true, limits positive gains to 0 dB to avoid digital clipping.
    ///
    /// - Returns: Final gain in dB, clamped to VLC's acceptable range.
    static func calculateFinalGain(
        normalizationGain: Float?,
        preAmp: Float,
        preventClipping: Bool
    ) -> Float {
        guard let normalizationGain else {
            return 0
        }

        var finalGain = normalizationGain + preAmp

        if preventClipping && finalGain > 0 {
            finalGain = 0
        }

        return finalGain.clamped(to: gainRange)
    }

    /// Convert dB gain to linear scale for VLC's gain option.
    ///
    /// VLC's gain parameter uses linear scale (1.0 = unity gain).
    /// Formula: linear = 10^(dB/20)
    ///
    /// - Parameter dB: Gain in decibels
    /// - Returns: Linear gain multiplier
    static func dBToLinear(_ dB: Float) -> Float {
        pow(10, dB / 20.0)
    }
}

private extension Comparable {

    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
