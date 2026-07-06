//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

@testable import Swiftfin_tvOS
import XCTest

final class AppBuildInfoTests: XCTestCase {

    func testVersionDisplayIncludesMarketingAndBundleVersion() {
        let sut = AppBuildInfo(version: "1.3.0", build: "1", gitCommitHash: "4016df2")

        XCTAssertEqual(sut.versionDisplay, "1.3.0 (1)")
    }

    func testCommitDisplayUsesGitCommitHash() {
        let sut = AppBuildInfo(version: "1.3.0", build: "1", gitCommitHash: "4016df2")

        XCTAssertEqual(sut.commitDisplay, "4016df2")
    }

    func testDisplaysFallbackForMissingValues() {
        let sut = AppBuildInfo(version: nil, build: nil, gitCommitHash: nil)

        XCTAssertEqual(sut.versionDisplay, "-- (--)")
        XCTAssertEqual(sut.commitDisplay, "--")
    }
}
