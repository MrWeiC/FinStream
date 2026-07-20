//
// WatermelonFin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct CapsuleSlider<Value: BinaryFloatingPoint>: View {

    @Binding
    private var value: Value

    private let total: Value
    private let step: Value
    private let focusRequest: Int
    private var onEditingChanged: (Bool) -> Void
    private var onFocusChanged: (Bool) -> Void

    init(value: Binding<Value>, total: Value, step: Value = 1, focusRequest: Int = 0) {
        self._value = value
        self.total = total
        self.step = step
        self.focusRequest = focusRequest
        self.onEditingChanged = { _ in }
        self.onFocusChanged = { _ in }
    }

    var body: some View {
        SliderContainer(
            value: $value,
            total: total,
            step: step,
            focusRequest: focusRequest,
            onEditingChanged: onEditingChanged,
            onFocusChanged: onFocusChanged
        ) {
            CapsuleSliderContent()
        }
    }
}

extension CapsuleSlider {

    func onEditingChanged(_ action: @escaping (Bool) -> Void) -> Self {
        copy(modifying: \.onEditingChanged, with: action)
    }

    func onFocusChanged(_ action: @escaping (Bool) -> Void) -> Self {
        copy(modifying: \.onFocusChanged, with: action)
    }
}

private struct CapsuleSliderContent: SliderContentView {

    @EnvironmentObject
    var sliderState: SliderContainerState<Double>

    /// The surrounding timeline card communicates focus; the track communicates
    /// progress and becomes stronger only while actively scrubbing.
    private var barHeight: CGFloat {
        if sliderState.isEditing {
            return 14
        }
        return sliderState.isFocused ? 10 : 8
    }

    /// Avoid making the track look like a second, competing focus ring.
    private var scaleEffect: CGFloat {
        if sliderState.isEditing {
            return 1.02
        }
        return 1
    }

    var body: some View {
        // Progress bar with visual states
        ProgressView(value: sliderState.value, total: sliderState.total)
            .progressViewStyle(PlaybackProgressViewStyle(cornerStyle: .round))
            .frame(height: barHeight)
            .overlay(alignment: .leading) {
                if sliderState.isFocused || sliderState.isEditing {
                    GeometryReader { geometry in
                        let progress = sliderState.total > 0
                            ? max(0, min(1, sliderState.value / sliderState.total))
                            : 0
                        let thumbSize: CGFloat = sliderState.isEditing ? 26 : 22
                        let xOffset = max(
                            0,
                            min(
                                geometry.size.width - thumbSize,
                                geometry.size.width * CGFloat(progress) - thumbSize / 2
                            )
                        )

                        Circle()
                            .fill(.white)
                            .frame(width: thumbSize, height: thumbSize)
                            .shadow(color: .black.opacity(0.45), radius: 4, y: 2)
                            .offset(x: xOffset, y: (geometry.size.height - thumbSize) / 2)
                    }
                }
            }
            .shadow(
                color: sliderState.isEditing ? Color.white.opacity(0.3) : Color.clear,
                radius: sliderState.isEditing ? 8 : 0
            )
            .scaleEffect(scaleEffect)
            .animation(.easeInOut(duration: 0.2), value: sliderState.isFocused)
            .animation(.easeInOut(duration: 0.15), value: sliderState.isEditing)
    }
}
