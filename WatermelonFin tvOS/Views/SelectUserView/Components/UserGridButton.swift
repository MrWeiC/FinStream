//
// WatermelonFin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension SelectUserView {

    struct UserGridButton: View {

        private static let profileImageSize: CGFloat = 220
        private static let selectedBadgeSize: CGFloat = 56

        @Default(.accentColor)
        private var accentColor

        @Environment(\.isEditing)
        private var isEditing
        @Environment(\.isSelected)
        private var isSelected

        private let user: UserState
        private let server: ServerState
        private let showServer: Bool
        private let focusedUserID: FocusState<String?>.Binding
        private let action: () -> Void
        private let onDelete: () -> Void

        // MARK: - Initializer

        init(
            user: UserState,
            server: ServerState,
            showServer: Bool,
            focusedUserID: FocusState<String?>.Binding,
            action: @escaping () -> Void,
            onDelete: @escaping () -> Void
        ) {
            self.user = user
            self.server = server
            self.showServer = showServer
            self.focusedUserID = focusedUserID
            self.action = action
            self.onDelete = onDelete
        }

        // MARK: - Label Foreground Style

        private var labelForegroundStyle: some ShapeStyle {
            guard isEditing else { return .primary }

            return isSelected ? .primary : .secondary
        }

        // MARK: - Body

        var body: some View {
            Button(action: action) {
                UserProfileImage(
                    userID: user.id,
                    source: user.profileImageSource(
                        client: server.client
                    ),
                    pipeline: .WatermelonFin.local
                )
                .frame(width: Self.profileImageSize, height: Self.profileImageSize)
                .overlay(alignment: .bottom) {
                    if isEditing && isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: Self.selectedBadgeSize, height: Self.selectedBadgeSize)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(accentColor.overlayColor, accentColor)
                    }
                }
                .hoverEffect(.highlight)

                Text(user.username)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(labelForegroundStyle)
                    .lineLimit(1)

                if showServer {
                    Text(server.name)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.borderless)
            .buttonBorderShape(.circle)
            .focused(focusedUserID, equals: user.id)
            .contextMenu {
                if !isEditing {
                    Button(
                        L10n.delete,
                        role: .destructive,
                        action: onDelete
                    )
                }
            }
        }
    }
}
