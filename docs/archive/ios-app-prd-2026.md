# Oscar's Tracker iOS App - Product Requirements Document

## Overview

**Product Name:** Oscar's Tracker
**Platform:** iOS (SwiftUI Native)
**Target iOS Version:** iOS 17+
**Device Support:** iPhone and iPad
**Backend:** Existing Supabase infrastructure (shared with web app)

## Executive Summary

Oscar's Tracker is a native SwiftUI iOS application that mirrors the functionality of the existing React web application. The app enables users to track Academy Award nominated movies, make predictions for Oscar winners, plan their movie watching schedule, and compete with friends via prediction pools.

---

## Goals & Objectives

### Primary Goals
1. Deliver a native iOS experience that feels premium and cinematic
2. Maintain feature parity with the web application
3. Share the same backend/database for seamless cross-platform experience
4. Leverage iOS-native features (haptics, widgets, notifications)

### Success Metrics
- User engagement: Daily active users tracking movies
- Feature adoption: % of users making predictions before ballot locks
- Cross-platform usage: Users active on both web and iOS

---

## Target Users

- **Movie enthusiasts** who want to watch all Oscar-nominated films before the ceremony
- **Oscar prediction participants** who compete in prediction pools with friends/family
- **Casual viewers** who want to track what they've watched and plan viewing schedules

---

# Section 1: Data Models & API Specifications

## Swift Data Models

```swift
// MARK: - Movie
struct Movie: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let posterUrl: String?
    let releaseYear: Int?
    let runtimeMinutes: Int?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title
        case posterUrl = "poster_url"
        case releaseYear = "release_year"
        case runtimeMinutes = "runtime_minutes"
        case createdAt = "created_at"
    }

    var formattedRuntime: String {
        guard let minutes = runtimeMinutes else { return "" }
        let hours = minutes / 60
        let mins = minutes % 60
        if hours == 0 { return "\(mins)m" }
        if mins == 0 { return "\(hours)h" }
        return "\(hours)h \(mins)m"
    }
}

// MARK: - Category
struct Category: Codable, Identifiable {
    let id: Int
    let name: String
    let pointsValue: Int?
    let year: Int?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, year
        case pointsValue = "points_value"
        case createdAt = "created_at"
    }
}

// MARK: - Nomination
struct Nomination: Codable, Identifiable {
    let id: Int
    let categoryId: Int?
    let movieId: Int?
    let detailText: String?
    let isWinner: Bool?
    let createdAt: String?

    // Joined data (when fetching with movie)
    var movie: Movie?

    enum CodingKeys: String, CodingKey {
        case id
        case categoryId = "category_id"
        case movieId = "movie_id"
        case detailText = "detail_text"
        case isWinner = "is_winner"
        case createdAt = "created_at"
        case movie
    }
}

// MARK: - CategoryWithNominations
struct CategoryWithNominations: Identifiable {
    let id: Int
    let name: String
    let pointsValue: Int?
    let nominations: [Nomination]
}

// MARK: - UserWatched
struct UserWatched: Codable, Identifiable {
    let id: Int
    let userId: String
    let movieId: Int
    let watchedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case movieId = "movie_id"
        case watchedAt = "watched_at"
    }
}

// MARK: - WatchPlanItem
struct WatchPlanItem: Codable, Identifiable {
    let id: Int
    let userId: String
    let movieId: Int
    let plannedDate: String
    let createdAt: String?

    // Joined data
    var movie: Movie?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case movieId = "movie_id"
        case plannedDate = "planned_date"
        case createdAt = "created_at"
        case movie
    }

    var isMissed: Bool {
        guard let date = ISO8601DateFormatter().date(from: plannedDate + "T00:00:00Z") else {
            return false
        }
        return date < Calendar.current.startOfDay(for: Date())
    }
}

// MARK: - UserPrediction
struct UserPrediction: Codable, Identifiable {
    let id: Int
    let userId: String
    let categoryId: Int
    let nominationId: Int
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case categoryId = "category_id"
        case nominationId = "nomination_id"
        case createdAt = "created_at"
    }
}

// MARK: - Group
struct Group: Codable, Identifiable {
    let id: Int
    let name: String
    let createdBy: String
    let inviteCode: String
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case createdBy = "created_by"
        case inviteCode = "invite_code"
        case createdAt = "created_at"
    }
}

// MARK: - GroupMember
struct GroupMember: Codable, Identifiable {
    let id: Int
    let groupId: Int?
    let userId: String?
    let joinedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case groupId = "group_id"
        case userId = "user_id"
        case joinedAt = "joined_at"
    }
}

// MARK: - Profile
struct Profile: Codable, Identifiable {
    let id: String
    var username: String?
    var avatarUrl: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, username
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - LeaderboardEntry (from RPC function)
struct LeaderboardEntry: Codable, Identifiable {
    var id: String { userId }
    let userId: String
    let username: String
    let avatarUrl: String?
    let watchedCount: Int
    let predictionScore: Int
    let lastWatchedAt: String?
    let rank: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
        case avatarUrl = "avatar_url"
        case watchedCount = "watched_count"
        case predictionScore = "prediction_score"
        case lastWatchedAt = "last_watched_at"
        case rank
    }
}
```

## Supabase API Mappings

| Operation | Supabase Query |
|-----------|----------------|
| Fetch all movies | `supabase.from("movies").select("*")` |
| Fetch user watched | `supabase.from("user_watched").select("*").eq("user_id", userId)` |
| Toggle watched (add) | `supabase.from("user_watched").insert(["user_id": userId, "movie_id": movieId])` |
| Toggle watched (remove) | `supabase.from("user_watched").delete().eq("user_id", userId).eq("movie_id", movieId)` |
| Fetch watch plan | `supabase.from("watch_plan").select("*, movie:movies(*)").eq("user_id", userId)` |
| Add to watch plan | `supabase.from("watch_plan").insert(["user_id": userId, "movie_id": movieId, "planned_date": date])` |
| Reschedule movie | `supabase.from("watch_plan").update(["planned_date": newDate]).eq("id", planId)` |
| Remove from plan | `supabase.from("watch_plan").delete().eq("id", planId)` |
| Fetch categories with nominations | `supabase.from("categories").select("*, nominations(*, movie:movies(*))").order("points_value", ascending: false)` |
| Fetch user predictions | `supabase.from("user_predictions").select("*").eq("user_id", userId)` |
| Save prediction | `supabase.from("user_predictions").upsert(["user_id": userId, "category_id": categoryId, "nomination_id": nominationId], onConflict: "user_id,category_id")` |
| Fetch leaderboard | `supabase.rpc("get_leaderboard")` |
| Fetch groups (created) | `supabase.from("groups").select("*").eq("created_by", userId)` |
| Fetch groups (joined) | `supabase.from("group_members").select("*, group:groups(*)").eq("user_id", userId)` |
| Create group | `supabase.from("groups").insert(["name": name, "created_by": userId])` |
| Join group | `supabase.from("group_members").insert(["group_id": groupId, "user_id": userId])` |
| Find group by invite code | `supabase.from("groups").select("*").eq("invite_code", code).single()` |
| Update profile | `supabase.from("profiles").update(["username": username]).eq("id", userId)` |
| Delete account | `supabase.rpc("delete_user")` |

---

# Section 2: Design System Specifications

## Color Palette (HSL Values)

### Core Colors
| Token | HSL | Hex Equivalent | Usage |
|-------|-----|----------------|-------|
| `background` | 0 0% 5% | #0D0D0D | Main app background |
| `foreground` | 45 20% 95% | #F5F3EF | Primary text |
| `card` | 0 0% 8% | #141414 | Card backgrounds |
| `card-foreground` | 45 20% 95% | #F5F3EF | Card text |
| `primary` | 43 74% 49% | #D4A017 | Gold accent (buttons, highlights) |
| `primary-foreground` | 0 0% 5% | #0D0D0D | Text on gold |
| `secondary` | 0 0% 12% | #1F1F1F | Secondary backgrounds |
| `muted` | 0 0% 15% | #262626 | Muted backgrounds |
| `muted-foreground` | 45 10% 60% | #A39E8F | Secondary text |
| `destructive` | 0 62% 50% | #D12F2F | Error states, delete actions |
| `border` | 0 0% 18% | #2E2E2E | Borders |

### Gold Palette
| Token | HSL | Usage |
|-------|-----|-------|
| `gold` | 43 74% 49% | Primary gold |
| `gold-light` | 43 74% 65% | Lighter gold accents |
| `gold-dark` | 43 74% 35% | Darker gold |

### SwiftUI Color Extension
```swift
extension Color {
    // Backgrounds
    static let appBackground = Color(hue: 0, saturation: 0, brightness: 0.05)
    static let cardBackground = Color(hue: 0, saturation: 0, brightness: 0.08)
    static let secondaryBackground = Color(hue: 0, saturation: 0, brightness: 0.12)

    // Gold Theme
    static let goldPrimary = Color(hue: 43/360, saturation: 0.74, brightness: 0.49)
    static let goldLight = Color(hue: 43/360, saturation: 0.74, brightness: 0.65)
    static let goldDark = Color(hue: 43/360, saturation: 0.74, brightness: 0.35)

    // Text
    static let textPrimary = Color(hue: 45/360, saturation: 0.20, brightness: 0.95)
    static let textMuted = Color(hue: 45/360, saturation: 0.10, brightness: 0.60)

    // Semantic
    static let destructive = Color(hue: 0, saturation: 0.62, brightness: 0.50)
    static let borderColor = Color(hue: 0, saturation: 0, brightness: 0.18)
}
```

### Gold Gradient
```swift
extension LinearGradient {
    static let gold = LinearGradient(
        colors: [
            Color(hex: "#FDE68A"), // amber-200
            Color(hex: "#EAB308"), // yellow-500
            Color(hex: "#FCD34D")  // amber-300
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
}
```

## Typography

### Font Families
| Usage | Web Font | iOS Equivalent |
|-------|----------|----------------|
| Display/Headings | Outfit | SF Pro Rounded (Bold) or custom Outfit font |
| Body | Inter | SF Pro Text |

### Type Scale
| Style | Size | Weight | Line Height | Usage |
|-------|------|--------|-------------|-------|
| Large Title | 34pt | Bold | 1.2 | Screen titles |
| Title 1 | 28pt | Bold | 1.2 | Section headers |
| Title 2 | 22pt | Bold | 1.2 | Card titles |
| Title 3 | 20pt | Semibold | 1.3 | Subsection headers |
| Headline | 17pt | Semibold | 1.3 | Emphasized body |
| Body | 17pt | Regular | 1.4 | Primary body text |
| Callout | 16pt | Regular | 1.4 | Secondary info |
| Subheadline | 15pt | Regular | 1.4 | Labels |
| Footnote | 13pt | Regular | 1.3 | Metadata, timestamps |
| Caption | 12pt | Regular | 1.2 | Smallest text |

### SwiftUI Font Extension
```swift
extension Font {
    static let displayLarge = Font.system(size: 34, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 28, weight: .bold, design: .rounded)
    static let displaySmall = Font.system(size: 22, weight: .bold, design: .rounded)
    static let headingLarge = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let headingMedium = Font.system(size: 17, weight: .semibold)
    static let bodyLarge = Font.system(size: 17, weight: .regular)
    static let bodyMedium = Font.system(size: 15, weight: .regular)
    static let caption = Font.system(size: 13, weight: .regular)
    static let captionSmall = Font.system(size: 12, weight: .regular)
}
```

## Component Specifications

### Card Component
```swift
struct GlassCard<Content: View>: View {
    let content: Content

    var body: some View {
        content
            .padding(16)
            .background(.ultraThinMaterial)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}
```

### Gold Glow Effect
```swift
struct GoldGlow: ViewModifier {
    var intensity: Double = 0.3

    func body(content: Content) -> some View {
        content
            .shadow(color: Color.goldPrimary.opacity(intensity), radius: 10, x: 0, y: 0)
            .shadow(color: Color.goldPrimary.opacity(intensity * 0.5), radius: 20, x: 0, y: 0)
    }
}
```

### Button Styles
```swift
struct GoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(LinearGradient.gold)
            .foregroundColor(.black)
            .font(.headingMedium)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.secondaryBackground)
            .foregroundColor(.textPrimary)
            .font(.bodyMedium)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.borderColor, lineWidth: 1)
            )
    }
}
```

## Spacing System
| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 4pt | Tight spacing |
| `sm` | 8pt | Element padding |
| `md` | 12pt | Component gaps |
| `lg` | 16pt | Section padding |
| `xl` | 24pt | Major sections |
| `2xl` | 32pt | Screen padding |

## Border Radius
| Token | Value |
|-------|-------|
| `sm` | 4pt |
| `md` | 8pt |
| `lg` | 12pt |
| `xl` | 16pt |
| `full` | 9999pt (pill) |

---

# Section 3: UI/UX Specifications

## Navigation Architecture

### Tab Bar Structure
```
+-----------------------------------------------------------+
|                    App Content                            |
+---------+---------+---------+---------+-------------------+
| Dashboard|Watch Plan| Ballot |Leaderboard|    More        |
|    film |  calendar| seal   |  trophy  |    ellipsis     |
+---------+---------+---------+---------+-------------------+
```

**Tab Items:**
1. **Dashboard** - Home icon (SF Symbol: `film`)
2. **Watch Plan** - Calendar icon (SF Symbol: `calendar`)
3. **Ballot** - Ballot icon (SF Symbol: `checkmark.seal`)
4. **Leaderboard** - Trophy icon (SF Symbol: `trophy`)
5. **More** - Ellipsis (SF Symbol: `ellipsis`) -> Opens menu for Groups + Profile

### Screen Flow Diagram
```
Auth Flow:
+---------+    +----------+    +-----------+    +-----------+
| Launch  |--->|  Login   |--->| Onboarding|--->| Dashboard |
| Screen  |    |  Screen  |    | (new user)|    |           |
+---------+    +----------+    +-----------+    +-----------+
                    |
                    v
              +----------+
              |  Sign Up |
              |  Screen  |
              +----------+

Main App Flow:
+-----------+    +------------+    +----------+
| Dashboard |--->| Movie Card |--->|  Toggle  |
|           |    |   Detail   |    | Watched  |
+-----------+    +------------+    +----------+
      |
      v
+------------+    +--------------+    +------------+
| Watch Plan |--->| Add to Plan  |--->|   Date     |
|            |    |    Sheet     |    |  Picker    |
+------------+    +--------------+    +------------+
      |
      v
+------------+    +--------------+
|   Ballot   |--->|  Category   |
|            |    |   Detail    |
+------------+    +--------------+
```

---

## Screen Specifications

### 1. Dashboard Screen

**Layout:**
```
+----------------------------------------+
| Dashboard                              | <- Title (gold gradient)
| Track your Oscar's movie marathon      | <- Subtitle (muted)
+----------------------------------------+
| +------------------------------------+ |
| | film Your Oscar Journey        75% | | <- Progress Hero Card
| | 30 of 40 films watched             | |
| | ================================== | | <- Gold progress bar
| | calendar Watch 2.5 films/day       | |
| +------------------------------------+ |
+----------------------------------------+
| Nominated Movies                       |
| +------------+------------+            |
| | Master List| By Category|            | <- Segmented control
| +------------+------------+            |
+----------------------------------------+
| +----+ +----+ +----+ +----+            |
| |    | |    | |    | |    |            | <- Movie poster grid
| |film| |film| |film| |film|            |   2 columns (iPhone)
| |    | |    | |    | |    |            |   3-4 columns (iPad)
| +----+ +----+ +----+ +----+            |
| |Title| |Title| |Title| |Title|        |
| | OK | |    | | OK | |    |            | <- Checkmark for watched
| +----+ +----+ +----+ +----+            |
+----------------------------------------+
```

**Components:**
- **ProgressHeroView**: Glass card with radial gradient background, percentage display
- **SegmentedPicker**: Toggle between Master List and Category views
- **MovieGridView**: LazyVGrid with adaptive columns
- **MovieCardView**: Poster image, title, runtime, watched indicator

**Interactions:**
- Tap movie card -> Toggle watched status (with haptic)
- Long press movie card -> Show context menu (Add to Plan, View Details)
- Pull to refresh -> Reload movies and watched status

---

### 2. Watch Plan Screen

**Layout:**
```
+----------------------------------------+
| Watch Plan                    [gear][+]| <- Title + Action buttons
| Your upcoming movie schedule           |
+----------------------------------------+
| calendar Agenda (15 planned - 25 unplanned)|
+----------------------------------------+
| warning OVERDUE                        | <- Red section header
| +------------------------------------+ |
| | [Poster] Movie Title (2h 15m)   X  | |
| |          2024  warning Missed      | |
| |          [Move] [Watched]          | |
| +------------------------------------+ |
+----------------------------------------+
| TODAY                                  | <- Date header
| +------------------------------------+ |
| | [Poster] Movie Title (1h 52m)   X  | |
| |          2024                      | |
| |          [Move] [Watched]          | |
| +------------------------------------+ |
+----------------------------------------+
| TOMORROW                               |
| ... (more date groups)                 |
+----------------------------------------+

+----------------------+
|         +            | <- Floating action button
+----------------------+   (gold, fixed bottom right)
```

**Components:**
- **DateGroupView**: Section header with date, droppable target
- **DraggableMovieRow**: Movie card that can be dragged between dates
- **ActionButtons**: "Move" (date picker sheet), "Watched" (complete + remove)
- **FloatingActionButton**: Opens Add to Plan sheet

**Modals/Sheets:**
1. **AddToPlanSheet**: Movie picker + date picker
2. **AutoSchedulerSheet**: AI-like gap filling (select movies, see suggested schedule)
3. **WhatCanIWatchSheet**: Filter unwatched movies by availability

**Interactions:**
- Drag movie card -> Drop on different date group to reschedule
- Tap "Move" -> Show date picker
- Tap "Watched" -> Mark watched, remove from plan
- Tap X -> Remove from plan (confirmation)
- Tap FAB -> Open Add to Plan sheet

---

### 3. Ballot Screen

**Layout:**
```
+----------------------------------------+
| Your Ballot                            |
| Select your predicted winners          |
+----------------------------------------+
| +------------------------------------+ |
| | trophy Ballot closes in 2d 14h 32m | | <- Countdown card
| +------------------------------------+ |
+----------------------------------------+
| +------------------------------------+ |
| | award Ballot Progress     18 of 23 | |
| | ================================== | | <- Progress indicator
| +------------------------------------+ |
+----------------------------------------+
| +------------------------------------+ |
| | Best Picture                 10pts | | <- Category card
| +------------------------------------+ |
| | o Anora                            | |
| | * The Brutalist           <- OK    | | <- Selected nomination
| | o A Complete Unknown               | |
| | o Conclave                         | |
| | o Dune: Part Two                   | |
| +------------------------------------+ |
|                                        |
| +------------------------------------+ |
| | Best Director                8pts  | |
| | ... nominations ...                | |
| +------------------------------------+ |
+----------------------------------------+
```

**Components:**
- **CountdownTimerView**: Live countdown to ballot lock
- **ProgressCard**: Shows completed/total categories
- **CategoryCard**: Expandable card with radio button nominations
- **NominationRow**: Radio button, movie/person name, winner badge (post-ceremony)

**Interactions:**
- Tap nomination -> Select as prediction (auto-saves)
- Visual feedback on selection (gold highlight, checkmark)
- When locked: Disable all selections, show lock icon

---

### 4. Leaderboard Screen

**Layout:**
```
+----------------------------------------+
| Leaderboard                            |
| See how you stack up                   |
+----------------------------------------+
| +------------------------------------+ |
| | 1st 1. MovieBuff42             125 | | <- Top 3 with medals
| |    32 watched - 18 correct         | |
| +------------------------------------+ |
| | 2nd 2. OscarFan99              110 | |
| |    28 watched - 15 correct         | |
| +------------------------------------+ |
| | 3rd 3. CinemaLover              98 | |
| |    25 watched - 12 correct         | |
| +------------------------------------+ |
+----------------------------------------+
| +------------------------------------+ |
| | 4. Username                     85 | |
| +------------------------------------+ |
| | 5. Username                     80 | |
| +------------------------------------+ |
| | ...                                | |
| +------------------------------------+ |
| | star 12. You (CurrentUser)      52 | | <- Highlighted current user
| |    20 watched - 8 correct          | |
| +------------------------------------+ |
+----------------------------------------+
```

**Components:**
- **TopThreeCard**: Special styling for ranks 1-3 with medals
- **LeaderboardRow**: Rank, username, score, stats
- **CurrentUserHighlight**: Gold border for logged-in user's row

**Interactions:**
- Pull to refresh -> Update rankings
- Scroll to find current user position

---

### 5. Groups Screen

**Layout:**
```
+----------------------------------------+
| Groups                        [Create] |
| Compete with friends                   |
+----------------------------------------+
| MY GROUPS                              |
| +------------------------------------+ |
| | film Family Oscar Pool             | |
| | Code: ABC123  [Copy]               | |
| | 5 members                          | |
| +------------------------------------+ |
+----------------------------------------+
| JOINED GROUPS                          |
| +------------------------------------+ |
| | film Office Predictions            | |
| | 12 members                         | |
| +------------------------------------+ |
+----------------------------------------+
| +------------------------------------+ |
| | [Enter invite code]      [Join]    | | <- Join group input
| +------------------------------------+ |
+----------------------------------------+
```

**Modals:**
- **CreateGroupSheet**: Name input with validation

**Interactions:**
- Tap "Create" -> Show create group sheet
- Tap "Copy" -> Copy invite code to clipboard
- Tap group -> Navigate to group leaderboard
- Enter code + tap "Join" -> Join group

---

### 6. Profile Screen

**Layout:**
```
+----------------------------------------+
| Profile                                |
| Manage your account                    |
+----------------------------------------+
| +------------------------------------+ |
| | [Avatar]                           | |
| | Username: CurrentUser    [Edit]    | |
| | Email: user@email.com              | |
| +------------------------------------+ |
+----------------------------------------+
| ACCOUNT                                |
| +------------------------------------+ |
| | Change Password              >     | |
| +------------------------------------+ |
| | Sign Out                     >     | |
| +------------------------------------+ |
| | Delete Account               >     | | <- Destructive color
| +------------------------------------+ |
+----------------------------------------+
| ABOUT                                  |
| +------------------------------------+ |
| | Version 1.0.0                      | |
| | 98th Academy Awards                | |
| +------------------------------------+ |
+----------------------------------------+
```

**Interactions:**
- Tap "Edit" username -> Inline edit with save
- Tap "Change Password" -> Password change sheet
- Tap "Sign Out" -> Confirmation alert -> Sign out
- Tap "Delete Account" -> Destructive confirmation -> Delete

---

### 7. Authentication Screens

**Login Screen:**
```
+----------------------------------------+
|                                        |
|           [Oscar Logo]                 |
|        Oscar's Tracker                 |
|        2025 Predictions                |
|                                        |
+----------------------------------------+
| +------------------------------------+ |
| | Email                              | |
| +------------------------------------+ |
| +------------------------------------+ |
| | Password                           | |
| +------------------------------------+ |
|                                        |
| +------------------------------------+ |
| |           Sign In                  | | <- Gold button
| +------------------------------------+ |
|                                        |
| -------------- OR --------------       |
|                                        |
| +------------------------------------+ |
| |      [G] Continue with Google      | |
| +------------------------------------+ |
|                                        |
|        Don't have an account?          |
|            Sign Up                     | <- Link
+----------------------------------------+
```

**Onboarding Sheet (first login):**
```
+----------------------------------------+
| Welcome to Oscar's Tracker!            |
|                                        |
| Choose a username:                     |
| +------------------------------------+ |
| | Username                           | |
| +------------------------------------+ |
|                                        |
| +------------------------------------+ |
| |         Continue                   | |
| +------------------------------------+ |
+----------------------------------------+
```

---

## Haptic Feedback Patterns

| Action | Haptic Type | SwiftUI Code |
|--------|-------------|--------------|
| Toggle watched | Light impact | `UIImpactFeedbackGenerator(style: .light).impactOccurred()` |
| Start drag | Medium impact | `UIImpactFeedbackGenerator(style: .medium).impactOccurred()` |
| Drop on date | Success notification | `UINotificationFeedbackGenerator().notificationOccurred(.success)` |
| Select prediction | Light impact | `UIImpactFeedbackGenerator(style: .light).impactOccurred()` |
| Error | Error notification | `UINotificationFeedbackGenerator().notificationOccurred(.error)` |
| Button tap | Selection | `UISelectionFeedbackGenerator().selectionChanged()` |

---

## iPad Adaptations

| Element | iPhone | iPad |
|---------|--------|------|
| Movie grid | 2 columns | 4-5 columns |
| Category cards | 1 column | 2 columns |
| Tab bar | Bottom tabs | Sidebar navigation |
| Sheets | Modal sheets | Popovers where appropriate |
| Drag & drop | Touch sensors | Mouse/trackpad support |

---

# Section 4: Technical Architecture

## Project Structure
```
OscarsTracker/
+-- App/
|   +-- OscarsTrackerApp.swift
|   +-- ContentView.swift
+-- Models/
|   +-- Movie.swift
|   +-- Category.swift
|   +-- Nomination.swift
|   +-- WatchPlanItem.swift
|   +-- UserPrediction.swift
|   +-- Group.swift
|   +-- GroupMember.swift
|   +-- Profile.swift
|   +-- LeaderboardEntry.swift
+-- Services/
|   +-- SupabaseClient.swift
|   +-- AuthService.swift
|   +-- MovieService.swift
|   +-- WatchPlanService.swift
|   +-- BallotService.swift
|   +-- LeaderboardService.swift
|   +-- GroupService.swift
|   +-- ProfileService.swift
+-- ViewModels/
|   +-- AuthViewModel.swift
|   +-- DashboardViewModel.swift
|   +-- WatchPlanViewModel.swift
|   +-- BallotViewModel.swift
|   +-- LeaderboardViewModel.swift
|   +-- GroupsViewModel.swift
|   +-- ProfileViewModel.swift
+-- Views/
|   +-- Auth/
|   |   +-- LoginView.swift
|   |   +-- SignUpView.swift
|   |   +-- OnboardingView.swift
|   +-- Dashboard/
|   |   +-- DashboardView.swift
|   |   +-- ProgressHeroView.swift
|   |   +-- MovieGridView.swift
|   |   +-- MovieCardView.swift
|   |   +-- CategoryListView.swift
|   +-- WatchPlan/
|   |   +-- WatchPlanView.swift
|   |   +-- DateGroupView.swift
|   |   +-- DraggableMovieRow.swift
|   |   +-- AddToPlanSheet.swift
|   |   +-- AutoSchedulerSheet.swift
|   |   +-- WhatCanIWatchSheet.swift
|   +-- Ballot/
|   |   +-- BallotView.swift
|   |   +-- CategoryCardView.swift
|   |   +-- NominationRowView.swift
|   |   +-- CountdownTimerView.swift
|   +-- Leaderboard/
|   |   +-- LeaderboardView.swift
|   +-- Groups/
|   |   +-- GroupsView.swift
|   |   +-- GroupRowView.swift
|   |   +-- CreateGroupSheet.swift
|   +-- Profile/
|       +-- ProfileView.swift
+-- Components/
|   +-- GlassCard.swift
|   +-- GoldButton.swift
|   +-- LoadingView.swift
|   +-- ErrorView.swift
|   +-- AsyncImageView.swift
+-- Utilities/
|   +-- Color+Extensions.swift
|   +-- Font+Extensions.swift
|   +-- Date+Extensions.swift
|   +-- HapticManager.swift
+-- Resources/
    +-- Assets.xcassets
    +-- Localizable.strings
```

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| supabase-swift | Latest | Supabase SDK for iOS |
| Kingfisher | 7.0+ | Async image loading and caching |

## State Management Pattern

Using iOS 17's `@Observable` macro:

```swift
@Observable
final class DashboardViewModel {
    private let movieService: MovieService

    var movies: [Movie] = []
    var watchedMovieIds: Set<Int> = []
    var isLoading = false
    var error: Error?

    var watchedCount: Int { watchedMovieIds.count }
    var totalCount: Int { movies.count }

    init(movieService: MovieService = .shared) {
        self.movieService = movieService
    }

    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let moviesTask = movieService.fetchMovies()
            async let watchedTask = movieService.fetchWatched()

            let (fetchedMovies, watched) = try await (moviesTask, watchedTask)
            movies = fetchedMovies
            watchedMovieIds = Set(watched.map { $0.movieId })
        } catch {
            self.error = error
        }
    }

    func toggleWatched(movieId: Int) async {
        // Optimistic update
        let wasWatched = watchedMovieIds.contains(movieId)
        if wasWatched {
            watchedMovieIds.remove(movieId)
        } else {
            watchedMovieIds.insert(movieId)
        }

        // Haptic feedback
        HapticManager.shared.lightImpact()

        do {
            if wasWatched {
                try await movieService.removeWatched(movieId: movieId)
            } else {
                try await movieService.addWatched(movieId: movieId)
            }
        } catch {
            // Rollback on error
            if wasWatched {
                watchedMovieIds.insert(movieId)
            } else {
                watchedMovieIds.remove(movieId)
            }
            self.error = error
        }
    }
}
```

---

# Section 5: Development Phases

## Phase 1: Foundation
- [ ] Create Xcode project with SwiftUI
- [ ] Set up supabase-swift SDK
- [ ] Implement SupabaseClient singleton
- [ ] Create all data models
- [ ] Implement AuthService and AuthViewModel
- [ ] Build LoginView and SignUpView
- [ ] Set up navigation structure (TabView)
- [ ] Create color and font extensions
- [ ] Build base components (GlassCard, GoldButton)

## Phase 2: Dashboard
- [ ] Implement MovieService
- [ ] Build DashboardViewModel
- [ ] Create ProgressHeroView
- [ ] Build MovieCardView with watch toggle
- [ ] Create MovieGridView with LazyVGrid
- [ ] Implement CategoryListView (grouped by category)
- [ ] Add Kingfisher for async image loading
- [ ] Implement haptic feedback

## Phase 3: Watch Plan
- [ ] Implement WatchPlanService
- [ ] Build WatchPlanViewModel
- [ ] Create WatchPlanView with date grouping
- [ ] Implement native drag & drop with DragGesture/DropDelegate
- [ ] Build AddToPlanSheet with movie picker + date picker
- [ ] Create AutoSchedulerSheet with scheduling logic
- [ ] Implement WhatCanIWatchSheet

## Phase 4: Ballot & Leaderboard
- [ ] Implement BallotService
- [ ] Build BallotViewModel with prediction map
- [ ] Create CategoryCardView with radio selections
- [ ] Build CountdownTimerView with Timer
- [ ] Implement LeaderboardService (RPC call)
- [ ] Build LeaderboardView with rankings

## Phase 5: Groups & Profile
- [ ] Implement GroupService
- [ ] Build GroupsViewModel
- [ ] Create GroupsView with create/join functionality
- [ ] Implement ProfileService
- [ ] Build ProfileView with account management
- [ ] Implement OnboardingView for new users
- [ ] Add sign out and account deletion flows

## Phase 6: Polish
- [ ] Refine all animations
- [ ] Perfect haptic feedback
- [ ] iPad layout optimizations
- [ ] Accessibility audit (VoiceOver, Dynamic Type)
- [ ] Error handling and empty states
- [ ] Loading states and skeletons
- [ ] App icon and launch screen
- [ ] TestFlight beta testing

---

# Section 6: Out of Scope (v1)

- Apple Watch app
- tvOS app
- Offline mode / local caching
- Push notifications
- Home screen widgets
- Dark/light mode toggle (dark only)
- Social sharing features
- In-app movie trailers
- Streaming service availability

---

# Section 7: Success Criteria

The iOS app is complete when:
1. All 7 main features are implemented and functional
2. Users can log in with existing web accounts
3. All data syncs correctly between web and iOS
4. App follows iOS Human Interface Guidelines
5. Haptic feedback is implemented throughout
6. iPad layout works correctly
7. App passes App Store review requirements
8. Performance is smooth (60fps scrolling, fast load times)
