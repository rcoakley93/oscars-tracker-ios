# Agent guidelines: Oscars Tracker for iOS

This is the product: a native SwiftUI app for iPhone, iPhone Duo and iPad, iOS 27.1 and later (the target is raised from 26.0 in task P3-13). The season plan, the database and the website live in the backend repo, `~/Documents/Projects/oscars-tracker` (`rcoakley93/oscars-tracker`). Read its `docs/season-2027/README.md` before starting a phase, and `docs/design/brand.md`, `voice.md` and `screens.md` before touching the UI. `screens.md` holds the iOS 27.1 build sheets: one per screen, an element guide and the iPhone Duo rules; build every screen from its sheet and its artboard in the iOS 27.1 mockups canvas it links.

## Project layout
- `OscarsTracker/OscarsTracker.xcodeproj`: one app target (`OscarsTracker`) and one unit-test target (`OscarsTrackerTests`), and a shared scheme.
- **Groups are folder-synced.** Any file in `OscarsTracker/OscarsTracker/` belongs to the app and any file in `OscarsTracker/OscarsTrackerTests/` to the tests. Never edit `project.pbxproj` to add a file. `Info.plist` is excluded from the app's resources by an exception set in the project.
- `OscarsTracker/Config/Shared.xcconfig`: the public Supabase host and anon key, read through `Info.plist` (`SupabaseHost`, `SupabaseAnonKey`) by `Services/SupabaseClient.swift`. Never put the service role key, the APNs key or the TMDB key in this repo.
- `docs/brand/`: the app icon's source image. `docs/archive/`: the 2025–26 product notes and screenshots.

## Build and test
Run Xcode tools with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` (xcode-select points at the Command Line Tools on this Mac).

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project OscarsTracker/OscarsTracker.xcodeproj -scheme OscarsTracker -destination 'platform=iOS Simulator,name=iPhone 18 Pro'
```

- Pick simulators by name and OS that exist on this Mac (`xcrun simctl list devices available`). There is an iPhone Duo simulator on the iOS 27.1 runtime; Device Hub's fold buttons (hold Option for the hinge angle) drive its poses.
- Use the iOS Simulator tools to launch, screenshot and drive the app, and attach the live panel when the user wants to watch.
- CI runs on Xcode Cloud (season plan P3-02), set up in App Store Connect for the `Oscars Tracker` app: **Tests** runs the unit tests on pull requests to `main` and on pushes to `main` (required to pass); **TestFlight** archives `main` and delivers it to TestFlight internal testing. Wait for every check to pass, then merge with `gh pr merge <n> --merge`; never `--auto`, which merges at once (no required checks on this repo).

## Swift settings
- Swift 6 language mode, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, approachable concurrency and `MemberImportVisibility`.
- So: code is main-actor isolated unless marked otherwise. Data types that decode from the network or cross actors are `nonisolated` (every `Codable` model is). Import every module whose members you use (`Combine` for `@Published`, `Auth` for Supabase user fields, and so on).
- The test target is still Swift 5 mode with no default isolation, so the old XCTest suite compiles. New tests use Swift Testing (`import Testing`, `@Test`, `#expect`); move old tests over as their code is rewritten, and then switch the test target to Swift 6.

## Architecture (P3-03)
- `App/AppModel.swift`: the app's state, injected with `.environment(model)` and read with `@Environment(AppModel.self)`. It owns one `@Observable` store per area in `Stores/` (session, season, films, ballot, plan, groups, leaderboard, profile) and `AppNavigation`.
- `AppNavigation` holds the selected tab, film, category, day and group, and the open sheet. Keep navigation state there, never in views, so a fold or unfold of an iPhone Duo keeps it.
- `Data/AppDataSource.swift` is every backend call. `LiveDataSource` talks to Supabase; `SampleDataSource` serves a sample season in memory for previews (`AppModel.preview()`) and tests. Its `failure` property makes every call fail, to preview error states.
- Stores change state optimistically and roll back on failure, setting `actionError` (an `AppError` with friendly text) for the view to show. `LoadState` drives skeletons, content and error views.
- `Utilities/PlanDay.swift`: `PlanDay` is a calendar day in the viewer's time zone (watch plans). Deadlines are `Date` instants (`Ceremony.ballotLockAt`). `Runtime.format` is the one runtime formatter.
- The old `ViewModels/` and `Views/` still run the current screens. Each is deleted when Phase 4 rebuilds its screen on the stores.

## Conventions
- Prefer system components and their iOS 27 behaviour: `TabView` with `Tab` (plus the search tab and the season ticker in `tabViewBottomAccessory`), `NavigationStack` and `NavigationSplitView`, toolbars, sheets with detents, `Menu`, `.buttonStyle(.glass)` and `.glassProminent`, SF Symbols.
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
