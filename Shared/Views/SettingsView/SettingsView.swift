//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import JellyfinAPI
import SwiftUI

struct SettingsView: View {

    @Router
    var router

    #if os(iOS)
    @Default(.userAppearance)
    private var appearance
    #endif

    @Default(.userAccentColor)
    private var accentColor

    @Default(.VideoPlayer.videoPlayerType)
    private var videoPlayerType

    @StateObject
    private var viewModel = SettingsViewModel()

    // MARK: - Body

    var body: some View {
        Form(image: .finstreamLogo) {
            accountAndServerSection
            videoPlayerSection
            mediaAndAppearanceSection
            diagnosticsSection
        }
        #if os(iOS)
        .navigationTitle(L10n.settings)
        .navigationBarCloseButton {
            router.dismiss()
        }
        #endif
    }

    // MARK: - Account and Server Section

    private var accountAndServerSection: some View {
        Section(L10n.accountAndServer) {
            UserProfileRow(user: viewModel.userSession!.user.data) {
                router.route(to: .userProfile(viewModel: viewModel))
            }

            ChevronButton(
                L10n.server,
                action: {
                    router.route(to: .editServer(server: viewModel.userSession!.server))
                }
            ) {
                EmptyView()
            } subtitle: {
                serverSubtitle
            }

            #if os(iOS)
            if viewModel.userSession!.user.permissions.isAdministrator {
                ChevronButton(L10n.dashboard) {
                    router.route(to: .adminDashboard)
                }
            }
            #endif

            Button {
                UIDevice.impact(.medium)
                viewModel.signOut()
                router.dismiss()
            } label: {
                Label(L10n.switchUser, systemImage: "person.2")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.primary)
        }
    }

    private var serverSubtitle: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Label {
                Text(viewModel.userSession!.server.name)
            } icon: {
                if !viewModel.userSession!.server.isVersionCompatible {
                    Image(systemName: "exclamationmark.circle.fill")
                }
            }
            .labelStyle(.sectionFooterWithImage(imageStyle: .orange))

            Text(viewModel.userSession!.server.currentURL.host ?? viewModel.userSession!.server.currentURL.absoluteString)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Playback Section

    private var videoPlayerSection: some View {
        #if os(iOS)
        Section(L10n.playback) {
            Picker(L10n.videoPlayerType, selection: $videoPlayerType)

            ChevronButton(L10n.nativePlayer) {
                router.route(to: .nativePlayerSettings)
            }

            ChevronButton(L10n.videoPlayer) {
                router.route(to: .videoPlayerSettings)
            }

            ChevronButton(L10n.playbackQuality) {
                router.route(to: .playbackQualitySettings)
            }
        } learnMore: {
            LabeledContent(
                "FinStream",
                value: L10n.playerFinStreamDescription
            )
            LabeledContent(
                L10n.native,
                value: L10n.playerNativeDescription
            )
        }
        #else
        Section(L10n.playback) {
            ListRowMenu(L10n.videoPlayerType, selection: $videoPlayerType)
                .focusedValue(\.formLearnMore, videoPlayerTypeLearnMore)

            ChevronButton(L10n.videoPlayer) {
                router.route(to: .videoPlayerSettings)
            }

            ChevronButton(L10n.playbackQuality) {
                router.route(to: .playbackQualitySettings)
            }
        }
        #endif
    }

    @LabeledContentBuilder
    private var videoPlayerTypeLearnMore: AnyView {
        LabeledContent(
            "FinStream",
            value: L10n.playerFinStreamDescription
        )
        LabeledContent(
            L10n.native,
            value: L10n.playerNativeDescription
        )
    }

    // MARK: - Media and Appearance Section

    @ViewBuilder
    private var mediaAndAppearanceSection: some View {
        Section(L10n.mediaAndAppearance) {
            #if os(tvOS)
            ChevronButton(L10n.media) {
                router.route(to: .media)
            }
            #endif

            #if os(iOS)
            Picker(L10n.appearance, selection: $appearance)
            #endif

            ChevronButton(L10n.customize) {
                router.route(to: .customizeViewsSettings)
            }
        }

        #if os(iOS)
        Section {
            ColorPicker(L10n.accentColor, selection: $accentColor, supportsOpacity: false)
        } footer: {
            Text(L10n.viewsMayRequireRestart)
        }
        #endif
    }

    // MARK: - Diagnostics Section

    private var diagnosticsSection: some View {
        Section(L10n.advancedAndDiagnostics) {
            LabeledContent {
                Text(AppBuildInfo.current.commitDisplay)
            } label: {
                Text(verbatim: "Commit")
            }
            .focusable(false)

            ChevronButton(
                L10n.diagnostics,
                subtitle: L10n.diagnosticsDescription
            ) {
                router.route(to: .diagnostics)
            }

            #if DEBUG && os(iOS)
            ChevronButton("Debug") {
                router.route(to: .debugSettings)
            }
            #endif
        }
    }
}
