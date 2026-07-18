//
// WatermelonFin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct PlaylistPickerView: View {

    @Environment(\.dismiss)
    private var dismiss

    @StateObject
    private var viewModel: PlaylistPickerViewModel

    @State
    private var isPresentingCreatePlaylist = false
    @State
    private var newPlaylistName = ""

    init(itemID: String) {
        self._viewModel = StateObject(wrappedValue: PlaylistPickerViewModel(itemID: itemID))
    }

    var body: some View {
        NavigationStack {
            Form(systemImage: "rectangle.stack.badge.plus") {
                Section {
                    Button(PlaylistL10n.createPlaylist, systemImage: "plus") {
                        isPresentingCreatePlaylist = true
                    }
                }

                Section(PlaylistL10n.playlists) {
                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else if viewModel.playlists.isEmpty {
                        Text(PlaylistL10n.noVideoPlaylists)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.playlists, id: \.id) { playlist in
                            Button {
                                add(to: playlist)
                            } label: {
                                Label(playlist.displayTitle, systemImage: "rectangle.stack")
                            }
                            .disabled(viewModel.isSaving)
                        }
                    }
                }
            }
            .navigationTitle(PlaylistL10n.playlists)
            .task {
                await viewModel.loadPlaylists()
            }
            .alert(PlaylistL10n.createPlaylist, isPresented: $isPresentingCreatePlaylist) {
                Backport.textField(PlaylistL10n.playlist, text: $newPlaylistName)
                Button(L10n.add) {
                    createPlaylist()
                }
                .disabled(newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button(L10n.cancel, role: .cancel) {
                    newPlaylistName = ""
                }
            }
            .errorMessage($viewModel.error)
            .overlay {
                if viewModel.isSaving {
                    ZStack {
                        Color.black.opacity(0.35)
                            .ignoresSafeArea()
                        ProgressView()
                            .controlSize(.large)
                    }
                }
            }
        }
    }

    private func add(to playlist: BaseItemDto) {
        Task {
            if await viewModel.add(to: playlist) {
                dismiss()
            }
        }
    }

    private func createPlaylist() {
        let name = newPlaylistName
        newPlaylistName = ""

        Task {
            if await viewModel.createPlaylist(named: name) {
                dismiss()
            }
        }
    }
}
