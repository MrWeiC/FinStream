//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import MediaPlayer
@testable import Swiftfin_tvOS
import SwiftUI
import XCTest

@MainActor
final class NowPlayableLanguageOptionsTests: XCTestCase {

    private let testURL = URL(string: "https://example.com/video")!

    override func tearDown() async throws {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        try await super.tearDown()
    }

    func testNowPlayingInfoExposesSubtitleLanguageOptions() {
        let playbackItem = makePlaybackItem(
            subtitleStreams: [
                makeSubtitleStream(index: 2, language: "eng", displayTitle: "English"),
                makeSubtitleStream(index: 3, language: "zho", displayTitle: "Chinese, Traditional"),
            ],
            selectedSubtitleStreamIndex: 3
        )
        let manager = MediaPlayerManager(playbackItem: playbackItem)
        let observer = NowPlayableObserver()

        observer.manager = manager

        let nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
        let groups = nowPlayingInfo?[MPNowPlayingInfoPropertyAvailableLanguageOptions] as? [MPNowPlayingInfoLanguageOptionGroup]
        let currentOptions = nowPlayingInfo?[MPNowPlayingInfoPropertyCurrentLanguageOptions] as? [MPNowPlayingInfoLanguageOption]
        let subtitleGroup = groups?.first { group in
            group.languageOptions.contains { $0.languageOptionType == .legible }
        }

        XCTAssertEqual(subtitleGroup?.languageOptions.compactMap(\.identifier), ["subtitle:2", "subtitle:3"])
        XCTAssertEqual(subtitleGroup?.defaultLanguageOption?.identifier, "subtitle:3")
        XCTAssertEqual(currentOptions?.compactMap(\.identifier), ["audio:1", "subtitle:3"])
    }

    func testSelectingNowPlayableSubtitleLanguageOptionUpdatesSelectedSubtitle() throws {
        let playbackItem = makePlaybackItem(
            subtitleStreams: [
                makeSubtitleStream(index: 2, language: "eng", displayTitle: "English"),
                makeSubtitleStream(index: 3, language: "zho", displayTitle: "Chinese, Traditional"),
            ],
            selectedSubtitleStreamIndex: -1
        )
        let subtitleGroup = playbackItem.nowPlayableLanguageMetadata.availableLanguageOptionGroups.first { group in
            group.languageOptions.contains { $0.languageOptionType == .legible }
        }
        let chineseOption = try XCTUnwrap(
            subtitleGroup?.languageOptions.first { $0.identifier == "subtitle:3" }
        )

        XCTAssertTrue(playbackItem.select(languageOption: chineseOption))
        XCTAssertEqual(playbackItem.selectedSubtitleStreamIndex, 3)
        XCTAssertTrue(playbackItem.disable(languageOption: chineseOption))
        XCTAssertEqual(playbackItem.selectedSubtitleStreamIndex, -1)
    }

    func testSelectingSubtitlePassesFullExternalStreamToProxy() async {
        let playbackItem = makePlaybackItem(
            subtitleStreams: [
                makeSubtitleStream(index: 2, language: "eng", displayTitle: "English"),
                makeSubtitleStream(index: 3, language: "zho", displayTitle: "Chinese, Traditional"),
            ],
            selectedSubtitleStreamIndex: -1
        )
        let manager = MediaPlayerManager(playbackItem: playbackItem)
        let didSetSubtitle = expectation(description: "Proxy received selected subtitle stream")
        var receivedStream: MediaStream?
        let proxy = SubtitleSpyProxy { stream in
            guard stream.index == 3 else { return }
            receivedStream = stream
            didSetSubtitle.fulfill()
        }

        manager.proxy = proxy
        playbackItem.selectedSubtitleStreamIndex = 3

        await fulfillment(of: [didSetSubtitle], timeout: 1)
        XCTAssertEqual(receivedStream?.index, 3)
        XCTAssertEqual(receivedStream?.deliveryMethod, .external)
        XCTAssertEqual(receivedStream?.displayTitle, "Chinese, Traditional")
    }

    func testSubtitleFontResolverFallsBackToChineseCapableFontForSystemFont() throws {
        let systemFontName = UIFont.systemFont(ofSize: 14).fontName
        let resolvedFontName = SubtitleFontResolver.resolvedFontName(preferredFontName: systemFontName)
        let resolvedFont = try XCTUnwrap(UIFont(name: resolvedFontName, size: 14))

        XCTAssertNotEqual(resolvedFontName, systemFontName)
        XCTAssertTrue(resolvedFont.canRender("中文字幕繁體"))
    }

    private func makePlaybackItem(
        subtitleStreams: [MediaStream],
        selectedSubtitleStreamIndex: Int
    ) -> MediaPlayerItem {
        var baseItem = BaseItemDto()
        baseItem.name = "Test Video"

        var mediaSource = MediaSourceInfo()
        mediaSource.transcodingURL = nil
        mediaSource.mediaStreams = [
            makeStream(index: 0, type: .video),
            makeStream(index: 1, type: .audio, language: "eng", displayTitle: "English"),
        ] + subtitleStreams
        mediaSource.defaultAudioStreamIndex = 1
        mediaSource.defaultSubtitleStreamIndex = selectedSubtitleStreamIndex

        return MediaPlayerItem(
            baseItem: baseItem,
            mediaSource: mediaSource,
            playSessionID: "test-session",
            url: testURL
        )
    }

    private func makeStream(
        index: Int,
        type: MediaStreamType,
        language: String? = nil,
        displayTitle: String? = nil
    ) -> MediaStream {
        var stream = MediaStream()
        stream.index = index
        stream.type = type
        stream.language = language
        stream.displayTitle = displayTitle
        return stream
    }

    private func makeSubtitleStream(
        index: Int,
        language: String,
        displayTitle: String
    ) -> MediaStream {
        var stream = makeStream(index: index, type: .subtitle, language: language, displayTitle: displayTitle)
        stream.codec = "subrip"
        stream.deliveryMethod = .external
        return stream
    }
}

private extension UIFont {

    func canRender(_ string: String) -> Bool {
        let coreTextFont = CTFontCreateWithName(fontName as CFString, pointSize, nil)
        let characters = Array(string.utf16)
        var glyphs = Array(repeating: CGGlyph(), count: characters.count)

        return CTFontGetGlyphsForCharacters(coreTextFont, characters, &glyphs, characters.count)
    }
}

@MainActor
private final class SubtitleSpyProxy: VideoMediaPlayerProxy {

    let isBuffering = PublishedBox<Bool>(initialValue: false)
    let videoSize = PublishedBox<CGSize>(initialValue: .zero)

    weak var manager: MediaPlayerManager?

    private let onSubtitleStream: (MediaStream) -> Void

    init(onSubtitleStream: @escaping (MediaStream) -> Void) {
        self.onSubtitleStream = onSubtitleStream
    }

    var videoPlayerBody: EmptyView {
        EmptyView()
    }

    func play() {}
    func pause() {}
    func stop() {}
    func jumpForward(_ seconds: Duration) {}
    func jumpBackward(_ seconds: Duration) {}
    func setRate(_ rate: Float) {}
    func setSeconds(_ seconds: Duration) {}
    func setAspectFill(_ aspectFill: Bool) {}
    func setAudioStream(_ stream: MediaStream) {}

    func setSubtitleStream(_ stream: MediaStream) {
        onSubtitleStream(stream)
    }
}
