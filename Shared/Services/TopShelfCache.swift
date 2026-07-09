//
// WatermelonFin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if os(tvOS)
import Foundation
import JellyfinAPI
import TVServices

enum TopShelfCache {

    static let payloadKey = "WatermelonFinTopShelfPayload"
    static let maxItemsPerSection = 12

    private static let appGroupInfoPlistKey = "WatermelonFinAppGroupIdentifier"
    private static let defaultAppGroupIdentifier = "group.org.chenacademy.watermelonfin"
    private static let payloadVersion = 1

    static var appGroupIdentifier: String {
        Bundle.main.object(forInfoDictionaryKey: appGroupInfoPlistKey) as? String ?? defaultAppGroupIdentifier
    }

    static func update(
        resumeItems: [BaseItemDto],
        nextUpItems: [BaseItemDto],
        session: UserSession
    ) {
        let payload = makePayload(
            resumeItems: resumeItems,
            nextUpItems: nextUpItems,
            session: session
        )

        guard payload.sections.isNotEmpty else {
            clear()
            return
        }

        guard let defaults = sharedDefaults,
              let data = try? JSONEncoder().encode(payload)
        else { return }

        defaults.set(data, forKey: payloadKey)
        defaults.synchronize()
        TVTopShelfContentProvider.topShelfContentDidChange()
    }

    static func clear() {
        guard let defaults = sharedDefaults else { return }

        defaults.removeObject(forKey: payloadKey)
        defaults.synchronize()
        TVTopShelfContentProvider.topShelfContentDidChange()
    }

    static func item(id: String, session: UserSession) async throws -> BaseItemDto {
        let request = Paths.getItem(itemID: id, userID: session.user.id)
        let response = try await session.client.send(request)
        return response.value
    }

    static func makePayload(
        resumeItems: [BaseItemDto],
        nextUpItems: [BaseItemDto],
        session: UserSession
    ) -> TopShelfPayload {
        let sections = [
            makeSection(
                title: L10n.resume,
                items: resumeItems,
                session: session
            ),
            makeSection(
                title: L10n.nextUp,
                items: nextUpItems,
                session: session
            ),
        ]
            .compactMap { $0 }

        return TopShelfPayload(
            version: payloadVersion,
            updatedAt: Date.now.timeIntervalSince1970,
            sections: sections
        )
    }

    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    private static func makeSection(
        title: String,
        items: [BaseItemDto],
        session: UserSession
    ) -> TopShelfSection? {
        let topShelfItems = items
            .prefix(maxItemsPerSection)
            .compactMap { makeItem($0, session: session) }

        guard topShelfItems.isNotEmpty else { return nil }

        return TopShelfSection(
            title: title,
            items: topShelfItems
        )
    }

    private static func makeItem(
        _ item: BaseItemDto,
        session: UserSession
    ) -> TopShelfItem? {
        guard let id = item.id,
              let displayURL = TopShelfDeepLink(action: .item, itemID: id).url
        else { return nil }

        let playURL: URL? = {
            guard item.isPlayable else { return nil }
            return TopShelfDeepLink(action: .play, itemID: id).url
        }()

        return TopShelfItem(
            id: id,
            title: title(for: item),
            imageURL: imageURL(for: item, session: session)?.absoluteString,
            displayURL: displayURL.absoluteString,
            playURL: playURL?.absoluteString
        )
    }

    private static func title(for item: BaseItemDto) -> String {
        if item.type == .episode,
           let seriesName = item.seriesName,
           seriesName.isNotEmpty
        {
            return seriesName
        }

        return item.displayTitle
    }

    private static func imageURL(
        for item: BaseItemDto,
        session: UserSession
    ) -> URL? {
        let candidates: [URL?]

        if item.type == .episode {
            candidates = [
                item.imageURL(.thumb, maxWidth: 1920, quality: 90),
                item.imageURL(.backdrop, maxWidth: 1920, quality: 90),
                item.seriesImageURL(.backdrop, maxWidth: 1920, quality: 90),
                item.imageURL(.primary, maxWidth: 600, quality: 90),
            ]
        } else {
            candidates = [
                item.imageURL(.thumb, maxWidth: 1920, quality: 90),
                item.imageURL(.backdrop, maxWidth: 1920, quality: 90),
                item.imageURL(.primary, maxWidth: 600, quality: 90),
            ]
        }

        return candidates
            .compactMap { $0 }
            .first?
            .addingAPIKey(session.user.accessToken)
    }
}

struct TopShelfPayload: Codable, Equatable {
    let version: Int
    let updatedAt: TimeInterval
    let sections: [TopShelfSection]
}

struct TopShelfSection: Codable, Equatable {
    let title: String
    let items: [TopShelfItem]
}

struct TopShelfItem: Codable, Equatable {
    let id: String
    let title: String
    let imageURL: String?
    let displayURL: String
    let playURL: String?
}

struct TopShelfDeepLink: Equatable {

    enum Action: String {
        case item
        case play
    }

    let action: Action
    let itemID: String

    init(action: Action, itemID: String) {
        self.action = action
        self.itemID = itemID
    }

    init?(url: URL) {
        guard url.scheme == "watermelonfin",
              url.host == "topshelf",
              let action = Action(rawValue: url.lastPathComponent),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let itemID = components.queryItems?.first(where: { $0.name == "id" })?.value,
              itemID.isNotEmpty
        else { return nil }

        self.action = action
        self.itemID = itemID
    }

    var url: URL? {
        var components = URLComponents()
        components.scheme = "watermelonfin"
        components.host = "topshelf"
        components.path = "/\(action.rawValue)"
        components.queryItems = [
            URLQueryItem(name: "id", value: itemID),
        ]
        return components.url
    }
}

@MainActor
enum TopShelfDeepLinkStore {

    private static var pendingURL: URL?

    static func receive(_ url: URL) {
        guard TopShelfDeepLink(url: url) != nil else { return }

        pendingURL = url
        Notifications[.didReceiveDeepLink].post(url)
    }

    static func consumePendingURL() -> URL? {
        defer { pendingURL = nil }
        return pendingURL
    }

    static func markHandled(_ url: URL) {
        guard pendingURL == url else { return }
        pendingURL = nil
    }
}

private extension URL {

    func addingAPIKey(_ apiKey: String) -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }

        var queryItems = components.queryItems ?? []
        queryItems.removeAll { $0.name == "api_key" }
        queryItems.append(.init(name: "api_key", value: apiKey))
        components.queryItems = queryItems

        return components.url ?? self
    }
}
#endif
