//
// WatermelonFin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
@testable import WatermelonFin_tvOS
import XCTest

final class BaseItemDtoUserDataTests: XCTestCase {

    func testSetPlayedStateMarksPlayedAndClearsResumeProgress() {
        var item: BaseItemDto = .init()
        item.userData = UserItemDataDto(
            playbackPositionTicks: 123_456,
            isPlayed: false,
            playedPercentage: 42
        )

        item.setPlayedState(true)

        XCTAssertEqual(item.userData?.isPlayed, true)
        XCTAssertEqual(item.userData?.playbackPositionTicks, 0)
        XCTAssertEqual(item.userData?.playedPercentage, 100)
    }

    func testSetPlayedStateMarksUnplayedAndClearsResumeProgress() {
        var item: BaseItemDto = .init()
        item.userData = UserItemDataDto(
            playbackPositionTicks: 987_654,
            isPlayed: true,
            playedPercentage: 91
        )

        item.setPlayedState(false)

        XCTAssertEqual(item.userData?.isPlayed, false)
        XCTAssertEqual(item.userData?.playbackPositionTicks, 0)
        XCTAssertEqual(item.userData?.playedPercentage, 0)
    }

    func testSetPlayedStateCreatesUserDataWhenMissing() {
        var item: BaseItemDto = .init()

        item.setPlayedState(true)

        XCTAssertEqual(item.userData?.isPlayed, true)
        XCTAssertEqual(item.userData?.playbackPositionTicks, 0)
        XCTAssertEqual(item.userData?.playedPercentage, 100)
    }

    func testMoviesLibraryUsesLocalizedCollectionTitle() {
        var item: BaseItemDto = .init()
        item.name = "Movies"
        item.collectionType = .movies

        XCTAssertEqual(item.localizedLibraryDisplayTitle, L10n.movies)
    }

    func testShowsLibraryUsesSeriesTitleInsteadOfServerName() {
        var item: BaseItemDto = .init()
        item.name = "Shows"
        item.collectionType = .tvshows

        XCTAssertEqual(item.localizedLibraryDisplayTitle, L10n.series)
    }

    func testDefaultEnglishLibraryNamesUseLocalizedTitles() {
        var movieLibrary: BaseItemDto = .init()
        movieLibrary.name = "Movies"

        var showsLibrary: BaseItemDto = .init()
        showsLibrary.name = "Shows"

        XCTAssertEqual(movieLibrary.localizedLibraryDisplayTitle, L10n.movies)
        XCTAssertEqual(showsLibrary.localizedLibraryDisplayTitle, L10n.series)
    }

    func testCustomLibraryNameIsPreservedWhenCollectionTypeIsMovie() {
        var library: BaseItemDto = .init()
        library.name = "Home School"
        library.collectionType = .movies

        XCTAssertEqual(library.localizedLibraryDisplayTitle, "Home School")
    }

    func testGenericLibraryParentUsesLocalizedDefaultLibraryTitle() {
        let movieParent: TitledLibraryParent = TitledLibraryParent(displayTitle: "movies")
        let showsParent: TitledLibraryParent = TitledLibraryParent(displayTitle: "TV Shows")

        XCTAssertEqual(movieParent.localizedLibraryDisplayTitle, L10n.movies)
        XCTAssertEqual(showsParent.localizedLibraryDisplayTitle, L10n.series)
    }

    func testLatestLibraryTitlesUseNaturalChineseText() {
        XCTAssertEqual(L10n.latestWithString(L10n.movies), "最新电影")
        XCTAssertEqual(L10n.latestWithString(L10n.series), "最新剧集")
    }

    func testLatestLibraryParentTitleUsesLocalizedLibraryName() {
        let movieParent: TitledLibraryParent = TitledLibraryParent(displayTitle: "movies")
        let showsParent: TitledLibraryParent = TitledLibraryParent(displayTitle: "shows")

        XCTAssertEqual(movieParent.localizedLatestLibraryTitle, "最新电影")
        XCTAssertEqual(showsParent.localizedLatestLibraryTitle, "最新剧集")
    }

    func testMediaLibraryCardsUseLocalizedLibraryNames() {
        var movieLibrary: BaseItemDto = .init()
        movieLibrary.name = "Movies"

        var showsLibrary: BaseItemDto = .init()
        showsLibrary.name = "Shows"

        XCTAssertEqual(MediaViewModel.MediaType.library(movieLibrary).displayTitle, L10n.movies)
        XCTAssertEqual(MediaViewModel.MediaType.library(showsLibrary).displayTitle, L10n.series)
    }

    func testMediaLibraryCardsPreserveCustomLibraryNames() {
        var library: BaseItemDto = .init()
        library.name = "Home School"
        library.collectionType = .movies

        XCTAssertEqual(MediaViewModel.MediaType.library(library).displayTitle, "Home School")
    }

    func testWatchedActionLabelsUseChineseText() {
        XCTAssertEqual(L10n.markWatched, "标记已观看")
        XCTAssertEqual(L10n.markUnwatched, "标记未观看")
    }

    @MainActor
    func testPlaybackRateSupplementUsesLocalizedTitle() {
        XCTAssertEqual(PlaybackRateMediaPlayerSupplement().displayTitle, "播放速度")
    }

    func testMediaCountLabelsUseNaturalChineseMeasureWords() {
        XCTAssertEqual(BaseItemKind.movie.localizedCountLabel(2), "2 部电影")
        XCTAssertEqual(BaseItemKind.series.localizedCountLabel(2), "2 部剧集")
        XCTAssertEqual(BaseItemKind.episode.localizedCountLabel(2), "2 集")
        XCTAssertEqual(BaseItemKind.boxSet.localizedCountLabel(2), "2 个合集")
        XCTAssertEqual(BaseItemKind.video.localizedCountLabel(2), "2 个项目")
    }

    func testUnknownLibraryFallsBackToServerName() {
        var item: BaseItemDto = .init()
        item.name = "Kids"

        XCTAssertEqual(item.localizedLibraryDisplayTitle, "Kids")
    }
}
