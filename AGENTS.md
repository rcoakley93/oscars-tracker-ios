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
