//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct DiagnosticsView: View {

    @Router
    private var router

    @StateObject
    private var viewModel = SettingsViewModel()

    var body: some View {
        Form(systemImage: "wrench.and.screwdriver") {
            connectionSection

            #if DEBUG || !os(tvOS)
            logsSection
            #endif
        }
        .navigationTitle(L10n.diagnostics)
    }

    @ViewBuilder
    private var connectionSection: some View {
        if let session = viewModel.userSession {
            Section {
                LabeledContent(
                    L10n.name,
                    value: session.server.name
                )
                .focusable(false)

                LabeledContent(
                    L10n.currentServerAddress,
                    value: session.server.currentURL.absoluteString
                )
                .focusable(false)
            } header: {
                Text(L10n.server)
            } footer: {
                Text(L10n.diagnosticsDescription)
            }
        }
    }

    #if DEBUG || !os(tvOS)
    private var logsSection: some View {
        Section(L10n.advancedAndDiagnostics) {
            ChevronButton(
                L10n.advancedLogs,
                subtitle: L10n.advancedLogsDescription
            ) {
                router.route(to: .log)
            }
        }
    }
    #endif
}
