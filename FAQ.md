# Frequently Asked Questions

## General

### What is FinStream?

FinStream is a native tvOS client for Jellyfin media servers. It's a fork of Swiftfin focused exclusively on Apple TV with modern tvOS features like Liquid Glass effects.

### Is FinStream affiliated with Jellyfin or Swiftfin?

No. FinStream is an independent fork of Swiftfin, developed separately. It is not affiliated with or endorsed by the Jellyfin project or the Swiftfin team.

### What platforms does FinStream support?

tvOS only (Apple TV). FinStream does not support iOS, iPadOS, or macOS.

---

## Pricing & Source Code

### Why does FinStream cost $8.99 on the App Store?

The $8.99 covers:
- Apple's $99/year developer program fee
- Ongoing development, support, and updates
- App Store distribution and hosting

### Is the source code free?

Yes. FinStream is open source under the MPL 2.0 license. The full source code is available at [github.com/mrweic/FinStream](https://github.com/mrweic/FinStream).

### Can I build FinStream for free?

Yes. Developers can clone the repository and build FinStream themselves using Xcode. See [INSTALLATION.md](INSTALLATION.md) for instructions.

---

## Technical

### What tvOS version do I need?

- **Minimum**: tvOS 17
- **Recommended**: tvOS 18+ (for Liquid Glass effects)

### Does FinStream work with all Jellyfin servers?

FinStream is designed for Jellyfin 10.11+. Older versions may work but are not officially supported.

### What media formats does FinStream support?

FinStream uses MPV for playback, which supports a wide range of codecs including:
- H.264, H.265/HEVC
- VP9, AV1
- MP4, MKV, AVI containers
- AAC, AC3, DTS audio

See MPV documentation for the complete codec list.

### Does FinStream support HDR?

Yes. FinStream supports HDR10 and Dolby Vision content when your Apple TV and TV support these formats.

---

## App Store

### Which countries is FinStream available in?

FinStream is available in 175 countries on the Apple App Store, covering most global regions.

### Can I purchase FinStream from my iPhone?

No. tvOS apps must be purchased directly on your Apple TV device. You can browse the app on your iPhone/iPad, but the purchase must be completed on Apple TV.

### Is there a subscription?

No. FinStream is a one-time purchase of $8.99 USD with no subscriptions or in-app purchases.

### Do I need to pay again for updates?

No. Once purchased, all future updates are free.

---

## Fork Relationship

### Why fork Swiftfin instead of contributing?

Swiftfin tvOS development has been paused with no TestFlight available and no committed timeline. FinStream was created to serve tvOS users who needed a working app immediately.

Long-term, focusing exclusively on tvOS allows for platform-specific improvements that are more difficult in a multi-platform codebase.

### Will FinStream merge back into Swiftfin?

No plans for that. FinStream is a separate project with independent development. However, improvements from FinStream may be contributed back to Swiftfin if appropriate.

### What's different from Swiftfin?

- tvOS-exclusive focus (no iOS/iPadOS)
- tvOS 18 Liquid Glass transport bar
- Redesigned playback controls
- Fixed navigation bugs and memory leaks
- Active development and App Store distribution

---

## Support

### How do I report a bug?

File an issue on GitHub: [github.com/mrweic/FinStream/issues](https://github.com/mrweic/FinStream/issues)

Use the bug report template and include:
- FinStream version/build number
- Apple TV model and tvOS version
- Steps to reproduce
- Expected vs. actual behavior

### How do I request a feature?

Create a feature request on GitHub Discussions: [github.com/mrweic/FinStream/discussions](https://github.com/mrweic/FinStream/discussions)

---

## Beta Program

### Was there a beta program?

Yes. FinStream ran a public beta via TestFlight from December 2025 through January 17, 2026. The beta program closed when FinStream launched on the App Store.

### Can I still join the beta?

The public beta program is closed. Beta testers have been migrated to the App Store version.

### Will there be future betas?

Possibly, for major feature testing. Future beta programs will be announced on GitHub.
