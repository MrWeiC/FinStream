//
// WatermelonFin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

@testable import WatermelonFin_tvOS
import XCTest

final class AsyncExpiringCacheTests: XCTestCase {

    @MainActor
    func testReusesAndExpiresValues() async throws {
        var currentDate = Date(timeIntervalSince1970: 1000)
        var loadCount = 0
        let cache = AsyncExpiringCache<String, Int>(
            timeToLive: 300,
            now: { currentDate }
        )

        let first = try await cache.value(for: "library") {
            loadCount += 1
            return loadCount
        }
        let cached = try await cache.value(for: "library") {
            loadCount += 1
            return loadCount
        }

        XCTAssertEqual(first, 1)
        XCTAssertEqual(cached, 1)
        XCTAssertEqual(loadCount, 1)

        currentDate.addTimeInterval(301)

        let expired = try await cache.value(for: "library") {
            loadCount += 1
            return loadCount
        }

        XCTAssertEqual(expired, 2)
        XCTAssertEqual(loadCount, 2)
    }

    @MainActor
    func testCanInvalidateMatchingValues() async throws {
        let cache = AsyncExpiringCache<String, Int>(timeToLive: 300)

        _ = try await cache.value(for: "first") { 1 }
        _ = try await cache.value(for: "second") { 2 }
        cache.removeAll { $0 == "first" }

        let refreshed = try await cache.value(for: "first") { 3 }
        let retained = try await cache.value(for: "second") { 4 }

        XCTAssertEqual(refreshed, 3)
        XCTAssertEqual(retained, 2)
    }

    @MainActor
    func testCoalescesConcurrentLoads() async throws {
        var loadCount = 0
        var continuation: CheckedContinuation<Int, Never>?
        let cache = AsyncExpiringCache<String, Int>(timeToLive: 300)

        let firstTask = Task {
            try await cache.value(for: "library") {
                loadCount += 1
                return await withCheckedContinuation {
                    continuation = $0
                }
            }
        }

        while continuation == nil {
            await Task.yield()
        }

        let secondTask = Task {
            try await cache.value(for: "library") {
                loadCount += 1
                return -1
            }
        }

        await Task.yield()
        XCTAssertEqual(loadCount, 1)

        let pendingContinuation = try XCTUnwrap(continuation)
        continuation = nil
        pendingContinuation.resume(returning: 42)

        let first = try await firstTask.value
        let second = try await secondTask.value

        XCTAssertEqual(first, 42)
        XCTAssertEqual(second, 42)
        XCTAssertEqual(loadCount, 1)
    }
}
