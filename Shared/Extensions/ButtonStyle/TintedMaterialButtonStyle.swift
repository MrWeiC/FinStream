//
// WatermelonFin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ButtonStyle where Self == TintedMaterialButtonStyle {

    // TODO: just be `Material` backed instead of `TintedMaterial`
    static var material: TintedMaterialButtonStyle {
        TintedMaterialButtonStyle(
            tint: Color.clear,
            foregroundColor: Color.primary,
            focusedScale: 1.05
        )
    }

    static func tintedMaterial(
        tint: Color,
        foregroundColor: Color,
        focusedScale: CGFloat = 1.05
    ) -> TintedMaterialButtonStyle {
        TintedMaterialButtonStyle(
            tint: tint,
            foregroundColor: foregroundColor,
            focusedScale: focusedScale
        )
    }
}

struct TintedMaterialButtonStyle: ButtonStyle {

    @Environment(\.isSelected)
    private var isSelected: Bool
    @Environment(\.isEnabled)
    private var isEnabled: Bool
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion: Bool

    #if os(tvOS)
    @Environment(\.isFocused)
    private var isFocused: Bool
    #endif

    // Take tint instead of reading from view as
    // global accent color causes flashes of color
    let tint: Color
    let foregroundColor: Color
    let focusedScale: CGFloat

    @ViewBuilder
    private func contentView(configuration: Configuration) -> some View {
        ZStack {
            TintedMaterial(tint: buttonTint)
                .id(isSelected)

            configuration.label
                .foregroundStyle(foregroundStyle)
                .symbolRenderingMode(.monochrome)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        #if os(tvOS)
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(isFocused ? 0.9 : 0), lineWidth: 3)
            }
            .scaleEffect(isFocused ? focusedScale : 1.0)
            .shadow(color: .black.opacity(isFocused ? 0.45 : 0), radius: 10, y: 6)
            .animation(
                reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.82),
                value: isFocused
            )
        #else
            .hoverEffect(.lift)
        #endif
    }

    func makeBody(configuration: Configuration) -> some View {
        contentView(configuration: configuration)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }

    private var buttonTint: Color {
        #if os(tvOS)
        if isFocused {
            return .white
        }
        #endif

        if isEnabled && isSelected {
            return tint
        } else {
            // TODO: change to a full-opacity color
            return Color.gray.opacity(0.3)
        }
    }

    private var foregroundStyle: AnyShapeStyle {
        #if os(tvOS)
        if isFocused {
            return AnyShapeStyle(Color.black)
        }
        #endif

        if isSelected {
            return AnyShapeStyle(foregroundColor)
        } else if isEnabled {
            return AnyShapeStyle(HierarchicalShapeStyle.primary)
        } else {
            // TODO: change to a full-opacity color
            return AnyShapeStyle(Color.gray.opacity(0.3))
        }
    }
}
