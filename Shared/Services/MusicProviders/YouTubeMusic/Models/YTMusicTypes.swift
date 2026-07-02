//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

// MARK: - Thumbnail

/// Thumbnail image from YouTube Music
struct YTMusicThumbnail: Hashable, Codable {
    let url: URL
    let width: Int
    let height: Int
}

extension Array where Element == YTMusicThumbnail {
    /// Get the highest quality thumbnail
    var bestQuality: YTMusicThumbnail? {
        self.max { $0.width * $0.height < $1.width * $1.height }
    }

    /// Get the thumbnail closest to a target size
    func closest(to size: Int) -> YTMusicThumbnail? {
        self.min { abs($0.width - size) < abs($1.width - size) }
    }
}

// MARK: - Artist Reference

/// Lightweight reference to an artist (used in album/track listings)
struct YTMusicArtistRef: Hashable, Codable {
    let id: String?
    let name: String

    /// Whether this artist has a browseable page
    var isBrowseable: Bool {
        id != nil
    }
}

// MARK: - Album Reference

/// Lightweight reference to an album (used in track listings)
struct YTMusicAlbumRef: Hashable, Codable {
    let id: String?
    let name: String

    /// Whether this album has a browseable page
    var isBrowseable: Bool {
        id != nil
    }
}

// MARK: - Album Type

/// Type of album (Album, Single, EP)
enum YTMusicAlbumType: String, Hashable, Codable {
    case album = "Album"
    case single = "Single"
    case ep = "EP"
    case unknown

    init(from string: String?) {
        guard let string = string else {
            self = .unknown
            return
        }

        switch string.lowercased() {
        case "album":
            self = .album
        case "single":
            self = .single
        case "ep":
            self = .ep
        default:
            self = .unknown
        }
    }
}

// MARK: - Feedback Tokens

/// Tokens used for like/dislike feedback
struct YTMusicFeedbackTokens: Hashable, Codable {
    let like: String?
    let dislike: String?
}

// MARK: - Search Result Type

/// Types of content that can appear in search results
enum YTMusicSearchResultType: String {
    case artist
    case album
    case song
    case video
    case playlist
    case station
    case profile
    case unknown
}
