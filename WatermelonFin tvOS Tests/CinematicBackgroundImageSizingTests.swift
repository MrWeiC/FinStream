//
// WatermelonFin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

@testable import WatermelonFin_tvOS
import XCTest

final class CinematicBackgroundImageSizingTests: XCTestCase {

    func testUsesNativeWidthFor1080pDisplay() {
        let width: CGFloat = CinematicBackgroundImageSizing.maxWidth(
            viewWidth: 1920,
            displayScale: 1
        )

        XCTAssertEqual(width, 1920)
    }

    func testUsesNativeWidthFor4KDisplay() {
        let width: CGFloat = CinematicBackgroundImageSizing.maxWidth(
            viewWidth: 1920,
            displayScale: 2
        )

        XCTAssertEqual(width, 3840)
    }

    func testClampsRequestWidthToSupportedRange() {
        XCTAssertEqual(
            CinematicBackgroundImageSizing.maxWidth(viewWidth: 1280, displayScale: 1),
            1920
        )
        XCTAssertEqual(
            CinematicBackgroundImageSizing.maxWidth(viewWidth: 2560, displayScale: 2),
            3840
        )
    }
}
