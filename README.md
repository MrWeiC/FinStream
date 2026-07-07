<div align="center">

# FinStream

**A tvOS-focused Jellyfin client**

<img src="https://img.shields.io/badge/tvOS-17+-blue"/>
<img src="https://img.shields.io/badge/Jellyfin-10.11-9962be"/>
<img src="https://img.shields.io/badge/License-MPL%202.0-brightgreen"/>

</div>

> **Note:** FinStream is an independent project. It is **not affiliated with or endorsed by** [Jellyfin](https://jellyfin.org), [Swiftfin](https://github.com/jellyfin/Swiftfin), or [Reefy](https://github.com/jmhunter83/reefy). It is a fork of Reefy — which is itself a fork of Swiftfin — developed separately with a focus on Apple TV.

---

## About

**FinStream** is a native Jellyfin media client built exclusively for Apple TV. It uses MPV for direct playback and is designed to feel native on tvOS.

This project focuses purely on the tvOS experience — no iOS, just Apple TV.

---

## Features

- **tvOS 18 Liquid Glass** — Native glass transport bar with tvOS 17 fallback
- **Redesigned playback controls** — Clean layout in the bottom of the screen
- **Native progress slider** — Pill-shaped playback scrubber
- **Full-screen item views** — Proper detail views, not cards
- **Improved focus states** — Smooth scale animations on button focus
- **MPV-based playback** — Wide codec and subtitle support for your media files

---

## Build from Source

FinStream is free and open source under the MPL 2.0 license. You can build it yourself:

**Requirements:**
- Xcode (latest)
- Apple TV (tvOS 17+ recommended, tvOS 18+ for Liquid Glass effects)
- A Jellyfin media server (10.11+ recommended)

See the [Documentation](Documentation/) directory for build details.

Before opening a pull request, run the local validation commands in [Contributing](Documentation/contributing.md#before-opening-a-pull-request) so GitHub Actions are used for confirmation rather than first-pass lint or build failures.

---

## Acknowledgments

FinStream stands on the work of others:

- [Jellyfin](https://jellyfin.org) — The free software media system
- [Swiftfin](https://github.com/jellyfin/Swiftfin) — The original native Swift Jellyfin client
- [Reefy](https://github.com/jmhunter83/reefy) — The tvOS-focused fork of Swiftfin that FinStream is forked from

The full attribution chain: **FinStream ← Reefy ← Swiftfin**.

---

## License

This project is licensed under the [Mozilla Public License 2.0](LICENSE.md), the same license as Swiftfin and Reefy. Original copyright and license notices are retained in the source files.
