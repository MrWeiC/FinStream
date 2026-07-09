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

        private var label: some View {
            HStack(spacing: 22) {
                ZStack {
                    Circle()
                        .fill(Color.watermelonRed.overlayColor.opacity(0.18))

                    Image(systemName: "plus")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.watermelonRed.overlayColor)
                }
                .frame(width: 72, height: 72)

                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.addUser)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(isEnabled ? Color.watermelonRed.overlayColor : .secondary)

                    Text(serverForSignIn?.name ?? L10n.selectServerToSignIn)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(Color.watermelonRed.overlayColor.opacity(0.75))
                        .lineLimit(1)
                }

                Spacer(minLength: 24)

                Image(systemName: serverForSignIn == nil ? "chevron.down" : "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.watermelonRed.overlayColor.opacity(0.7))
            }
            .padding(.horizontal, 28)
            .frame(width: 620, height: 112)
            .background(Color.watermelonRed, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            }
            .hoverEffect(.highlight)
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
            .buttonBorderShape(.roundedRectangle(radius: 18))
            .accessibilityLabel(L10n.addUser)
        }
    }
}
