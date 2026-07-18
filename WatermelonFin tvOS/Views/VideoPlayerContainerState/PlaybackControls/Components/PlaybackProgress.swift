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

        @EnvironmentObject
        private var manager: MediaPlayerManager

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState

        @EnvironmentObject
        private var scrubbedSecondsBox: PublishedBox<Duration>

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
                        step: 15
                    )
                    .onEditingChanged { isEditing in
                        containerState.isScrubbing = isEditing

                        if !isEditing {
                            let seconds = scrubbedSecondsBox.value
                            manager.seconds = seconds
                            manager.proxy?.setSeconds(seconds)
                        }
                    }
                    .onFocusChanged { isFocused in
                        if isFocused {
                            containerState.timer.poke()
                        }
                    }
                    .frame(height: 44)
                }

                // Timestamps
                SplitTimeStamp()
            }
            .frame(maxWidth: .infinity)
        }
    }
}
