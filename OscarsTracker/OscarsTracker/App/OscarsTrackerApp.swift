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
    /// (`-signed-out` too, for the sign-in screen, and `-full-ballot` for all
    /// 24 categories).
    private static func dataSource() -> any AppDataSource {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-sample-data") {
            return SampleDataSource(signedIn: !arguments.contains("-signed-out"), fullBallot: arguments.contains("-full-ballot"))
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
