//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

/// Protocol defining a music service provider
///
/// MusicProvider abstracts different music sources (Jellyfin, YouTube Music, Spotify, etc.)
/// into a common interface using Jellyfin's BaseItemDto as the universal model.
///
/// This allows the UI layer to work with any music provider without knowing
/// the underlying implementation details.
public protocol MusicProvider {

    /// Provider identifier (e.g., "jellyfin", "youtube-music")
    var id: String { get }

    /// Human-readable provider name
    var displayName: String { get }

    /// Whether authentication is required to use this provider
    var requiresAuth: Bool { get }

    /// Whether the user is currently authenticated
    var isAuthenticated: Bool { get }

    // MARK: - Library Access

    /// Get artists from the user's library
    /// - Parameter limit: Maximum number of results (nil for default)
    /// - Returns: Array of artists as BaseItemDto
    func getArtists(limit: Int?) async throws -> [BaseItemDto]

    /// Get albums from the user's library, optionally filtered by artist
    /// - Parameters:
    ///   - artistID: Optional artist ID to filter albums
    ///   - limit: Maximum number of results (nil for default)
    /// - Returns: Array of albums as BaseItemDto
    func getAlbums(artistID: String?, limit: Int?) async throws -> [BaseItemDto]

    /// Get tracks from an album
    /// - Parameter albumID: The album's ID
    /// - Returns: Array of tracks as BaseItemDto
    func getTracks(albumID: String) async throws -> [BaseItemDto]

    /// Get recently played tracks
    /// - Parameter limit: Maximum number of results
    /// - Returns: Array of tracks as BaseItemDto
    func getRecentlyPlayed(limit: Int) async throws -> [BaseItemDto]

    // MARK: - Search

    /// Search for artists, albums, or tracks
    /// - Parameters:
    ///   - query: The search query
    ///   - limit: Maximum number of results (nil for default)
    /// - Returns: Array of mixed results as BaseItemDto
    func search(query: String, limit: Int?) async throws -> [BaseItemDto]

    // MARK: - Details

    /// Get detailed artist information
    /// - Parameter artistID: The artist's ID
    /// - Returns: The artist as BaseItemDto
    func getArtistDetails(artistID: String) async throws -> BaseItemDto

    /// Get detailed album information
    /// - Parameter albumID: The album's ID
    /// - Returns: The album as BaseItemDto
    func getAlbumDetails(albumID: String) async throws -> BaseItemDto
}

// MARK: - Default Implementations

public extension MusicProvider {

    /// Default search implementation that returns empty results
    func search(query: String, limit: Int?) async throws -> [BaseItemDto] {
        []
    }

    /// Default artist details that throws not found
    func getArtistDetails(artistID: String) async throws -> BaseItemDto {
        throw MusicProviderError.notFound
    }

    /// Default album details that throws not found
    func getAlbumDetails(albumID: String) async throws -> BaseItemDto {
        throw MusicProviderError.notFound
    }
}

// MARK: - Provider Errors

/// Errors that can occur across all music providers
public enum MusicProviderError: LocalizedError {

    /// Not authenticated with the provider
    case notAuthenticated

    /// Resource not found
    case notFound

    /// Operation not supported by this provider
    case notSupported

    /// Network error
    case networkError(underlying: Error)

    /// Provider-specific error
    case providerError(message: String)

    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not signed in to music provider"
        case .notFound:
            return "Item not found"
        case .notSupported:
            return "Operation not supported"
        case let .networkError(underlying):
            return underlying.localizedDescription
        case let .providerError(message):
            return message
        }
    }
}
