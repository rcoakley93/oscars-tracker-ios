# Agent guidelines: Oscars Tracker for iOS

This is the product: a native SwiftUI app for iPhone, iPhone Duo and iPad, iOS 26 and later. The season plan, the database and the website live in the backend repo, `~/Documents/Projects/oscars-tracker` (`rcoakley93/oscars-tracker`). Read its `docs/season-2027/README.md` before starting a phase, and `docs/design/brand.md` and `voice.md` before touching the UI.

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

- Pick simulators by name and OS that exist on this Mac (`xcrun simctl list devices available`). There is an iPhone Duo simulator on the iOS 27.1 runtime.
- Use the iOS Simulator tools to launch, screenshot and drive the app, and attach the live panel when the user wants to watch.
- CI runs on Xcode Cloud (season plan P3-02). Wait for every check to pass, then merge with `gh pr merge <n> --merge`; never `--auto`, which merges at once (no required checks on this repo).

## Swift settings
- Swift 6 language mode, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, approachable concurrency and `MemberImportVisibility`.
- So: code is main-actor isolated unless marked otherwise. Data types that decode from the network or cross actors are `nonisolated` (every `Codable` model is). Import every module whose members you use (`Combine` for `@Published`, `Auth` for Supabase user fields, and so on).
- The test target is still Swift 5 mode with no default isolation, so the old XCTest suite compiles. New tests use Swift Testing (`import Testing`, `@Test`, `#expect`); move old tests over as their code is rewritten, and then switch the test target to Swift 6.

## Conventions
- Prefer system components and their iOS 26 behaviour: `TabView` with `Tab`, `NavigationStack` and `NavigationSplitView`, toolbars, sheets with detents, `Menu`, `.buttonStyle(.glass)` and `.glassProminent`, SF Symbols. `glassEffect` only for custom floating elements, never on list content.
- System text styles, so Dynamic Type works. `@ScaledMetric` for any size that must grow with text.
- `@Observable` models injected through the environment (the old `ObservableObject` view models are replaced in P3-03).
- Every screen has previews with sample data, no network, in dark, light and a large text size.
- Gold is earned: it marks progress, your picks and wins, nothing decorative.
- The `Group` model clashes with SwiftUI's `Group`; it is being renamed in P3-03. Until then, don't use SwiftUI's `Group` in files that see the model.
- Acting categories lead with the person (`detail_text`) and show the film underneath. Show years with `Text(verbatim:)` so 2025 doesn't become "2,025".
