//
// WatermelonFin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import Get
import JellyfinAPI

final class WatermelonFinAPIClientDelegate: APIClientDelegate {

    weak var jellyfinClient: JellyfinClient?

    private let actualDelegate: APIClientDelegate?

    init(actualDelegate: APIClientDelegate? = nil) {
        self.actualDelegate = actualDelegate
    }

    func client(_ client: APIClient, willSendRequest request: inout URLRequest) async throws {
        if let configuration = jellyfinClient?.configuration {
            request.setValue(
                Self.authorizationHeader(configuration: configuration),
                forHTTPHeaderField: "Authorization"
            )
        }

        try await actualDelegate?.client(client, willSendRequest: &request)
    }

    func client(_ client: APIClient, validateResponse response: HTTPURLResponse, data: Data, task: URLSessionTask) throws {
        if let actualDelegate {
            try actualDelegate.client(client, validateResponse: response, data: data, task: task)
        } else {
            guard (200 ..< 300).contains(response.statusCode) else {
                throw APIError.unacceptableStatusCode(response.statusCode)
            }
        }
    }

    func client(_ client: APIClient, shouldRetry task: URLSessionTask, error: Error, attempts: Int) async throws -> Bool {
        try await actualDelegate?.client(client, shouldRetry: task, error: error, attempts: attempts) ?? false
    }

    func client(_ client: APIClient, makeURLForRequest request: Request<some Any>) throws -> URL? {
        try actualDelegate?.client(client, makeURLForRequest: request)
    }

    static func authorizationHeader(configuration: JellyfinClient.Configuration) -> String {
        var fields: [(key: String, value: String)] = [
            ("Client", configuration.client),
            ("Device", configuration.deviceName),
            ("DeviceId", configuration.deviceID),
            ("Version", configuration.version),
        ]

        if let accessToken = configuration.accessToken {
            fields.append(("Token", accessToken))
        }

        let parameters = fields
            .map { "\($0.key)=\(quoted($0.value))" }
            .joined(separator: ", ")

        return "MediaBrowser \(parameters)"
    }

    private static func quoted(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        return "\"\(escaped)\""
    }
}

extension JellyfinClient {

    static func watermelonfinClient(
        configuration: Configuration,
        delegate actualDelegate: APIClientDelegate? = nil,
        sessionConfiguration: URLSessionConfiguration = .default,
        sessionDelegate: URLSessionDelegate? = nil
    ) -> JellyfinClient {
        let delegate = WatermelonFinAPIClientDelegate(actualDelegate: actualDelegate)
        let client = JellyfinClient(
            configuration: configuration,
            delegate: delegate,
            sessionConfiguration: sessionConfiguration,
            sessionDelegate: sessionDelegate
        )

        delegate.jellyfinClient = client

        return client
    }
}
