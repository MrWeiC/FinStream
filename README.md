<div align="center">

# WatermelonFin

**A tvOS-focused Jellyfin client**

<img src="https://img.shields.io/badge/tvOS-17+-blue"/>
<img src="https://img.shields.io/badge/Jellyfin-10.11-9962be"/>
<img src="https://img.shields.io/badge/License-MPL%202.0-brightgreen"/>

</div>

> **Note:** WatermelonFin is an independent project. It is **not affiliated with or endorsed by** [Jellyfin](https://jellyfin.org), [Swiftfin](https://github.com/jellyfin/Swiftfin), or [Reefy](https://github.com/jmhunter83/reefy). It is developed separately with a focus on Apple TV.

---

## About

**WatermelonFin** is a native Jellyfin media client built exclusively for Apple TV. It uses MPV for direct playback and is designed to feel native on tvOS.

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

WatermelonFin is free and open source under the MPL 2.0 license. You can build it yourself:

**Requirements:**
- Xcode (latest)
- Apple TV (tvOS 17+ recommended, tvOS 18+ for Liquid Glass effects)
- A Jellyfin media server (10.11+ recommended)

See the [Documentation](Documentation/) directory for build details.

Before opening a pull request, run the local validation commands in [Contributing](Documentation/contributing.md#before-opening-a-pull-request) so GitHub Actions are used for confirmation rather than first-pass lint or build failures.

---

## Acknowledgments

WatermelonFin stands on the work of others:

- [Jellyfin](https://jellyfin.org) — The free software media system
- [Swiftfin](https://github.com/jellyfin/Swiftfin) — The original native Swift Jellyfin client
- [Reefy](https://github.com/jmhunter83/reefy) — A tvOS-focused fork in this project's lineage

The source lineage is: **WatermelonFin <- Reefy <- Swiftfin**.

---

## License

This project is licensed under the [Mozilla Public License 2.0](LICENSE.md). Original copyright and license notices are retained where required by upstream source files.
