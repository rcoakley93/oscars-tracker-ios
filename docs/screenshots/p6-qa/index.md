# Phase 6 visual QA matrix (P6-10)

Sample data (`-sample-data`), captured Oct 25, 2026 on iPhone 18 Pro (27.0), iPhone Duo (27.1) and iPad Pro 11" (27.0). "large" is `accessibility-large`, dark. Half-resolution JPEGs. Same method as [P4-14](../p4-qa/index.md).

The Mac was overloaded for most of the run, so some cells are **not taken**: a shot that came back blank was deleted rather than kept.

| Screen | iPhone 18 Pro | Duo outer | Duo inner | iPad Pro 11" |
|---|---|---|---|---|
| Results recap (sheet) | [dark](recap-iphone-dark.jpg) · [light](recap-iphone-light.jpg) · [large](recap-iphone-dark-large.jpg) | [dark](recap-duo-outer-dark.jpg) · [light](recap-duo-outer-light.jpg) | dark: not taken | [dark](recap-ipad-dark.jpg) · [light](recap-ipad-light.jpg) |
| Share card sheet | [dark](share-iphone-dark.jpg) · [light](share-iphone-light.jpg) · [large](share-iphone-dark-large.jpg) | [dark](share-duo-outer-dark.jpg) · [light](share-duo-outer-light.jpg) | dark: not taken | [dark](share-ipad-dark.jpg) · [light](share-ipad-light.jpg) |
| Admin (Profile → Admin) | [dark](admin-iphone-dark.jpg) · [light](admin-iphone-light.jpg) · [large](admin-iphone-dark-large.jpg) | [dark](admin-duo-outer-dark.jpg) · light: not taken | dark: not taken | [dark](admin-ipad-dark.jpg) · [light](admin-ipad-light.jpg) |
| Ballot with results and points | [dark](ballot-results-iphone-dark.jpg) · [light](ballot-results-iphone-light.jpg) · [large](ballot-results-iphone-dark-large.jpg) | [dark](ballot-results-duo-outer-dark.jpg) · [light](ballot-results-duo-outer-light.jpg) | dark: not taken | [dark](ballot-results-ipad-dark.jpg) · [light](ballot-results-ipad-light.jpg) |
| Films hero after the ceremony | [dark](films-hero-after-iphone-dark.jpg) · light: not taken · [large](films-hero-after-iphone-dark-large.jpg) | [dark](films-hero-after-duo-outer-dark.jpg) · [light](films-hero-after-duo-outer-light.jpg) | dark: not taken | [dark](films-hero-after-ipad-dark.jpg) · [light](films-hero-after-ipad-light.jpg) |
| Movie sheet group lines | [dark](groups-compare-iphone-dark.jpg) · [light](groups-compare-iphone-light.jpg) · [large](groups-compare-iphone-dark-large.jpg) | [dark](groups-compare-duo-outer-dark.jpg) · [light](groups-compare-duo-outer-light.jpg) | [dark](groups-compare-duo-inner-dark.jpg) | [dark](groups-compare-ipad-dark.jpg) · [light](groups-compare-ipad-light.jpg) |
| Profile reminders | [dark](profile-reminders-iphone-dark.jpg) · [light](profile-reminders-iphone-light.jpg) · [large](profile-reminders-iphone-dark-large.jpg) | [dark](profile-reminders-duo-outer-dark.jpg) · [light](profile-reminders-duo-outer-light.jpg) | [dark](profile-reminders-duo-inner-dark.jpg) | [dark](profile-reminders-ipad-dark.jpg) · [light](profile-reminders-ipad-light.jpg) |

## Live mode on the Duo inner display

- [Flat, split: envelope beside the live board, dark](live-split-duo-inner-dark.jpg)
- [Tabletop: reveal above the hinge, board below, dark](live-tabletop-duo-inner-dark.jpg)
- [Side-by-side hinge pose, dark](live-hinged-duo-inner-dark.jpg)

All three were taken before "And the Oscar goes to…" became "And the winner is…", so they show the old line. Light and Large text variants of the inner display: not taken.

## Not taken

- Duo inner: light and Large text for every screen; recap, share, admin, ballot results, ballot shares, films hero. Live Activity (Lock Screen, Dynamic Island compact, minimal, expanded) and the P6-16 Report and Block screens (menus, Blocked people, the Admin report queue): no screenshots; all have SwiftUI previews.
- iPad landscape for every P6 screen.
- Ballot shares ("50% of Movies LLC picked …"): the shots showed "Pens down" twice (status bar and under it), so they were deleted. The duplicate is fixed in this PR but not recaptured.

## Findings

1. **"Pens down" appeared twice on a locked Ballot (fixed).** The status bar and the intro both said it. The intro stays empty now.
2. **Ticker had no Follow button in live mode (fixed).** It showed Ballot; it now shows Follow when the Live Activity can start, and starts it.
3. **"1 pts" (fixed).** Category points say "1 pt" and "2 pts".
4. **"And the Oscar goes to…" (changed)** to "And the winner is…", per the user.
5. **Duo inner display: the season ticker floats over the lists** (see [films](../p4-qa/films-duo-inner-dark.jpg), [boards](../p4-qa/boards-duo-inner-dark.jpg)) and covers the last row. Not fixed here.
6. **New: results recap** from the ticker's Recap button after the show: gold score, "And that's a wrap" (Host) or "The results" (Classic), how many winners you called, your place, each category. Gold dust only if you called at least one.
