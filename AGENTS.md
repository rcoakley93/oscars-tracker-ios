# Agent guidelines: Oscars Tracker for iOS

This is the product: a native SwiftUI app for iPhone, iPhone Duo and iPad, iOS 27.0 and later (raised from 26.0 in P3-13 to 27.1, then lowered to 27.0 on Oct 24 so phones not yet on 27.1 can test; the iPhone Duo's 27.1 APIs sit behind `#available(iOS 27.1, *)`). The season plan, the database and the website live in the backend repo, `~/Documents/Projects/oscars-tracker` (`rcoakley93/oscars-tracker`). Read its `docs/season-2027/README.md` before starting a phase, and `docs/design/brand.md`, `voice.md` and `screens.md` before touching the UI. `screens.md` holds the iOS 27.1 build sheets: one per screen, an element guide and the iPhone Duo rules; build every screen from its sheet and its artboard in the iOS 27.1 mockups canvas it links.

## Project layout
- `OscarsTracker/OscarsTracker.xcodeproj`: one app target (`OscarsTracker`) and one unit-test target (`OscarsTrackerTests`), and a shared scheme.
- `OscarsTracker/OscarsTrackerWidgets/`: the widget extension (`OscarsTrackerWidgets`, `com.oscars.tracker.widgets`), embedded in the app. It holds the ceremony-night Live Activity (P6-03); P6-09's widgets join its `WidgetBundle`. `OscarsTracker/Shared/` is compiled into both the app and the extension (`CeremonyActivityAttributes`, its copy). The extension also takes the app's `Design/Theme.swift` and `Resources/Assets.xcassets` through a membership exception in the project, so the colour sets and `Theme` work there; add a file to that exception only if it needs nothing else from the app.
- **Groups are folder-synced.** Any file in `OscarsTracker/OscarsTracker/` belongs to the app and any file in `OscarsTracker/OscarsTrackerTests/` to the tests. Never edit `project.pbxproj` to add a file. `Info.plist` is excluded from the app's resources by an exception set in the project.
- `OscarsTracker/Config/Shared.xcconfig`: the public Supabase host and anon key, read through `Info.plist` (`SupabaseHost`, `SupabaseAnonKey`) by `Services/SupabaseClient.swift`. `SITE_HOST` (Info.plist `SiteHost`) is the website's host for invite links, `oscarstracker.com` (P5-00); it and `applinks:<host>` in the entitlements change together, and the site serves the `apple-app-site-association` file for `/join/*` (P5-03). Never put the service role key, the APNs key or the TMDB key in this repo.
- `docs/brand/`: the app icon's source image. `docs/archive/`: the 2025–26 product notes and screenshots.

## Build and test
Run Xcode tools with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` (xcode-select points at the Command Line Tools on this Mac).

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project OscarsTracker/OscarsTracker.xcodeproj -scheme OscarsTracker -destination 'platform=iOS Simulator,name=iPhone Duo'
```

- The deployment target is iOS 27.0. The iOS 27.1 simulator runtime supports only the iPhone Duo; the iPhone 18 Pro and iPad Pro 11" simulators run iOS 27.0. The Duo APIs are iOS 27.1-only, so they go through `Utilities/DuoCompatibility.swift` (toolbar compression, the hinge, `SplitArrangement`) or an `#available(iOS 27.1, *)` check (`FoldLayout`). Pick simulators by name and OS that exist (`xcrun simctl list devices available`). Device Hub's fold buttons (hold Option for the hinge angle) drive the Duo's poses.
- Use the iOS Simulator tools to launch, screenshot and drive the app, and attach the live panel when the user wants to watch.
- UI tests (`OscarsTracker/OscarsTrackerUITests/`, XCTest) run from their own scheme, `OscarsTrackerUITests`, on an iPhone simulator; the Tests workflow doesn't run them. The ballot test there walks a pick by accessibility elements and audits the screen (P4-14).
- CI runs on Xcode Cloud (season plan P3-02), set up in App Store Connect for the `Oscars Tracker` app: **Tests** runs the unit tests on pull requests to `main` and on pushes to `main` (required to pass); **TestFlight** starts only on a tag beginning with `testflight/` (since Oct 23; merges to `main` no longer ship) and delivers to the internal group. Ship a build on purpose, at most about once a day: `git tag testflight/<YYYY-MM-DD> && git push origin testflight/<YYYY-MM-DD>`. **Default** archives `main` with no distribution. Wait for every check to pass, then merge with `gh pr merge <n> --merge`; never `--auto`, which merges at once (no required checks on this repo).

## Swift settings
- Swift 6 language mode, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, approachable concurrency and `MemberImportVisibility`.
- So: code is main-actor isolated unless marked otherwise. Data types that decode from the network or cross actors are `nonisolated` (every `Codable` model is). Import every module whose members you use (`Combine` for `@Published`, `Auth` for Supabase user fields, and so on).
- The test target has the same settings (P3-13). New tests use Swift Testing (`import Testing`, `@Test`, `#expect`). The old XCTest classes are `nonisolated` with `@MainActor` test methods and async `setUp`/`tearDown`; move them to Swift Testing as Phase 4 rewrites their code, or delete them with the view model they test.

## Architecture (P3-03)
- `App/AppModel.swift`: the app's state, injected with `.environment(model)` and read with `@Environment(AppModel.self)`. It owns one `@Observable` store per area in `Stores/` (session, season, films, ballot, plan, groups, leaderboard, profile) and `AppNavigation`.
- `AppNavigation` holds the selected tab, film, category, day and group, and the open sheet. Keep navigation state there, never in views, so a fold or unfold of an iPhone Duo keeps it.
- `Data/AppDataSource.swift` is every backend call. `LiveDataSource` talks to Supabase; `SampleDataSource` serves a sample season in memory for previews (`AppModel.preview()`) and tests. Its `failure` property makes every call fail, to preview error states.
- Stores change state optimistically and roll back on failure, setting `actionError` (an `AppError` with friendly text) for the view to show. `LoadState` drives skeletons, content and error views.
- `Utilities/PlanDay.swift`: `PlanDay` is a calendar day in the viewer's time zone (watch plans). Deadlines are `Date` instants (`Ceremony.ballotLockAt`). `Runtime.format` is the one runtime formatter.
- Offline (P4-11): `AppModel` shows the last good copy (`Data/OfflineCache.swift`, per account in Caches) at launch, queues watched toggles and picks made offline (`PendingWrite`) and sends them first on the next refresh or when `Connectivity` sees the network return. Stores show errors through `.errorAlert(_:error:)` bound to `actionError`.
- Every screen runs on the stores; the old `ViewModels/` and `Views/` are gone (P4-11).

## Conventions
- Prefer system components and their iOS 27 behaviour: `TabView` with five `Tab`s (search is a sheet from the Films toolbar, so the five fit on an iPhone; the season ticker is in `tabViewBottomAccessory`), `NavigationStack` and `NavigationSplitView`, toolbars, sheets with detents, `Menu`, `.buttonStyle(.glass)` and `.glassProminent`, SF Symbols.
- Custom glass is counted: at most one `glassEffect` element per screen (the hero) plus one `GlassEffectContainer` of chips. Never on list content, never with its own shadow, stroke or highlight. Under Reduce Transparency or Increase Contrast it becomes `solidSurface`.
- The ambient layer is one `MeshGradient` per screen, behind the scroll view, coloured from the posters on screen; static under Reduce Motion, flat under Reduce Transparency.
- Every toolbar item has a title and a symbol, sits in a `ToolbarItemGroup` and carries a `visibilityPriority`; sorting and filtering go in `ToolbarOverflowMenu`. On the iPhone Duo's outer display the bars are vertical and items overflow bottom to top.
- Two panes come from the container that fits: `NavigationSplitView` for master and detail (Films, Ballot, Board, Groups), `ArrangementView` for two views with no navigation between them (Plan, live mode). Layout follows size classes and reserved regions, never the device model; the hinge angle only drives delight.
- A screen's one persistent status bar (ballot progress, films to reschedule) is a `safeAreaBar(edge: .top)`; the bottom edge belongs to the ticker and the tab bar.
- System text styles, so Dynamic Type works. `@ScaledMetric` for any size that must grow with text.
- `@Observable` stores injected through `AppModel` (see Architecture). Never add a new `ObservableObject`.
- Every screen has previews with sample data, no network, named Dark, Light and Large text (`.dynamicTypeSize(.accessibility2)`), plus one per non-trivial state. Before a PR, screenshots on the iPhone 18 Pro, the iPhone Duo (both displays, folded mid-task) and the iPad Pro 11" simulators go in `docs/screenshots/`.
- Gold is earned: it marks progress, your picks and wins, nothing decorative.
- The group model is `PoolGroup`, so SwiftUI's `Group` is free to use.
- Acting categories lead with the person (`detail_text`) and show the film underneath. Show years with `Text(verbatim:)` so 2025 doesn't become "2,025".
