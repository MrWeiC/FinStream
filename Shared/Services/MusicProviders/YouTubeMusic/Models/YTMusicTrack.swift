//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Represents a song/track from YouTube Music
struct YTMusicTrack: Identifiable, Hashable {

    /// Video ID used for playback
    let videoId: String

    /// Track title
    let title: String

    /// Artist(s) who performed this track
    let artists: [YTMusicArtistRef]

    /// Album this track belongs to (if known)
    let album: YTMusicAlbumRef?

    /// Duration in seconds
    let durationSeconds: Int?

    /// Duration as display string (e.g., "3:45")
    let duration: String?

    /// Available thumbnail images
    let thumbnails: [YTMusicThumbnail]

    /// Whether the track is marked as explicit
    let isExplicit: Bool

    /// Whether this is available for playback
    let isAvailable: Bool

    /// Feedback tokens for like/dislike (if authenticated)
    let feedbackTokens: YTMusicFeedbackTokens?

    /// Play count as string (e.g., "1.2M plays")
    let playCount: String?

    /// Track number in album (if from album view)
    let trackNumber: Int?

    /// Set ID for radio/shuffle playback
    let setVideoId: String?

    // MARK: - Identifiable

    var id: String {
        videoId
    }

    // MARK: - Computed Properties

    /// Best available thumbnail URL
    var thumbnailURL: URL? {
        thumbnails.bestQuality?.url
    }

    /// Primary artist name
    var artistName: String? {
        artists.first?.name
    }

    /// Album name
    var albumName: String? {
        album?.name
    }

    /// Duration formatted as minutes:seconds
    var formattedDuration: String {
        if let duration = duration {
            return duration
        }

        guard let seconds = durationSeconds else { return "--:--" }

        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Queue Item

extension YTMusicTrack {

    /// A track with queue-specific metadata
    struct QueueItem: Identifiable, Hashable {
        let track: YTMusicTrack
        let queuePosition: Int
        let isCurrentlyPlaying: Bool

        var id: String {
            "\(track.id)-\(queuePosition)"
        }
    }
}
