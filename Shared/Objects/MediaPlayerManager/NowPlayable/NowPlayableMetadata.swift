//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import MediaPlayer

struct NowPlayableLanguageMetadata {
    let currentLanguageOptions: [MPNowPlayingInfoLanguageOption]
    let availableLanguageOptionGroups: [MPNowPlayingInfoLanguageOptionGroup]
}

struct NowPlayableStaticMetadata {

    let mediaType: MPNowPlayingInfoMediaType
    let isLiveStream: Bool

    let title: String
    let artist: String?
    let artwork: MPMediaItemArtwork?

    let albumArtist: String?
    let albumTitle: String?

    init(
        mediaType: MPNowPlayingInfoMediaType,
        isLiveStream: Bool = false,
        title: String,
        artist: String? = nil,
        artwork: MPMediaItemArtwork? = nil,
        albumArtist: String? = nil,
        albumTitle: String? = nil
    ) {
        self.mediaType = mediaType
        self.isLiveStream = isLiveStream
        self.title = title
        self.artist = artist
        self.artwork = artwork
        self.albumArtist = albumArtist
        self.albumTitle = albumTitle
    }
}

struct NowPlayableDynamicMetadata {

    let rate: Float
    let position: Duration
    let duration: Duration

    let currentLanguageOptions: [MPNowPlayingInfoLanguageOption]
    let availableLanguageOptionGroups: [MPNowPlayingInfoLanguageOptionGroup]

    @MainActor
    init(
        rate: Float = 1,
        position: Duration,
        duration: Duration,
        item: MediaPlayerItem? = nil,
        currentLanguageOptions: [MPNowPlayingInfoLanguageOption] = [],
        availableLanguageOptionGroups: [MPNowPlayingInfoLanguageOptionGroup] = []
    ) {
        let languageMetadata = item?.nowPlayableLanguageMetadata
        self.rate = rate
        self.position = position
        self.duration = duration
        self.currentLanguageOptions = languageMetadata?.currentLanguageOptions ?? currentLanguageOptions
        self.availableLanguageOptionGroups = languageMetadata?.availableLanguageOptionGroups ?? availableLanguageOptionGroups
    }
}

extension MediaPlayerItem {

    var nowPlayableLanguageMetadata: NowPlayableLanguageMetadata {
        let audioOptions = audioStreams.compactMap(\.nowPlayableAudioLanguageOption)
        let subtitleOptions = subtitleStreams.compactMap(\.nowPlayableSubtitleLanguageOption)

        var currentOptions: [MPNowPlayingInfoLanguageOption] = []
        var groups: [MPNowPlayingInfoLanguageOptionGroup] = []

        if !audioOptions.isEmpty {
            let defaultAudioOption = option(
                in: audioOptions,
                matching: MediaStream.nowPlayableAudioIdentifier(for: selectedAudioStreamIndex)
            )
            if let defaultAudioOption {
                currentOptions.append(defaultAudioOption)
            }
            groups.append(
                MPNowPlayingInfoLanguageOptionGroup(
                    languageOptions: audioOptions,
                    defaultLanguageOption: defaultAudioOption,
                    allowEmptySelection: false
                )
            )
        }

        if !subtitleOptions.isEmpty {
            let defaultSubtitleOption = option(
                in: subtitleOptions,
                matching: MediaStream.nowPlayableSubtitleIdentifier(for: selectedSubtitleStreamIndex)
            )
            if let defaultSubtitleOption {
                currentOptions.append(defaultSubtitleOption)
            }
            groups.append(
                MPNowPlayingInfoLanguageOptionGroup(
                    languageOptions: subtitleOptions,
                    defaultLanguageOption: defaultSubtitleOption,
                    allowEmptySelection: true
                )
            )
        }

        return .init(
            currentLanguageOptions: currentOptions,
            availableLanguageOptionGroups: groups
        )
    }

    func select(languageOption: MPNowPlayingInfoLanguageOption) -> Bool {
        guard let identifier = languageOption.identifier else { return false }

        if let index = MediaStream.audioIndex(fromNowPlayableIdentifier: identifier),
           audioStreams.contains(where: { $0.index == index })
        {
            selectedAudioStreamIndex = index
            return true
        }

        if let index = MediaStream.subtitleIndex(fromNowPlayableIdentifier: identifier),
           subtitleStreams.contains(where: { $0.index == index })
        {
            selectedSubtitleStreamIndex = index
            return true
        }

        return false
    }

    func disable(languageOption: MPNowPlayingInfoLanguageOption) -> Bool {
        guard languageOption.languageOptionType == .legible else { return false }

        selectedSubtitleStreamIndex = -1
        return true
    }

    private func option(
        in options: [MPNowPlayingInfoLanguageOption],
        matching identifier: String?
    ) -> MPNowPlayingInfoLanguageOption? {
        guard let identifier else { return nil }
        return options.first { $0.identifier == identifier }
    }
}

extension MediaStream {

    static func nowPlayableAudioIdentifier(for index: Int?) -> String? {
        nowPlayableIdentifier(prefix: "audio", index: index)
    }

    static func nowPlayableSubtitleIdentifier(for index: Int?) -> String? {
        nowPlayableIdentifier(prefix: "subtitle", index: index)
    }

    static func audioIndex(fromNowPlayableIdentifier identifier: String) -> Int? {
        nowPlayableIndex(prefix: "audio", identifier: identifier)
    }

    static func subtitleIndex(fromNowPlayableIdentifier identifier: String) -> Int? {
        nowPlayableIndex(prefix: "subtitle", identifier: identifier)
    }

    var nowPlayableAudioLanguageOption: MPNowPlayingInfoLanguageOption? {
        guard type == .audio,
              let index,
              let identifier = Self.nowPlayableAudioIdentifier(for: index)
        else { return nil }

        return MPNowPlayingInfoLanguageOption(
            type: .audible,
            languageTag: nowPlayableLanguageTag,
            characteristics: nil,
            displayName: formattedAudioTitle,
            identifier: identifier
        )
    }

    var nowPlayableSubtitleLanguageOption: MPNowPlayingInfoLanguageOption? {
        guard type == .subtitle,
              let index,
              let identifier = Self.nowPlayableSubtitleIdentifier(for: index)
        else { return nil }

        return MPNowPlayingInfoLanguageOption(
            type: .legible,
            languageTag: nowPlayableLanguageTag,
            characteristics: nowPlayableSubtitleCharacteristics,
            displayName: formattedSubtitleTitle,
            identifier: identifier
        )
    }

    private static func nowPlayableIdentifier(prefix: String, index: Int?) -> String? {
        guard let index, index >= 0 else { return nil }
        return "\(prefix):\(index)"
    }

    private static func nowPlayableIndex(prefix: String, identifier: String) -> Int? {
        guard identifier.hasPrefix("\(prefix):") else { return nil }
        return Int(identifier.dropFirst(prefix.count + 1))
    }

    private var nowPlayableLanguageTag: String {
        guard let language, !language.isEmpty else { return "und" }

        switch language.lowercased() {
        case "chi", "zho":
            return "zh"
        case "cze", "ces":
            return "cs"
        case "dut", "nld":
            return "nl"
        case "eng":
            return "en"
        case "fre", "fra":
            return "fr"
        case "ger", "deu":
            return "de"
        case "gre", "ell":
            return "el"
        case "ice", "isl":
            return "is"
        case "jpn":
            return "ja"
        case "kor":
            return "ko"
        case "per", "fas":
            return "fa"
        case "rum", "ron":
            return "ro"
        case "spa":
            return "es"
        default:
            return language
        }
    }

    private var nowPlayableSubtitleCharacteristics: [String]? {
        var characteristics: [String] = []

        if isForced == true {
            characteristics.append(MPLanguageOptionCharacteristicContainsOnlyForcedSubtitles)
        }

        if isHearingImpaired == true {
            characteristics.append(MPLanguageOptionCharacteristicTranscribesSpokenDialog)
        }

        return characteristics.isEmpty ? nil : characteristics
    }
}
