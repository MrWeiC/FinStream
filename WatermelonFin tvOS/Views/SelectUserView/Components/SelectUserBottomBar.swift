//
// WatermelonFin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import OrderedCollections
import SwiftUI

extension SelectUserView {

    struct SelectUserBottomBar: View {

        // MARK: - State & Environment Objects

        @Router
        private var router

        @Binding
        private var isEditing: Bool

        @Binding
        private var serverSelection: SelectUserServerSelection

        private let focusedItem: FocusState<SelectUserView.BottomBarItem?>.Binding

        // MARK: - Variables

        private let areUsersSelected: Bool
        private let hasUsers: Bool
        private let selectedServer: ServerState?
        private let servers: OrderedSet<ServerState>

        private let onAddUser: (ServerState) -> Void
        private let onDelete: () -> Void
        private let toggleAllUsersSelected: () -> Void
        private let onMoveUp: () -> Void

        // MARK: - Initializer

        init(
            isEditing: Binding<Bool>,
            serverSelection: Binding<SelectUserServerSelection>,
            focusedItem: FocusState<SelectUserView.BottomBarItem?>.Binding,
            selectedServer: ServerState?,
            servers: OrderedSet<ServerState>,
            areUsersSelected: Bool,
            hasUsers: Bool,
            onAddUser: @escaping (ServerState) -> Void,
            onDelete: @escaping () -> Void,
            toggleAllUsersSelected: @escaping () -> Void,
            onMoveUp: @escaping () -> Void
        ) {
            self._isEditing = isEditing
            self._serverSelection = serverSelection
            self.focusedItem = focusedItem
            self.areUsersSelected = areUsersSelected
            self.hasUsers = hasUsers
            self.selectedServer = selectedServer
            self.servers = servers
            self.onAddUser = onAddUser
            self.onDelete = onDelete
            self.toggleAllUsersSelected = toggleAllUsersSelected
            self.onMoveUp = onMoveUp
        }

        // MARK: - Advanced Menu

        private var advancedMenu: some View {
            Menu {
                if hasUsers {
                    Button(L10n.editUsers, systemImage: "person.crop.circle") {
                        isEditing.toggle()
                    }

                    Divider()
                }

                if let selectedServer {
                    Button(L10n.editServer, systemImage: "server.rack") {
                        router.route(to: .editServer(server: selectedServer, isEditing: true))
                    }
                }

                Button(L10n.addServer, systemImage: "plus") {
                    router.route(to: .connectToServer)
                }

                Divider()

                Button(L10n.advanced, systemImage: "gearshape.fill") {
                    router.route(to: .appSettings)
                }
            } label: {
                Label(L10n.advanced, systemImage: "gearshape.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.primary)
                    .labelStyle(.iconOnly)
                    .frame(width: 50, height: 50)
            }
            .focused(focusedItem, equals: .advanced)

            // TODO: Do we want to support a grid view and list view like iOS?
//            if !viewModel.servers.isEmpty {
//                Picker(selection: $userListDisplayType) {
//                    ForEach(LibraryDisplayType.allCases, id: \.hashValue) {
//                        Label($0.displayTitle, systemImage: $0.systemImage)
//                            .tag($0)
//                    }
//                } label: {
//                    Text(L10n.layout)
//                    Text(userListDisplayType.displayTitle)
//                    Image(systemName: userListDisplayType.systemImage)
//                }
//                .pickerStyle(.menu)
//            }
        }

        // MARK: - Delete User Button

        private var deleteUsersButton: some View {
            Button(
                L10n.delete,
                role: .destructive,
                action: onDelete
            )
            .buttonStyle(.primary)
            .frame(width: 300, height: 64)
            .disabled(!areUsersSelected)
        }

        // MARK: - Content View

        private var contentView: some View {
            HStack(alignment: .top, spacing: 18) {
                if isEditing {
                    deleteUsersButton

                    Button {
                        toggleAllUsersSelected()
                    } label: {
                        Text(areUsersSelected ? L10n.deselectAll : L10n.selectAll)
                            .foregroundStyle(Color.primary)
                            .font(.body.weight(.semibold))
                            .frame(width: 220, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    Button {
                        isEditing = false
                    } label: {
                        Text(L10n.cancel)
                            .foregroundStyle(Color.primary)
                            .font(.body.weight(.semibold))
                            .frame(width: 220, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                } else {
                    if hasUsers {
                        AddUserBottomButton(
                            selectedServer: selectedServer,
                            servers: servers
                        ) { server in
                            onAddUser(server)
                        }
                        .focused(focusedItem, equals: .addUser)
                    }

                    ServerSelectionMenu(
                        selection: $serverSelection,
                        selectedServer: selectedServer,
                        servers: servers
                    )
                    .focused(focusedItem, equals: .serverSelection)

                    advancedMenu
                }
            }
        }

        // MARK: - Body

        var body: some View {
            // `Menu` with custom label has some weird additional
            // frame/padding that differs from default label style
            AlternateLayoutView(alignment: .top) {
                Color.clear
                    .frame(height: 100)
            } content: {
                contentView
            }
            .onMoveCommand { direction in
                if direction == .up, hasUsers, !isEditing {
                    onMoveUp()
                }
            }
        }
    }
}
