import SwiftUI
import WidgetKit

/// Days to the ceremony and films left (P6-09, screens.md section 6): Home
/// Screen small and medium, Lock Screen circular, rectangular and inline.
/// The app writes the snapshot into the App Group when its stores refresh;
/// the provider turns it into one entry per local midnight.
struct CeremonyProvider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry { .sample }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        completion(context.isPreview ? .sample : current())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        let snapshot = WidgetSnapshotStore.live.read() ?? .empty
        completion(Timeline(entries: WidgetEntry.timeline(snapshot), policy: .after(WidgetEntry.refreshDate())))
    }

    private func current() -> WidgetEntry {
        WidgetEntry.make(WidgetSnapshotStore.live.read() ?? .empty, at: .now)
    }
}

struct CeremonyCountdownWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CeremonyCountdown", provider: CeremonyProvider()) { entry in
            CeremonyWidgetView(entry: entry)
        }
        .configurationDisplayName("Ceremony countdown")
        .description("Days to the ceremony, films left, and tonight's film.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

private struct CeremonyWidgetView: View {
    let entry: WidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemMedium: MediumWidgetView(entry: entry)
        case .accessoryCircular: CircularAccessoryView(entry: entry)
        case .accessoryRectangular: RectangularAccessoryView(entry: entry)
        case .accessoryInline: InlineAccessoryView(entry: entry)
        default: SmallWidgetView(entry: entry)
        }
    }
}

#Preview("Small", as: .systemSmall) { CeremonyCountdownWidget() } timeline: { WidgetEntry.sample; WidgetEntry.empty }
#Preview("Medium", as: .systemMedium) { CeremonyCountdownWidget() } timeline: { WidgetEntry.sample }
#Preview("Circular", as: .accessoryCircular) { CeremonyCountdownWidget() } timeline: { WidgetEntry.sample }
#Preview("Rectangular", as: .accessoryRectangular) { CeremonyCountdownWidget() } timeline: { WidgetEntry.sample }
#Preview("Inline", as: .accessoryInline) { CeremonyCountdownWidget() } timeline: { WidgetEntry.sample }
