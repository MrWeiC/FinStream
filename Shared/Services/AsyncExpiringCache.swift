//
// WatermelonFin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

@MainActor
final class AsyncExpiringCache<Key: Hashable, Value> {

    private struct Entry {
        let value: Value
        let expiresAt: Date
    }

    private struct Request {
        let id: UUID
        let task: Task<Value, Error>
    }

    private var entries: [Key: Entry] = [:]
    private var requests: [Key: Request] = [:]

    private let now: () -> Date
    private let timeToLive: TimeInterval

    init(
        timeToLive: TimeInterval,
        now: @escaping () -> Date = Date.init
    ) {
        self.timeToLive = timeToLive
        self.now = now
    }

    func value(
        for key: Key,
        load: @escaping () async throws -> Value
    ) async throws -> Value {

        let currentDate = now()

        if let entry = entries[key], entry.expiresAt > currentDate {
            return entry.value
        }

        entries[key] = nil

        if let request = requests[key] {
            return try await request.task.value
        }

        let requestID = UUID()
        let task = Task {
            try await load()
        }
        requests[key] = Request(id: requestID, task: task)

        do {
            let value = try await task.value

            if requests[key]?.id == requestID {
                entries[key] = Entry(
                    value: value,
                    expiresAt: now().addingTimeInterval(timeToLive)
                )
                requests[key] = nil
            }

            return value
        } catch {
            if requests[key]?.id == requestID {
                requests[key] = nil
            }
            throw error
        }
    }

    func removeAll(where shouldRemove: (Key) -> Bool = { _ in true }) {
        entries.keys
            .filter(shouldRemove)
            .forEach { entries[$0] = nil }

        requests
            .filter { shouldRemove($0.key) }
            .forEach { key, request in
                request.task.cancel()
                requests[key] = nil
            }
    }
}
