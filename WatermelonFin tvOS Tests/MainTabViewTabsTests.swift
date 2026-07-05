//
// WatermelonFin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

@testable import WatermelonFin_tvOS
import XCTest

@MainActor
final class MainTabViewTabsTests: XCTestCase {

    func testTVOSTabsIncludeLibrariesBetweenMoviesAndSearch() {
        let tabs = TabItem.tvOSTabs

        XCTAssertEqual(
            tabs.map(\.title),
            [
                L10n.home,
                L10n.tv,
                L10n.movies,
                L10n.libraries,
                L10n.search,
                L10n.settings,
            ]
        )
        XCTAssertEqual(tabs.first { $0.title == L10n.libraries }?.id, "libraries")
        XCTAssertEqual(tabs.first { $0.title == L10n.libraries }?.systemImage, "rectangle.stack.fill")
    }
}
