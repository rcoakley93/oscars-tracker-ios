import SwiftUI

@main
struct OscarsTrackerApp: App {
    @State private var model = AppModel(data: Self.dataSource())

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .task {
                    await model.start()
                    #if DEBUG
                    Self.openScreenshotRoute(in: model)
                    #endif
                }
        }
    }

    /// The live backend, or (debug builds only) the sample season when launched
    /// with `-sample-data`, for screenshots and demos without an account.
    private static func dataSource() -> any AppDataSource {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-sample-data") {
            return SampleDataSource()
        }
        #endif
        return LiveDataSource()
    }

    #if DEBUG
    /// Opens a tab, a film or a debug gallery from launch arguments, so
    /// screenshot runs need no taps: `-tab ballot`, `-movie 3`, `-category 2`,
    /// `-gallery tokens`.
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
        model.navigation.debugGallery = defaults.string(forKey: "gallery")
    }
    #endif
}
