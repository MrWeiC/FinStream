//
// WatermelonFin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Defaults
import Factory
import JellyfinAPI
import Logging
import Pulse

final class UserSession {

    let client: JellyfinClient
    let server: ServerState
    let user: UserState

    init(
        server: ServerState,
        user: UserState
    ) {
        self.server = server
        self.user = user

        let client = JellyfinClient.watermelonfinClient(
            configuration: .watermelonfinConfiguration(
                url: server.currentURL,
                accessToken: user.accessToken
            ),
            sessionConfiguration: .watermelonfin,
            sessionDelegate: URLSessionProxyDelegate(logger: NetworkLogger.watermelonfin())
        )

        self.client = client
    }
}

extension Container {

    // TODO: be parameterized, take user id
    //       - don't be optional
    //       - in `ViewModel`, don't be implicitly unwrapped
    //         and have idempotent default value
    var currentUserSession: Factory<UserSession?> {
        self {
            guard case let .signedIn(userId) = Defaults[.lastSignedInUserID] else { return nil }

            guard let user = try? WatermelonFinStore.dataStack.fetchOne(
                From<UserModel>().where(\.$id == userId)
            ) else {
                // had last user ID but no saved user
                Defaults[.lastSignedInUserID] = .signedOut

                return nil
            }

            guard let server = user.server,
                  let _ = WatermelonFinStore.dataStack.fetchExisting(server)
            else {
                // Orphaned user - sign out gracefully
                let logger = Logger.watermelonfin()
                logger.error("No associated server for user \(userId). Signing out.")
                Defaults[.lastSignedInUserID] = .signedOut
                return nil
            }

            guard let userState = user.state else {
                let logger = Logger.watermelonfin()
                logger.error("User \(userId) has no valid state. Signing out.")
                Defaults[.lastSignedInUserID] = .signedOut
                return nil
            }

            guard userState.hasAccessToken else {
                let logger = Logger.watermelonfin()
                logger.error("User \(userId) has no access token in keychain. Signing out.")
                Defaults[.lastSignedInUserID] = .signedOut
                return nil
            }

            return .init(
                server: server.state,
                user: userState
            )
        }.cached
    }
}
