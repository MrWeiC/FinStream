//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

struct AppBuildInfo: Equatable {

    static let gitCommitHashInfoKey = "GitCommitHash"

    let version: String?
    let build: String?
    let gitCommitHash: String?

    var versionDisplay: String {
        "\(displayValue(version)) (\(displayValue(build)))"
    }

    var commitDisplay: String {
        displayValue(gitCommitHash)
    }

    static var current: AppBuildInfo {
        AppBuildInfo(bundle: .main)
    }

    init(
        version: String?,
        build: String?,
        gitCommitHash: String?
    ) {
        self.version = version
        self.build = build
        self.gitCommitHash = gitCommitHash
    }

    init(bundle: Bundle) {
        self.init(
            version: bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            build: bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String,
            gitCommitHash: bundle.object(forInfoDictionaryKey: Self.gitCommitHashInfoKey) as? String
        )
    }

    private func displayValue(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return .emptyDash }
        return value
    }
}
