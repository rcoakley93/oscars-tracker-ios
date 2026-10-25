# Submission checklist (P6-12)

Prepared Oct 25, 2026 against `main` at 9cdbf32. The user submits and releases in App Store Connect; Claude never does. Target submit: **Jan 8, 2027**. Re-run every "Check" the week before.

## Version number

Decision for the user, sent to the PM (Oct 25). Facts:

- `MARKETING_VERSION` is 1.1 in all four build configurations. `CURRENT_PROJECT_VERSION` is 1; Xcode Cloud sets the build number on its archives.
- TestFlight holds an expired 1.2 (1) from the old Capacitor app. Expiry doesn't delete it; the build stays in the 1.2 train.
- App Store Connect rule (I could not open Apple's own page; this is Apple's long-standing behaviour, confirmed by developer-forum reports): a new store version must be **higher than the last version released on the App Store**, and each build number must be unique and rising *within a version*. TestFlight-only versions don't block anything. If the old app never shipped to the App Store, 1.1, 1.2 and 2.0 are all legal for the first release. Check App Store Connect → the app → the version list: any "Ready for Distribution" version above 1.1 changes this.
- Recommendation: **2.0**. It is a different app (native rewrite), it is above everything in TestFlight history (so no confusion with the expired 1.2), and it reads honestly to anyone who had the old build. 1.3 also works but implies an update to the old app. Whichever is chosen, change `MARKETING_VERSION` in one go (four places in `project.pbxproj`) in the PR that cuts the release build.

## Checks against the code

| # | Item | Result | Evidence / action |
|---|---|---|---|
| 1 | Export compliance | **Pass** | `Info.plist` sets `ITSAppUsesNonExemptEncryption = false`. The app uses only HTTPS (Supabase) and Apple's CryptoKit/`swift-crypto` for the Apple sign-in nonce hash, which are exempt. No App Store Connect export prompt at upload. |
| 2 | Privacy manifest | **Fixed in this PR** | There was no `PrivacyInfo.xcprivacy`. Added `OscarsTracker/OscarsTracker/PrivacyInfo.xcprivacy`: no tracking, no tracking domains; collected data matches the nutrition labels in `listing.md` (email, other user content, user ID, device ID, product interaction; all linked, not tracking, app functionality). Verified it lands in the built `.app`. |
| 3 | Required-reason APIs | **Pass, declared** | Only `UserDefaults` is used in app code (`@AppStorage`, `SessionStore`, `PushStore`, `SeasonStore`) → `NSPrivacyAccessedAPICategoryUserDefaults`, reason `CA92.1` (app's own data). `FileManager` is used only to create and delete files in Caches (`OfflineCache`), which is not a required-reason call. No file-timestamp, disk-space, system-boot-time or active-keyboard calls found by grep. Dependencies: supabase-swift 2.39 and swift-crypto; swift-crypto ships its own manifests, which Xcode merges. **Check at archive time**: Xcode → Product → Archive → Generate Privacy Report, and confirm no "missing manifest" email from App Store Connect after upload. |
| 4 | Sign in with Apple and Google (4.8) | **Pass** | `Shell/SignInView.swift` offers Apple (first), Google and email. Apple is the privacy-equivalent option 4.8 asks for. Entitlement `com.apple.developer.applesignin` is set. `aps-environment` is `development` in the file; Xcode swaps it to production when signing for distribution. |
| 5 | Account deletion (5.1.1) | **Pass in app** | Verified in `listing.md` ("Account deletion check"). The support page also covers "How do I delete my account?" (checked Oct 25). **User still has to** delete a throwaway email and Apple account on TestFlight against the real backend. |
| 6 | Trademark wording (5.2.1) | **Pass; decided Oct 25** | Name, subtitle, keywords, promo text and captions carry no Oscar marks; "Academy Awards" appears once in the description plus the disclaimer. The user decided: the envelope line becomes "And the winner is…" (P6-10 changes it in the app), and "99th Academy Awards" stays as the factual ceremony name, so it is fine in the store images. The Live screenshot is retaken after P6-10 merges. |
| 7 | Age rating | **Ready** | Answers in `listing.md`. Expected 4+ (12+ if the UGC answer lifts it). Re-answer after report/block ships: the questionnaire asks whether the app has UGC *and* whether it has moderation tools. |
| 8 | Content rights | **Ready** | "Yes" (TMDB, JustWatch attribution in Profile → About). Confirm TMDB's non-commercial terms still fit: the app is free with no ads. |
| 9 | User-generated content (1.2) | **In flight** | Report and block is being built in a separate session. The review notes below assume Report on a group and on a member, plus Block, reachable from Groups; correct the notes' navigation to what merges. |
| 10 | Support and privacy URLs | **Live, Oct 25** | `https://oscarstracker.com/privacy` and `/support` return 200 with real pages (titled "Privacy policy · Oscars Tracker" and "Support · Oscars Tracker") and both show support@oscarstracker.com. `/terms` also 200. Recheck the week of submission. |
| 11 | Developer Program renewal | **User, before Jan 18, 2027** | Renew in the Apple Developer account (Membership). An expired membership pulls the app from sale and stops uploads. Do it before submitting, not after. |
| 12 | Version/build | Open | See "Version number". Build comes from an Xcode Cloud archive on a `testflight/<date>` tag, only when the PM asks. |
| 13 | Demo account | User | Create the email account, set `profiles.is_tester = true`, check it sees the rehearsal ceremony. Credentials go in App Store Connect only. |

## Screenshots

Sizes (from `listing.md`, checked Oct 24): iPhone 6.9" 1320 × 2868, iPhone 6.1" 1206 × 2622, iPad 13" 2064 × 2752, and optionally iPhone Duo outer 1398 × 2034 and inner 2007 × 2853 (required from April 2027).

Capture script: `scripts/capture-store-screenshots.sh` builds the app, then for each size boots the simulator, sets dark mode and a clean status bar (9:41), launches with `-sample-data -tab <tab>` (plus `-movie 3`, `-full-ballot`, `-live`), and saves PNGs to `docs/app-store/screenshots/<set>/`. It warns if an image isn't the exact App Store size.

| Set | Simulator | Pixels |
|---|---|---|
| `iphone-6.9` | iPhone 18 Pro Max (iOS 27.0) | 1320 × 2868 |
| `iphone-6.1` | iPhone 18 Pro (iOS 27.0) | 1206 × 2622 |
| `ipad-13` | iPad Pro 13-inch (M5) (iOS 27.0) | 2064 × 2752 |
| `duo-outer` | iPhone Duo (iOS 27.1), folded | 1398 × 2034 |
| `duo-inner` | iPhone Duo, unfolded: capture by hand in Device Hub (the script can't fold), 2007 × 2853 | |

Shots: 01 films, 02 ballot, 03 full ballot, 04 plan, 05 board, 06 film sheet, 07 live mode, 08 ballot share card, 09 results share card (`-sheet share-card`, DEBUG builds). Map them to the captions in the shot list in `listing.md`. Run the script only after the PM says Phase 6 has merged; take captions from `listing.md` (they're added in App Store Connect's marketing frames or a design tool, not by the script).
```bash
scripts/capture-store-screenshots.sh            # all shots, all sizes
scripts/capture-store-screenshots.sh 02-ballot  # one shot
```
