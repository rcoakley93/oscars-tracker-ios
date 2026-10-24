# What to test

Paste the section for a build into App Store Connect → TestFlight → the build → Test Details. Keep it under 4,000 characters.

## First Phase 4 build (all native screens)

Thanks for testing Oscars Tracker. This build has every screen rebuilt for iOS 27. Please try:

- **Sign in** with Apple, Google or email. Forgot password should email you a link that opens the app.
- **Films:** mark a few films watched (tap the circle on a poster) and unwatch one. The hero count and the season line under the tab bar should follow.
- **A film:** tap a poster. Check where to watch, the "have seen it" line for your group, and Share.
- **Plan:** add a film to tonight, drag one to another day, swipe one away, and try "Fill my plan" and "What can I watch?".
- **Ballot:** pick in a few categories. Each picked card folds to one line; tap it to change your pick. Finishing the ballot should sparkle.
- **Board:** switch between Global and your group (the people icon at the top), and tap someone to see their films.
- **Groups:** create a group, share the invite, and have a friend join with the code. Leave or delete a test group afterwards.
- **Profile:** change the voice between Host and Classic and watch the app's lines change. Turn notifications on.
- **Offline:** turn on Airplane Mode, mark a film watched and make a pick, then turn it off. Both should stick.
- **Bigger text:** Settings → Accessibility → Display & Text Size → Larger Text. Every screen should still read.

Tell us anything that looks wrong, reads oddly, or loses your place, with a screenshot if you can (shake or use the TestFlight app's Send Beta Feedback).

Known gaps: push notifications don't arrive yet. Deleting an account that signs in with Apple fails until the server side is switched on.
