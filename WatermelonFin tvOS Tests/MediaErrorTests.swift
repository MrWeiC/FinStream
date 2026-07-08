//
// WatermelonFin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

@testable import WatermelonFin_tvOS
import XCTest

/// Tests for MediaError
final class MediaErrorTests: XCTestCase {

    // MARK: - Error Description Tests

    func testNoPlayableSourceDescription() {
        let error = MediaError.noPlayableSource
        XCTAssertEqual(error.errorDescription, L10n.mediaNoPlayableSource)
    }

    func testUnsupportedFormatWithFormat() {
        let error = MediaError.unsupportedFormat(format: "HEVC")
        XCTAssertEqual(error.errorDescription, L10n.mediaUnsupportedFormatWithFormat("HEVC"))
    }

    func testUnsupportedFormatWithoutFormat() {
        let error = MediaError.unsupportedFormat(format: nil)
        XCTAssertEqual(error.errorDescription, L10n.mediaUnsupportedFormat)
    }

    func testItemNotFoundWithId() {
        let error = MediaError.itemNotFound(itemId: "abc123")
        XCTAssertEqual(error.errorDescription, L10n.mediaItemNotFoundWithID("abc123"))
    }

    func testItemNotFoundWithoutId() {
        let error = MediaError.itemNotFound(itemId: nil)
        XCTAssertEqual(error.errorDescription, L10n.mediaItemNotFound)
    }

    // MARK: - Error Title Tests

    func testNoPlayableSourceTitle() {
        XCTAssertEqual(MediaError.noPlayableSource.errorTitle, L10n.mediaCannotPlay)
    }

    func testTranscodingFailedTitle() {
        XCTAssertEqual(MediaError.transcodingFailed(reason: nil).errorTitle, L10n.mediaTranscodingError)
    }

    func testStreamEndedTitle() {
        XCTAssertEqual(MediaError.streamEnded.errorTitle, L10n.mediaPlaybackError)
    }

    func testItemNotFoundTitle() {
        XCTAssertEqual(MediaError.itemNotFound(itemId: nil).errorTitle, L10n.mediaItemError)
    }

    func testSessionExpiredTitle() {
        XCTAssertEqual(MediaError.sessionExpired.errorTitle, L10n.mediaSessionError)
    }

    // MARK: - Retryability Tests

    func testTranscodingFailedIsRetryable() {
        XCTAssertTrue(MediaError.transcodingFailed(reason: nil).isRetryable)
    }

    func testStreamEndedIsRetryable() {
        XCTAssertTrue(MediaError.streamEnded.isRetryable)
    }

    func testLoadFailedIsRetryable() {
        XCTAssertTrue(MediaError.loadFailed(reason: nil).isRetryable)
    }

    func testSessionExpiredIsRetryable() {
        XCTAssertTrue(MediaError.sessionExpired.isRetryable)
    }

    func testNoPlayableSourceIsNotRetryable() {
        XCTAssertFalse(MediaError.noPlayableSource.isRetryable)
    }

    func testUnsupportedFormatIsNotRetryable() {
        XCTAssertFalse(MediaError.unsupportedFormat(format: nil).isRetryable)
    }

    func testItemNotFoundIsNotRetryable() {
        XCTAssertFalse(MediaError.itemNotFound(itemId: nil).isRetryable)
    }

    func testNotPlayableIsNotRetryable() {
        XCTAssertFalse(MediaError.notPlayable.isRetryable)
    }

    // MARK: - Hashable Conformance Tests

    func testErrorsAreHashable() {
        var set = Set<MediaError>()
        set.insert(.noPlayableSource)
        set.insert(.streamEnded)
        set.insert(.noPlayableSource) // Duplicate

        XCTAssertEqual(set.count, 2)
    }

    func testDifferentItemNotFoundErrorsAreDistinct() {
        let error1 = MediaError.itemNotFound(itemId: "abc")
        let error2 = MediaError.itemNotFound(itemId: "xyz")

        XCTAssertNotEqual(error1, error2)
    }
}
