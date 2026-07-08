# Frequently Asked Questions

## General

### What is WatermelonFin?

WatermelonFin is a native tvOS client for Jellyfin media servers, focused exclusively on Apple TV with modern tvOS features like Liquid Glass effects.

### Is WatermelonFin affiliated with Jellyfin?

No. WatermelonFin is an independent project developed separately. It is not affiliated with or endorsed by the Jellyfin project.

### What platforms does WatermelonFin support?

tvOS only (Apple TV). WatermelonFin does not support iOS, iPadOS, or macOS.

---

## Pricing & Source Code

### Why does WatermelonFin cost $8.99 on the App Store?

The $8.99 covers:
- Apple's $99/year developer program fee
- Ongoing development, support, and updates
- App Store distribution and hosting

### Is the source code free?

Yes. WatermelonFin is open source under the MPL 2.0 license. The full source code is available at [github.com/MrWeiC/WatermelonFin](https://github.com/MrWeiC/WatermelonFin).

### Can I build WatermelonFin for free?

Yes. Developers can clone the repository and build WatermelonFin themselves using Xcode. See [INSTALLATION.md](INSTALLATION.md) for instructions.

---

## Technical

### What tvOS version do I need?

- **Minimum**: tvOS 17
- **Recommended**: tvOS 18+ (for Liquid Glass effects)

### Does WatermelonFin work with all Jellyfin servers?

WatermelonFin is designed for Jellyfin 10.11+. Older versions may work but are not officially supported.

### What media formats does WatermelonFin support?

WatermelonFin uses MPV for playback, which supports a wide range of codecs including:
- H.264, H.265/HEVC
- VP9, AV1
- MP4, MKV, AVI containers
- AAC, AC3, DTS audio

See MPV documentation for the complete codec list.

### Does WatermelonFin support HDR?

Yes. WatermelonFin supports HDR10 and Dolby Vision content when your Apple TV and TV support these formats.

---

## App Store

### Which countries is WatermelonFin available in?

WatermelonFin is available in 175 countries on the Apple App Store, covering most global regions.

### Can I purchase WatermelonFin from my iPhone?

No. tvOS apps must be purchased directly on your Apple TV device. You can browse the app on your iPhone/iPad, but the purchase must be completed on Apple TV.

### Is there a subscription?

No. WatermelonFin is a one-time purchase of $8.99 USD with no subscriptions or in-app purchases.

### Do I need to pay again for updates?

No. Once purchased, all future updates are free.

---

## Project Direction

### Why focus only on Apple TV?

WatermelonFin is scoped to tvOS so Apple TV navigation, focus behavior, playback controls, and TestFlight/App Store releases can move independently.

Long-term, focusing exclusively on tvOS allows for platform-specific improvements that are more difficult in a multi-platform codebase.

### Will WatermelonFin support iOS or iPadOS?

No. The project is intentionally tvOS-only.

### What makes WatermelonFin different?

- tvOS-exclusive focus (no iOS/iPadOS)
- tvOS 18 Liquid Glass transport bar
- Redesigned playback controls
- Fixed navigation bugs and memory leaks
- Active development and App Store distribution

---

## Support

### How do I report a bug?

File an issue on GitHub: [github.com/MrWeiC/WatermelonFin/issues](https://github.com/MrWeiC/WatermelonFin/issues)

Use the bug report template and include:
- WatermelonFin version/build number
- Apple TV model and tvOS version
- Steps to reproduce
- Expected vs. actual behavior

### How do I request a feature?

Create a feature request on GitHub Discussions: [github.com/MrWeiC/WatermelonFin/discussions](https://github.com/MrWeiC/WatermelonFin/discussions)

---

## Beta Program

### Was there a beta program?

Yes. WatermelonFin ran a public beta via TestFlight from December 2025 through January 17, 2026. The beta program closed when WatermelonFin launched on the App Store.

### Can I still join the beta?

The public beta program is closed. Beta testers have been migrated to the App Store version.

### Will there be future betas?

Possibly, for major feature testing. Future beta programs will be announced on GitHub.
