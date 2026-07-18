//
// WatermelonFin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

@MainActor
final class PlaylistPickerViewModel: ViewModel {

    @Published
    private(set) var isLoading = false
    @Published
    private(set) var isSaving = false
    @Published
    private(set) var playlists: [BaseItemDto] = []
    @Published
    var error: Error?

    private let itemID: String

    init(itemID: String) {
        self.itemID = itemID
        super.init()
    }

    func loadPlaylists() async {
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let session = try requireSession()
            var parameters = Paths.GetItemsParameters()
            parameters.userID = session.user.id
            parameters.includeItemTypes = [.playlist]
            parameters.mediaTypes = [.video]
            parameters.isRecursive = true
            parameters.fields = .MinimumFields

            let response = try await session.client.send(Paths.getItems(parameters: parameters))
            playlists = (response.value.items ?? []).sorted {
                $0.displayTitle.localizedCaseInsensitiveCompare($1.displayTitle) == .orderedAscending
            }
        } catch {
            self.error = error
        }
    }

    func add(to playlist: BaseItemDto) async -> Bool {
        guard let playlistID = playlist.id else {
            error = ErrorMessage(L10n.unknownError)
            return false
        }

        return await performSave {
            let session = try requireSession()
            let request = Paths.addItemToPlaylist(
                playlistID: playlistID,
                ids: [itemID],
                userID: session.user.id
            )
            _ = try await session.client.send(request)
        }
    }

    func createPlaylist(named name: String) async -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedName.isNotEmpty else { return false }

        return await performSave {
            let session = try requireSession()
            let body = CreatePlaylistDto(
                ids: [itemID],
                isPublic: false,
                mediaType: .video,
                name: trimmedName,
                userID: session.user.id
            )
            let response = try await session.client.send(Paths.createPlaylist(body))
            guard response.value.id != nil else {
                throw ErrorMessage(L10n.unknownError)
            }
        }
    }

    private func performSave(_ operation: () async throws -> Void) async -> Bool {
        guard !isSaving else { return false }

        isSaving = true
        defer { isSaving = false }

        do {
            try await operation()
            return true
        } catch {
            self.error = error
            return false
        }
    }
}
