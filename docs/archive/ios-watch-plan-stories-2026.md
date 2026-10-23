# Oscar's Tracker iOS - Bug Fixes & Feature Stories

## Priority Order: Bug Fixes → AI Features → Calendar Improvements

---

## Story 1: Fix Visual Bugs in Watch Plan Move Functionality

**Type:** Bug Fix
**Priority:** P1 - High
**Estimate:** Small

### Description
The Move functionality in the Watch Plan section has layout/positioning issues and animation/transition bugs when opening.

### Acceptance Criteria
- [ ] Move modal/sheet opens without visual glitches
- [ ] Calendar component is properly positioned and aligned
- [ ] Transitions/animations are smooth when opening and closing
- [ ] No overlapping elements or misaligned components

### Files to Modify
- `OscarsTracker/OscarsTracker/Views/WatchPlan/WatchPlanView.swift` (lines 486-501 for Move button, lines 241-270 for reschedule handling)

### Verification
- Open Watch Plan tab
- Tap "Move" button on any scheduled movie
- Verify calendar/date picker appears correctly
- Verify animation is smooth
- Test on multiple device sizes

---

## Story 2: Fix Drag and Drop in Watch Plan

**Type:** Bug Fix
**Priority:** P1 - High
**Estimate:** Medium

### Description
Drag and drop to move movies between dates doesn't work. The implementation uses SwiftUI's `.draggable()` and `.dropDestination()` modifiers with a custom `WatchPlanItemTransfer` type.

### Acceptance Criteria
- [ ] User can long-press a movie card to start dragging
- [ ] Drag preview appears showing the movie being dragged
- [ ] Drop zones highlight when dragging over valid date groups
- [ ] Dropping on a date group reschedules the movie
- [ ] Haptic feedback on successful drop
- [ ] Cannot drop on OVERDUE section

### Files to Modify
- `OscarsTracker/OscarsTracker/Views/WatchPlan/WatchPlanView.swift`
  - `WatchPlanItemTransfer` struct (lines 321-329)
  - `.draggable()` modifier (lines 363-369)
  - `.dropDestination()` modifier (lines 241-258)

### Technical Notes
- Uses `UTType.watchPlanItem` custom content type
- Transfer object contains `itemId` and `movieId`
- Calls `viewModel.reschedule(itemId:to:)` on drop

### Verification
- Long-press a movie to start drag
- Drag to a different date section
- Verify movie moves to new date
- Verify Supabase `watch_plan` table is updated

---

## Story 3: Implement AI-Powered Auto Scheduler (Match Web)

**Type:** Feature Enhancement
**Priority:** P2 - Medium
**Estimate:** Large

### Description
Replace the current client-side scheduling algorithm with AI-powered scheduling that matches the web version. The web calls a Supabase Edge Function `'auto-scheduler'` with natural language input.

### Current iOS Behavior
- Local algorithm that sorts movies by runtime
- Fills gaps from today through Oscar deadline
- No natural language input

### Target iOS Behavior (Match Web)
- Text input field for natural language prompts (e.g., "Plan my weekends", "I missed yesterday, fix it")
- Quick action buttons: "Fill Gaps", "Reschedule Overdue", "Reorganize Plan"
- "Generate Plan" button that calls AI backend
- Preview of suggested schedule before confirming

### API Endpoint
```
POST https://mukucjdrafjndtlxvbsj.supabase.co/functions/v1/auto-scheduler
```

### Request Format
```json
{
  "user_prompt": "string",
  "today": "yyyy-MM-dd",
  "movies_pool": [
    { "id": 123, "title": "Movie", "runtime": 120, "plan_id": null, "current_date": null }
  ],
  "existing_schedule": [
    { "date": "yyyy-MM-dd", "movieTitle": "string" }
  ]
}
```

### Response Format
```json
{
  "plan": [
    { "movie_id": 123, "date": "yyyy-MM-dd", "reason": "explanation" }
  ]
}
```

### Files to Modify
- `OscarsTracker/OscarsTracker/Views/WatchPlan/AutoSchedulerSheet.swift` - Complete UI redesign
- `OscarsTracker/OscarsTracker/ViewModels/WatchPlanViewModel.swift` - Add AI API call method
- `OscarsTracker/OscarsTracker/Services/SupabaseClient.swift` - Add edge function invoke method if needed

### Verification
- Open Auto Scheduler sheet
- Enter natural language prompt
- Tap "Generate Plan"
- Verify API call is made (check network)
- Verify preview shows AI-generated schedule
- Confirm schedule and verify movies are added to plan

---

## Story 4: Update "What Can I Watch" UI to Match Web

**Type:** Feature Enhancement
**Priority:** P2 - Medium
**Estimate:** Medium

### Description
Update "What Can I Watch" feature UI to match web behavior exactly. Both versions use client-side filtering.

### Current iOS Behavior
- Runtime filter tabs: All, Short (<90m), Medium (90-120m), Long (>120m)
- Shows list of filtered movies
- Quick add to today's plan

### Target iOS Behavior (Match Web Exactly)
- Modal with "How much time do you have?" header
- Four button options in 2x2 grid:
  - Short (< 40m)
  - Medium (< 90m)
  - Standard (< 2h)
  - Unlimited
- On selection, show random movie recommendation(s) from matching runtime
- Quick add to plan functionality

### Web Time Ranges (from web code)
- Short: < 40 minutes
- Medium: 40-90 minutes
- Standard: 91-120 minutes
- Unlimited: 3 longest unwatched movies

### Files to Modify
- `OscarsTracker/OscarsTracker/Views/WatchPlan/WhatCanIWatchSheet.swift` - Redesign UI to match web

### Verification
- Open "What Can I Watch" sheet
- Verify "How much time do you have?" header appears
- Verify 4 time option buttons in grid layout
- Select each option and verify appropriate movies are shown
- Test quick add functionality

---

## Story 5: Redesign Add to Plan Calendar UX

**Type:** Feature Enhancement
**Priority:** P3 - Medium
**Estimate:** Large

### Description
Improve the Add to Plan sheet calendar experience. Current calendar takes too much space. Need better visual flow and indicators.

### Current iOS Behavior
- Search field to find unwatched movie
- Full graphical DatePicker (`.datePickerStyle(.graphical)`)
- No indicators for days with existing movies

### Target iOS Behavior
1. **Flow:** Show unwatched movie list → User taps movie → Compact calendar appears
2. **Calendar Indicators:**
   - White dot below dates that have movies scheduled
   - Distinct styling for currently selected date
3. **Day Details:** When user selects a day with movies, show a window/popover listing movies already scheduled for that day
4. **Compact Size:** Calendar should take less vertical space

### Files to Modify
- `OscarsTracker/OscarsTracker/Views/WatchPlan/AddToPlanSheet.swift`
  - Redesign layout flow
  - Create custom calendar component or customize DatePicker
  - Add scheduled movie indicators
  - Add day detail popover

### Technical Considerations
- May need custom calendar view instead of `.datePickerStyle(.graphical)`
- Need to pass `watchPlanItems` to determine which dates have movies
- Consider using a compact calendar library or building custom

### Verification
- Open Add to Plan sheet
- Verify movie list appears first
- Select a movie and verify calendar appears
- Verify white dots appear on dates with scheduled movies
- Tap a date with movies and verify popover shows existing movies
- Complete adding movie and verify it's saved

---

## Files Reference

| File | Purpose |
|------|---------|
| `Views/WatchPlan/WatchPlanView.swift` | Main watch plan view, drag-drop, move functionality |
| `Views/WatchPlan/AutoSchedulerSheet.swift` | Auto scheduler UI (needs AI integration) |
| `Views/WatchPlan/WhatCanIWatchSheet.swift` | What can I watch UI |
| `Views/WatchPlan/AddToPlanSheet.swift` | Add movie to plan with calendar |
| `ViewModels/WatchPlanViewModel.swift` | View model with API calls |
| `Services/SupabaseClient.swift` | Supabase client configuration |

---

## Supabase Configuration

- **Project URL:** `https://mukucjdrafjndtlxvbsj.supabase.co`
- **Edge Function:** `auto-scheduler`
- **Tables:** `movies`, `watch_plan`, `user_watched`
