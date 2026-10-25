# App Store listing: Oscars Tracker (P6-11)

Status: **draft for review** (Oct 24, 2026). Claude drafted it; the user reviews it and enters it in App Store Connect (P6-12 submits, target Jan 8, 2027). Voice follows the backend's `docs/design/voice.md`: Host-flavoured, short sentences, sentence case, digits for numbers, no jokes about real people. Store copy is the one place the Host speaks to people who haven't picked a voice yet, so the cheek stays light and every line still carries its facts.

Trademark rule (P5-00, guideline 5.2.1): the *name* is "Oscars Tracker" and stays so. The icon has no statuette. The description says the app tracks "the Academy Awards" once, in plain words, and never claims to be official. No Oscar marks in the subtitle, keywords, screenshots' captions or the promo text.

## App information

| Field | Value | Limit |
|---|---|---|
| Name | Oscars Tracker | 30 |
| Subtitle | Watch, pick, beat your friends | 30 (30 used) |
| Category | Primary: Entertainment. Secondary: Lifestyle (or Social Networking if groups lead the story) | |
| Privacy policy URL | https://oscarstracker.com/privacy | |
| Support URL | https://oscarstracker.com/support | |
| Marketing URL | https://oscarstracker.com | optional |
| Copyright | 2027 Ryan Coakley (confirm the legal name to show) | |

Site check, Oct 24: `/privacy`, `/support` and `/terms` answer 200, but the response is still the old web app's HTML shell. P5-02's new copy must be live before submission; recheck both URLs then.

## Promotional text (170 max; editable without a new build)

> The ballot opens when the nominations land. Make your picks, lock them before the show, and watch the board change as the winners are read.

(Swap in the live line near the ceremony: "Ballots lock at showtime. Last chance to pick." Facts and dates come from `app_config`, so check the date before pasting.)

## Description (4000 max)

> Oscars Tracker is the app for people who take awards night a little too seriously. It tracks the Academy Awards from the nominations to the final envelope.
>
> WATCH THE NOMINEES
> Every nominated film in one place, with posters, runtimes and where each one is streaming. Mark what you've seen. Filter by category. See how many films you have left and how many days you have to watch them.
>
> PLAN YOUR WATCHING
> Drop films onto the days you have. The planner fills a weekend for you if you ask, and tells you which films slipped.
>
> MAKE YOUR PICKS
> One pick per category on a ballot that scrolls like a ballot should. Change your mind as often as you like until it locks. It locks before the ceremony, and the time is on the screen.
>
> BEAT YOUR FRIENDS
> Start a group, share the invite link, and see who is ahead. Everyone is on the global board too. Past seasons keep your record.
>
> FOLLOW THE NIGHT
> When the show starts, winners appear as they are announced and the board moves with them. Turn on notifications for ballot reminders and results. Nothing else.
>
> MADE FOR YOUR DEVICE
> Built for iPhone and iPad, with two panes where there's room, Dynamic Type, VoiceOver and dark mode. Choose the Host (a witty emcee) or Classic (the same facts, said straight).
>
> Sign in with Apple, Google or email. Delete your account any time from Profile.
>
> Film data and posters come from TMDB. Where-to-watch data comes from JustWatch. Oscars Tracker is an independent fan app. It is not affiliated with, endorsed by or sponsored by the Academy of Motion Picture Arts and Sciences or ABC.

Check before pasting: the "FOLLOW THE NIGHT" and planner lines describe Phase 6 features (P6-03 live mode, notifications, plan filler). Cut any that don't ship by Jan 8. "Oscars" appears only in the app name; "Academy Awards" appears once in the opening line and once in the disclaimer, with the organisation named in the disclaimer.

## Keywords (100 max, comma-separated, no spaces)

```
awards,ballot,predictions,nominees,movies,film,watchlist,pool,picks,leaderboard,streaming,cinema
```

Rules applied: no words already in the name or subtitle ("oscars", "tracker", "watch", "pick", "beat", "friends"), no singular and plural pairs, no "Oscar" or "Academy" (trademark risk in the keyword field), no competitor names. 96 characters.

## Privacy nutrition labels

Derived from the code and the schema, Oct 24. Re-derive if a Phase 6 feature adds a collection point (the P6 sessions are still changing screens). Answer "Yes, we collect data" and "No" to tracking. There is no ATT prompt, no analytics SDK, no crash SDK, no ads, and no `AdSupport` import. The only networked dependencies are Supabase (`Services/SupabaseClient.swift`) and the Apple and Google sign-in flows.

| Apple category | Data type | Collected | Linked to the user | Tracking | Purpose | Where it comes from |
|---|---|---|---|---|---|---|
| Contact Info | Email address | Yes | Yes | No | App functionality (account, password reset) | `Account.email` from Supabase Auth (Apple's private relay address counts) |
| User Content | Other user content | Yes | Yes | No | App functionality | Picks, watched films, watch plan, group names |
| Identifiers | User ID | Yes | Yes | No | App functionality | Supabase user id; the username in `profiles` is shown to group members and boards |
| Identifiers | Device ID | Yes | Yes | No | App functionality (push) | APNs device token in `devices` via `register_device`, only after you turn on notifications; removed on sign-out |
| Usage Data | Product interaction | Yes | Yes | No | App functionality | Scores, ranks and season history computed from your picks and watched films; no behavioural analytics |

Notes for the form:

- **Name and username.** Apple lists "Name" under Contact Info. The app doesn't collect a real name; the username is user-chosen and is an identifier. Don't tick Name.
- **Photos.** The `avatar_url` column exists, but nothing in the app uploads or picks a photo. Don't tick Photos or Videos. Recheck if a Phase 6 session adds avatars.
- **Search and browsing history.** Film search runs against the on-device and Supabase film list and is not stored. Don't tick.
- **Location, contacts, health, financial, diagnostics, sensitive info.** None. No crash or performance data leaves the device except what Apple collects itself (not declared by the developer).
- **Third parties.** Sign in with Apple and Google receive your sign-in, as for any app that offers them. TMDB posters are fetched from TMDB's image CDN by URL; no user data is sent. JustWatch data is synced on the server; the app only links out.
- **Retention.** Account data is deleted when the account is deleted (below).

## Age rating answers

The questionnaire (as of the Jan 2026 revision, with the 13+, 16+ and 18+ tiers):

| Question | Answer |
|---|---|
| Violent, sexual, profane or crude content, horror, alcohol, tobacco or drugs, gambling (simulated or real), medical or wellness | None |
| Contests | None. Pools are for fun, no prizes or money |
| Unrestricted web access | No (links open Safari for TMDB and JustWatch) |
| User-generated content | **Yes, minimal.** Usernames and group names are visible to other people in a group. See the guideline 1.2 note below |
| Messaging or chat | No |
| Advertising | No |
| Parental controls or age assurance | Not required |

Expected result: **4+**. If the user-generated-content answer lifts it, 12+ is still fine for the audience. Film posters can carry R-rated artwork, but the content descriptors above are about the app's own content.

**Guideline 1.2 (user-generated content).** Group names and usernames are the only user text. There is no report or block action in the app today and nothing in the code filters them (`Services/ValidationService.swift` checks shape only). Reviewers do sometimes ask. Options if they do: add "Report" on a group and a member (a `reports` table plus email), or filter names. Not in scope for this draft; flagged for the user.

## Content Rights

Answer **Yes**, the app contains, shows or accesses third-party content, and we have the rights.

- **TMDB** posters, film titles, runtimes and metadata. Attribution is in Profile → About: "This product uses the TMDB API but is not endorsed or certified by TMDB." with a link to themoviedb.org. TMDB's terms require this and allow free non-commercial use; confirm the key's use stays non-commercial.
- **JustWatch** where-to-watch availability, via TMDB's watch-provider data. Attribution is in Profile → About ("Where-to-watch data from JustWatch") and on each film's sheet ("Data from JustWatch").
- Film posters belong to their studios; they are displayed through TMDB's API under its terms.

## Review notes

Paste into App Review Information → Notes. Fill the two placeholders in App Store Connect only. **Never commit a password to this repo.**

> Oscars Tracker lets people follow the Academy Awards nominees, make their picks and compete with friends. It needs an account.
>
> DEMO ACCOUNT
> Email: `<DEMO_EMAIL, entered in App Store Connect only>`
> Password: `<DEMO_PASSWORD, entered in App Store Connect only>`
> Sign in with the email form ("or with email"). The account is a tester account, so it sees a rehearsal ceremony ("Rehearsal: 99th Academy Awards") with an open ballot instead of the live ceremony.
>
> WHAT TO TRY
> 1. Films tab: browse the nominees, open a film, mark it watched.
> 2. Ballot tab: choose a nominee in a category. The pick saves at once. The ballot stays open on the rehearsal ceremony.
> 3. Board tab: the leaderboard. Rehearsal picks never appear on the real leaderboards.
> 4. Groups tab: create a group or join one with an invite code.
> 5. Profile (person icon, top right): sign out, change voice, and Delete account (Profile → scroll to the bottom → Delete account → confirm). Deletion removes the account, picks, watched films, plan and created groups.
>
> NOTES
> - Sign-in options: Sign in with Apple, Google and email and password (guideline 4.8).
> - Push notifications are optional and are asked for from Profile, never at launch.
> - The app is an independent fan app. It is not affiliated with the Academy of Motion Picture Arts and Sciences. Film data: TMDB. Where-to-watch data: JustWatch. Attribution is in Profile → About.
> - Support: https://oscarstracker.com/support. Privacy: https://oscarstracker.com/privacy.
> - Contact for review questions: support@oscarstracker.com (phone: `<PHONE, enter in App Store Connect>`)

**Before submitting (user):**

1. Create the demo account in the app (email sign-up), then set `profiles.is_tester = true` for it in the database (P2-13). Check it signs in and sees the rehearsal ceremony. Do not use Apple or Google sign-in for the demo account.
2. Make sure the rehearsal ceremony's ballot is unlocked on Jan 8 and stays unlocked through review.
3. Keep the account out of any real group and off the real leaderboard.
4. Put the contact email (support@oscarstracker.com) and a phone number in App Review Information. The support page and privacy policy already show support@oscarstracker.com.

## Screenshots

### Sizes App Store Connect asks for (checked Oct 24, 2026; Apple's Screenshot specifications page)

Upload 1 to 10 per size, `.png`, `.jpg` or `.jpeg`, no alpha channel. App Store Connect scales a larger set down if your UI is the same across sizes, but device-specific sets look better.

| Set | Pixels (portrait) | Status |
|---|---|---|
| iPhone 6.9" (Dynamic Island, large) | 1320 × 2868 (also 1290 × 2796, 1260 × 2736) | One *large* iPhone set is required: 6.9" or 6.5". Take the 6.9" set |
| iPhone 6.5" | 1284 × 2778 or 1242 × 2688 | Optional if 6.9" is supplied |
| iPhone 6.1" (Dynamic Island, medium) | 1206 × 2622 or 1179 × 2556 | Listed as required. The iPhone 18 Pro simulator draws this size (1206 × 2622), so capture there |
| iPad 13" | 2064 × 2752 or 2048 × 2732 | **Required**, the app runs on iPad. The iPad Pro 11" simulator makes 11" (1668 × 2420 or 2420 × 1668), which only falls back to 13"; use a 13" iPad simulator for the 13" set |
| iPhone Duo outer | 1398 × 2034 | Required for apps built with the iOS 27.1 SDK or later, **starting April 2027**; optional for a January submission. Capture anyway: this is the Duo's feature story |
| iPhone Duo inner | 2007 × 2853 | Same rule as the outer display |

Lower-priority sizes (5.8", 5.5", 4.7", 4", 3.5", iPad 12.9", 10.5", 9.7") are optional and fall back automatically. Apple Watch, Mac, TV and Vision sets don't apply.

The earlier task text said "iPhone 6.9" and 6.5", iPad 13"". The current rule is: one large iPhone set (6.9" or 6.5"), the 6.1" set, and iPad 13". Confirm the 6.1" requirement in App Store Connect itself when you open the version page; Apple's page is the only source and the label there can change.

### Shot list (do not capture yet; Phase 6 screens are still changing)

Feature the Liquid Glass chrome, and a two-pane layout on the larger screens. Real-looking data from the rehearsal ceremony, dark mode first, Host voice, no debug rows. Use the demo account or `-sample-data`.

| # | Screen | Caption (Host, sentence case) | Sizes |
|---|---|---|---|
| 1 | Films: progress hero and "Still to watch" | Every nominee, one list. | iPhone, iPad (split view), Duo |
| 2 | Ballot with a pick made and the progress bar | One pick per category. Change your mind until lock. | iPhone, iPad (split view), Duo |
| 3 | Ballot pick or the envelope reveal moment | Lock it in. | iPhone |
| 4 | Plan: week agenda with films on days | Plan your watching, day by day. | iPhone, iPad (two-pane) |
| 5 | Board: group leaderboard | Beat your friends. | iPhone, iPad (split view), Duo |
| 6 | Film sheet with where-to-watch | Know where it's streaming. | iPhone |
| 7 | Live mode: winners coming in (P6-03) | Follow the night as it happens. | iPhone, iPad, Duo |
| 8 | iPhone Duo inner display, ballot beside a category or film | Two panes on a fold. | Duo inner |

Captions are one line, sentence case, with no Oscar marks and no jokes at anyone's expense. Capture with `-sample-data` or the demo account on the simulators, save to `docs/screenshots/store/`, and strip alpha before upload (`sips -s format jpeg` or export PNG without transparency).

## Account deletion check (guideline 5.1.1)

**Result: works.** Checked Oct 24, 2026.

Code path:

- `Shell/ProfileSheet.swift`: Profile → "Delete account" (destructive) opens `DeleteAccountSheet`. It states what is deleted and that it can't be undone.
- Email and Google accounts: a "Delete account" button. Apple accounts: a "Continue with Apple" confirmation that supplies an authorization code.
- `Stores/ProfileStore.swift` `deleteAccount`: for an Apple account it first calls the `revoke-apple` edge function with the code and stops if that fails; then it calls the `delete_user` RPC. Nothing signs out unless both succeed, so a failure leaves the account intact and shows an error.
- `App/AppModel.swift` `deleteAccount`: on success clears the per-account offline cache, queued writes and store state, and `SessionStore.didDeleteAccount()` returns to the signed-out screen.
- Backend: `delete_user()` (backend migration `20261022000200_fix_account_deletion.sql`) deletes the caller's `auth.users` row. `profiles`, `push_subscriptions` and created `groups` cascade away (that migration fixed a foreign-key failure that made every earlier call fail).

On the simulator (iPhone 18 Pro, iOS 27.0, `-sample-data` build from this branch): Profile → Delete account → the confirmation sheet → Delete account → the app returned to the sign-in screen. Because `-sample-data` uses the in-memory data source, this proves the UI flow and the state reset, not the live RPC. The live RPC and the Apple revocation are not exercised here: that needs a real account, and I did not create one on the production backend. The backend's `npm run test:db` is the place that should cover the cascade; I did not rerun it.

Before submission (user): delete a throwaway email account and a throwaway Apple account against the real backend on TestFlight, and confirm in Supabase that the user, profile, picks and groups are gone. If the Apple path fails on a device, check that `revoke-apple` has the Sign in with Apple key configured.

Not found, worth a look: the support and privacy pages should repeat the deletion steps (P5-02 says they will).
