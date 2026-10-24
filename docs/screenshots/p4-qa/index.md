# Phase 4 visual QA matrix (P4-14)

Sample data (`-sample-data`), recaptured Oct 24, 2026 with the five-tab bar (Search in the Films toolbar). "large" is `accessibility-large` (SwiftUI `.accessibility2`), dark. Each cell links the shot; half resolution JPEG.

| Screen | iPhone 18 Pro (27.0) | Duo outer (27.1) | Duo inner (27.1) | iPad Pro 11" portrait (27.0) | iPad landscape |
|---|---|---|---|---|---|
| Films | [dark](films-iphone-dark.jpg) · [light](films-iphone-light.jpg) · [large](films-iphone-large.jpg) | [dark](films-duo-outer-dark.jpg) · [light](films-duo-outer-light.jpg) | — | [dark](films-ipad-dark.jpg) · [light](films-ipad-light.jpg) | [dark](films-ipad-landscape-dark.jpg) |
| Movie sheet (KPop Demon Hunters) | [dark](movie-iphone-dark.jpg) · [light](movie-iphone-light.jpg) · [large](movie-iphone-large.jpg) | [dark](movie-duo-outer-dark.jpg) · [light](movie-duo-outer-light.jpg) | — | [dark](movie-ipad-dark.jpg) · [light](movie-ipad-light.jpg) | [dark](movie-ipad-landscape-dark.jpg) |
| Plan | [dark](plan-iphone-dark.jpg) · [light](plan-iphone-light.jpg) · [large](plan-iphone-large.jpg) | [dark](plan-duo-outer-dark.jpg) · [light](plan-duo-outer-light.jpg) | — | [dark](plan-ipad-dark.jpg) · [light](plan-ipad-light.jpg) | [dark](plan-ipad-landscape-dark.jpg) |
| Ballot | [dark](ballot-iphone-dark.jpg) · [light](ballot-iphone-light.jpg) · [large](ballot-iphone-large.jpg) | [dark](ballot-duo-outer-dark.jpg) · [light](ballot-duo-outer-light.jpg) | — | [dark](ballot-ipad-dark.jpg) · [light](ballot-ipad-light.jpg) | [dark](ballot-ipad-landscape-dark.jpg) |
| Board | [dark](boards-iphone-dark.jpg) · [light](boards-iphone-light.jpg) · [large](boards-iphone-large.jpg) | [dark](boards-duo-outer-dark.jpg) · [light](boards-duo-outer-light.jpg) | — | [dark](boards-ipad-dark.jpg) · [light](boards-ipad-light.jpg) | [dark](boards-ipad-landscape-dark.jpg) |
| Groups (Movies LLC open) | [dark](groups-iphone-dark.jpg) · [light](groups-iphone-light.jpg) · [large](groups-iphone-large.jpg) | [dark](groups-duo-outer-dark.jpg) · [light](groups-duo-outer-light.jpg) | — | [dark](groups-ipad-dark.jpg) · [light](groups-ipad-light.jpg) | [dark](groups-ipad-landscape-dark.jpg) |
| Profile | [dark](profile-iphone-dark.jpg) · [light](profile-iphone-light.jpg) · [large](profile-iphone-large.jpg) | [dark](profile-duo-outer-dark.jpg) · [light](profile-duo-outer-light.jpg) | — | [dark](profile-ipad-dark.jpg) · [light](profile-ipad-light.jpg) | [dark](profile-ipad-landscape-dark.jpg) |
| Sign-in | [dark](signin-iphone-dark.jpg) · [light](signin-iphone-light.jpg) · [large](signin-iphone-large.jpg) | [dark](signin-duo-outer-dark.jpg) · [light](signin-duo-outer-light.jpg) | — | [dark](signin-ipad-dark.jpg) · [light](signin-ipad-light.jpg) | [dark](signin-ipad-landscape-dark.jpg) |

Duo inner: pending the Simulator unfold (Device Hub's fold control can't be driven from the command line). The P3-11 inner set is in [`../p3-11/`](../p3-11/).

## Findings for review

1. **iPhone tab bar overflowed into More (fixed).** Five tabs plus a search tab didn't fit an iPhone, so Groups and Search sat under More, and Groups' detail showed two back buttons. Search is now a sheet from a Films toolbar button, so the five tabs fit everywhere and Groups has one back button.
2. **Notification taps crashed the app (fixed here).** Tapping any notification closed the app: the `nonisolated async` `didReceive` returned to UIKit off the main thread. Build `testflight/2026-10-24.2` has this bug; the next build has the fix.
3. **Compact Ballot didn't scroll to a category (fixed).** A push, link or search result for a category opened the Ballot but stayed at the top. Checked with `-full-ballot` (24 categories): launch at category 15, a push to `/category/19` from Films, and a push to `/category/13` with the Ballot open all land on their card now.

## iPad: rotation, Split View and Stage Manager widths

Checked on the iPad Pro 11" (27.0), Ballot with a category open, then Plan, Films with a film open:

| Check | Result |
|---|---|
| Rotate to landscape | Sidebar tab view, two columns, state kept. See the landscape column above. |
| Narrow window (~345 pt, the Split View third / Slide Over width) | One column with the compact tab bar; the open category's pick kept. [ballot](ipad-multitasking/narrow-window-ballot.jpg), [plan](ipad-multitasking/narrow-window-plan.jpg), [movie sheet](ipad-multitasking/narrow-window-movie.jpg) |
| Medium window (~700 pt, half screen) | Two columns, nothing clipped once the resize settles. [ballot](ipad-multitasking/medium-window-ballot.jpg), [plan](ipad-multitasking/medium-window-plan.jpg) |

Windows were resized by dragging the window corner in iPadOS's windowed multitasking (the Stage Manager window model); a relaunch restores full screen. No layout bugs found.

## VoiceOver: ballot pick

`OscarsTrackerUITests/BallotAccessibilityTests` (run with the `OscarsTrackerUITests` scheme; not in the Tests workflow) picks a nominee, reopens a folded card and changes an acting pick through accessibility elements only, then runs `performAccessibilityAudit()` on the Ballot. Fixed here:

- A folded card's pick ("Your pick: …") opened on tap but wasn't a button to VoiceOver. It now has the button trait, a hint and a default action.
- The season ticker's tap target was its text line (16 pt tall); it now fills the accessory.

Excused in the audit, on purpose: the season ticker and the ballot status bar stop growing at a set text size (P3-10, with the Large Content Viewer), and the ticker's contrast check samples the glass over posters behind its system-vibrant text.

## Notification tap routing

`xcrun simctl push` with send-push's payload (`{"aps": {"alert": …}, "path": …}`) on the iPhone 18 Pro, app in the background, banner tapped. Every path send-push accepts lands on its screen: [proof sheet](push-routing-iphone.jpg) (taken before the tab bar change, so it still shows More).

| path | Lands on |
|---|---|
| `/films`, `/plan`, `/ballot`, `/board`, `/groups` | That tab |
| `/movie/3` | The film's sheet over the current tab |
| `/category/2` | Ballot tab, scrolled to the category (see finding 3) |
| `/group/2` | Groups, that group's detail |
| `/` | The app as it was |

A banner tapped with the app open (the `willPresent` path) routes the same way.

## How to recapture

Debug builds take `-sample-data`, `-signed-out`, `-full-ballot`, `-appearance light|dark`, `-tab`, `-movie`, `-category`, `-group` and `-sheet profile`. The iPad and Duo simulators ignore `simctl ui appearance`, hence `-appearance`.
