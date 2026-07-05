//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Errors that can occur during media playback
enum MediaError: LocalizedError, Hashable {

    // MARK: - Playback Errors

    /// No playable media source available for this item
    case noPlayableSource

    /// The media format is not supported
    case unsupportedFormat(format: String?)

    /// Transcoding failed on the server
    case transcodingFailed(reason: String?)

    /// The media stream ended unexpectedly
    case streamEnded

    /// Failed to load the media
    case loadFailed(reason: String?)

    // MARK: - Item Errors

    /// The requested item was not found
    case itemNotFound(itemId: String?)

    /// The item has no associated media
    case noMediaInfo

    /// The item type is not playable
    case notPlayable

    // MARK: - Session Errors

    /// Failed to create a playback session
    case sessionCreationFailed

    /// The playback session expired
    case sessionExpired

    /// Failed to report playback progress
    case reportingFailed

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .noPlayableSource:
            return L10n.mediaNoPlayableSource
        case let .unsupportedFormat(format):
            if let format {
                return L10n.mediaUnsupportedFormatWithFormat(format)
            }
            return L10n.mediaUnsupportedFormat
        case let .transcodingFailed(reason):
            if let reason {
                return L10n.mediaTranscodingFailedWithReason(reason)
            }
            return L10n.mediaTranscodingFailed
        case .streamEnded:
            return L10n.mediaStreamEnded
        case let .loadFailed(reason):
            if let reason {
                return L10n.mediaLoadFailedWithReason(reason)
            }
            return L10n.mediaLoadFailed
        case let .itemNotFound(itemId):
            if let itemId {
                return L10n.mediaItemNotFoundWithID(itemId)
            }
            return L10n.mediaItemNotFound
        case .noMediaInfo:
            return L10n.mediaNoMediaInfo
        case .notPlayable:
            return L10n.mediaNotPlayable
        case .sessionCreationFailed:
            return L10n.mediaSessionCreationFailed
        case .sessionExpired:
            return L10n.mediaSessionExpired
        case .reportingFailed:
            return L10n.mediaReportingFailed
        }
    }

    /// A user-friendly title for the error
    var errorTitle: String {
        switch self {
        case .noPlayableSource, .unsupportedFormat, .notPlayable:
            return L10n.mediaCannotPlay
        case .transcodingFailed:
            return L10n.mediaTranscodingError
        case .streamEnded, .loadFailed:
            return L10n.mediaPlaybackError
        case .itemNotFound, .noMediaInfo:
            return L10n.mediaItemError
        case .sessionCreationFailed, .sessionExpired, .reportingFailed:
            return L10n.mediaSessionError
        }
    }

    /// Whether the user should retry
    var isRetryable: Bool {
        switch self {
        case .transcodingFailed, .streamEnded, .loadFailed, .sessionExpired, .reportingFailed:
            return true
        case .noPlayableSource, .unsupportedFormat, .itemNotFound, .noMediaInfo, .notPlayable, .sessionCreationFailed:
            return false
        }
    }
}
