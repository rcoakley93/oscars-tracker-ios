import SwiftUI
import WidgetKit

/// The widget extension: the ceremony-night Live Activity (P6-03) for now.
/// P6-09's Home Screen and Lock Screen widgets join this bundle; code both
/// the app and the extension need goes in `Shared/`.
@main
struct OscarsTrackerWidgets: WidgetBundle {
    var body: some Widget {
        CeremonyLiveActivity()
    }
}
