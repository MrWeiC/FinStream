//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Manages HTTP headers required for YouTube Music API requests
///
/// YouTube Music's internal API requires specific headers to be set for requests
/// to be accepted. These headers mimic a browser session accessing music.youtube.com.
enum YTMusicHeaders {

    // MARK: - Constants

    /// Base URL for YouTube Music
    static let baseURL = URL(string: "https://music.youtube.com")!

    /// API base URL for youtubei endpoints
    static let apiBaseURL = URL(string: "https://music.youtube.com/youtubei/v1/")!

    /// Client name sent in API requests
    private static let clientName = "WEB_REMIX"

    /// Client version - should be updated periodically to match current YouTube Music
    private static let clientVersion = "1.20241111.01.00"

    /// User agent mimicking a modern browser
    private static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " +
        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

    // MARK: - Header Builders

    /// Standard headers for all YouTube Music API requests
    static func standardHeaders(accessToken: String? = nil) -> [String: String] {
        var headers: [String: String] = [
            "User-Agent": userAgent,
            "Accept": "*/*",
            "Accept-Language": "en-US,en;q=0.9",
            "Content-Type": "application/json",
            "X-Goog-AuthUser": "0",
            "X-Origin": "https://music.youtube.com",
            "Origin": "https://music.youtube.com",
            "Referer": "https://music.youtube.com/",
        ]

        if let token = accessToken {
            headers["Authorization"] = "Bearer \(token)"
        }

        return headers
    }

    /// Request context sent in the body of API requests
    ///
    /// This context object is required by the youtubei API and contains
    /// client information that YouTube uses to determine response format.
    static func requestContext(visitorData: String? = nil) -> [String: Any] {
        var client: [String: Any] = [
            "clientName": clientName,
            "clientVersion": clientVersion,
            "hl": "en",
            "gl": "US",
            "platform": "DESKTOP",
            "userAgent": userAgent,
        ]

        if let visitor = visitorData {
            client["visitorData"] = visitor
        }

        let context: [String: Any] = [
            "client": client,
        ]

        return ["context": context]
    }

    /// Builds a complete request body with context and additional parameters
    static func buildRequestBody(
        context: [String: Any]? = nil,
        params: [String: Any] = [:]
    ) -> [String: Any] {
        var body = context ?? requestContext()

        for (key, value) in params {
            body[key] = value
        }

        return body
    }
}

// MARK: - API Endpoints

extension YTMusicHeaders {

    /// Known API endpoints for YouTube Music
    enum Endpoint {
        case search
        case browse
        case player
        case getSearchSuggestions
        case next

        var path: String {
            switch self {
            case .search:
                return "search"
            case .browse:
                return "browse"
            case .player:
                return "player"
            case .getSearchSuggestions:
                return "music/get_search_suggestions"
            case .next:
                return "next"
            }
        }

        var url: URL {
            YTMusicHeaders.apiBaseURL.appendingPathComponent(path)
        }
    }
}

// MARK: - Browse Parameters

extension YTMusicHeaders {

    /// Known browse IDs for different content types
    enum BrowseID {
        /// User's library of artists
        static let libraryArtists = "FEmusic_library_corpus_track_artists"

        /// User's library of albums
        static let libraryAlbums = "FEmusic_library_corpus_artists"

        /// User's liked songs playlist
        static let likedSongs = "FEmusic_liked_videos"

        /// User's history
        static let history = "FEmusic_history"

        /// Home page/feed
        static let home = "FEmusic_home"
    }
}
