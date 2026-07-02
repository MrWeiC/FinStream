//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

/// ReplayGain normalization mode for audio playback.
///
/// ReplayGain uses metadata from audio files to normalize volume levels,
/// so tracks mastered at different loudness levels play at consistent volume.
enum ReplayGainMode: String, CaseIterable, Displayable, Storable {

    /// Normalize each track independently to target loudness.
    /// Best for shuffle/mixed playlists where album context doesn't matter.
    case track

    /// Maintain relative loudness within albums while normalizing between albums.
    /// Preserves intentional dynamics (e.g., quiet intros) within an album.
    /// Note: Jellyfin API currently only provides track gain, so this behaves
    /// the same as track mode until the API is enhanced.
    case album

    var displayTitle: String {
        switch self {
        case .track:
            return L10n.track
        case .album:
            return L10n.album
        }
    }

    var description: String {
        switch self {
        case .track:
            return "Normalize each track independently"
        case .album:
            return "Preserve dynamics within albums"
        }
    }
}
