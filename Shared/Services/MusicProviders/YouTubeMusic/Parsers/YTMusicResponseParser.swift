//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import Logging

/// Parses YouTube Music API responses into Swift models
///
/// YouTube Music's internal API returns deeply nested JSON structures.
/// This parser navigates the nesting to extract usable data.
///
/// The response structure typically follows this pattern:
/// ```
/// {
///   "contents": {
///     "singleColumnBrowseResultsRenderer": {
///       "tabs": [{
///         "tabRenderer": {
///           "content": {
///             "sectionListRenderer": {
///               "contents": [...]
///             }
///           }
///         }
///       }]
///     }
///   }
/// }
/// ```
enum YTMusicResponseParser {

    private static let logger = Logger.swiftfin()

    // MARK: - Search Parsing

    /// Parse search results into mixed content
    static func parseSearchResults(_ response: [String: Any]) -> [Any] {
        var results: [Any] = []

        guard let contents = navigateToContents(response, path: [
            "contents",
            "tabbedSearchResultsRenderer",
            "tabs",
            0,
            "tabRenderer",
            "content",
            "sectionListRenderer",
            "contents",
        ]) as? [[String: Any]] else {
            // Try alternative path for filtered results
            if let altContents = navigateToContents(response, path: [
                "contents",
                "sectionListRenderer",
                "contents",
            ]) as? [[String: Any]] {
                return parseSearchSections(altContents)
            }
            return results
        }

        return parseSearchSections(contents)
    }

    /// Parse search sections into results
    private static func parseSearchSections(_ sections: [[String: Any]]) -> [Any] {
        var results: [Any] = []

        for section in sections {
            guard let musicShelfRenderer = section["musicShelfRenderer"] as? [String: Any],
                  let contents = musicShelfRenderer["contents"] as? [[String: Any]]
            else {
                continue
            }

            for item in contents {
                if let parsed = parseSearchItem(item) {
                    results.append(parsed)
                }
            }
        }

        return results
    }

    /// Parse a single search result item
    private static func parseSearchItem(_ item: [String: Any]) -> Any? {
        guard let musicResponsiveListItemRenderer = item["musicResponsiveListItemRenderer"] as? [String: Any] else {
            return nil
        }

        // Determine the type from navigation endpoint
        let resultType = determineSearchResultType(musicResponsiveListItemRenderer)

        switch resultType {
        case .artist:
            return parseArtistFromSearch(musicResponsiveListItemRenderer)
        case .album:
            return parseAlbumFromSearch(musicResponsiveListItemRenderer)
        case .song:
            return parseTrackFromSearch(musicResponsiveListItemRenderer)
        default:
            return nil
        }
    }

    /// Determine what type of result an item is
    private static func determineSearchResultType(_ renderer: [String: Any]) -> YTMusicSearchResultType {
        // Check for navigation endpoint to determine type
        if let navigationEndpoint = renderer["navigationEndpoint"] as? [String: Any] {
            if navigationEndpoint["browseEndpoint"] != nil {
                // Could be artist, album, or playlist
                if let browseEndpoint = navigationEndpoint["browseEndpoint"] as? [String: Any],
                   let browseId = browseEndpoint["browseId"] as? String
                {
                    if browseId.hasPrefix("UC") {
                        return .artist
                    } else if browseId.hasPrefix("MPREb") {
                        return .album
                    }
                }
            } else if navigationEndpoint["watchEndpoint"] != nil {
                return .song
            }
        }

        // Check flexColumns for type hints
        if let flexColumns = renderer["flexColumns"] as? [[String: Any]] {
            for column in flexColumns {
                if let text = extractTextFromFlexColumn(column)?.lowercased() {
                    if text.contains("artist") {
                        return .artist
                    } else if text.contains("album") || text.contains("single") || text.contains("ep") {
                        return .album
                    } else if text.contains("song") {
                        return .song
                    }
                }
            }
        }

        return .unknown
    }

    // MARK: - Artist Parsing

    /// Parse an artist from search results
    private static func parseArtistFromSearch(_ renderer: [String: Any]) -> YTMusicArtist? {
        guard let browseId = extractBrowseId(renderer),
              let name = extractTitle(renderer)
        else {
            return nil
        }

        let thumbnails = extractThumbnails(renderer)
        let subscriberCount = extractSubtitle(renderer)

        return YTMusicArtist(
            id: browseId,
            name: name,
            subscriberCount: subscriberCount,
            thumbnails: thumbnails,
            description: nil,
            radioId: nil,
            shuffleId: nil,
            albumCount: nil
        )
    }

    /// Parse full artist details from browse response
    static func parseArtistDetails(_ response: [String: Any]) -> YTMusicArtist? {
        guard let header = response["header"] as? [String: Any],
              let musicImmersiveHeaderRenderer = header["musicImmersiveHeaderRenderer"] as? [String: Any]
        else {
            // Try alternative header
            if let header = response["header"] as? [String: Any],
               let musicVisualHeaderRenderer = header["musicVisualHeaderRenderer"] as? [String: Any]
            {
                return parseArtistFromVisualHeader(musicVisualHeaderRenderer, response: response)
            }
            return nil
        }

        guard let title = musicImmersiveHeaderRenderer["title"] as? [String: Any],
              let runs = title["runs"] as? [[String: Any]],
              let name = runs.first?["text"] as? String
        else {
            return nil
        }

        // Extract browse ID from page URL or navigation
        let browseId = extractPageBrowseId(response) ?? ""

        let thumbnails = extractThumbnailsFromRenderer(musicImmersiveHeaderRenderer)
        let subscriberCount = extractSubscriberCount(musicImmersiveHeaderRenderer)
        let description = extractDescription(musicImmersiveHeaderRenderer)

        return YTMusicArtist(
            id: browseId,
            name: name,
            subscriberCount: subscriberCount,
            thumbnails: thumbnails,
            description: description,
            radioId: nil,
            shuffleId: nil,
            albumCount: nil
        )
    }

    private static func parseArtistFromVisualHeader(
        _ header: [String: Any],
        response: [String: Any]
    ) -> YTMusicArtist? {
        guard let title = header["title"] as? [String: Any],
              let runs = title["runs"] as? [[String: Any]],
              let name = runs.first?["text"] as? String
        else {
            return nil
        }

        let browseId = extractPageBrowseId(response) ?? ""
        let thumbnails = extractThumbnailsFromRenderer(header)

        return YTMusicArtist(
            id: browseId,
            name: name,
            subscriberCount: nil,
            thumbnails: thumbnails,
            description: nil,
            radioId: nil,
            shuffleId: nil,
            albumCount: nil
        )
    }

    // MARK: - Album Parsing

    /// Parse an album from search results
    private static func parseAlbumFromSearch(_ renderer: [String: Any]) -> YTMusicAlbum? {
        guard let browseId = extractBrowseId(renderer),
              let title = extractTitle(renderer)
        else {
            return nil
        }

        let thumbnails = extractThumbnails(renderer)
        let subtitle = extractSubtitle(renderer)

        // Parse artist and year from subtitle (e.g., "Album • Artist • 2023")
        let (artists, year, albumType) = parseAlbumSubtitle(subtitle)

        return YTMusicAlbum(
            id: browseId,
            title: title,
            type: albumType,
            artists: artists,
            year: year,
            trackCount: nil,
            duration: nil,
            thumbnails: thumbnails,
            isExplicit: extractIsExplicit(renderer),
            playlistId: nil,
            audioPlaylistId: nil
        )
    }

    /// Parse full album details from browse response
    static func parseAlbumDetails(_ response: [String: Any]) -> YTMusicAlbum? {
        guard let header = response["header"] as? [String: Any],
              let musicDetailHeaderRenderer = header["musicDetailHeaderRenderer"] as? [String: Any]
        else {
            return nil
        }

        guard let title = musicDetailHeaderRenderer["title"] as? [String: Any],
              let runs = title["runs"] as? [[String: Any]],
              let albumTitle = runs.first?["text"] as? String
        else {
            return nil
        }

        let browseId = extractPageBrowseId(response) ?? ""
        let thumbnails = extractThumbnailsFromRenderer(musicDetailHeaderRenderer)

        // Extract subtitle info
        var artists: [YTMusicArtistRef] = []
        var year: String?
        var albumType: YTMusicAlbumType = .album
        var trackCount: Int?
        var duration: String?

        if let subtitle = musicDetailHeaderRenderer["subtitle"] as? [String: Any],
           let subtitleRuns = subtitle["runs"] as? [[String: Any]]
        {
            for run in subtitleRuns {
                guard let text = run["text"] as? String else { continue }

                if let endpoint = run["navigationEndpoint"] as? [String: Any],
                   let browseEndpoint = endpoint["browseEndpoint"] as? [String: Any],
                   let artistId = browseEndpoint["browseId"] as? String
                {
                    // This is an artist link
                    artists.append(YTMusicArtistRef(id: artistId, name: text))
                } else if text.contains("Album") || text.contains("Single") || text.contains("EP") {
                    albumType = YTMusicAlbumType(from: text)
                } else if let yearInt = Int(text), yearInt > 1900, yearInt < 2100 {
                    year = text
                }
            }
        }

        // Extract secondary info (track count, duration)
        if let menu = musicDetailHeaderRenderer["menu"] as? [String: Any],
           let secondaryInfo = musicDetailHeaderRenderer["secondarySubtitle"] as? [String: Any],
           let runs = secondaryInfo["runs"] as? [[String: Any]]
        {
            for run in runs {
                if let text = run["text"] as? String {
                    if text.contains("song") {
                        // Extract number from "X songs" pattern
                        let numbers = text.components(separatedBy: CharacterSet.decimalDigits.inverted)
                            .compactMap { Int($0) }
                        if let count = numbers.first {
                            trackCount = count
                        }
                    } else if text.contains("min") || text.contains("hour") {
                        duration = text
                    }
                }
            }
        }

        // Extract playlist ID for playback
        var playlistId: String?
        if let menu = musicDetailHeaderRenderer["menu"] as? [String: Any],
           let menuRenderer = menu["menuRenderer"] as? [String: Any],
           let items = menuRenderer["items"] as? [[String: Any]]
        {
            for item in items {
                if let menuServiceItemRenderer = item["menuServiceItemRenderer"] as? [String: Any],
                   let serviceEndpoint = menuServiceItemRenderer["serviceEndpoint"] as? [String: Any],
                   let playlistEndpoint = serviceEndpoint["queueAddEndpoint"] as? [String: Any],
                   let queueTarget = playlistEndpoint["queueTarget"] as? [String: Any],
                   let id = queueTarget["playlistId"] as? String
                {
                    playlistId = id
                    break
                }
            }
        }

        return YTMusicAlbum(
            id: browseId,
            title: albumTitle,
            type: albumType,
            artists: artists,
            year: year,
            trackCount: trackCount,
            duration: duration,
            thumbnails: thumbnails,
            isExplicit: false,
            playlistId: playlistId,
            audioPlaylistId: nil
        )
    }

    /// Parse album tracks from browse response
    static func parseAlbumTracks(_ response: [String: Any]) -> [YTMusicTrack] {
        var tracks: [YTMusicTrack] = []

        guard let contents = navigateToContents(response, path: [
            "contents",
            "singleColumnBrowseResultsRenderer",
            "tabs",
            0,
            "tabRenderer",
            "content",
            "sectionListRenderer",
            "contents",
        ]) as? [[String: Any]] else {
            return tracks
        }

        for section in contents {
            if let musicShelfRenderer = section["musicShelfRenderer"] as? [String: Any],
               let shelfContents = musicShelfRenderer["contents"] as? [[String: Any]]
            {
                for (index, item) in shelfContents.enumerated() {
                    if let track = parseTrackFromAlbum(item, trackNumber: index + 1) {
                        tracks.append(track)
                    }
                }
            }
        }

        return tracks
    }

    // MARK: - Track Parsing

    /// Parse a track from search results
    private static func parseTrackFromSearch(_ renderer: [String: Any]) -> YTMusicTrack? {
        guard let videoId = extractVideoId(renderer),
              let title = extractTitle(renderer)
        else {
            return nil
        }

        let thumbnails = extractThumbnails(renderer)
        let (artists, album, duration) = parseTrackFlexColumns(renderer)

        return YTMusicTrack(
            videoId: videoId,
            title: title,
            artists: artists,
            album: album,
            durationSeconds: parseDurationToSeconds(duration),
            duration: duration,
            thumbnails: thumbnails,
            isExplicit: extractIsExplicit(renderer),
            isAvailable: true,
            feedbackTokens: nil,
            playCount: nil,
            trackNumber: nil,
            setVideoId: nil
        )
    }

    /// Parse a track from album view
    private static func parseTrackFromAlbum(_ item: [String: Any], trackNumber: Int) -> YTMusicTrack? {
        guard let musicResponsiveListItemRenderer = item["musicResponsiveListItemRenderer"] as? [String: Any],
              let videoId = extractVideoId(musicResponsiveListItemRenderer),
              let title = extractTitle(musicResponsiveListItemRenderer)
        else {
            return nil
        }

        let thumbnails = extractThumbnails(musicResponsiveListItemRenderer)
        let (artists, _, duration) = parseTrackFlexColumns(musicResponsiveListItemRenderer)

        // Extract set video ID for queue operations
        var setVideoId: String?
        if let playlistItemData = musicResponsiveListItemRenderer["playlistItemData"] as? [String: Any] {
            setVideoId = playlistItemData["videoId"] as? String
        }

        return YTMusicTrack(
            videoId: videoId,
            title: title,
            artists: artists,
            album: nil,
            durationSeconds: parseDurationToSeconds(duration),
            duration: duration,
            thumbnails: thumbnails,
            isExplicit: extractIsExplicit(musicResponsiveListItemRenderer),
            isAvailable: true,
            feedbackTokens: nil,
            playCount: nil,
            trackNumber: trackNumber,
            setVideoId: setVideoId
        )
    }

    // MARK: - Library Parsing

    /// Parse library artists from browse response
    static func parseLibraryArtists(_ response: [String: Any]) -> [YTMusicArtist] {
        var artists: [YTMusicArtist] = []

        guard let contents = navigateToLibraryContents(response) else {
            return artists
        }

        for item in contents {
            if let musicResponsiveListItemRenderer = item["musicResponsiveListItemRenderer"] as? [String: Any],
               let artist = parseArtistFromSearch(musicResponsiveListItemRenderer)
            {
                artists.append(artist)
            }
        }

        return artists
    }

    /// Parse library albums from browse response
    static func parseLibraryAlbums(_ response: [String: Any]) -> [YTMusicAlbum] {
        var albums: [YTMusicAlbum] = []

        guard let contents = navigateToLibraryContents(response) else {
            return albums
        }

        for item in contents {
            if let musicTwoRowItemRenderer = item["musicTwoRowItemRenderer"] as? [String: Any] {
                if let album = parseAlbumFromTwoRowRenderer(musicTwoRowItemRenderer) {
                    albums.append(album)
                }
            } else if let musicResponsiveListItemRenderer = item["musicResponsiveListItemRenderer"] as? [String: Any],
                      let album = parseAlbumFromSearch(musicResponsiveListItemRenderer)
            {
                albums.append(album)
            }
        }

        return albums
    }

    /// Parse an album from two-row renderer (grid view)
    private static func parseAlbumFromTwoRowRenderer(_ renderer: [String: Any]) -> YTMusicAlbum? {
        guard let browseId = extractBrowseIdFromTwoRow(renderer),
              let title = extractTitleFromTwoRow(renderer)
        else {
            return nil
        }

        let thumbnails = extractThumbnailsFromRenderer(renderer)
        let subtitle = extractSubtitleFromTwoRow(renderer)
        let (artists, year, albumType) = parseAlbumSubtitle(subtitle)

        return YTMusicAlbum(
            id: browseId,
            title: title,
            type: albumType,
            artists: artists,
            year: year,
            trackCount: nil,
            duration: nil,
            thumbnails: thumbnails,
            isExplicit: false,
            playlistId: nil,
            audioPlaylistId: nil
        )
    }

    // MARK: - Helper Methods

    /// Navigate through nested JSON using a path
    private static func navigateToContents(_ json: [String: Any], path: [Any]) -> Any? {
        var current: Any = json

        for key in path {
            if let stringKey = key as? String, let dict = current as? [String: Any] {
                guard let next = dict[stringKey] else { return nil }
                current = next
            } else if let intKey = key as? Int, let array = current as? [Any] {
                guard intKey < array.count else { return nil }
                current = array[intKey]
            } else {
                return nil
            }
        }

        return current
    }

    /// Navigate to library contents (common structure)
    private static func navigateToLibraryContents(_ response: [String: Any]) -> [[String: Any]]? {
        if let contents = navigateToContents(response, path: [
            "contents",
            "singleColumnBrowseResultsRenderer",
            "tabs",
            0,
            "tabRenderer",
            "content",
            "sectionListRenderer",
            "contents",
            0,
            "musicShelfRenderer",
            "contents",
        ]) as? [[String: Any]] {
            return contents
        }

        // Try alternative grid layout
        if let contents = navigateToContents(response, path: [
            "contents",
            "singleColumnBrowseResultsRenderer",
            "tabs",
            0,
            "tabRenderer",
            "content",
            "sectionListRenderer",
            "contents",
            0,
            "gridRenderer",
            "items",
        ]) as? [[String: Any]] {
            return contents
        }

        return nil
    }

    /// Extract browse ID from a renderer
    private static func extractBrowseId(_ renderer: [String: Any]) -> String? {
        if let endpoint = renderer["navigationEndpoint"] as? [String: Any],
           let browseEndpoint = endpoint["browseEndpoint"] as? [String: Any],
           let browseId = browseEndpoint["browseId"] as? String
        {
            return browseId
        }
        return nil
    }

    /// Extract browse ID from two-row renderer
    private static func extractBrowseIdFromTwoRow(_ renderer: [String: Any]) -> String? {
        if let endpoint = renderer["navigationEndpoint"] as? [String: Any],
           let browseEndpoint = endpoint["browseEndpoint"] as? [String: Any],
           let browseId = browseEndpoint["browseId"] as? String
        {
            return browseId
        }
        return nil
    }

    /// Extract page browse ID from response
    private static func extractPageBrowseId(_ response: [String: Any]) -> String? {
        if let responseContext = response["responseContext"] as? [String: Any],
           let serviceTrackingParams = responseContext["serviceTrackingParams"] as? [[String: Any]]
        {
            for params in serviceTrackingParams {
                if let paramsArray = params["params"] as? [[String: Any]] {
                    for param in paramsArray {
                        if param["key"] as? String == "browse_id",
                           let value = param["value"] as? String
                        {
                            return value
                        }
                    }
                }
            }
        }
        return nil
    }

    /// Extract video ID from a renderer
    private static func extractVideoId(_ renderer: [String: Any]) -> String? {
        if let endpoint = renderer["overlay"] as? [String: Any],
           let musicItemThumbnailOverlayRenderer = endpoint["musicItemThumbnailOverlayRenderer"] as? [String: Any],
           let content = musicItemThumbnailOverlayRenderer["content"] as? [String: Any],
           let musicPlayButtonRenderer = content["musicPlayButtonRenderer"] as? [String: Any],
           let playNavigationEndpoint = musicPlayButtonRenderer["playNavigationEndpoint"] as? [String: Any],
           let watchEndpoint = playNavigationEndpoint["watchEndpoint"] as? [String: Any],
           let videoId = watchEndpoint["videoId"] as? String
        {
            return videoId
        }

        if let endpoint = renderer["navigationEndpoint"] as? [String: Any],
           let watchEndpoint = endpoint["watchEndpoint"] as? [String: Any],
           let videoId = watchEndpoint["videoId"] as? String
        {
            return videoId
        }

        if let playlistItemData = renderer["playlistItemData"] as? [String: Any],
           let videoId = playlistItemData["videoId"] as? String
        {
            return videoId
        }

        return nil
    }

    /// Extract title from a renderer
    private static func extractTitle(_ renderer: [String: Any]) -> String? {
        if let flexColumns = renderer["flexColumns"] as? [[String: Any]],
           let firstColumn = flexColumns.first,
           let musicResponsiveListItemFlexColumnRenderer = firstColumn[
               "musicResponsiveListItemFlexColumnRenderer"
           ] as? [String: Any],
           let text = musicResponsiveListItemFlexColumnRenderer["text"] as? [String: Any],
           let runs = text["runs"] as? [[String: Any]],
           let title = runs.first?["text"] as? String
        {
            return title
        }
        return nil
    }

    /// Extract title from two-row renderer
    private static func extractTitleFromTwoRow(_ renderer: [String: Any]) -> String? {
        if let title = renderer["title"] as? [String: Any],
           let runs = title["runs"] as? [[String: Any]],
           let text = runs.first?["text"] as? String
        {
            return text
        }
        return nil
    }

    /// Extract subtitle from a renderer
    private static func extractSubtitle(_ renderer: [String: Any]) -> String? {
        if let flexColumns = renderer["flexColumns"] as? [[String: Any]],
           flexColumns.count > 1,
           let secondColumn = flexColumns[safe: 1],
           let musicResponsiveListItemFlexColumnRenderer = secondColumn[
               "musicResponsiveListItemFlexColumnRenderer"
           ] as? [String: Any],
           let text = musicResponsiveListItemFlexColumnRenderer["text"] as? [String: Any],
           let runs = text["runs"] as? [[String: Any]]
        {
            return runs.compactMap { $0["text"] as? String }.joined()
        }
        return nil
    }

    /// Extract subtitle from two-row renderer
    private static func extractSubtitleFromTwoRow(_ renderer: [String: Any]) -> String? {
        if let subtitle = renderer["subtitle"] as? [String: Any],
           let runs = subtitle["runs"] as? [[String: Any]]
        {
            return runs.compactMap { $0["text"] as? String }.joined()
        }
        return nil
    }

    /// Extract text from a flex column
    private static func extractTextFromFlexColumn(_ column: [String: Any]) -> String? {
        if let musicResponsiveListItemFlexColumnRenderer = column[
            "musicResponsiveListItemFlexColumnRenderer"
        ] as? [String: Any],
            let text = musicResponsiveListItemFlexColumnRenderer["text"] as? [String: Any],
            let runs = text["runs"] as? [[String: Any]]
        {
            return runs.compactMap { $0["text"] as? String }.joined()
        }
        return nil
    }

    /// Extract thumbnails from a renderer
    private static func extractThumbnails(_ renderer: [String: Any]) -> [YTMusicThumbnail] {
        if let thumbnail = renderer["thumbnail"] as? [String: Any] {
            return extractThumbnailsFromRenderer(thumbnail)
        }
        return []
    }

    /// Extract thumbnails from any renderer with thumbnail data
    private static func extractThumbnailsFromRenderer(_ renderer: [String: Any]) -> [YTMusicThumbnail] {
        var thumbnails: [YTMusicThumbnail] = []

        let thumbnailContainer: [String: Any]?
        if let musicThumbnailRenderer = renderer["musicThumbnailRenderer"] as? [String: Any] {
            thumbnailContainer = musicThumbnailRenderer["thumbnail"] as? [String: Any]
        } else if let thumbnail = renderer["thumbnail"] as? [String: Any],
                  let musicThumbnailRenderer = thumbnail["musicThumbnailRenderer"] as? [String: Any]
        {
            thumbnailContainer = musicThumbnailRenderer["thumbnail"] as? [String: Any]
        } else {
            thumbnailContainer = renderer["thumbnail"] as? [String: Any]
        }

        guard let container = thumbnailContainer,
              let thumbs = container["thumbnails"] as? [[String: Any]]
        else {
            return thumbnails
        }

        for thumb in thumbs {
            guard let urlString = thumb["url"] as? String,
                  let url = URL(string: urlString),
                  let width = thumb["width"] as? Int,
                  let height = thumb["height"] as? Int
            else {
                continue
            }

            thumbnails.append(YTMusicThumbnail(url: url, width: width, height: height))
        }

        return thumbnails
    }

    /// Extract subscriber count from header
    private static func extractSubscriberCount(_ header: [String: Any]) -> String? {
        if let subscriptionButton = header["subscriptionButton"] as? [String: Any],
           let subscriberCountText = subscriptionButton["subscriberCountText"] as? [String: Any],
           let runs = subscriberCountText["runs"] as? [[String: Any]],
           let count = runs.first?["text"] as? String
        {
            return count
        }
        return nil
    }

    /// Extract description from header
    private static func extractDescription(_ header: [String: Any]) -> String? {
        if let description = header["description"] as? [String: Any],
           let runs = description["runs"] as? [[String: Any]]
        {
            return runs.compactMap { $0["text"] as? String }.joined()
        }
        return nil
    }

    /// Check if item is marked as explicit
    private static func extractIsExplicit(_ renderer: [String: Any]) -> Bool {
        if let badges = renderer["badges"] as? [[String: Any]] {
            for badge in badges {
                if let musicInlineBadgeRenderer = badge["musicInlineBadgeRenderer"] as? [String: Any],
                   let accessibilityData = musicInlineBadgeRenderer["accessibilityData"] as? [String: Any],
                   let accessibilityLabel = accessibilityData["accessibilityData"] as? [String: Any],
                   let label = accessibilityLabel["label"] as? String,
                   label.lowercased().contains("explicit")
                {
                    return true
                }
            }
        }
        return false
    }

    /// Parse album subtitle into components
    private static func parseAlbumSubtitle(_ subtitle: String?) -> (
        artists: [YTMusicArtistRef],
        year: String?,
        type: YTMusicAlbumType
    ) {
        guard let subtitle = subtitle else {
            return ([], nil, .unknown)
        }

        var artists: [YTMusicArtistRef] = []
        var year: String?
        var type: YTMusicAlbumType = .unknown

        let parts = subtitle.components(separatedBy: " • ")
        for part in parts {
            let trimmed = part.trimmingCharacters(in: .whitespaces)

            if ["Album", "Single", "EP"].contains(trimmed) {
                type = YTMusicAlbumType(from: trimmed)
            } else if let yearInt = Int(trimmed), yearInt > 1900, yearInt < 2100 {
                year = trimmed
            } else if !trimmed.isEmpty {
                // Assume it's an artist name (no ID available in subtitle)
                artists.append(YTMusicArtistRef(id: nil, name: trimmed))
            }
        }

        return (artists, year, type)
    }

    /// Parse track flex columns for artist, album, and duration
    private static func parseTrackFlexColumns(_ renderer: [String: Any]) -> (
        artists: [YTMusicArtistRef],
        album: YTMusicAlbumRef?,
        duration: String?
    ) {
        var artists: [YTMusicArtistRef] = []
        var album: YTMusicAlbumRef?
        var duration: String?

        guard let flexColumns = renderer["flexColumns"] as? [[String: Any]] else {
            return (artists, album, duration)
        }

        // Second column usually has artist • album • duration
        if flexColumns.count > 1,
           let column = flexColumns[safe: 1],
           let columnRenderer = column["musicResponsiveListItemFlexColumnRenderer"] as? [String: Any],
           let text = columnRenderer["text"] as? [String: Any],
           let runs = text["runs"] as? [[String: Any]]
        {
            for run in runs {
                guard let runText = run["text"] as? String else { continue }

                if let endpoint = run["navigationEndpoint"] as? [String: Any] {
                    if let browseEndpoint = endpoint["browseEndpoint"] as? [String: Any],
                       let browseId = browseEndpoint["browseId"] as? String
                    {
                        if browseId.hasPrefix("UC") {
                            artists.append(YTMusicArtistRef(id: browseId, name: runText))
                        } else if browseId.hasPrefix("MPREb") {
                            album = YTMusicAlbumRef(id: browseId, name: runText)
                        }
                    }
                } else if runText.contains(":") && runText.count <= 8 {
                    // Likely a duration (e.g., "3:45")
                    duration = runText
                }
            }
        }

        // Fixed column might have duration
        if let fixedColumns = renderer["fixedColumns"] as? [[String: Any]],
           let column = fixedColumns.first,
           let columnRenderer = column["musicResponsiveListItemFixedColumnRenderer"] as? [String: Any],
           let text = columnRenderer["text"] as? [String: Any],
           let runs = text["runs"] as? [[String: Any]],
           let runText = runs.first?["text"] as? String
        {
            if runText.contains(":") {
                duration = runText
            }
        }

        return (artists, album, duration)
    }

    /// Parse duration string to seconds
    private static func parseDurationToSeconds(_ duration: String?) -> Int? {
        guard let duration = duration else { return nil }

        let parts = duration.components(separatedBy: ":").compactMap { Int($0) }

        switch parts.count {
        case 2:
            return parts[0] * 60 + parts[1]
        case 3:
            return parts[0] * 3600 + parts[1] * 60 + parts[2]
        default:
            return nil
        }
    }
}

// MARK: - Array Safe Subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
