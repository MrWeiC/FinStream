//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension FocusedValues {

    @Entry
    var formLearnMore: AnyView? = nil
}

// MARK: - Form Overloads

func Form<Content: View>(
    systemImage: String,
    @ViewBuilder content: @escaping () -> Content
) -> some View {
    PlatformForm(content: content) {
        Image(systemName: systemImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 400)
    }
}

func Form<Content: View>(
    image: ImageResource,
    @ViewBuilder content: @escaping () -> Content
) -> some View {
    PlatformForm(content: content) {
        Image(image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 400)
    }
}

func Form<Image: View, Content: View>(
    @ViewBuilder content: @escaping () -> Content,
    @ViewBuilder image: @escaping () -> Image
) -> some View {
    PlatformForm(content: content, image: image)
}

// MARK: - Platform Form

private struct PlatformForm<Image: View, Content: View>: PlatformView {

    @FocusedValue(\.formLearnMore)
    private var focusedLearnMore

    private let content: Content
    private let image: Image

    init(
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder image: @escaping () -> Image
    ) {
        self.content = content()
        self.image = image()
    }

    var iOSView: some View {
        Form {
            content
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    var tvOSView: some View {
        HStack(spacing: 0) {
            descriptionView
                .frame(maxWidth: .infinity)

            Form {
                content
            }
            .toggleStyle(.localizedSettings)
            .frame(maxWidth: .infinity)
            .padding(.top)
            .backport
            .scrollClipDisabled()
        }
        .background(Color.black.ignoresSafeArea())
    }

    private var descriptionView: some View {
        ZStack {
            image

            if let focusedLearnMore {
                learnMoreModal(focusedLearnMore)
            }
        }
        .animation(.linear(duration: 0.2), value: focusedLearnMore == nil)
    }

    private func learnMoreModal(_ content: AnyView) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            content
                .labeledContentStyle(LearnMoreLabeledContentStyle())
                .foregroundStyle(Color.primary, Color.secondary)
        }
        .edgePadding()
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Material.thick)
        }
        .padding()
    }
}

private struct LocalizedSettingsToggleStyle: ToggleStyle {

    func makeBody(configuration: Configuration) -> some View {
        LocalizedSettingsToggle(configuration: configuration)
    }
}

private struct LocalizedSettingsToggle: View {

    @FocusState
    private var isFocused: Bool

    let configuration: ToggleStyle.Configuration

    var body: some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack {
                configuration.label
                    .foregroundStyle(isFocused ? .black : .primary)
                    .padding(.leading, 4)

                Spacer()

                Text(configuration.isOn ? L10n.enabled : L10n.disabled)
                    .fontWeight(.medium)
                    .foregroundStyle(isFocused ? .black : .secondary)
                    .brightness(isFocused ? 0.4 : 0)

                Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                    .font(.body.weight(.regular))
                    .foregroundStyle(isFocused ? .black : .secondary)
                    .brightness(isFocused ? 0.4 : 0)
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isFocused ? Color.white : Color.clear)
            )
            .scaleEffect(isFocused ? 1.04 : 1.0)
            .animation(.easeInOut(duration: 0.125), value: isFocused)
        }
        .buttonStyle(.plain)
        .listRowInsets(.zero)
        .focused($isFocused)
        .accessibilityValue(configuration.isOn ? L10n.enabled : L10n.disabled)
    }
}

private extension ToggleStyle where Self == LocalizedSettingsToggleStyle {

    static var localizedSettings: LocalizedSettingsToggleStyle {
        LocalizedSettingsToggleStyle()
    }
}
