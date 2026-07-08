//
// WatermelonFin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
@testable import WatermelonFin_tvOS
import XCTest

/// Regression tests for initial media stream selection.
@MainActor
final class MediaPlayerItemAudioSelectionTests: XCTestCase {

    private let testURL = URL(string: "https://example.com/video")!

    private func makeStream(index: Int, type: MediaStreamType, language: String? = nil, displayTitle: String? = nil) -> MediaStream {
        var stream = MediaStream()
        stream.index = index
        stream.type = type
        stream.language = language
        stream.displayTitle = displayTitle
        return stream
    }

    private func makeMediaSource(
        defaultAudioStreamIndex: Int?,
        defaultSubtitleStreamIndex: Int? = nil,
        audioLanguages: [String],
        subtitleLanguages: [String] = []
    ) -> MediaSourceInfo {
        var mediaStreams: [MediaStream] = [
            makeStream(index: 0, type: .video),
        ]

        for (offset, language) in audioLanguages.enumerated() {
            mediaStreams.append(
                makeStream(index: offset + 1, type: .audio, language: language, displayTitle: language)
            )
        }

        let subtitleStartIndex = mediaStreams.count
        for (offset, language) in subtitleLanguages.enumerated() {
            mediaStreams.append(
                makeStream(index: subtitleStartIndex + offset, type: .subtitle, language: language, displayTitle: language)
            )
        }

        var mediaSource = MediaSourceInfo()
        mediaSource.transcodingURL = nil
        mediaSource.mediaStreams = mediaStreams
        mediaSource.defaultAudioStreamIndex = defaultAudioStreamIndex
        mediaSource.defaultSubtitleStreamIndex = defaultSubtitleStreamIndex
        return mediaSource
    }

    private func makeItem(mediaSource: MediaSourceInfo) -> MediaPlayerItem {
        .init(
            baseItem: BaseItemDto(),
            mediaSource: mediaSource,
            playSessionID: "test-session",
            url: testURL
        )
    }

    func testSelectsFirstAudioWhenDefaultIsNil() {
        let originalPreferredLanguage = Defaults[.VideoPlayer.Audio.preferredLanguage]
        defer { Defaults[.VideoPlayer.Audio.preferredLanguage] = originalPreferredLanguage }
        Defaults[.VideoPlayer.Audio.preferredLanguage] = "zzz"

        let mediaSource = makeMediaSource(defaultAudioStreamIndex: nil, audioLanguages: ["eng", "spa"])
        let item = makeItem(mediaSource: mediaSource)

        XCTAssertEqual(item.audioStreams.count, 2)
        XCTAssertNotNil(item.selectedAudioStreamIndex)
        XCTAssertGreaterThanOrEqual(item.selectedAudioStreamIndex ?? -1, 0)
        XCTAssertEqual(item.selectedAudioStreamIndex, item.audioStreams.first?.index)
    }

    func testSelectsDefaultAudioWhenValid() {
        let originalPreferredLanguage = Defaults[.VideoPlayer.Audio.preferredLanguage]
        defer { Defaults[.VideoPlayer.Audio.preferredLanguage] = originalPreferredLanguage }
        Defaults[.VideoPlayer.Audio.preferredLanguage] = "zzz"

        let mediaSource = makeMediaSource(defaultAudioStreamIndex: 2, audioLanguages: ["eng", "spa"])
        let item = makeItem(mediaSource: mediaSource)

        XCTAssertEqual(item.audioStreams.count, 2)
        XCTAssertEqual(item.selectedAudioStreamIndex, 2)
    }

    func testSelectsPreferredLanguageOverDefault() {
        let originalPreferredLanguage = Defaults[.VideoPlayer.Audio.preferredLanguage]
        defer { Defaults[.VideoPlayer.Audio.preferredLanguage] = originalPreferredLanguage }
        Defaults[.VideoPlayer.Audio.preferredLanguage] = "spa"

        let mediaSource = makeMediaSource(defaultAudioStreamIndex: 1, audioLanguages: ["eng", "spa"])
        let item = makeItem(mediaSource: mediaSource)

        XCTAssertEqual(item.audioStreams.count, 2)
        XCTAssertEqual(item.selectedAudioStreamIndex, 2)
    }

    func testFallsBackWhenDefaultInvalid() {
        let originalPreferredLanguage = Defaults[.VideoPlayer.Audio.preferredLanguage]
        defer { Defaults[.VideoPlayer.Audio.preferredLanguage] = originalPreferredLanguage }
        Defaults[.VideoPlayer.Audio.preferredLanguage] = "zzz"

        let mediaSource = makeMediaSource(defaultAudioStreamIndex: 99, audioLanguages: ["eng", "spa"])
        let item = makeItem(mediaSource: mediaSource)

        XCTAssertEqual(item.audioStreams.count, 2)
        XCTAssertNotNil(item.selectedAudioStreamIndex)
        XCTAssertGreaterThanOrEqual(item.selectedAudioStreamIndex ?? -1, 0)
        XCTAssertEqual(item.selectedAudioStreamIndex, item.audioStreams.first?.index)
    }

    func testSelectsFirstSubtitleWhenDefaultIsMissing() {
        let mediaSource = makeMediaSource(
            defaultAudioStreamIndex: 1,
            defaultSubtitleStreamIndex: -1,
            audioLanguages: ["eng"],
            subtitleLanguages: ["eng", "spa"]
        )
        let item = makeItem(mediaSource: mediaSource)

        XCTAssertEqual(item.subtitleStreams.count, 2)
        XCTAssertNotNil(item.selectedSubtitleStreamIndex)
        XCTAssertEqual(item.selectedSubtitleStreamIndex, item.subtitleStreams.first?.index)
    }

    func testMapsSubtitleStreamIndexToNativeLegibleOptionIndex() {
        let mediaSource = makeMediaSource(
            defaultAudioStreamIndex: 1,
            audioLanguages: ["eng"],
            subtitleLanguages: ["eng", "spa"]
        )
        let item = makeItem(mediaSource: mediaSource)

        XCTAssertEqual(
            AVMediaPlayerProxy.legibleOptionIndex(
                for: item.subtitleStreams[0].index,
                subtitleStreams: item.subtitleStreams
            ),
            0
        )
        XCTAssertEqual(
            AVMediaPlayerProxy.legibleOptionIndex(
                for: item.subtitleStreams[1].index,
                subtitleStreams: item.subtitleStreams
            ),
            1
        )
    }

    func testMPVMapsAdjustedAudioIndexesToOneBasedTrackIDs() {
        let streams = [
            makeStream(index: 1, type: .audio, language: "eng"),
            makeStream(index: 2, type: .audio, language: "spa"),
        ]

        XCTAssertEqual(MPVMediaPlayerProxy.audioTrackID(for: 1, audioStreams: streams), 1)
        XCTAssertEqual(MPVMediaPlayerProxy.audioTrackID(for: 2, audioStreams: streams), 2)
        XCTAssertNil(MPVMediaPlayerProxy.audioTrackID(for: -1, audioStreams: streams))
        XCTAssertNil(MPVMediaPlayerProxy.audioTrackID(for: 8, audioStreams: streams))
    }

    func testMPVMapsAdjustedSubtitleIndexesToOneBasedTrackIDs() {
        let streams = [
            makeStream(index: 3, type: .subtitle, language: "eng"),
            makeStream(index: 4, type: .subtitle, language: "chi"),
        ]

        XCTAssertEqual(MPVMediaPlayerProxy.subtitleTrackID(for: 3, subtitleStreams: streams), 1)
        XCTAssertEqual(MPVMediaPlayerProxy.subtitleTrackID(for: 4, subtitleStreams: streams), 2)
        XCTAssertEqual(MPVMediaPlayerProxy.subtitleTrackID(for: -1, subtitleStreams: streams), -1)
        XCTAssertNil(MPVMediaPlayerProxy.subtitleTrackID(for: 8, subtitleStreams: streams))
    }

    func testMPVMapsReplayGainToVolumePercent() {
        let originalEnabled = Defaults[.VideoPlayer.Audio.replayGainEnabled]
        let originalPreAmp = Defaults[.VideoPlayer.Audio.replayGainPreAmp]
        let originalPreventClipping = Defaults[.VideoPlayer.Audio.replayGainPreventClipping]
        defer {
            Defaults[.VideoPlayer.Audio.replayGainEnabled] = originalEnabled
            Defaults[.VideoPlayer.Audio.replayGainPreAmp] = originalPreAmp
            Defaults[.VideoPlayer.Audio.replayGainPreventClipping] = originalPreventClipping
        }

        Defaults[.VideoPlayer.Audio.replayGainEnabled] = true
        Defaults[.VideoPlayer.Audio.replayGainPreAmp] = 0
        Defaults[.VideoPlayer.Audio.replayGainPreventClipping] = false

        var item = BaseItemDto()
        item.type = .audio
        item.normalizationGain = -6

        XCTAssertEqual(MPVMediaPlayerProxy.volumePercent(for: item), 50.1187, accuracy: 0.0001)
    }
}
