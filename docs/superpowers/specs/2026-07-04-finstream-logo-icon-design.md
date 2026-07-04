# FinStream Logo And Icon Design

Date: 2026-07-04

## Approved Direction

FinStream will use the "Subtle Nod" direction selected during visual review. The identity should feel modern, premium, and app-icon-first, with only a quiet reference to Jellyfin rather than a direct clone of Jellyfin's triangular mark.

The core mark is a rounded-square obsidian badge containing aqua-to-blue stream/current lines and a forward play arrow. A small angular highlight near the top keeps a memory of Jellyfin's triangular geometry, but the primary read should be FinStream as its own media app.

## Visual Principles

- Modern tvOS app icon first: readable from a distance, strong at large screen sizes, and clean at small in-app sizes.
- Dark cinematic base: deep navy/obsidian surfaces with subtle luminous accents.
- Jellyfin-adjacent, not Jellyfin-identical: preserve lineage through color energy and a small triangular cue, not through the full nested-triangle silhouette.
- Motion without clutter: use stream/current strokes that imply playback, flow, and forward movement.
- Simple export set: generate assets that fit the existing Xcode asset catalog without changing app code.

## Palette

- Obsidian background: `#050711`, `#070912`, `#08131D`
- Cyan stream: `#25C4FF`
- Aqua accent: `#27F5B8`
- Electric blue endpoint: `#4B7BFF`
- White wordmark and highlights: `#FFFFFF` with controlled opacity for secondary highlights

## Logo System

The set should include:

- Standalone icon mark for compact use.
- Horizontal wordmark with icon plus `FinStream`.
- Existing-size in-app logo replacements for `finstream-logo.imageset`.
- tvOS layered app icon assets with distinct back and front layers.
- App Store layered icon assets at existing required sizes.
- Top shelf standard and wide images using the same visual language.

## Asset Targets

Generate replacements for the existing files in:

- `Swiftfin tvOS/Resources/Assets.xcassets/finstream-logo.imageset/`
- `Swiftfin tvOS/Resources/Assets.xcassets/App Icon & Top Shelf Image.brandassets/App Icon.imagestack/`
- `Swiftfin tvOS/Resources/Assets.xcassets/App Icon & Top Shelf Image.brandassets/App Icon - App Store.imagestack/`
- `Swiftfin tvOS/Resources/Assets.xcassets/App Icon & Top Shelf Image.brandassets/Top Shelf Image.imageset/`
- `Swiftfin tvOS/Resources/Assets.xcassets/App Icon & Top Shelf Image.brandassets/Top Shelf Image Wide.imageset/`

Keep the existing `Contents.json` structures intact unless a generated filename needs to match an already referenced slot.

Required export dimensions:

- `finstream-logo.png`: `100 x 60` RGBA
- `finstream-logo@2x.png`: `200 x 120` RGBA
- `finstream-logo@3x.png`: `300 x 180` RGBA
- tvOS app icon back/front layers: `400 x 240` and `800 x 480`
- App Store back/front layers: `400 x 240` and `1280 x 768`
- Top shelf image: `1920 x 720` and `3840 x 1440`
- Top shelf wide image: `2320 x 720` and `4640 x 1440`

## Implementation Notes

Use generated raster PNGs for tvOS icon and top shelf assets because those asset slots already use PNGs. The icon back layer should carry the dark cinematic gradient and subtle motion depth. The front layer should contain the rounded-square FinStream mark with transparency where required by the existing front-layer assets.

The wordmark should be bold, geometric, and readable, matching the current simple `FinStream` brand lockup while feeling more polished. Use white text on transparent or dark backgrounds depending on the target slot. Avoid thin strokes that disappear at `1x` sizes.

## Verification

After asset generation:

- Confirm every referenced PNG exists at the size expected by the current asset catalogs.
- Inspect the generated logo, app icon front/back layers, and top shelf images visually.
- Check `git status` to ensure only intended branding assets and this approved spec are changed.
- Run an Xcode asset/catalog validation or tvOS build check when local signing and the installed toolchain allow it; if the build is blocked by environment setup, record the exact blocker.

## Non-Goals

- Do not redesign app UI screens.
- Do not rename app targets or asset catalogs.
- Do not introduce a new design system dependency.
- Do not make FinStream look like a direct Jellyfin recolor.
