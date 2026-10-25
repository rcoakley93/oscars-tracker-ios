import SwiftUI
import WidgetKit

/// The widgets' views (P6-09, screens.md section 6), plain SwiftUI so they
/// preview and test in the app; the extension wraps them in a `Widget`.
/// Every one sets `containerBackground(for: .widget)` and marks its number
/// `.widgetAccentable()`, so accented and vibrant rendering keep the number
/// in the accent group.
enum WidgetCopy {
    static func filmsLeft(_ n: Int) -> String { n == 1 ? "1 film left" : "\(n) films left" }
    static func daysUnit(_ n: Int) -> String { n == 1 ? "day to go" : "days to go" }
    static let tonightDay = "Ceremony night"
    static let noSeason = "Open Oscars Tracker"

    /// The number the widgets lead with, or a dash with no ceremony in sight.
    static func days(_ entry: WidgetEntry) -> String { entry.daysToCeremony.map(String.init) ?? "–" }

    static func accessibility(_ entry: WidgetEntry) -> String {
        guard let days = entry.daysToCeremony else { return noSeason }
        let when = days == 0 ? tonightDay : "\(days) \(daysUnit(days))"
        return entry.filmsTotal > 0 ? "\(when), \(filmsLeft(entry.filmsLeft))" : when
    }
}

/// The big gold number. Gold only in full colour; accented and vibrant
/// rendering recolour it themselves.
private struct DaysNumber: View {
    let entry: WidgetEntry
    @ScaledMetric private var size: CGFloat
    @Environment(\.widgetRenderingMode) private var mode

    init(entry: WidgetEntry, size: CGFloat = 48) {
        self.entry = entry
        _size = ScaledMetric(wrappedValue: size, relativeTo: .largeTitle)
    }

    var body: some View {
        Text(verbatim: WidgetCopy.days(entry))
            .font(.system(size: size, weight: .bold, design: .rounded))
            .monospacedDigit()
            .minimumScaleFactor(0.6)
            .lineLimit(1)
            .foregroundStyle(mode == .fullColor ? AnyShapeStyle(Theme.goldGradient) : AnyShapeStyle(.primary))
            .widgetAccentable()
    }
}

/// One cell per film: watched ones gold, the rest dim. Gold marks progress.
struct WidgetFilmStrip: View {
    let watched: Int
    let total: Int
    var maxCells = 24
    @Environment(\.widgetRenderingMode) private var mode

    /// Cells shown, scaled down when there are more films than room.
    private var cells: (filled: Int, count: Int) {
        guard total > 0 else { return (0, 0) }
        let count = min(total, maxCells)
        return (Int((Double(watched) / Double(total) * Double(count)).rounded()), count)
    }

    var body: some View {
        let cells = cells
        HStack(spacing: 2) {
            ForEach(0..<cells.count, id: \.self) { index in
                let filled = index < cells.filled
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(filled ? (mode == .fullColor ? AnyShapeStyle(Color.gold) : AnyShapeStyle(.primary)) : AnyShapeStyle(Color.hairline))
                    .opacity(filled || mode == .fullColor ? 1 : 0.35)
                    .widgetAccentable(filled)
            }
        }
        .frame(height: 8)
        .accessibilityElement()
        .accessibilityLabel("\(watched) of \(total) films watched")
    }
}

struct SmallWidgetView: View {
    let entry: WidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xxs) {
            Text("Ceremony").eyebrowStyle()
            Spacer(minLength: 0)
            if entry.daysToCeremony != nil {
                DaysNumber(entry: entry, size: 52)
                Text(WidgetCopy.daysUnit(entry.daysToCeremony ?? 0)).font(.footnote).foregroundStyle(.inkMuted)
            } else {
                Text(WidgetCopy.noSeason).font(.headline).foregroundStyle(.ink)
            }
            if entry.filmsTotal > 0 {
                Text(WidgetCopy.filmsLeft(entry.filmsLeft)).font(.footnote.weight(.semibold)).foregroundStyle(.ink)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(Color.ground, for: .widget)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(WidgetCopy.accessibility(entry))
    }
}

struct MediumWidgetView: View {
    let entry: WidgetEntry

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Space.m) {
            SmallWidgetContent(entry: entry)
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                if entry.filmsTotal > 0 {
                    WidgetFilmStrip(watched: entry.filmsWatched, total: entry.filmsTotal)
                    Text("\(entry.filmsWatched) of \(entry.filmsTotal) watched").font(.footnote).foregroundStyle(.inkMuted)
                }
                Spacer(minLength: 0)
                Text("Tonight").eyebrowStyle()
                if let tonight = entry.tonight {
                    Text(tonight).font(.headline).foregroundStyle(.ink).lineLimit(2)
                    if entry.tonightExtra > 0 { Text("+\(entry.tonightExtra) more").font(.footnote).foregroundStyle(.inkMuted) }
                } else {
                    Text("Nothing planned").font(.subheadline).foregroundStyle(.inkMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .containerBackground(Color.ground, for: .widget)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(WidgetCopy.accessibility(entry) + (entry.tonight.map { ". Tonight: \($0)" } ?? ""))
    }
}

/// The small widget's content, without its background, for the medium one.
private struct SmallWidgetContent: View {
    let entry: WidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xxs) {
            Text("Ceremony").eyebrowStyle()
            Spacer(minLength: 0)
            if let days = entry.daysToCeremony {
                DaysNumber(entry: entry)
                Text(WidgetCopy.daysUnit(days)).font(.footnote).foregroundStyle(.inkMuted)
            } else {
                Text(WidgetCopy.noSeason).font(.headline).foregroundStyle(.ink)
            }
            if entry.filmsTotal > 0 {
                Text(WidgetCopy.filmsLeft(entry.filmsLeft)).font(.footnote.weight(.semibold)).foregroundStyle(.ink)
            }
        }
        .frame(width: 110, alignment: .leading)
    }
}

struct CircularAccessoryView: View {
    let entry: WidgetEntry

    var body: some View {
        VStack(spacing: 0) {
            Text(verbatim: WidgetCopy.days(entry))
                .font(.system(.title2, design: .rounded, weight: .bold))
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .widgetAccentable()
            Text("days").font(.system(size: 9, weight: .semibold)).textCase(.uppercase)
        }
        .containerBackground(.clear, for: .widget)
        .accessibilityLabel(WidgetCopy.accessibility(entry))
    }
}

struct RectangularAccessoryView: View {
    let entry: WidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            if let days = entry.daysToCeremony {
                Text(verbatim: "\(days) \(WidgetCopy.daysUnit(days))")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .widgetAccentable()
            } else {
                Text(WidgetCopy.noSeason).font(.headline).widgetAccentable()
            }
            if entry.filmsTotal > 0 { Text(WidgetCopy.filmsLeft(entry.filmsLeft)).font(.subheadline) }
            if let tonight = entry.tonight { Text(tonight).font(.caption).lineLimit(1) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(.clear, for: .widget)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(WidgetCopy.accessibility(entry))
    }
}

struct InlineAccessoryView: View {
    let entry: WidgetEntry

    var body: some View {
        Group {
            if let days = entry.daysToCeremony {
                Text(verbatim: "\(days) \(WidgetCopy.daysUnit(days)) · \(entry.filmsLeft) left")
            } else {
                Text(WidgetCopy.noSeason)
            }
        }
        .containerBackground(.clear, for: .widget)
        .accessibilityLabel(WidgetCopy.accessibility(entry))
    }
}

#Preview("Small, full colour") {
    SmallWidgetView(entry: .sample).frame(width: 158, height: 158).padding(16).background(Color.ground)
}

#Preview("Small, accented", traits: .sizeThatFitsLayout) {
    SmallWidgetView(entry: .sample).frame(width: 158, height: 158).padding(16).background(Color.ground)
        .environment(\.widgetRenderingMode, .accented)
}

#Preview("Medium, dark") {
    MediumWidgetView(entry: .sample).frame(width: 338, height: 158).padding(16).background(Color.ground)
        .preferredColorScheme(.dark)
}

#Preview("Medium, large text") {
    MediumWidgetView(entry: .sample).frame(width: 338, height: 158).padding(16).background(Color.ground)
        .dynamicTypeSize(.accessibility2)
}

#Preview("Lock Screen, vibrant") {
    VStack(spacing: 12) {
        CircularAccessoryView(entry: .sample).frame(width: 72, height: 72)
        RectangularAccessoryView(entry: .sample).frame(width: 170, height: 72)
        InlineAccessoryView(entry: .sample)
    }
    .padding().background(Color.black).foregroundStyle(.white)
    .environment(\.widgetRenderingMode, .vibrant)
}

#Preview("No season") {
    SmallWidgetView(entry: .empty).frame(width: 158, height: 158).padding(16).background(Color.ground)
}
