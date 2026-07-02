//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import Logging

/// Extension providing typed library access methods for YTMusicClient
extension YTMusicClient {

    // MARK: - Library Access (Typed Responses)

    /// Get user's subscribed artists with parsed results
    func fetchLibraryArtists(limit: Int = 25) async throws -> [YTMusicArtist] {
        guard auth.isAuthenticated else {
            throw YTMusicError.notAuthenticated
        }

        let response = try await getLibraryArtists(limit: limit)
        return YTMusicResponseParser.parseLibraryArtists(response)
    }

    /// Get user's saved albums with parsed results
    func fetchLibraryAlbums(limit: Int = 25) async throws -> [YTMusicAlbum] {
        guard auth.isAuthenticated else {
            throw YTMusicError.notAuthenticated
        }

        let response = try await getLibraryAlbums(limit: limit)
        return YTMusicResponseParser.parseLibraryAlbums(response)
    }

    /// Get user's liked songs playlist
    func fetchLikedSongs() async throws -> [YTMusicTrack] {
        guard auth.isAuthenticated else {
            throw YTMusicError.notAuthenticated
        }

        let response = try await getLikedSongs()
        return parseLikedSongsResponse(response)
    }

    /// Get user's play history
    func fetchHistory(limit: Int = 50) async throws -> [YTMusicTrack] {
        guard auth.isAuthenticated else {
            throw YTMusicError.notAuthenticated
        }

        let response = try await getHistory()
        return parseHistoryResponse(response)
    }

    /// Get user's playlists
    func fetchLibraryPlaylists(limit: Int = 25) async throws -> [YTMusicPlaylist] {
        guard auth.isAuthenticated else {
            throw YTMusicError.notAuthenticated
        }

        let response = try await browse(browseId: "FEmusic_liked_playlists")
        return parseLibraryPlaylistsResponse(response)
    }

    // MARK: - Browse Access (Typed Responses)

    /// Get artist details with parsed results
    func fetchArtist(id: String) async throws -> YTMusicArtist {
        let response = try await getArtist(artistId: id)

        guard let artist = YTMusicResponseParser.parseArtistDetails(response) else {
            throw YTMusicError.notFound(resourceType: "Artist")
        }

        return artist
    }

    /// Get album details with parsed results
    func fetchAlbum(id: String) async throws -> (album: YTMusicAlbum, tracks: [YTMusicTrack]) {
        let response = try await getAlbum(albumId: id)

        guard let album = YTMusicResponseParser.parseAlbumDetails(response) else {
            throw YTMusicError.notFound(resourceType: "Album")
        }

        let tracks = YTMusicResponseParser.parseAlbumTracks(response)

        return (album, tracks)
    }

    /// Get artist's albums (discography)
    func fetchArtistAlbums(artistId: String) async throws -> [YTMusicAlbum] {
        let response = try await getArtist(artistId: artistId)
        return parseArtistAlbumsResponse(response)
    }

    // MARK: - Search (Typed Responses)

    /// Search for artists with parsed results
    func searchForArtists(query: String, limit: Int = 20) async throws -> [YTMusicArtist] {
        let response = try await searchArtists(query: query, limit: limit)
        return parseSearchResultsAsArtists(response)
    }

    /// Search for albums with parsed results
    func searchForAlbums(query: String, limit: Int = 20) async throws -> [YTMusicAlbum] {
        let response = try await searchAlbums(query: query, limit: limit)
        return parseSearchResultsAsAlbums(response)
    }

    /// Search for tracks with parsed results
    func searchForTracks(query: String, limit: Int = 20) async throws -> [YTMusicTrack] {
        let response = try await searchSongs(query: query, limit: limit)
        return parseSearchResultsAsTracks(response)
    }

    // MARK: - Private Parsing Helpers

    /// Parse liked songs response
    private func parseLikedSongsResponse(_ response: [String: Any]) -> [YTMusicTrack] {
        var tracks: [YTMusicTrack] = []

        guard let contents = navigateToPlaylistContents(response) else {
            return tracks
        }

        for item in contents {
            if let track = parseTrackFromPlaylistItem(item) {
                tracks.append(track)
            }
        }

        return tracks
    }

    /// Parse history response
    private func parseHistoryResponse(_ response: [String: Any]) -> [YTMusicTrack] {
        var tracks: [YTMusicTrack] = []

        // History uses a different structure - items are grouped by date
        guard let contents = navigateToHistoryContents(response) else {
            return tracks
        }

        for section in contents {
            if let musicShelfRenderer = section["musicShelfRenderer"] as? [String: Any],
               let shelfContents = musicShelfRenderer["contents"] as? [[String: Any]]
            {
                for item in shelfContents {
                    if let track = parseTrackFromPlaylistItem(item) {
                        tracks.append(track)
                    }
                }
            }
        }

        return tracks
    }

    /// Parse library playlists response
    private func parseLibraryPlaylistsResponse(_ response: [String: Any]) -> [YTMusicPlaylist] {
        var playlists: [YTMusicPlaylist] = []

        guard let contents = navigateToGridContents(response) else {
            return playlists
        }

        for item in contents {
            if let musicTwoRowItemRenderer = item["musicTwoRowItemRenderer"] as? [String: Any],
               let playlist = parsePlaylistFromTwoRowRenderer(musicTwoRowItemRenderer)
            {
                playlists.append(playlist)
            }
        }

        return playlists
    }

    /// Parse artist albums from artist response
    private func parseArtistAlbumsResponse(_ response: [String: Any]) -> [YTMusicAlbum] {
        var albums: [YTMusicAlbum] = []

        guard let contents = navigateToArtistContents(response) else {
            return albums
        }

        for section in contents {
            // Look for album/single sections
            if let musicCarouselShelfRenderer = section["musicCarouselShelfRenderer"] as? [String: Any],
               let carouselContents = musicCarouselShelfRenderer["contents"] as? [[String: Any]]
            {
                for item in carouselContents {
                    if let musicTwoRowItemRenderer = item["musicTwoRowItemRenderer"] as? [String: Any],
                       let album = parseAlbumFromCarouselItem(musicTwoRowItemRenderer)
                    {
                        albums.append(album)
                    }
                }
            }
        }

        return albums
    }

    /// Parse search results as artists
    private func parseSearchResultsAsArtists(_ response: [String: Any]) -> [YTMusicArtist] {
        let results = YTMusicResponseParser.parseSearchResults(response)
        return results.compactMap { $0 as? YTMusicArtist }
    }

    /// Parse search results as albums
    private func parseSearchResultsAsAlbums(_ response: [String: Any]) -> [YTMusicAlbum] {
        let results = YTMusicResponseParser.parseSearchResults(response)
        return results.compactMap { $0 as? YTMusicAlbum }
    }

    /// Parse search results as tracks
    private func parseSearchResultsAsTracks(_ response: [String: Any]) -> [YTMusicTrack] {
        let results = YTMusicResponseParser.parseSearchResults(response)
        return results.compactMap { $0 as? YTMusicTrack }
    }

    // MARK: - Navigation Helpers

    /// Navigate to playlist contents
    private func navigateToPlaylistContents(_ response: [String: Any]) -> [[String: Any]]? {
        if let contents = response["contents"] as? [String: Any],
           let singleColumnBrowseResultsRenderer = contents["singleColumnBrowseResultsRenderer"] as? [String: Any],
           let tabs = singleColumnBrowseResultsRenderer["tabs"] as? [[String: Any]],
           let tab = tabs.first,
           let tabRenderer = tab["tabRenderer"] as? [String: Any],
           let content = tabRenderer["content"] as? [String: Any],
           let sectionListRenderer = content["sectionListRenderer"] as? [String: Any],
           let sectionContents = sectionListRenderer["contents"] as? [[String: Any]],
           let section = sectionContents.first,
           let musicPlaylistShelfRenderer = section["musicPlaylistShelfRenderer"] as? [String: Any],
           let playlistContents = musicPlaylistShelfRenderer["contents"] as? [[String: Any]]
        {
            return playlistContents
        }

        // Alternative structure for some playlists
        if let contents = response["contents"] as? [String: Any],
           let singleColumnBrowseResultsRenderer = contents["singleColumnBrowseResultsRenderer"] as? [String: Any],
           let tabs = singleColumnBrowseResultsRenderer["tabs"] as? [[String: Any]],
           let tab = tabs.first,
           let tabRenderer = tab["tabRenderer"] as? [String: Any],
           let content = tabRenderer["content"] as? [String: Any],
           let sectionListRenderer = content["sectionListRenderer"] as? [String: Any],
           let sectionContents = sectionListRenderer["contents"] as? [[String: Any]],
           let section = sectionContents.first,
           let musicShelfRenderer = section["musicShelfRenderer"] as? [String: Any],
           let shelfContents = musicShelfRenderer["contents"] as? [[String: Any]]
        {
            return shelfContents
        }

        return nil
    }

    /// Navigate to history contents
    private func navigateToHistoryContents(_ response: [String: Any]) -> [[String: Any]]? {
        if let contents = response["contents"] as? [String: Any],
           let singleColumnBrowseResultsRenderer = contents["singleColumnBrowseResultsRenderer"] as? [String: Any],
           let tabs = singleColumnBrowseResultsRenderer["tabs"] as? [[String: Any]],
           let tab = tabs.first,
           let tabRenderer = tab["tabRenderer"] as? [String: Any],
           let content = tabRenderer["content"] as? [String: Any],
           let sectionListRenderer = content["sectionListRenderer"] as? [String: Any],
           let sectionContents = sectionListRenderer["contents"] as? [[String: Any]]
        {
            return sectionContents
        }
        return nil
    }

    /// Navigate to grid contents (for library playlists)
    private func navigateToGridContents(_ response: [String: Any]) -> [[String: Any]]? {
        if let contents = response["contents"] as? [String: Any],
           let singleColumnBrowseResultsRenderer = contents["singleColumnBrowseResultsRenderer"] as? [String: Any],
           let tabs = singleColumnBrowseResultsRenderer["tabs"] as? [[String: Any]],
           let tab = tabs.first,
           let tabRenderer = tab["tabRenderer"] as? [String: Any],
           let content = tabRenderer["content"] as? [String: Any],
           let sectionListRenderer = content["sectionListRenderer"] as? [String: Any],
           let sectionContents = sectionListRenderer["contents"] as? [[String: Any]],
           let section = sectionContents.first,
           let gridRenderer = section["gridRenderer"] as? [String: Any],
           let items = gridRenderer["items"] as? [[String: Any]]
        {
            return items
        }
        return nil
    }

    /// Navigate to artist page contents
    private func navigateToArtistContents(_ response: [String: Any]) -> [[String: Any]]? {
        if let contents = response["contents"] as? [String: Any],
           let singleColumnBrowseResultsRenderer = contents["singleColumnBrowseResultsRenderer"] as? [String: Any],
           let tabs = singleColumnBrowseResultsRenderer["tabs"] as? [[String: Any]],
           let tab = tabs.first,
           let tabRenderer = tab["tabRenderer"] as? [String: Any],
           let content = tabRenderer["content"] as? [String: Any],
           let sectionListRenderer = content["sectionListRenderer"] as? [String: Any],
           let sectionContents = sectionListRenderer["contents"] as? [[String: Any]]
        {
            return sectionContents
        }
        return nil
    }

    // MARK: - Item Parsing Helpers

    /// Parse a track from playlist item
    private func parseTrackFromPlaylistItem(_ item: [String: Any]) -> YTMusicTrack? {
        guard let musicResponsiveListItemRenderer = item["musicResponsiveListItemRenderer"] as? [String: Any] else {
            return nil
        }

        // Extract video ID
        var videoId: String?
        if let playlistItemData = musicResponsiveListItemRenderer["playlistItemData"] as? [String: Any] {
            videoId = playlistItemData["videoId"] as? String
        }

        if videoId == nil {
            if let overlay = musicResponsiveListItemRenderer["overlay"] as? [String: Any],
               let thumbnailOverlay = overlay["musicItemThumbnailOverlayRenderer"] as? [String: Any],
               let content = thumbnailOverlay["content"] as? [String: Any],
               let playButton = content["musicPlayButtonRenderer"] as? [String: Any],
               let endpoint = playButton["playNavigationEndpoint"] as? [String: Any],
               let watchEndpoint = endpoint["watchEndpoint"] as? [String: Any]
            {
                videoId = watchEndpoint["videoId"] as? String
            }
        }

        guard let id = videoId else { return nil }

        // Extract title
        var title: String?
        if let flexColumns = musicResponsiveListItemRenderer["flexColumns"] as? [[String: Any]],
           let firstColumn = flexColumns.first,
           let columnRenderer = firstColumn["musicResponsiveListItemFlexColumnRenderer"] as? [String: Any],
           let text = columnRenderer["text"] as? [String: Any],
           let runs = text["runs"] as? [[String: Any]],
           let firstRun = runs.first
        {
            title = firstRun["text"] as? String
        }

        guard let trackTitle = title else { return nil }

        // Extract artist and album from second column
        var artists: [YTMusicArtistRef] = []
        var album: YTMusicAlbumRef?
        var duration: String?

        if let flexColumns = musicResponsiveListItemRenderer["flexColumns"] as? [[String: Any]],
           flexColumns.count > 1,
           let secondColumn = flexColumns[1]["musicResponsiveListItemFlexColumnRenderer"] as? [String: Any],
           let text = secondColumn["text"] as? [String: Any],
           let runs = text["runs"] as? [[String: Any]]
        {
            for run in runs {
                guard let runText = run["text"] as? String else { continue }

                if let endpoint = run["navigationEndpoint"] as? [String: Any],
                   let browseEndpoint = endpoint["browseEndpoint"] as? [String: Any],
                   let browseId = browseEndpoint["browseId"] as? String
                {
                    if browseId.hasPrefix("UC") {
                        artists.append(YTMusicArtistRef(id: browseId, name: runText))
                    } else if browseId.hasPrefix("MPREb") {
                        album = YTMusicAlbumRef(id: browseId, name: runText)
                    }
                }
            }
        }

        // Extract duration from fixed column
        if let fixedColumns = musicResponsiveListItemRenderer["fixedColumns"] as? [[String: Any]],
           let firstFixed = fixedColumns.first,
           let columnRenderer = firstFixed["musicResponsiveListItemFixedColumnRenderer"] as? [String: Any],
           let text = columnRenderer["text"] as? [String: Any],
           let runs = text["runs"] as? [[String: Any]],
           let firstRun = runs.first,
           let durationText = firstRun["text"] as? String
        {
            duration = durationText
        }

        // Extract thumbnails
        var thumbnails: [YTMusicThumbnail] = []
        if let thumbnail = musicResponsiveListItemRenderer["thumbnail"] as? [String: Any],
           let musicThumbnailRenderer = thumbnail["musicThumbnailRenderer"] as? [String: Any],
           let thumbContainer = musicThumbnailRenderer["thumbnail"] as? [String: Any],
           let thumbs = thumbContainer["thumbnails"] as? [[String: Any]]
        {
            for thumb in thumbs {
                if let urlString = thumb["url"] as? String,
                   let url = URL(string: urlString),
                   let width = thumb["width"] as? Int,
                   let height = thumb["height"] as? Int
                {
                    thumbnails.append(YTMusicThumbnail(url: url, width: width, height: height))
                }
            }
        }

        // Check for explicit badge
        var isExplicit = false
        if let badges = musicResponsiveListItemRenderer["badges"] as? [[String: Any]] {
            for badge in badges {
                if let inlineBadge = badge["musicInlineBadgeRenderer"] as? [String: Any],
                   let accessibilityData = inlineBadge["accessibilityData"] as? [String: Any],
                   let labelData = accessibilityData["accessibilityData"] as? [String: Any],
                   let label = labelData["label"] as? String,
                   label.lowercased().contains("explicit")
                {
                    isExplicit = true
                    break
                }
            }
        }

        return YTMusicTrack(
            videoId: id,
            title: trackTitle,
            artists: artists,
            album: album,
            durationSeconds: parseDuration(duration),
            duration: duration,
            thumbnails: thumbnails,
            isExplicit: isExplicit,
            isAvailable: true,
            feedbackTokens: nil,
            playCount: nil,
            trackNumber: nil,
            setVideoId: nil
        )
    }

    /// Parse playlist from two-row renderer
    private func parsePlaylistFromTwoRowRenderer(_ renderer: [String: Any]) -> YTMusicPlaylist? {
        // Extract browse ID
        var playlistId: String?
        if let endpoint = renderer["navigationEndpoint"] as? [String: Any],
           let browseEndpoint = endpoint["browseEndpoint"] as? [String: Any],
           let browseId = browseEndpoint["browseId"] as? String
        {
            playlistId = browseId
        }

        guard let id = playlistId else { return nil }

        // Extract title
        var title: String?
        if let titleContainer = renderer["title"] as? [String: Any],
           let runs = titleContainer["runs"] as? [[String: Any]],
           let firstRun = runs.first
        {
            title = firstRun["text"] as? String
        }

        guard let playlistTitle = title else { return nil }

        // Extract thumbnails
        var thumbnails: [YTMusicThumbnail] = []
        if let thumbnailRenderer = renderer["thumbnailRenderer"] as? [String: Any],
           let musicThumbnailRenderer = thumbnailRenderer["musicThumbnailRenderer"] as? [String: Any],
           let thumbnail = musicThumbnailRenderer["thumbnail"] as? [String: Any],
           let thumbs = thumbnail["thumbnails"] as? [[String: Any]]
        {
            for thumb in thumbs {
                if let urlString = thumb["url"] as? String,
                   let url = URL(string: urlString),
                   let width = thumb["width"] as? Int,
                   let height = thumb["height"] as? Int
                {
                    thumbnails.append(YTMusicThumbnail(url: url, width: width, height: height))
                }
            }
        }

        // Extract subtitle info
        var trackCount: Int?
        var author: YTMusicArtistRef?

        if let subtitle = renderer["subtitle"] as? [String: Any],
           let runs = subtitle["runs"] as? [[String: Any]]
        {
            for run in runs {
                guard let text = run["text"] as? String else { continue }

                if text.contains("song") || text.contains("track") {
                    let numbers = text.components(separatedBy: CharacterSet.decimalDigits.inverted)
                        .compactMap { Int($0) }
                    if let count = numbers.first {
                        trackCount = count
                    }
                } else if let endpoint = run["navigationEndpoint"] as? [String: Any],
                          let browseEndpoint = endpoint["browseEndpoint"] as? [String: Any],
                          let authorId = browseEndpoint["browseId"] as? String
                {
                    author = YTMusicArtistRef(id: authorId, name: text)
                }
            }
        }

        return YTMusicPlaylist(
            id: id,
            title: playlistTitle,
            description: nil,
            trackCount: trackCount,
            thumbnails: thumbnails,
            author: author,
            privacy: .unknown,
            duration: nil,
            year: nil,
            isAutoGenerated: false,
            isEditable: false
        )
    }

    /// Parse album from carousel item (artist page)
    private func parseAlbumFromCarouselItem(_ renderer: [String: Any]) -> YTMusicAlbum? {
        // Extract browse ID
        var albumId: String?
        if let endpoint = renderer["navigationEndpoint"] as? [String: Any],
           let browseEndpoint = endpoint["browseEndpoint"] as? [String: Any],
           let browseId = browseEndpoint["browseId"] as? String
        {
            albumId = browseId
        }

        guard let id = albumId else { return nil }

        // Extract title
        var title: String?
        if let titleContainer = renderer["title"] as? [String: Any],
           let runs = titleContainer["runs"] as? [[String: Any]],
           let firstRun = runs.first
        {
            title = firstRun["text"] as? String
        }

        guard let albumTitle = title else { return nil }

        // Extract thumbnails
        var thumbnails: [YTMusicThumbnail] = []
        if let thumbnailRenderer = renderer["thumbnailRenderer"] as? [String: Any],
           let musicThumbnailRenderer = thumbnailRenderer["musicThumbnailRenderer"] as? [String: Any],
           let thumbnail = musicThumbnailRenderer["thumbnail"] as? [String: Any],
           let thumbs = thumbnail["thumbnails"] as? [[String: Any]]
        {
            for thumb in thumbs {
                if let urlString = thumb["url"] as? String,
                   let url = URL(string: urlString),
                   let width = thumb["width"] as? Int,
                   let height = thumb["height"] as? Int
                {
                    thumbnails.append(YTMusicThumbnail(url: url, width: width, height: height))
                }
            }
        }

        // Extract subtitle (type • year)
        var albumType: YTMusicAlbumType = .unknown
        var year: String?

        if let subtitle = renderer["subtitle"] as? [String: Any],
           let runs = subtitle["runs"] as? [[String: Any]]
        {
            for run in runs {
                guard let text = run["text"] as? String else { continue }

                if ["Album", "Single", "EP"].contains(text) {
                    albumType = YTMusicAlbumType(from: text)
                } else if let yearInt = Int(text), yearInt > 1900, yearInt < 2100 {
                    year = text
                }
            }
        }

        return YTMusicAlbum(
            id: id,
            title: albumTitle,
            type: albumType,
            artists: [],
            year: year,
            trackCount: nil,
            duration: nil,
            thumbnails: thumbnails,
            isExplicit: false,
            playlistId: nil,
            audioPlaylistId: nil
        )
    }

    /// Parse duration string to seconds
    private func parseDuration(_ duration: String?) -> Int? {
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
