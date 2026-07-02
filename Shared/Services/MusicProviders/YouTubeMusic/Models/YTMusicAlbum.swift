//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Represents an album from YouTube Music
struct YTMusicAlbum: Identifiable, Hashable {

    /// Unique identifier (browse ID)
    let id: String

    /// Album title
    let title: String

    /// Album type (Album, Single, EP, etc.)
    let type: YTMusicAlbumType

    /// Artist(s) who created this album
    let artists: [YTMusicArtistRef]

    /// Release year (e.g., "2023")
    let year: String?

    /// Total track count
    let trackCount: Int?

    /// Total duration as string (e.g., "45 min")
    let duration: String?

    /// Available thumbnail images
    let thumbnails: [YTMusicThumbnail]

    /// Whether the album is marked as explicit
    let isExplicit: Bool

    /// Playlist ID for playback (different from browse ID)
    let playlistId: String?

    /// Audio playlist ID (for audio-only playback)
    let audioPlaylistId: String?

    // MARK: - Identifiable

    var browseId: String {
        id
    }

    // MARK: - Computed Properties

    /// Best available thumbnail URL
    var thumbnailURL: URL? {
        thumbnails.bestQuality?.url
    }

    /// Primary artist name (first artist)
    var artistName: String? {
        artists.first?.name
    }

    /// Convert to a lightweight reference
    var asRef: YTMusicAlbumRef {
        YTMusicAlbumRef(id: id, name: title)
    }
}
