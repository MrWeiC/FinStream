//
// WatermelonFin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls {

    struct PlaybackProgress: View {

        let focusRequest: Int

        @EnvironmentObject
        private var manager: MediaPlayerManager

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState

        @EnvironmentObject
        private var scrubbedSecondsBox: PublishedBox<Duration>

        @State
        private var isTimelineFocused = false

        @State
        private var isTimelineEditing = false

        private var scrubbedSeconds: Binding<Double> {
            Binding(
                get: { scrubbedSecondsBox.value.seconds },
                set: { scrubbedSecondsBox.value = .seconds($0) }
            )
        }

        var body: some View {
            VStack(spacing: 12) {
                if let runtime = manager.item.runtime, runtime > .zero {
                    CapsuleSlider(
                        value: scrubbedSeconds,
                        total: runtime.seconds,
                        step: 15,
                        focusRequest: focusRequest
                    )
                    .onEditingChanged { isEditing in
                        isTimelineEditing = isEditing
                        containerState.isScrubbing = isEditing

                        if !isEditing {
                            let seconds = scrubbedSecondsBox.value
                            manager.seconds = seconds
                            manager.proxy?.setSeconds(seconds)
                        }
                    }
                    .onFocusChanged { isFocused in
                        isTimelineFocused = isFocused
                        if isFocused {
                            containerState.timer.poke()
                        }
                    }
                    .frame(height: 44)
                }

                // Timestamps
                SplitTimeStamp()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white.opacity(isTimelineFocused ? 0.12 : 0))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                .white.opacity(isTimelineFocused ? (isTimelineEditing ? 0.95 : 0.72) : 0),
                                lineWidth: isTimelineEditing ? 4 : 3
                            )
                    }
                    .shadow(
                        color: .black.opacity(isTimelineFocused ? 0.45 : 0),
                        radius: 14,
                        y: 7
                    )
            }
            .scaleEffect(isTimelineFocused ? 1.012 : 1)
            .animation(.easeInOut(duration: 0.2), value: isTimelineFocused)
            .animation(.easeInOut(duration: 0.15), value: isTimelineEditing)
        }
    }
}
