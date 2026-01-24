# Agent Guidelines for OscarsTracker iOS

## Project Structure
- Xcode project: `OscarsTracker/OscarsTracker.xcodeproj`
- Source files: `OscarsTracker/OscarsTracker/`
- Tests: `tests/` (Playwright for validating file structure)

## Folder Organization
- `App/` - Main app entry point and ContentView
- `Models/` - Data models (Codable + Identifiable)
- `Services/` - API clients (SupabaseClient singleton)
- `Components/` - Reusable SwiftUI components
- `Utilities/` - Extensions (Color, Font, etc.)
- `Views/` - Screen views
- `ViewModels/` - @Observable view models
- `Resources/` - Assets, images

## Key Patterns

### Adding New Swift Files
1. Create the `.swift` file in the appropriate folder
2. Add to `project.pbxproj`:
   - PBXFileReference section
   - PBXGroup (parent folder's children array)
   - PBXBuildFile section
   - PBXSourcesBuildPhase files array

### SwiftUI Components
- ViewModifiers: Implement `ViewModifier` protocol, add extension on `View`
- ButtonStyles: Implement `ButtonStyle` with `makeBody(configuration:)`
- Card effects: Layer backgrounds with opacity, use RadialGradient for depth

### Testing
- Playwright tests validate file existence and content
- Run `./scripts/validate.sh` to run all tests
- Tests check project structure, not runtime behavior

## Dependencies
- supabase-swift: Database and auth
- Kingfisher: Async image loading

## Design System
- Colors: Use `Color.goldPrimary`, `Color.appBackground`, etc.
- Fonts: Use `Font.displayLarge`, `Font.bodyMedium`, etc.
- Cards: Use `.glassCard()` modifier or `GlassCard { }` wrapper
- Buttons: Use `.buttonStyle(.gold)` or `.buttonStyle(.goldOutline)`
- Glow: Use `.goldGlow()` modifier

## Data Operations

### Supabase Insert Pattern
- Use `AnyJSON` enum for dynamic insert data: `[String: AnyJSON]`
- Values: `.string()`, `.integer()`, `.bool()`, etc.
- Chain `.insert()`, `.select()`, `.execute()` for insert with return

### Sheet Pattern
- Use `@State private var showSheet = false` in parent
- Pass `viewModel` via `@ObservedObject` to share state
- Use `@Environment(\.dismiss)` for sheet dismissal
- Disable with `.disabled()` and show `ProgressView` during async ops

### Floating Action Button (FAB)
- Use ZStack with `.bottomTrailing` alignment
- Gold circular button with shadow: `.shadow(color: Color.goldPrimary.opacity(0.4), radius: 8)`
- Add bottom padding to ScrollView content to avoid overlap

### Supabase Auth Update Pattern
- Verify current password by attempting `supabase.auth.signIn()` first
- Update password with `supabase.auth.update(user: UserAttributes(password: newPassword))`
- Requires existing session to be active
- Use `try? await supabase.auth.session.user.email` to get current user email

### Change Password Form Pattern
- Create separate computed properties for each password requirement
- Use `PasswordStrength` enum from AuthViewModel for strength indicator
- Show password match indicator only when confirm field is not empty
- Use `.interactiveDismissDisabled()` during async operations to prevent accidental dismiss
- Clear error message on any field change with `.onChange(of:)` modifiers

### Haptic Feedback Pattern
- Use `HapticManager` enum with static functions for all haptic feedback
- Light impact: `.light()` for toggles, selections, minor interactions
- Medium impact: `.medium()` for drag start, significant actions
- Heavy impact: `.heavy()` for major actions
- Success: `.success()` after successful API operations
- Error: `.error()` after failed API operations
- Selection: `.selection()` for button taps, picker changes
- Call haptics immediately before async operations start (optimistic feedback)

### Loading States Pattern
- Use `LoadingView` component for standardized loading spinner with message
- Use `SkeletonView` for pulse-animated placeholder elements
- Screen-specific skeleton views: `MovieCardSkeletonView`, `ListRowSkeletonView`, etc.
- Check `viewModel.isLoading && data.isEmpty` before showing loading state
- Skeleton animations: `Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)`
- Hide skeleton views from accessibility tree with `.accessibilityHidden(true)`
- Use `Color.borderColor` as fill color for skeleton views

### Error Handling Pattern
- Use `ErrorView` for full-screen error states with retry button
- Use `NetworkErrorView` for network-specific errors (wifi.slash icon)
- Use `ToastView` with `.toast()` modifier for transient error messages
- Use `ErrorBanner` for inline form validation errors
- Use `PartialErrorView` for graceful degradation on partial failures
- ToastData: `.error()`, `.success()`, `.warning()`, `.info()` static constructors
- Toast auto-dismisses after `duration` seconds when `autoDismiss: true`
- ViewModels use `@Published var errorMessage: String?` with try/catch

### Empty States Pattern
- Use `EmptyStateView` for reusable empty states with icon, title, subtitle
- Optional `actionTitle` and `action` closure for call-to-action button
- Screen-specific empty states: `WatchPlanEmptyState`, `GroupsEmptyState`, etc.
- Icon size: `.font(.system(size: 56))` with `.foregroundStyle(Color.goldPrimary)`
- Title uses `.headingMedium`, subtitle uses `.bodyMedium` with `.textMuted`
- Always check `data.isEmpty` after loading completes to show empty state

### Actor Category Display Pattern
- Use `CategoryNominee` struct to carry both `movie: Movie` and `detailText: String?`
- `CategoryWithMovies.isActorCategory` computed property detects actor/actress categories
- For actor categories, display actor name (from detailText) as primary headline
- Display movie title with year (e.g., "Movie Title (2025)") as secondary subheadline
- Sort actor categories by actor name, other categories by movie title
- Use `Text(verbatim:)` for year display to prevent comma formatting (2,025 -> 2025)
- Accessibility labels include "Actor Name in Movie Title" format for actor categories
