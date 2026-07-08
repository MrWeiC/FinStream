# WatermelonFin tvOS First-Run UI Review

Date: 2026-07-04

This review covers the tvOS first-run path for adding a server, adding an existing Jellyfin user, and reaching the first usable app state. Local screenshots are stored under `docs/ui-review/screenshots/2026-07-04-round-1/` through `docs/ui-review/screenshots/2026-07-04-round-6/`; that folder is intentionally ignored by git.

## Direction

- Keep the app video-first and remote-friendly: clear focus states, predictable up/down navigation, and no landing-page style onboarding.
- Treat Jellyfin as the source of truth for users and permissions. WatermelonFin should say “add existing user” rather than implying that it creates Jellyfin users.
- Use Chinese as a first-class default experience. Avoid mixed labels such as “最新 Movies” or “最新 Shows”.

## Findings

- The select-user screen had a strong avatar focus, but not enough context explaining whether the user was selecting a saved user or adding a new server-side account.
- The add-user screen treated username/password and Quick Connect with similar visual weight, even though username/password is the expected path for an existing Jellyfin user.
- The public-users empty state occupied too much visual space and used wording that was too literal for Chinese.
- The search empty state lacked a section title and made suggested terms feel like stray text.

## First Iteration

- Select-user now shows a Chinese title and description explaining saved users versus adding another existing Jellyfin user.
- Add-user now uses “添加已有用户 / 添加已有 Jellyfin 用户” wording and labels the server-specific form as adding an existing Jellyfin user to that server.
- The public-users section is now “可见用户”, with a lighter empty state and a short explanation of what it means.
- The search empty state now has a library-search heading, short category hint, and card-style suggested searches.

## Next Iterations

- Refine select-user spacing so the avatar and bottom actions feel less detached.
- Make the server address model resilient to local IP changes by distinguishing manual URL, discovered URL, and last successful URL.
- Re-capture the full page set after a safe logged-in simulator state is available, including search and settings.

## Second Iteration Review

Round 3 screenshots show the first iteration improved wording, but the select-user grid still lets a single user avatar expand to the full five-column cell width. That makes the avatar feel like a poster hero and pushes the account/server actions into a separate visual zone near the bottom of the screen.

For this iteration:

- Cap select-user avatar and add-user icon sizes so one user does not dominate the screen.
- Keep the title and explanation, but reduce the vertical spacer above them.
- Keep the bottom actions in place for now, then re-capture the select-user and add-user pages to see whether the relationship feels tighter before changing navigation behavior.

## Third Iteration Review

The server flow already exposes useful status badges for discovered addresses, but the behavior still required a manual confirmation when the same Jellyfin server ID appeared at a new local IP. That does not match the product need for a home-network media client: if a saved server reboots and DHCP assigns a new IP, the client should recover without making the user re-add the server.

For this iteration:

- Treat Jellyfin server ID as the stable identity.
- When connecting to a URL that resolves to an already-saved server ID, automatically save that URL and make it the current address.
- Keep previously saved URLs, so users can still choose among known addresses in server settings.
- Update local-server helper copy so Chinese users understand discovered servers can update saved addresses automatically.

This is a behavior change behind the existing first-run and server settings UI. A later visual pass should add a small “自动更新” state to the server detail screen, but the main reliability issue is handled in the connection model first.

## Fourth Iteration Review

Round 5 screenshots reached the logged-in home, library, search, settings, and server-detail pages from a clean automation path against the local development server. The remaining high-priority copy issue was mixed-language media library headings: Jellyfin may return default server library names such as `Movies` and `Shows`, which produced awkward Chinese titles like “最新 Movies”.

For this iteration:

- Keep using `collectionType` when Jellyfin provides it, so Movies and TV libraries render as “电影” and “剧集”.
- Add a conservative fallback for common default English library names when `collectionType` is missing, covering `Movies`, `Shows`, `TV Shows`, `Series`, and adjacent Jellyfin defaults.
- Update the server-detail saved-addresses description so it matches the automatic IP recovery behavior instead of implying the user must manually choose the rediscovered address.

This keeps Chinese as the default product language without requiring users to rename their Jellyfin libraries on the server.

## Fifth Iteration Review

Round 6 screenshots covered the logged-in home, TV, movies, search, settings, server detail, select-user, server selector menu, and add-existing-user form. UI Pro Max guidance for this pass emphasized visible focus states, reachable keyboard/remote navigation, clear form labels, and avoiding keyboard traps.

Findings from the screenshots and simulator navigation:

- The add-existing-user form has clear Chinese copy, but the tvOS version did not expose a normal cancel or close action while idle. On a remote-first surface, that creates a trap: users can enter the form accidentally and then have no obvious way back to the user picker.
- The select-user bottom server menu is useful, but it is visually close to “添加已有用户” and can easily receive focus first from the centered avatar. When opened, it visually covers the user name and competes with the add-user action.
- The server detail page now matches the automatic IP update behavior: saved addresses explain that rediscovered IPs are saved and switched automatically.
- The main tabs are consistently Chinese and the home screen no longer depends on Jellyfin English library names for latest-library headings.

Changes for this iteration:

- Add a visible tvOS “取消” action to the add-existing-user form when no sign-in request is running.
- Keep the existing signing-in cancel behavior for cancelling the network request.

Next pass:

- Continue screenshot traversal through playback, media, personalization, diagnostic, and item-detail pages.
- Revisit select-user bottom bar focus order so “添加已有用户” is easier to reach than the server menu when users move down from the selected profile.

## Sixth Iteration Review

Round 7 attempted to continue into deeper settings and item pages, but the simulator repeatedly exposed a more important account-picker issue first: after the app relaunched to the select-user screen, focus landed on the bottom action bar instead of the saved user. Pressing Select opened “添加已有用户”, and pressing Up did not reliably move focus back to the saved profile.

UI Pro Max guidance for this pass flagged focus state visibility and keyboard/remote navigation order as high severity. For a tvOS client, the saved user should be the default action when at least one user exists; secondary actions such as adding another user, switching server filters, and advanced settings should not intercept the first remote click.

Changes for this iteration:

- Bind saved-user grid buttons to an explicit `FocusState`.
- When saved users load, move focus to the first visible saved user if no saved user is already focused.
- Restore focus to the first saved user when leaving edit mode.

Additional screenshots captured after the fix:

- Home after focus recovery.
- Settings overview.
- Video player type menu.
- Video player settings.
- Playback quality settings.
- Diagnostics settings.

The deeper settings screenshots show a second pattern to revisit: long settings lists can land on adjacent rows or menus when driven by remote-only navigation. This is especially visible around “视频播放器类型”, where opening a picker overlays the list and visually competes with the “视频播放器” detail row below it.

Next pass:

- Continue media, personalization, advanced logs, and item-detail screenshots.
- Consider whether settings rows that open a picker should be visually more distinct from rows that navigate to another page.

## Seventh Iteration Review

Round 9 screenshots covered the home latest rows, a movie detail page, the settings overview, and the media library card grid. The home latest headings now read naturally in Chinese (“最新电影” and “最新剧集”), and the item-detail page is broadly coherent in Chinese with clear playback, watched, and favorite actions.

The new high-priority issue is the media grid reached from settings: collection cards still showed Jellyfin server names such as `Movies` and `Shows`. This is the same mixed-language problem as the home latest rows, but it used a different title path (`MediaViewModel.MediaType.displayTitle`) and therefore bypassed the localized library-title mapping.

Changes for this iteration:

- Reuse the localized collection-title mapping for media library cards.
- Add regression coverage so `Movies` and `Shows` collection-folder media cards display as “电影” and “剧集”.

Follow-up plan:

- Continue the remaining settings branches after this localization fix is verified: personalization, diagnostics, advanced logs, and deeper playback/player sheets.
- Improve the settings overview affordance so rows that open inline pickers are easier to distinguish from rows that navigate into detail pages.
- Revisit back/menu behavior from the media grid, because the current tvOS navigation state does not make the path back to the settings list visually obvious.

## Eighth Iteration Review

Round 10 started from the fixed media grid and tried to continue into the remaining settings branches. The media grid itself now displays localized card titles (“电影” and “剧集”), but it exposed a more basic tvOS navigation problem: when the media grid is opened from Settings, the view hides the navigation bar, so there is no visible title, back affordance, or layer cue. Remote navigation then tends to stay inside the grid, and repeated Menu/Up/Left attempts do not make the path back to the settings list obvious.

UI Pro Max guidance for this pass again points to visible focus, reduced clutter, and clear settings navigation. For this app, the media grid can stay full-bleed when it is a top-level media tab, but it should show navigation chrome when it is launched from a settings row.

Changes for this iteration:

- Keep the media tab full-screen by default.
- Show the navigation bar when the same media grid is opened from Settings, so users get a visible title and system back/layer affordance.

Follow-up plan:

- Verify the Settings -> Media path after rebuild with a fresh screenshot.
- Continue with personalization, diagnostics, advanced logs, and deep playback/player settings after the media route no longer traps remote focus.
- Address the personalization screenshot's remaining mixed-language switch values (`On`) with a tvOS-friendly localized switch/value presentation.
- Then revisit settings row affordances for inline pickers versus detail navigation.

## Ninth Iteration Review

Round 10's personalization screenshot showed another Chinese-default problem: SwiftUI's tvOS `Toggle` rows displayed the system value `On` even though the app content is now Chinese. This affects more than one page because many settings branches use the shared custom `Form` wrapper.

UI Pro Max guidance for this pass emphasized visible focus indicators, predictable settings controls, and avoiding mixed-language UI on a Chinese-first surface. The safest fix is to localize switch values at the shared tvOS settings-form layer rather than editing each setting row separately.

Changes for this iteration:

- Add a shared tvOS settings toggle style that displays localized `启用` / `禁用` values.
- Keep the same white focused-row treatment used by other tvOS settings controls, so switches remain remote-friendly.
- Apply the style through the shared `PlatformForm` tvOS branch, covering settings pages that use the project form wrapper.

Follow-up plan:

- Rebuild and re-capture personalization to confirm `On` is gone.
- Continue diagnostics and advanced logs screenshots.
- Review whether inline picker rows need a clearer symbol or value treatment distinct from navigation rows.

## Tenth Iteration Review

Round 11 verified the shared tvOS toggle style and caught one important localization regression in the media library grid. The previous collection-title fix was too aggressive: it used `collectionType` first, so a custom Jellyfin library named `Home School` with a movie collection type was also displayed as “电影”. That made the grid show two indistinguishable “电影” cards.

The corrected rule is:

- Preserve the Jellyfin library name whenever the server provides a non-empty custom name.
- Localize only known default Jellyfin English names such as `Movies`, `Shows`, and `TV Shows`.
- Use `collectionType` as the fallback when the server does not provide a name.

Verification screenshots:

- `docs/ui-review/screenshots/2026-07-04-round-11/02-media-grid-after-custom-name-fix.png` shows `收藏夹`, `Home School`, `电影`, and `剧集`.
- `docs/ui-review/screenshots/2026-07-04-round-11/04-customization-toggle-localized.png` shows settings switch values as `启用` instead of `On`.

Follow-up plan:

- Continue diagnostics and advanced logs screenshots.
- Review inline picker rows so they are visually distinct from rows that navigate to another page.
- Keep custom Jellyfin library names server-owned unless they match known Jellyfin defaults.

## Eleventh Iteration Review

Round 12 covered the home, TV, movies, empty search, settings overview, server detail, select-user, and add-existing-user flows. UI Pro Max guidance for this pass again ranked visible remote focus, predictable keyboard/remote navigation, and clear error/action affordances as high priority.

Screenshots captured:

- `docs/ui-review/screenshots/2026-07-04-round-12/01-home-current.png`
- `docs/ui-review/screenshots/2026-07-04-round-12/02-tv-tab.png`
- `docs/ui-review/screenshots/2026-07-04-round-12/03-movies-tab.png`
- `docs/ui-review/screenshots/2026-07-04-round-12/04-search-tab-empty.png`
- `docs/ui-review/screenshots/2026-07-04-round-12/05-settings-overview.png`
- `docs/ui-review/screenshots/2026-07-04-round-12/06-server-detail.png`
- `docs/ui-review/screenshots/2026-07-04-round-12/07-select-user.png`
- `docs/ui-review/screenshots/2026-07-04-round-12/08-select-user-bottom-focus-after-down.png`
- `docs/ui-review/screenshots/2026-07-04-round-12/09-select-user-after-enter-bottom.png`
- `docs/ui-review/screenshots/2026-07-04-round-12/10-select-user-after-focus-fix-initial.png`
- `docs/ui-review/screenshots/2026-07-04-round-12/11-select-user-add-user-focus-fixed.png`
- `docs/ui-review/screenshots/2026-07-04-round-12/12-add-existing-user-form-fixed.png`

Findings:

- The select-user page copy now correctly says the app adds an existing Jellyfin user rather than creating one.
- The saved user card initially receives focus, but pressing Down from it moved to the centered server-selection menu before the left-side “添加已有用户” action. Pressing Select then opened a server menu, not the add-user form.
- On a one-server setup, “添加已有用户” still behaved like a server chooser when the filter was set to “全部服务器”. This made the happy path two steps longer and looked broken because the only server was already known.
- The server detail page clearly explains automatic saved-address updates for changing local IPs.

Changes for this iteration:

- Add explicit bottom-bar focus tracking so the first Down movement from a saved user lands on “添加已有用户”.
- Keep the server filter and advanced settings reachable from the bottom bar after the add-user action receives focus.
- Treat a single saved server as the add-user target even when the select-user filter is “全部服务器”, so the button opens the username/password form directly.
- Apply the same single-server direct behavior to the empty-state grid add-user button.

Verification:

- `11-select-user-add-user-focus-fixed.png` shows the white tvOS focus on “添加已有用户” after pressing Down from the saved user.
- `12-add-existing-user-form-fixed.png` shows the same remote path opening the “添加已有 Jellyfin 用户” form directly.

Follow-up plan:

- Continue diagnostics, advanced logs, user profile, security, and experimental settings screenshots.
- Review the empty search page for a clearer first-use prompt if it remains visually blank.
- Review settings rows that open inline pickers versus rows that navigate, because the visual affordances still look too similar.

## Twelfth Iteration Review

Round 13 started by trying to continue into deep settings, but the active simulator session surfaced a more relevant first-run issue: the saved user was returning to the existing-user sign-in form, so the select-user and add-existing-user path needed another focus pass before continuing wider screenshots.

UI Pro Max guidance for this pass emphasized:

- Do not leave users in blank or ambiguous states.
- Keep focus indicators visible and predictable for keyboard/remote navigation.
- Make error or re-authentication paths explicit, not visually indistinguishable from unrelated actions.

Screenshots captured:

- `docs/ui-review/screenshots/2026-07-04-round-13/01-add-existing-user-form-baseline.png`
- `docs/ui-review/screenshots/2026-07-04-round-13/02-select-user-focus-after-delayed-restore.png`
- `docs/ui-review/screenshots/2026-07-04-round-13/03-login-form-before-env-login.png`

Findings:

- The search page from round 12 is not actually blank: it shows the search field, a “查找媒体库” prompt, and suggested searches. No immediate change is needed there.
- The add-existing-user form is clear in Chinese and explains that it does not create Jellyfin users.
- The select-user page still relied on an outer `.focused` modifier around `UserGridButton`. That is weak on tvOS because the real focusable element is the nested `Button`, not the wrapper view.
- The active saved user route currently returns to the sign-in form, likely because the local saved user needs a fresh access token. That means entering the form after selecting the saved user is not enough evidence by itself that focus is wrong.

Changes for this iteration:

- Move the saved-user `FocusState` binding into `UserGridButton` and attach it directly to the real `Button`.
- Keep the delayed focus reset that clears bottom-bar focus after tvOS restores its remembered focus.
- Continue treating single-server add-user as a direct sign-in action rather than a server-picker detour.

Verification:

- The app builds and launches after the nested button focus change.
- `02-select-user-focus-after-delayed-restore.png` shows the bottom bar no longer presenting “添加已有用户” as the active white-focused button after delayed restoration.
- The active saved-user account still routes to the sign-in form in this simulator state, so the next pass should verify the full saved-user-to-home path after a fresh successful sign-in.

Follow-up plan:

- Re-run the credential sign-in path and confirm whether the saved user has a valid token after submitting the form.
- Once the saved-user-to-home path is stable again, continue diagnostics, advanced logs, user profile, security, and experimental settings screenshots.
- Revisit whether re-authentication copy should say “重新登录此用户” when launched from a saved user, instead of looking identical to “添加已有用户”.

## Thirteenth Iteration Review

Round 14 focused on the saved-user re-authentication branch and then resumed broad screenshot coverage. UI Pro Max guidance for this pass emphasized visible remote focus, helpful empty states, clear disabled/loading states, and Form-based settings groups.

Screenshots captured:

- `Documentation/ui-review/screenshots/2026-07-04-round-14/upright/01-select-user.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-14/upright/02-reauth-password-focused.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-14/upright/03-quick-connect-accidental.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-14/upright/04-home-after-login.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-14/upright/05-tv-tab.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-14/upright/06-movies-tab.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-14/upright/07-search-tab.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-14/upright/08-settings-root.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-14/upright/09-server-settings.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-14/upright/10-media-settings.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-14/upright/11-diagnostics-settings.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-14/upright/12-advanced-logs.jpg`

Findings:

- Selecting a saved user with a missing or expired Jellyfin token now opens a distinct “重新登录 Jellyfin 用户” form instead of the generic add-existing-user form.
- The re-authentication form pre-fills the saved username, locks that field, focuses the password field, and explains that the user already exists on this Apple TV.
- After the first-time automation test refreshes the token, selecting the saved user goes straight to the home screen.
- The search page is no longer a blank-feeling state. It shows “查找媒体库”, supporting copy, and suggested searches.
- Home, TV, and Movies tabs are Chinese-first; no `Movies` / `Shows` headings appeared in this pass.
- Server settings now explain that rediscovered local IP addresses are saved and switched automatically.
- Advanced logs still contain English control labels: `Errors Only`, `Network Only`, `Network Filters`, `Store Info`, `Remove Logs`, and `Settings`.

Changes for this iteration:

- Route missing-token saved users through `userSignIn(server:reauthenticatingUser:)`.
- Add re-authentication-specific Chinese and English strings.
- Auto-replace the same saved user's access token after successful re-authentication, avoiding the duplicate-user alert.
- Remove the duplicate-user alert's forced authentication-action unwrap by sharing the `saveExistingUser` helper.
- Require both username and password before enabling the password sign-in button.
- Keep the first-time automation path passing against `http://192.168.86.88:8096`.

Verification:

- `swiftformat . --lint --config .swiftformat` passed.
- `git diff --check` passed.
- `swift Scripts/Checks/ValidateATSConfiguration.swift` passed.
- `build_run_sim` for `WatermelonFin tvOS` passed.
- `python3 Scripts/Automation/add_dev_user_from_env.py .env` passed `FirstTimeAccountFlowAutomationTests/testDevServerCanBeAddedFromEmptyLocalState` with 0 failures.

Follow-up plan:

- Localize the advanced logs controls listed above. They come from hard-coded PulseUI tvOS labels, so this likely needs either a small WatermelonFin-owned log view or an upstream/forked PulseUI localization patch.
- Continue settings screenshots for user profile, local security, video player, playback quality, personalization, and any experimental settings pages not yet captured in this round.
- Review settings row affordances so rows that open inline pickers are visually distinct from rows that navigate into detail pages.
- Consider hiding or visually separating Quick Connect on the re-authentication form, because remote navigation can land there when the password sign-in button is disabled.

## Fourteenth Iteration Review

Round 15 focused on the advanced logs page that was still leaking PulseUI's English tvOS labels. UI Pro Max guidance for this pass emphasized visible focus indicators, Form-based settings groups, and readable scrollable log content.

Screenshots captured:

- `Documentation/ui-review/screenshots/2026-07-04-round-15/upright/13-localized-advanced-logs.jpg`

Findings:

- The previous PulseUI tvOS log screen hard-coded labels such as `Errors Only`, `Network Only`, `Store Info`, and `Remove Logs`, so the page could not be made Chinese-first through string resources alone.
- A WatermelonFin-owned tvOS log view now keeps the diagnostics controls in Chinese: `仅错误`, `仅网络`, `日志条目`, `网络请求`, `应用消息`, `刷新`, and `删除日志`.
- Network rows now summarize common states in Chinese. Cancelled image requests display as `已取消` and are not treated as real errors; successful Jellyfin requests display as `200 成功`.
- The page keeps the important debugging data visible: method, path, host, payload size, duration, and timestamp.

Changes for this iteration:

- Route tvOS advanced logs to `LocalizedLogView` while leaving PulseUI's `ConsoleView` in place for non-tvOS builds.
- Add a tvOS-specific log page backed by `LoggerStore.shared` and localized string resources.
- Replace the English/native toggle presentation with focused tvOS buttons that expose `启用` and `禁用`.
- Normalize network status titles so common success and cancellation states do not show English `No Error` or raw `NSURLErrorDomain` titles.

Verification:

- `plutil -lint Translations/en.lproj/Localizable.strings Translations/zh-Hans.lproj/Localizable.strings` passed.
- `swiftformat Shared/Views/SettingsView/DiagnosticsView.swift --config .swiftformat` passed.
- `git diff --check` passed.
- `build_run_sim` for `WatermelonFin tvOS` passed.
- Simulator automation reached Settings -> Diagnostics -> Advanced Logs and confirmed the localized controls and log row titles.

Follow-up plan:

- Continue screenshots for user profile, local security, video player, playback quality, personalization, and experimental settings pages.
- Review whether a log-detail drill-in is needed later. The current view is intentionally readable and localized, but less exhaustive than PulseUI's developer console.
- Continue checking Chinese media labels, especially any remaining headings that could combine Chinese with raw Jellyfin defaults.

## Fifteenth Iteration Review

Round 16 covered the remaining settings branches and a focused pass over hard-coded English labels. UI Pro Max guidance for this pass emphasized visible remote focus, predictable Back behavior, keyboard/remote reachability, Form-based settings groups, and avoiding English leakage in localized UI.

Screenshots captured:

- `Documentation/ui-review/screenshots/2026-07-04-round-16/upright/01-settings-root.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-16/upright/02-user-profile.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-16/upright/03-local-security.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-16/upright/04-video-player-settings.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-16/upright/05-server-settings.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-16/upright/06-playback-quality.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-16/upright/07-media-settings.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-16/upright/08-personalization.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-16/upright/09-personalization-lower.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-16/upright/10-diagnostics.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-16/upright/11-advanced-logs.jpg`

Findings:

- Settings pages are now broadly Chinese-first. User profile, local security, server, playback quality, media, personalization, diagnostics, and advanced logs did not show raw `Movies` / `Shows` headings in this pass.
- Media settings now shows `收藏夹`, `Home School`, `电影`, and `剧集`, preserving a custom Jellyfin library name while localizing default server library names.
- Personalization toggles now show `启用`; no native `On` value appeared in the captured state.
- Advanced logs remain localized after the previous fix, including `200 成功`, `仅错误`, `仅网络`, and `删除日志`.
- Returning from some detail pages can leave inline settings pickers expanded or require a second Back press before navigation returns to the root list. This is not a blocking login issue, but it should be cleaned up because it makes remote automation and real remote navigation feel inconsistent.
- The video player settings copy is mostly localized, but labels like `栏按钮` and `目录按键` still read mechanically and should be renamed in a later copy pass.
- A code review found several hard-coded English labels outside the captured settings screens, including player `Info`/`Information`, `From Beginning`, `Episodes`, `Coming Soon`, and `Unable to load this item.`
- The clearest quantity-format issue was a hard-coded profile summary shaped like `2 Audio, 4 Video`. Chinese should not rely on that English word order.

Changes for this iteration:

- Localize the custom playback profile summary through `audioVideoProfileSummary`, so Chinese can render as `音频 2 个，视频 4 个`.
- Localize player information labels through `L10n.info`.
- Localize player `From Beginning` buttons as `从头播放`.
- Localize the transport-bar episode button with `L10n.episodes`.
- Localize Live TV placeholder copy with `comingSoon`.
- Localize player load-failure alerts with `unableToLoadThisItem`.

Verification:

- `plutil -lint Translations/en.lproj/Localizable.strings Translations/zh-Hans.lproj/Localizable.strings` passed after adding keys.
- `swiftgen` regenerated `Shared/Strings/Strings.swift`.
- `swiftformat` passed on changed files.
- `swiftformat . --lint --config .swiftformat` passed.
- `git diff --check` passed.
- A targeted hard-coded string search no longer finds those English literals in source files, outside generated fallback strings.
- `build_run_sim` for `WatermelonFin tvOS` passed.

Follow-up plan:

- Do one copy-polish pass for mechanically translated settings labels such as `栏按钮`, `目录按键`, `尾值`, and `最新资料库`.
- Review Back behavior from detail settings pages, especially when returning from inline picker states.
- Capture a video-player overlay pass later to verify the newly localized `信息`, `从头播放`, and `剧集` labels in the runtime overlay.

## Sixteenth Iteration Review

Round 17 focused on the Chinese copy polish called out in the previous pass. UI Pro Max guidance for this pass emphasized clear form labels, visible focus, and predictable tvOS navigation.

Screenshots captured:

- `Documentation/ui-review/screenshots/2026-07-04-round-17/upright/01-video-player-copy-polish.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-17/upright/02-personalization-copy-polish.jpg`

Findings:

- Video player settings no longer use mechanically translated labels like `栏按钮`, `目录按键`, or `尾值`.
- The video player page now reads more naturally: `播放栏按钮`, `更多菜单按钮`, `进度预览图`, and `右侧时间显示`.
- Personalization no longer composes the awkward `最新资料库` label through `latestWithString(L10n.library)`.
- The personalization poster rows now use context-specific labels: `继续观看`, `最近添加`, `最新媒体库内容`, `相关推荐`, and `搜索结果`.
- Returning from settings detail pages can still leave focus in a neighboring detail branch or require an extra Back press. This remains the next UX issue to address after copy polish.

Changes for this iteration:

- Replace generic personalization row labels with context-specific keys: `latestMediaLibraries`, `recommendedMedia`, and `searchResults`.
- Change the next-up poster row to use `L10n.nextUp` instead of generic `L10n.next`.
- Polish Chinese labels for playback button settings, menu button settings, progress preview images, poster indicators, recently added media, and trailing time display.
- Regenerate `Shared/Strings/Strings.swift` with SwiftGen.

Verification:

- `build_run_sim` for `WatermelonFin tvOS` passed.
- `swiftformat . --lint --config .swiftformat` passed.
- `plutil -lint Translations/en.lproj/Localizable.strings Translations/zh-Hans.lproj/Localizable.strings` passed.
- `git diff --check` passed.
- Runtime screenshots confirm the updated video player and personalization copy.

Follow-up plan:

- Triage the remaining Back/focus behavior in settings detail pages.
- Capture a video-player overlay pass to verify `信息`, `从头播放`, and `剧集` in playback controls.
- Continue a broader hard-coded text sweep for less common views such as migration recovery and Live TV empty states.

## Seventeenth Iteration Review

Round 18 focused on the playback overlay itself. UI Pro Max guidance for this pass emphasized video-first controls, visible remote focus, and accessible names for icon-only buttons.

Screenshots captured:

- `Documentation/ui-review/screenshots/2026-07-04-round-18/upright/01-player-overlay-english-skip.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-18/upright/02-player-overlay-localized-skip.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-18/upright/05-player-overlay-paused.jpg`

Findings:

- The playback overlay still exposed an English skip hint: `Skip: 1x=15s 2x=2min 3x=5min`.
- The detail page play entry is localized as `从头播放`, and playback launches successfully from the first-time automation path.
- Icon-only overlay buttons were discoverable visually, but the runtime accessibility snapshot exposed weak names such as `Tv` or an empty button name.
- After the fix, the runtime snapshot reports the overlay buttons as `音频`, `剧集`, and `下一集`, and the skip hint is `左右键跳转：1次=15秒 2次=2分钟 3次=5分钟`.
- The visible overlay screenshot confirms the page title and episode metadata are Chinese-first. The skip hint is now localized, though its visual size/contrast should be reviewed in a later polish pass because it sits over subtitles.

Changes for this iteration:

- Replace the hard-coded playback skip hint with `L10n.playbackSkipHint`.
- Add Chinese and English string resources for the skip hint.
- Add accessibility labels to `TransportBarButton`, `TransportBarMenu`, and `SidePanelMenu`.
- Replace transport-bar debug labels such as `PlayNext`, `PlayPrevious`, `AutoPlay`, and `AspectFill` with localized strings.
- Localize the Auto Play menu state from hard-coded `On` / `Off` to `启用` / `禁用`.
- Add an explicit `剧集` accessibility label to the side-panel episode button.

Verification:

- `build_run_sim` for `WatermelonFin tvOS` passed.
- Simulator automation reached Home -> item detail -> `从头播放` -> playback overlay.
- Runtime snapshot confirmed localized button names: `音频`, `剧集`, and `下一集`.
- Runtime snapshot confirmed the localized skip hint text.
- `swiftformat` passed on the changed playback control files.
- `plutil -lint Translations/en.lproj/Localizable.strings Translations/zh-Hans.lproj/Localizable.strings` passed.

Follow-up plan:

- Review the visual styling of the skip hint so it remains readable over subtitles and bright video frames.
- Continue the Back/focus behavior pass for settings detail pages.
- Continue the hard-coded text sweep for uncommon flows and error states.

## Eighteenth Iteration Review

Round 19 focused on settings Back/focus behavior. UI Pro Max guidance for this pass emphasized predictable Back navigation, visible focus, and making contextual help follow the focused control.

Screenshots captured:

- `Documentation/ui-review/screenshots/2026-07-04-round-19/upright/01-settings-root-before-back-test.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-19/upright/02-video-player-detail-before-back.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-19/upright/03-after-back-focus-jump.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-19/upright/04-after-back-focused-help-fixed.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-19/upright/05-player-type-help-still-scoped.jpg`

Findings:

- Back from `视频播放器` correctly returned to the settings root list.
- The visible focus returned to the `视频播放器` row, but the left help panel still showed `视频播放器类型` help copy (`WatermelonFin` / `原生 (AVKit)`).
- The root cause was section-level help: the entire `播放` section advertised the same `formLearnMore` content, so rows for `视频播放器` and `播放质量` inherited help that only described the player type picker.
- After the fix, focusing `视频播放器` returns the left panel to the WatermelonFin brand image, while focusing `视频播放器类型` still shows the WatermelonFin/native-player explanation.

Changes for this iteration:

- Scoped the tvOS player-type help to the `视频播放器类型` row with a row-level `formLearnMore` focused value.
- Kept the iOS playback section Learn More behavior unchanged.
- Left the navigation stack behavior untouched because Back itself was working; the confusing part was stale/context-wrong help.

Verification:

- `build_run_sim` for `WatermelonFin tvOS` passed.
- Simulator automation reproduced the issue via Settings -> `视频播放器` -> Back.
- Runtime snapshot after the fix no longer includes `WatermelonFin` / `原生 (AVKit)` help text when focus is on `视频播放器`.
- Runtime snapshot confirms the help text still appears when focus moves to `视频播放器类型`.

Follow-up plan:

- Continue checking settings detail pages where row-level help is tied to multi-row sections.
- Review less common flows and error states for hard-coded English.
- Later polish: consider adding context-specific help for rows like `视频播放器` and `播放质量`, instead of showing only the brand image.

## Nineteenth Iteration Review

Round 20 focused on uncommon empty/error states. UI Pro Max guidance for this pass emphasized helpful empty states, clear recovery copy, and localized error messages that do not leave users stranded.

Screenshots captured:

- `Documentation/ui-review/screenshots/2026-07-04-round-20/upright/01-live-tv-empty-before.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-20/upright/02-live-tv-empty-after.jpg`

Findings:

- The Live TV empty state was reachable from Home -> TV -> Live and displayed `直播 / 即将上映`.
- `即将上映` reads like a movie release date, not a product feature or TV capability. For this empty state, `即将推出` is more neutral and clearer.
- A hard-coded text scan found English in high-stress fallback flows: migration failure, media playback errors, player recovery suggestions, and the episode queue supplement's `Next` / `Previous` buttons.
- UI Pro Max treats error recovery and empty states as high-sensitivity UX: the user should get a localized explanation and a next step when something fails.

Changes for this iteration:

- Localized `AppLoadingView` migration failure title, description, and recovery checklist.
- Localized `MediaError` titles and descriptions.
- Localized `MediaPlayerError` descriptions and recovery suggestions.
- Localized episode queue supplement buttons from hard-coded `Next` / `Previous` to `下一集` / `上一集`.
- Changed the Chinese `comingSoon` translation from `即将上映` to `即将推出`.

Verification:

- `build_run_sim` for `WatermelonFin tvOS` passed after the string and error changes.
- Simulator automation confirmed Live TV now displays `直播 / 即将推出`.
- `swiftformat . --lint --config .swiftformat` passed.
- `plutil -lint Translations/en.lproj/Localizable.strings Translations/zh-Hans.lproj/Localizable.strings` passed.
- `git diff --check` passed.
- Targeted hard-coded string search no longer finds the migrated user-facing English strings, outside comments/resource fallbacks.

Follow-up plan:

- Continue the hard-coded text sweep for remaining rare views such as download/offline flows and custom profile editing.
- Consider adding a short secondary line or action to the Live TV empty state later, so it gives users a clearer expectation than only `即将推出`.
- Review the remaining player error surfaces visually if we can trigger representative failure states in the simulator.

## Twentieth Iteration Review

Round 21 focused on download/offline fallback copy and settings menu accessibility. UI Pro Max guidance for this pass emphasized form controls with clear semantic labels, localized error recovery, and avoiding blank interactive targets.

Screenshots captured:

- `Documentation/ui-review/screenshots/2026-07-04-round-21/upright/01-playback-quality-blank-menu-labels.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-21/upright/02-playback-quality-menu-labels-fixed.jpg`

Findings:

- Code review found download task failures still returning English: `Not enough storage`, `Item missing required ID`, and `Failed to encode item metadata`.
- The download error type only declared a `localizedDescription` property while conforming to `Error`; when surfaced as a generic `Error`, that custom property may not be used by Swift's standard localization path.
- The Playback Quality page was visually localized, but runtime snapshots exposed blank menu targets for `最大比特率`, `测试大小`, and `兼容性`.
- The custom profile settings files already use `L10n` for visible labels such as `配置文件`, `行为`, `配置`, `音频`, `视频`, `容器`, and warning copy.

Changes for this iteration:

- Changed `DownloadTask.DownloadError` to conform to `LocalizedError`.
- Added localized download error messages for insufficient storage, missing item IDs, and metadata save failures.
- Added accessibility labels and values to `ListRowMenu` for string-backed settings rows.
- Kept `Text`-backed `ListRowMenu` initializers compatible while improving the common string-backed path used by settings pages.

Verification:

- `build_run_sim` for `WatermelonFin tvOS` passed after the download and `ListRowMenu` changes.
- Runtime snapshot before the fix exposed blank menu buttons on Playback Quality.
- Runtime snapshot after the fix reports `最大比特率 | 自动`, `测试大小 | 常规`, and `兼容性 | 自动`.
- `swiftformat . --lint --config .swiftformat` passed.
- `plutil -lint Translations/en.lproj/Localizable.strings Translations/zh-Hans.lproj/Localizable.strings` passed.
- `git diff --check` passed.
- Targeted search now only finds the old download English in English resources or logs, not user-facing Chinese UI paths.

Follow-up plan:

- Trigger or simulate a real download/offline failure view later to inspect the complete user-facing presentation.
- Continue scanning remaining admin/editing flows that pass raw `error.localizedDescription` into `ErrorMessage`.
- Consider extending `ListRowMenu` semantic labels for the few `Text`-backed custom initializers if snapshots show any of them as blank targets.

## Twenty-First Iteration Review

Round 22 focused on the tvOS Search page and empty-state copy. UI Pro Max guidance for this pass emphasized that a no-results state should not feel like a dead end: it should name what failed and offer a clear next step.

Screenshots captured:

- `Documentation/ui-review/screenshots/2026-07-04-round-22/upright/search-suggestions.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-22/upright/search-with-suggestion-query.jpg`

Findings:

- The default Search page is now fully Chinese in the simulator: `查找媒体库`, `电影、剧集、人物和更多内容`, and `建议搜索`.
- The current no-results state only used the generic `没有结果。`, which is too abrupt for a focused search experience.
- tvOS search keyboard automation is currently brittle in this simulator: `type_text` cannot focus the SwiftUI `.searchable` field, direct AX taps fail on the rotated simulator coordinate probe, and hardware key entry does not reliably reach the text field.
- A direction-key fallback can navigate the keyboard, but focus can jump from the keyboard into result cards, so it is not reliable enough for a repeatable no-results screenshot yet.

Changes for this iteration:

- Added optional secondary description support to `EmptyStateView`.
- Changed the Search no-results state to show the attempted query with a localized title.
- Added localized Search recovery copy:
  - English: `No results for “%@”` / `Check the spelling, or try another title, series, or person.`
  - Chinese: `未找到“%@”` / `请检查拼写，或试试其他片名、剧名或人物名称。`

Verification:

- `build_run_sim` for `WatermelonFin tvOS` passed after the Search empty-state change.
- Runtime snapshot confirmed the Search suggestions page is Chinese.
- `swiftformat . --lint --config .swiftformat` passed.
- `plutil -lint Translations/en.lproj/Localizable.strings Translations/zh-Hans.lproj/Localizable.strings` passed.
- `git diff --check` passed.
- SwiftGen was regenerated after adding the new strings.

Follow-up plan:

- Next priority: fix Chinese count/plural formatting such as `2 电影` so it reads naturally as `2 部电影`.
- Add a more reliable automation hook for Search no-results, either through a UI test helper or a deterministic debug launch state, so screenshots can cover this state without fighting tvOS keyboard focus.
- Continue the remaining hard-coded text pass for less common settings and media detail surfaces.

## Twenty-Second Iteration Review

Round 23 focused on Chinese media-type labels and count phrasing. UI Pro Max guidance for this pass emphasized that Chinese UI should use natural Chinese reading patterns instead of English plural/category grammar.

Screenshots captured:

- `Documentation/ui-review/screenshots/2026-07-04-round-23/upright/home.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-23/upright/movies.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-23/upright/tv-before.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-23/upright/tv-after.jpg`

Findings:

- Home and Movies were visually stable in Chinese and did not expose a visible `2 电影` count string.
- The TV tab still used `电视节目` for the shows section. In this app, `剧集` is the clearer label and matches existing `最新剧集` wording.
- Code search did not find an active SwiftUI path that directly rendered `count + movies`. The likely risk is future reuse of English-style plural labels in count strings.
- Collection detail sections fetch up to 20 items per type, so changing section headers to `20 部电影` would be misleading without a true total count from the server.

Changes for this iteration:

- Changed Simplified Chinese `tvShows` and `tvShowsCapitalized` from `电视节目` to `剧集`.
- Added localized media count labels:
  - `movieCountLabel`: `2 部电影`
  - `seriesCountLabel`: `2 部剧集`
  - `episodeCountLabel`: `2 集`
  - `collectionCountLabel`: `2 个合集`
  - `itemCountLabel`: `2 个项目`
- Added `BaseItemKind.localizedCountLabel(_:)` so future count UI can use a single localized formatting path.
- Added tests covering the Chinese count labels to prevent regressions like `2 电影`.

Verification:

- `build_run_sim` for `WatermelonFin tvOS` passed after the string and helper changes.
- Simulator runtime snapshot confirmed the TV section pill changed from `电视节目` to `剧集`.
- `xcodebuild test -project WatermelonFin.xcodeproj -scheme 'WatermelonFin tvOS Tests' -destination 'platform=tvOS Simulator,id=AAFE64CE-367E-48B8-9E6D-C48EDD46DC74' -only-testing:'WatermelonFin tvOS Tests/BaseItemDtoUserDataTests' -skipMacroValidation` passed: 15 tests, 0 failures.
- `swiftformat . --lint --config .swiftformat` passed.
- `plutil -lint Translations/en.lproj/Localizable.strings Translations/zh-Hans.lproj/Localizable.strings` passed.
- `git diff --check` passed.
- SwiftGen was regenerated after adding the new count strings.

Follow-up plan:

- Continue scanning remaining detail and settings pages for English-style noun phrases, especially generated metadata or server-origin labels.
- If a future page needs media totals, fetch or store the real total count first, then render it through `BaseItemKind.localizedCountLabel(_:)`.
- Continue screenshot coverage for Settings subpages and item detail pages, since those still have the highest chance of rare copy issues.

## Twenty-Third Iteration Review

Round 24 focused on Settings, Diagnostics, and Advanced Logs. UI Pro Max guidance for this pass emphasized stable focus states, accessible form labels, clear control names, and avoiding hover/focus effects that shift layout.

Screenshots captured:

- `Documentation/ui-review/screenshots/2026-07-04-round-24/upright/settings-root.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-24/upright/settings-scrolled.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-24/upright/diagnostics-before-log-focus-fix.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-24/upright/advanced-logs-before-focus-fix.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-24/upright/advanced-logs-after-focus-fix.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-24/upright/advanced-logs-filter-focused-after.jpg`

Findings:

- Settings root is now consistently Chinese and shows the active server at `192.168.86.88`.
- The Customize detail page exposes clear Chinese labels for missing items, poster labels, poster type menus, and random images.
- Diagnostics presents server name, current address, and Advanced Logs in Chinese.
- Advanced Logs exposes usable Chinese labels for filters, counts, refresh, remove logs, and network status rows.
- The Advanced Logs filter buttons used a focused `scaleEffect(1.04)`. On tvOS forms this can make adjacent rows feel unstable or clipped, especially in the fixed-width right settings column.
- Automation note: elementRef tap still fails on the rotated tvOS simulator because the tool cannot always resolve landscape coordinates. Remote key navigation was reliable enough to reach Diagnostics and Advanced Logs.

Changes for this iteration:

- Removed the focused scale transform from Advanced Logs filter buttons.
- Reduced the filter button background corner radius from 10 to 8 to match the tighter settings-control style.
- Kept the white focused background, text/value contrast, and accessibility value behavior intact.

Verification:

- `build_run_sim` for `WatermelonFin tvOS` passed after the Diagnostics focus-state change.
- Simulator screenshots confirm Advanced Logs still renders the filter controls, counts, and actions correctly after the change.
- Runtime snapshot confirms Advanced Logs filter buttons have accessible labels and values such as `仅错误, 禁用` and `仅网络, 启用`.
- `swiftformat . --lint --config .swiftformat` passed.
- `plutil -lint Translations/en.lproj/Localizable.strings Translations/zh-Hans.lproj/Localizable.strings` passed.
- `git diff --check` passed.

Follow-up plan:

- Continue Settings coverage with Playback Quality and Video Player detail pages, where menu rows and contextual help are still high-risk for focus/label issues.
- Continue scanning item detail/player surfaces for hard-coded supplement titles such as playback-rate controls.
- Consider adding a deterministic UI automation helper for Settings deep links so future review rounds can jump directly to subpages without relying on long remote-key sequences.

## Twenty-Fourth Iteration Review

Round 25 focused on Playback Quality and Video Player settings. UI Pro Max guidance for this pass emphasized stable tvOS form rows, clear accessibility values, and Chinese labels that match player terminology rather than English category names.

Screenshots captured:

- `Documentation/ui-review/screenshots/2026-07-04-round-25/upright/settings-playback-entry.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-25/upright/video-player-settings.jpg`
- `Documentation/ui-review/screenshots/2026-07-04-round-25/upright/playback-quality-settings.jpg`

Findings:

- Settings root now exposes the playback entry points in Chinese: `视频播放器类型`, `视频播放器`, and `播放质量`.
- Video Player settings are mostly natural Chinese and expose useful row values such as `播放栏按钮`, `更多菜单按钮`, `偏移 0s`, `章节滑块 启用`, `进度预览图`, `右侧时间显示 剩余时间`, and `音频输出 自动`.
- Playback Quality settings are also Chinese in the runtime snapshot, including `最大比特率|自动`, `测试大小|常规`, and `兼容性|自动`.
- Code search still found a hard-coded `Playback Rate` title in `PlaybackRateMediaPlayerSupplement`, which could surface as English inside player controls.

Changes for this iteration:

- Changed `PlaybackRateMediaPlayerSupplement.displayTitle` to use the localized `L10n.playbackSpeed` string.
- Changed the supplement's internal id from the user-facing English phrase to `playbackRate`.
- Added a targeted test to keep the playback-rate supplement title localized.

Verification:

- `build_run_sim` for `WatermelonFin tvOS` passed before this documentation update, with only the existing `ServerTicks` deprecation warning.
- Simulator screenshots confirm the Playback Quality and Video Player settings pages render Chinese labels and row values.
- Runtime snapshot confirms Playback Quality exposes accessible labels and values such as `最大比特率|自动`, `测试大小|常规`, and `兼容性|自动`.
- `xcodebuild test -project WatermelonFin.xcodeproj -scheme 'WatermelonFin tvOS Tests' -destination 'platform=tvOS Simulator,id=AAFE64CE-367E-48B8-9E6D-C48EDD46DC74' -only-testing:'WatermelonFin tvOS Tests/BaseItemDtoUserDataTests' -skipMacroValidation` passed: 16 tests, 0 failures.
- `swiftformat . --lint --config .swiftformat` passed.
- `plutil -lint Translations/en.lproj/Localizable.strings Translations/zh-Hans.lproj/Localizable.strings` passed.
- `git diff --check` passed.
- Code search confirmed no remaining `Playback Rate` user-facing hits under the player supplement/control paths.

Follow-up plan:

- Continue with live playback overlay screenshots and player control focus states, since those are the most likely remaining place for supplement/action labels to leak English.
- Decide whether the playback-rate supplement should be exposed on tvOS or removed if it is no longer part of the active player controls.
- Continue scanning less common action buttons and media detail metadata for English-style phrasing before doing the final UI review pass.
