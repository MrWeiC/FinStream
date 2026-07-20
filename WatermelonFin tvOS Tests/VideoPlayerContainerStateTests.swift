//
// WatermelonFin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import JellyfinAPI
import SwiftUI
@testable import WatermelonFin_tvOS
import XCTest

/// Tests for VideoPlayerContainerState
@MainActor
final class VideoPlayerContainerStateTests: XCTestCase {

    var sut: VideoPlayerContainerState!

    override func setUp() async throws {
        sut = VideoPlayerContainerState()
    }

    override func tearDown() async throws {
        sut = nil
    }

    // MARK: - Overlay State Tests

    func testInitialOverlayStateIsHidden() {
        XCTAssertEqual(sut.overlayState, .hidden)
        XCTAssertFalse(sut.isPresentingOverlay)
    }

    func testSettingIsPresentingOverlayUpdatesOverlayState() {
        sut.isPresentingOverlay = true

        XCTAssertEqual(sut.overlayState, .visible)
        XCTAssertTrue(sut.isPresentingOverlay)
    }

    func testSettingIsPresentingOverlayToFalseUpdatesOverlayState() {
        sut.isPresentingOverlay = true
        sut.isPresentingOverlay = false

        XCTAssertEqual(sut.overlayState, .hidden)
        XCTAssertFalse(sut.isPresentingOverlay)
    }

    func testGestureLockPreventsOverlayFromShowing() {
        sut.isGestureLocked = true
        sut.isPresentingOverlay = true // Should be ignored

        XCTAssertEqual(sut.overlayState, .locked)
        XCTAssertFalse(sut.isPresentingOverlay) // Still false because locked
    }

    func testUnlockingGestureResetsToHidden() {
        sut.isGestureLocked = true
        sut.isGestureLocked = false

        XCTAssertEqual(sut.overlayState, .hidden)
        XCTAssertFalse(sut.isGestureLocked)
    }

    // MARK: - Supplement State Tests

    func testInitialSupplementStateIsClosed() {
        XCTAssertEqual(sut.supplementState, .closed)
        XCTAssertFalse(sut.isPresentingSupplement)
    }

    func testPresentationControllerShouldDismissWhenSupplementClosed() {
        XCTAssertTrue(sut.presentationControllerShouldDismiss)
    }

    func testMenuPressSwallowDecisionCanBeCapturedBeforeOverlayDismissal() {
        sut.isPresentingOverlay = true

        let shouldSwallowMenuPress = sut.shouldSwallowMenuPress
        sut.isPresentingOverlay = false

        XCTAssertTrue(shouldSwallowMenuPress)
    }

    func testMenuPressAfterOverlayDismissalIsTemporarilyBlocked() {
        sut.isPresentingOverlay = true

        sut.dismissOverlayFromMenu()

        XCTAssertFalse(sut.isPresentingOverlay)
        XCTAssertTrue(sut.overlayRecentlyDismissed)
        XCTAssertTrue(sut.shouldBlockMenuExit)
    }

    func testMenuPressAfterOverlayAutoDismissalIsTemporarilyBlocked() {
        sut.setOverlayVisible(true, animated: false)

        sut.setOverlayVisible(false, animated: false)

        XCTAssertFalse(sut.isPresentingOverlay)
        XCTAssertTrue(sut.overlayRecentlyDismissed)
        XCTAssertTrue(sut.shouldBlockMenuExit)
    }

    func testMenuPressIsSwallowedWhileScrubbing() {
        sut.isScrubbing = true

        XCTAssertTrue(sut.shouldSwallowMenuPress)
    }

    func testMenuPressAfterScrubbingDismissalIsTemporarilyBlocked() {
        sut.isScrubbing = true

        sut.dismissScrubbingFromMenu()

        XCTAssertFalse(sut.isScrubbing)
        XCTAssertTrue(sut.scrubbingRecentlyDismissed)
        XCTAssertTrue(sut.shouldBlockMenuExit)
    }

    // MARK: - Scrub State Tests

    func testInitialScrubStateIsIdle() {
        XCTAssertEqual(sut.scrubState, .idle)
        XCTAssertFalse(sut.isScrubbing)
    }

    func testSettingIsScrubbingUpdatesScrubState() {
        sut.isScrubbing = true

        XCTAssertEqual(sut.scrubState, .scrubbing)
        XCTAssertTrue(sut.isScrubbing)
    }

    func testSettingIsScrubbingToFalseReturnsToIdle() {
        sut.isScrubbing = true
        sut.isScrubbing = false

        XCTAssertEqual(sut.scrubState, .idle)
        XCTAssertFalse(sut.isScrubbing)
    }

    func testPausedOverlayAutoHidesAfterInactivity() async throws {
        let manager = MediaPlayerManager(initialState: .playback)
        sut = VideoPlayerContainerState(overlayAutoHideInterval: 0.01)
        sut.manager = manager
        sut.observePlaybackStatus()
        await manager.setPlaybackRequestStatus(status: .paused)
        sut.setOverlayVisible(true, animated: false)

        try await Task.sleep(for: .milliseconds(50))

        XCTAssertFalse(sut.isPresentingOverlay)
    }

    // MARK: - Helper Method Tests

    func testSetOverlayVisibleTrue() {
        sut.setOverlayVisible(true, animated: false)

        XCTAssertEqual(sut.overlayState, .visible)
    }

    func testSetOverlayVisibleFalse() {
        sut.setOverlayVisible(true, animated: false)
        sut.setOverlayVisible(false, animated: false)

        XCTAssertEqual(sut.overlayState, .hidden)
    }

    func testSetOverlayVisibleIgnoredWhenLocked() {
        sut.isGestureLocked = true
        sut.setOverlayVisible(true, animated: false)

        XCTAssertEqual(sut.overlayState, .locked)
    }

    func testToggleOverlay() {
        sut.toggleOverlay()
        XCTAssertEqual(sut.overlayState, .visible)

        sut.toggleOverlay()
        XCTAssertEqual(sut.overlayState, .hidden)
    }
}

@MainActor
final class MediaPlayerManagerAutoplayTests: XCTestCase {

    private let testURL = URL(string: "https://example.com/video")!

    func testNaturalEndAdvancesWhenLastProgressUpdateLagsRuntime() async {
        let originalAutoplay = Defaults[.VideoPlayer.autoPlayEnabled]
        let originalReporting = Defaults[.sendProgressReports]
        defer {
            Defaults[.VideoPlayer.autoPlayEnabled] = originalAutoplay
            Defaults[.sendProgressReports] = originalReporting
        }
        Defaults[.VideoPlayer.autoPlayEnabled] = true
        Defaults[.sendProgressReports] = false

        let currentItem = makePlaybackItem(id: "episode-1", runtimeSeconds: 1800)
        let nextItem = makePlaybackItem(id: "episode-2", runtimeSeconds: 1800)
        let nextProvider = MediaPlayerItemProvider(item: nextItem.baseItem) { _ in nextItem }
        let queue = AutoplayTestQueue(nextItem: nextProvider)
        let manager = MediaPlayerManager(playbackItem: currentItem, queue: queue)
        let proxy = AutoplayTestPlayerProxy()
        manager.proxy = proxy

        // The backend reached EOF, but the periodic position observer is still
        // several seconds behind. This used to discard the only ended event.
        manager.seconds = .seconds(1794)
        await manager.ended()

        XCTAssertEqual(manager.playbackItem?.baseItem.id, "episode-2")
        XCTAssertEqual(manager.state, .playback)
        XCTAssertEqual(proxy.stopCallCount, 0, "Replacing an episode must not tear down the player engine")
    }

    private func makePlaybackItem(id: String, runtimeSeconds: Int64) -> MediaPlayerItem {
        var item = BaseItemDto()
        item.id = id
        item.type = .episode
        item.runTimeTicks = Duration.seconds(runtimeSeconds).ticks

        return MediaPlayerItem(
            baseItem: item,
            mediaSource: MediaSourceInfo(),
            playSessionID: "test-session-\(id)",
            url: testURL
        )
    }
}

@MainActor
private final class AutoplayTestPlayerProxy: MediaPlayerProxy {

    weak var manager: MediaPlayerManager?
    let isBuffering = PublishedBox<Bool>(initialValue: false)
    private(set) var stopCallCount = 0

    func play() {}
    func pause() {}
    func stop() {
        stopCallCount += 1
    }

    func jumpForward(_ seconds: Duration) {}
    func jumpBackward(_ seconds: Duration) {}
    func setRate(_ rate: Float) {}
    func setSeconds(_ seconds: Duration) {}
}

@MainActor
private final class AutoplayTestQueue: MediaPlayerQueue {

    let displayTitle = "Autoplay test queue"
    let id = "AutoplayTestQueue"

    weak var manager: MediaPlayerManager?

    @Published
    var nextItem: MediaPlayerItemProvider?

    @Published
    var previousItem: MediaPlayerItemProvider?

    @Published
    var hasNextItem: Bool

    @Published
    var hasPreviousItem = false

    lazy var hasNextItemPublisher: Published<Bool>.Publisher = $hasNextItem
    lazy var hasPreviousItemPublisher: Published<Bool>.Publisher = $hasPreviousItem
    lazy var nextItemPublisher: Published<MediaPlayerItemProvider?>.Publisher = $nextItem
    lazy var previousItemPublisher: Published<MediaPlayerItemProvider?>.Publisher = $previousItem

    init(nextItem: MediaPlayerItemProvider?) {
        self.nextItem = nextItem
        self.hasNextItem = nextItem != nil
    }

    var videoPlayerBody: some PlatformView {
        AnyView(EmptyView())
    }
}
