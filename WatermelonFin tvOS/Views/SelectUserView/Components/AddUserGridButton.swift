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

    struct AddUserGridButton: View {

        private static let buttonImageSize: CGFloat = 280

        @Environment(\.isEnabled)
        private var isEnabled

        let selectedServer: ServerState?
        let servers: OrderedSet<ServerState>
        let action: (ServerState) -> Void

        private var serverForSignIn: ServerState? {
            if let selectedServer {
                selectedServer
            } else if servers.count == 1 {
                servers.first
            } else {
                nil
            }
        }

        @ViewBuilder
        private var label: some View {
            ZStack {
                Color.secondarySystemFill

                RelativeSystemImageView(systemName: "plus")
                    .foregroundStyle(.secondary)
            }
            .clipShape(.circle)
            .aspectRatio(1, contentMode: .fill)
            .frame(width: Self.buttonImageSize, height: Self.buttonImageSize)
            .hoverEffect(.highlight)

            Text(L10n.addUser)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(isEnabled ? .primary : .secondary)

            if serverForSignIn == nil {
                // For layout, not to be localized
                Text("Hidden")
                    .font(.footnote)
                    .hidden()
            }
        }

        var body: some View {
            ConditionalMenu(
                tracking: serverForSignIn,
                action: action
            ) {
                Text(L10n.selectServerToSignIn)

                ForEach(servers) { server in
                    Button {
                        action(server)
                    } label: {
                        Text(server.name)
                        Text(server.currentURL.absoluteString)
                    }
                }
            } label: {
                label
            }
            .buttonStyle(.borderless)
            .buttonBorderShape(.circle)
            .accessibilityLabel(L10n.addUser)
        }
    }
}
