//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
@testable import Swiftfin_tvOS
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
}
