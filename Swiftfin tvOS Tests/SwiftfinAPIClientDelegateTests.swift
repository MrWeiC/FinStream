//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import JellyfinAPI
@testable import Swiftfin_tvOS
import XCTest

@MainActor
final class SwiftfinAPIClientDelegateTests: XCTestCase {

    func testAuthorizationHeaderQuotesValuesWithSpaces() throws {
        let configuration = try JellyfinClient.Configuration(
            url: XCTUnwrap(URL(string: "http://jellyfin.local:8096")),
            accessToken: "token with spaces",
            client: "Swiftfin Apple TV",
            deviceName: "Living Room",
            deviceID: "tvOS_ABC123",
            version: "1.0"
        )

        let header = SwiftfinAPIClientDelegate.authorizationHeader(configuration: configuration)

        XCTAssertEqual(
            header,
            #"MediaBrowser Client="Swiftfin Apple TV", Device="Living Room", DeviceId="tvOS_ABC123", Version="1.0", Token="token with spaces""#
        )
    }

    func testAuthorizationHeaderOmitsMissingToken() throws {
        let configuration = try JellyfinClient.Configuration(
            url: XCTUnwrap(URL(string: "http://jellyfin.local:8096")),
            client: "Swiftfin Apple TV",
            deviceName: "Living Room",
            deviceID: "tvOS_ABC123",
            version: "1.0"
        )

        let header = SwiftfinAPIClientDelegate.authorizationHeader(configuration: configuration)

        XCTAssertFalse(header.contains("Token="))
    }

    func testUserStateHasAccessTokenIsFalseWhenKeychainEntryIsMissing() {
        let user = UserState(
            id: "missing-token-user",
            serverID: "server",
            username: "Local User"
        )

        Container.shared.keychainService().delete("\(user.id)-accessToken")

        XCTAssertFalse(user.hasAccessToken)
    }

    func testDefaultLocalizationUsesSimplifiedChinese() {
        XCTAssertEqual(L10n.connect, "连接")
        XCTAssertEqual(L10n.addUser, "登录用户")
    }

    func testSaveExistingRefreshesMissingAccessTokenEvenWithoutReplace() async throws {
        let user = UserState(
            id: "existing-user-missing-token",
            serverID: "server",
            username: "Local User"
        )
        let accessTokenKey = "\(user.id)-accessToken"
        let newAccessToken = "new-token"
        Container.shared.keychainService().delete(accessTokenKey)

        let serverURL = try XCTUnwrap(URL(string: "http://jellyfin.local:8096"))
        let viewModel = UserSignInViewModel(
            server: ServerState(
                urls: [serverURL],
                currentURL: serverURL,
                name: "Jellyfin",
                id: "server",
                usersIDs: [user.id]
            )
        )

        let saved = expectation(description: "existing user saved")
        var cancellables = Set<AnyCancellable>()
        viewModel.events
            .sink { event in
                if case .saved = event {
                    saved.fulfill()
                }
            }
            .store(in: &cancellables)

        await viewModel.saveExisting(
            user: ((user, newAccessToken), UserDto()),
            replaceForAccessToken: false,
            authenticationAction: (
                LocalUserAuthenticationAction { _, _ in EmptyEvaluatedUserAccessPolicy() },
                .none,
                nil
            ),
            evaluatedPolicyMap: .init { $0 }
        )

        await fulfillment(of: [saved], timeout: 1)
        XCTAssertEqual(Container.shared.keychainService().get(accessTokenKey), newAccessToken)

        Container.shared.keychainService().delete(accessTokenKey)
        _ = cancellables
    }
}
