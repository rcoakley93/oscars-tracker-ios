import SwiftUI

@main
struct OscarsTrackerApp: App {
    @State private var model = AppModel(data: Self.dataSource())
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @Environment(\.scenePhase) private var scenePhase

    init() {
        FilmsTab.clearCatchUpHidesWatched()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                #if DEBUG
                .preferredColorScheme(Self.screenshotColorScheme)
                #endif
                .task {
                    delegate.model = model
                    #if DEBUG
                    // Before start() too, so a slow first load (a busy Mac) can't delay the route.
                    Self.openScreenshotRoute(in: model)
                    #endif
                    await model.start()
                    #if DEBUG
                    Self.openScreenshotRoute(in: model)
                    if ProcessInfo.processInfo.arguments.contains("-live-activity") {
                        // After Best Picture is announced, so the activity shows a winner.
                        try? await Task.sleep(for: .seconds(4))
                        await model.followCeremony()
                    }
                    #endif
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { Task { await model.foreground() } }
                    // Watched toggles and plan changes since the last refresh.
                    if phase == .background { model.saveWidgetSnapshot() }
                }
        }
    }

    /// The live backend, or (debug builds only) the sample season when launched
    /// with `-sample-data`, for screenshots and demos without an account
    /// (`-signed-out` too, for the sign-in screen, `-full-ballot` for all
    /// 24 categories, `-admin` for the Admin screen, `-blocked` with Chris
    /// blocked (P6-16), and `-live` for live
    /// mode on the rehearsal, with Best Picture announced three seconds in;
    /// add `-live-activity` to start the Live Activity a second later).
    /// `-ballot-stage locked` or `winners` moves the season past the lock.
    private static func dataSource() -> any AppDataSource {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-sample-data") {
            let data = SampleDataSource(signedIn: !arguments.contains("-signed-out"), fullBallot: arguments.contains("-full-ballot"))
            data.isAdmin = arguments.contains("-admin")
            if arguments.contains("-blocked") {
                data.blocked = [BlockedUser(userId: "u-chris", username: "Chris", avatarUrl: nil, blockedAt: nil)]
            }
            switch UserDefaults.standard.string(forKey: "ballot-stage") {
            case "locked": data.passLock()
            case "winners": data.passLock(winners: true)
            default: break
            }
            if arguments.contains("-live") {
                data.isRehearsal = true
                data.config.featureFlags[AppConfig.liveMode] = true
                data.config.featureFlags[AppConfig.liveActivity] = arguments.contains("-live-activity")
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    data.announce([103], inCategory: 1)
                }
            }
            return data
        }
        #endif
        return LiveDataSource()
    }

    #if DEBUG
    /// `-appearance light` or `dark`, for screenshot runs on simulators that
    /// don't follow `simctl ui appearance`.
    private static var screenshotColorScheme: ColorScheme? {
        switch UserDefaults.standard.string(forKey: "appearance") {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }

    /// Opens a tab, a film or a debug gallery from launch arguments, so
    /// screenshot runs need no taps: `-tab ballot`, `-movie 3`, `-category 2`,
    /// `-group 1`, `-sheet profile` (or `report`, `report-group`, `share-card`, the
    /// results card with `-ballot-stage winners`), `-gallery tokens`.
    private static func openScreenshotRoute(in model: AppModel) {
        let defaults = UserDefaults.standard
        if let tab = defaults.string(forKey: "tab").flatMap(AppNavigation.Tab.init(rawValue:)) {
            model.navigation.tab = tab
        }
        if defaults.object(forKey: "movie") != nil {
            model.navigation.selectedMovieID = defaults.integer(forKey: "movie")
        }
        if defaults.object(forKey: "category") != nil {
            model.navigation.selectedCategoryID = defaults.integer(forKey: "category")
        }
        if defaults.object(forKey: "group") != nil {
            model.navigation.selectedGroupID = defaults.integer(forKey: "group")
        }
        switch defaults.string(forKey: "sheet") {
        case "profile": model.navigation.sheet = .profile
        case "recap": model.navigation.sheet = .recap
        case "share-card": model.navigation.sheet = .shareCard
        case "report": model.navigation.sheet = .report(.person(id: "u-chris", name: "Chris"))
        case "report-group": model.navigation.sheet = .report(.group(id: 2, name: "Family pool"))
        default: break
        }
        model.navigation.debugGallery = defaults.string(forKey: "gallery")
    }
    #endif
}
