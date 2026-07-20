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

@MainActor
final class MediaProgressObserverTests: XCTestCase {

    func testStopReportUsesPlaySessionIDForResumeTracking() throws {
        var item = BaseItemDto()
        item.id = "item-id"

        var mediaSource = MediaSourceInfo()
        mediaSource.id = "source-id"

        let playerItem = try MediaPlayerItem(
            baseItem: item,
            mediaSource: mediaSource,
            playSessionID: "play-session-id",
            url: XCTUnwrap(URL(string: "https://example.com/video"))
        )

        let info = MediaProgressObserver.playbackStopInfo(
            for: playerItem,
            seconds: .seconds(42)
        )

        XCTAssertEqual(info.itemID, "item-id")
        XCTAssertEqual(info.mediaSourceID, "source-id")
        XCTAssertEqual(info.playSessionID, "play-session-id")
        XCTAssertNil(info.sessionID)
        XCTAssertEqual(info.positionTicks, Duration.seconds(42).ticks)
    }
}
