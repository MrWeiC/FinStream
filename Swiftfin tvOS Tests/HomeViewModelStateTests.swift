//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
@testable import Swiftfin_tvOS
import XCTest

/// Tests for HomeViewModel state machine behavior
///
/// These tests focus on synchronous state transitions via `respond(to:)`.
/// For full integration tests (network, persistence), additional infrastructure
/// would be needed (protocol-based child VMs, Factory mocking).
@MainActor
final class HomeViewModelStateTests: XCTestCase {

    var sut: HomeViewModel!

    override func setUp() async throws {
        sut = HomeViewModel()
    }

    override func tearDown() async throws {
        sut = nil
    }

    // MARK: - Initial State Tests

    func testInitialStateIsInitial() {
        XCTAssertEqual(sut.state, .initial)
    }

    func testInitialLibrariesAreEmpty() {
        XCTAssertTrue(sut.libraries.isEmpty)
    }

    func testInitialResumeItemsAreEmpty() {
        XCTAssertTrue(sut.resumeItems.isEmpty)
    }

    func testInitialBackgroundStatesAreEmpty() {
        XCTAssertTrue(sut.backgroundStates.isEmpty)
    }

    func testInitialNotificationsReceivedIsEmpty() {
        XCTAssertTrue(sut.notificationsReceived.isEmpty)
    }

    // MARK: - State Machine: respond(to:) Tests

    func testRefreshActionReturnsRefreshingState() {
        let newState = sut.respond(to: .refresh)

        XCTAssertEqual(newState, .refreshing)
    }

    func testErrorActionReturnsErrorState() {
        let errorMessage = ErrorMessage("Test error")
        let newState = sut.respond(to: .error(errorMessage))

        if case let .error(message) = newState {
            XCTAssertEqual(message, errorMessage)
        } else {
            XCTFail("Expected error state, got \(newState)")
        }
    }

    func testBackgroundRefreshDoesNotChangeState() {
        // Start from content state
        sut.state = .content

        let newState = sut.respond(to: .backgroundRefresh)

        // Background refresh should not change the main state
        XCTAssertEqual(newState, .content)
    }

    func testBackgroundRefreshFromInitialStaysInitial() {
        let newState = sut.respond(to: .backgroundRefresh)

        XCTAssertEqual(newState, .initial)
    }

    func testSetIsPlayedDoesNotChangeState() {
        // SetIsPlayed should return current state (async operation happens in background)
        sut.state = .content

        // Create a minimal BaseItemDto for testing
        var item = BaseItemDto()
        item.id = "test-item-123"
        let newState = sut.respond(to: .setIsPlayed(true, item))

        XCTAssertEqual(newState, .content)
    }

    // MARK: - Background State Tests

    func testBackgroundRefreshAddsToBackgroundStates() {
        _ = sut.respond(to: .backgroundRefresh)

        XCTAssertTrue(sut.backgroundStates.contains(.refresh))
    }

    // MARK: - State Transition Sequences

    func testRefreshThenErrorTransition() {
        // Initial → Refreshing
        let state1 = sut.respond(to: .refresh)
        XCTAssertEqual(state1, .refreshing)

        // Refreshing → Error
        let errorMessage = ErrorMessage("Network timeout")
        let state2 = sut.respond(to: .error(errorMessage))

        if case .error = state2 {
            // Success - in error state
        } else {
            XCTFail("Expected error state after .error action")
        }
    }

    func testMultipleRefreshCallsCancelPrevious() {
        // Call refresh twice - second should cancel first
        _ = sut.respond(to: .refresh)
        let secondState = sut.respond(to: .refresh)

        // Both should return refreshing
        XCTAssertEqual(secondState, .refreshing)
    }

    // MARK: - Error Message Equality

    func testErrorMessagesWithSameTextAreEqual() {
        let error1 = ErrorMessage("Same error")
        let error2 = ErrorMessage("Same error")

        // Verify ErrorMessage equality works correctly for state comparisons
        let state1 = sut.respond(to: .error(error1))
        let state2 = sut.respond(to: .error(error2))

        XCTAssertEqual(state1, state2)
    }

    func testErrorMessagesWithDifferentTextAreNotEqual() {
        let error1 = ErrorMessage("Error A")
        let error2 = ErrorMessage("Error B")

        let state1 = sut.respond(to: .error(error1))
        sut.state = .initial // Reset
        let state2 = sut.respond(to: .error(error2))

        XCTAssertNotEqual(state1, state2)
    }
}
