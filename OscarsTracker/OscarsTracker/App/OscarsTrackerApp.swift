import SwiftUI

@main
struct OscarsTrackerApp: App {
    @State private var model = AppModel(data: Self.dataSource())
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                #if DEBUG
                .preferredColorScheme(Self.screenshotColorScheme)
                #endif
                .task {
                    delegate.model = model
                    await model.start()
                    #if DEBUG
                    Self.openScreenshotRoute(in: model)
                    #endif
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { Task { await model.foreground() } }
                }
        }
    }

    /// The live backend, or (debug builds only) the sample season when launched
    /// with `-sample-data`, for screenshots and demos without an account
    /// (`-signed-out` too, for the sign-in screen, `-full-ballot` for all
    /// 24 categories, `-admin` for the Admin screen, and `-live` for live
    /// mode on the rehearsal, with Best Picture announced three seconds in).
    /// `-ballot-stage locked` or `winners` moves the season past the lock.
    private static func dataSource() -> any AppDataSource {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-sample-data") {
            let data = SampleDataSource(signedIn: !arguments.contains("-signed-out"), fullBallot: arguments.contains("-full-ballot"))
            data.isAdmin = arguments.contains("-admin")
            switch UserDefaults.standard.string(forKey: "ballot-stage") {
            case "locked": data.passLock()
            case "winners": data.passLock(winners: true)
            default: break
            }
            if arguments.contains("-live") {
                data.isRehearsal = true
                data.config.featureFlags[AppConfig.liveMode] = true
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
    /// `-group 1`, `-sheet profile`, `-gallery tokens`.
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
        if defaults.string(forKey: "sheet") == "profile" {
            model.navigation.sheet = .profile
        }
        model.navigation.debugGallery = defaults.string(forKey: "gallery")
    }
    #endif
}
