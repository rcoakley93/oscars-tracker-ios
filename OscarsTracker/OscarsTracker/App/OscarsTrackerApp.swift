import SwiftUI

@main
struct OscarsTrackerApp: App {
    @State private var model = AppModel(data: Self.dataSource())

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .task { await model.start() }
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
}
