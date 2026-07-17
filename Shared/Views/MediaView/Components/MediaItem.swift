//
// WatermelonFin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// Note: the design reason to not have a local label always on top
//       is to have the same failure/empty color for all views

extension MediaView {

    // TODO: custom view for folders and tv (allow customization?)
    //       - differentiate between what media types are WatermelonFin only
    //         which would allow some cleanup
    //       - allow server or random view per library?
    // TODO: if local label on image, also needs to be in blurhash placeholder
    struct MediaItem: View {

        @Default(.Customization.Library.randomImage)
        private var useRandomImage

        @ObservedObject
        private var viewModel: MediaViewModel

        @Namespace
        private var namespace

        @State
        private var imageSources: [ImageSource] = []
        @State
        private var itemCount: Int?

        private let action: (Namespace.ID) -> Void
        private let mediaType: MediaViewModel.MediaType

        init(
            viewModel: MediaViewModel,
            type: MediaViewModel.MediaType,
            action: @escaping (Namespace.ID) -> Void
        ) {
            self.viewModel = viewModel
            self.action = action
            self.mediaType = type
        }

        private func setCardData() {
            Task { @MainActor in
                do {
                    let cardData = try await viewModel.cardData(
                        for: mediaType,
                        useRandomImage: useRandomImage
                    )
                    imageSources = cardData.imageSources
                    itemCount = cardData.itemCount
                } catch {
                    imageSources = []
                    itemCount = nil
                }
            }
        }

        private var countLabel: String? {
            itemCount.map(mediaType.countLabel)
        }

        private var cardOverlay: some View {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [.clear, .black.opacity(0.88)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                HStack(spacing: 18) {
                    Image(systemName: mediaType.systemImage)
                        .font(.title2)
                        .frame(width: 54, height: 54)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(mediaType.displayTitle)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .lineLimit(1)

                        if let countLabel {
                            Text(countLabel)
                                .font(.callout)
                                .foregroundStyle(.white.opacity(0.75))
                        }
                    }
                }
                .foregroundStyle(.white)
                .padding(24)
            }
        }

        var body: some View {
            Button {
                action(namespace)
            } label: {
                ImageView(imageSources)
                    .image { image in image }
                    .placeholder { imageSource in
                        DefaultPlaceholderView(blurHash: imageSource.blurHash)
                    }
                    .failure {
                        Color.secondarySystemFill
                            .opacity(0.75)
                    }
                    .id(imageSources.hashValue)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .posterStyle(.landscape)
                    .overlay {
                        cardOverlay
                    }
                    .backport
                    .matchedTransitionSource(id: "item", in: namespace)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(mediaType.displayTitle)
            .ifLet(countLabel) { view, countLabel in
                view.accessibilityValue(countLabel)
            }
            .onFirstAppear(perform: setCardData)
            .backport
            .onChange(of: useRandomImage) { _, _ in
                setCardData()
            }
            .onChange(of: viewModel.cardDataRevision) { _, _ in
                setCardData()
            }
            .buttonStyle(.card)
        }
    }
}
