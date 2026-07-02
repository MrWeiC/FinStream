//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Represents an artist from YouTube Music
struct YTMusicArtist: Identifiable, Hashable {

    /// Unique identifier (YouTube channel/browse ID)
    let id: String

    /// Display name of the artist
    let name: String

    /// Number of subscribers (e.g., "1.2M subscribers")
    let subscriberCount: String?

    /// Available thumbnail images at different sizes
    let thumbnails: [YTMusicThumbnail]

    /// Artist description/bio if available
    let description: String?

    /// Browse ID for the artist's radio station
    let radioId: String?

    /// Browse ID for the artist's shuffle playlist
    let shuffleId: String?

    /// Number of albums (if provided)
    let albumCount: Int?

    // MARK: - Identifiable

    var browseId: String {
        id
    }

    // MARK: - Computed Properties

    /// Best available thumbnail URL
    var thumbnailURL: URL? {
        thumbnails.bestQuality?.url
    }

    /// Convert to a lightweight reference
    var asRef: YTMusicArtistRef {
        YTMusicArtistRef(id: id, name: name)
    }
}

// MARK: - Artist Discography

extension YTMusicArtist {

    /// A section of an artist's discography (albums, singles, etc.)
    struct DiscographySection: Identifiable {
        let id: String
        let title: String
        let albums: [YTMusicAlbum]
    }
}
