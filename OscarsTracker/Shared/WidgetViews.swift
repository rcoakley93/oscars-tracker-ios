import SwiftUI
import WidgetKit

/// The widgets' views (P11-02, the "Film strip" direction; screens.md
/// section 6), plain SwiftUI so they preview and test in the app; the
/// extension wraps them in a `Widget`. Progress leads: a strip of frames,
/// each watched film lighting one in its poster's colour, and the count in
/// gold because it's earned. Every one sets `containerBackground(for: .widget)`
/// and marks the count and lit frames `.widgetAccentable()`, so accented and
/// vibrant rendering keep them in the accent group.

/// What a widget says in one state, for every family.
nonisolated struct WidgetFace: Equatable, Sendable {
    enum Frames: Equatable, Sendable {
        /// Watched films, in their poster colours.
        case films
        /// Categories picked or called right, in gold.
        case picks
    }

    var count: Int
    var of: Int
    var frames: Frames
    /// Under the count on the small widget.
    var unit: String
    /// The small widget's last line.
    var foot: String
    /// The medium widget's right column.
    var eyebrow: String
    var headline: String
    /// When set, the headline is a live countdown to this instant.
    var countdownTo: Date?
    var detail: String
    /// The medium widget's last line.
    var bottom: String?
    /// Under the count on the circular Lock Screen widget.
    var caption: String
    var rectangularTitle: String
    var rectangularLine: String
    var inline: String

    var fraction: Double { of > 0 ? min(Double(count) / Double(of), 1) : 0 }

    var accessibility: String {
        [rectangularTitle, rectangularLine, bottom].compactMap { $0 }.joined(separator: ", ")
    }
}

nonisolated enum WidgetCopy {
    static func days(_ n: Int) -> String { n == 1 ? "1 day" : "\(n) days" }
    static func ofTotal(_ n: Int, _ total: Int) -> String { "\(n) of \(total)" }

    static func ordinal(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: n as NSNumber) ?? "\(n)"
    }

    static func time(_ date: Date) -> String { date.formatted(date: .omitted, time: .shortened) }
    static func day(_ date: Date) -> String { date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()) }

    static func ceremony(_ number: Int?) -> String { number.map { "The \(ordinal($0)) Oscars" } ?? "The Oscars" }

    static func rank(_ results: WidgetSnapshot.Results) -> String? {
        guard let rank = results.rank, let ranked = results.ranked else { return nil }
        return "\(ordinal(rank)) of \(ranked)"
    }

    /// Tonight's film, or the next one planned.
    static func plan(_ entry: WidgetEntry) -> String? {
        if let tonight = entry.tonight {
            return "Tonight · \(tonight)" + (entry.tonightExtra > 0 ? ", +\(entry.tonightExtra) more" : "")
        }
        return entry.next.map { "Next · \($0.title), \(day($0.day.startDate()))" }
    }

    static func face(_ entry: WidgetEntry) -> WidgetFace {
        let watched = entry.filmsWatched, total = entry.filmsTotal
        let picked = entry.categoriesPicked, categories = entry.categoriesTotal
        let picks = ofTotal(picked, categories) + " picked"
        switch entry.phase {
        case .empty:
            return WidgetFace(count: 0, of: 0, frames: .films, unit: "films watched", foot: "Mark one to light a frame",
                              eyebrow: "Your season", headline: "No films yet", detail: "Mark one watched",
                              bottom: nil, caption: "WATCHED", rectangularTitle: "No films watched yet",
                              rectangularLine: "Mark one to light a frame", inline: "No films watched yet")
        case .contenders(let toNominations, _):
            let when = toNominations.map { $0 == 0 ? "Nominations today" : "\(days($0)) to nominations" } ?? "Before nominations"
            return WidgetFace(count: watched, of: total, frames: .films, unit: "contenders watched", foot: when,
                              eyebrow: "Nominations",
                              headline: toNominations.map { $0 == 0 ? "Today" : days($0) } ?? "Soon",
                              detail: entry.nominationsAt.map(day) ?? "Date to come",
                              bottom: plan(entry), caption: "OF \(total)", rectangularTitle: ofTotal(watched, total) + " watched",
                              rectangularLine: when,
                              inline: ofTotal(watched, total) + " watched" + (toNominations.map { " · \(days($0))" } ?? ""))
        case .season(let toCeremony):
            let foot = categories > 0 ? "\(days(toCeremony)) · \(picks)" : "\(days(toCeremony)) to go"
            return WidgetFace(count: watched, of: total, frames: .films, unit: "nominees watched", foot: foot,
                              eyebrow: "Ceremony", headline: days(toCeremony), detail: categories > 0 ? picks : ceremony(entry.ceremonyNumber),
                              bottom: plan(entry), caption: "OF \(total)", rectangularTitle: ofTotal(watched, total) + " watched",
                              rectangularLine: foot, inline: ofTotal(watched, total) + " watched · \(days(toCeremony))")
        case .lockDay(let locksAt):
            let at = time(locksAt)
            return WidgetFace(count: picked, of: categories, frames: .picks, unit: "categories picked", foot: "Locks \(at)",
                              eyebrow: "Ballot locks in", headline: at, countdownTo: locksAt, detail: "at \(at)",
                              bottom: ofTotal(watched, total) + " nominees watched", caption: "OF \(categories)",
                              rectangularTitle: picks, rectangularLine: "Ballot locks \(at)", inline: "\(picks) · locks \(at)")
        case .showtime(let startsAt):
            let live = entry.date >= startsAt
            let when = live ? "Live now" : time(startsAt)
            return WidgetFace(count: picked, of: categories, frames: .picks, unit: "categories picked", foot: "Ballot locked",
                              eyebrow: "Tonight", headline: when, detail: ceremony(entry.ceremonyNumber),
                              bottom: ofTotal(watched, total) + " nominees watched", caption: "OF \(categories)",
                              rectangularTitle: ceremony(entry.ceremonyNumber),
                              rectangularLine: live ? "Live now · \(picks)" : "Tonight at \(when)",
                              inline: live ? "Oscars live now" : "Oscars tonight · \(when)")
        case .results:
            guard let results = entry.results else {
                return WidgetFace(count: watched, of: total, frames: .films, unit: "nominees watched", foot: picks,
                                  eyebrow: "Ballot", headline: "Locked", detail: picks, bottom: nil, caption: "OF \(total)",
                                  rectangularTitle: ofTotal(watched, total) + " watched", rectangularLine: picks,
                                  inline: ofTotal(watched, total) + " watched")
            }
            let right = ofTotal(results.correct, results.total) + " right"
            let rank = rank(results)
            return WidgetFace(count: results.correct, of: results.total, frames: .picks, unit: "called right",
                              foot: rank ?? "of \(results.total) categories", eyebrow: "Everyone",
                              headline: results.rank.map(ordinal) ?? right,
                              detail: results.ranked.map { "of \($0)" } ?? ceremony(entry.ceremonyNumber),
                              bottom: ofTotal(watched, total) + " nominees watched", caption: "RIGHT", rectangularTitle: right,
                              rectangularLine: rank ?? ceremony(entry.ceremonyNumber), inline: right + (rank.map { " · \($0)" } ?? ""))
        case .offSeason:
            let season = entry.ceremonyNumber.map(ordinal) ?? "Last season"
            let right = entry.results.map { ofTotal($0.correct, $0.total) + " right" }
            return WidgetFace(count: watched, of: total, frames: .films, unit: "watched last season",
                              foot: right.map { "\(season): \($0)" } ?? ceremony(entry.ceremonyNumber),
                              eyebrow: ceremony(entry.ceremonyNumber),
                              headline: entry.results.map { ofTotal($0.correct, $0.total) } ?? "\(watched) films",
                              detail: entry.results.map { r in "right" + (rank(r).map { " · \($0)" } ?? "") } ?? "watched",
                              bottom: "Next season's contenders come in the fall", caption: "OF \(total)",
                              rectangularTitle: ofTotal(watched, total) + " watched",
                              rectangularLine: right.map { "\(season): \($0)" } ?? "last season",
                              inline: right.map { "Last season: \($0)" } ?? ofTotal(watched, total) + " watched last season")
        }
    }
}

// MARK: - The strip

/// The film strip: frames between two rows of sprocket holes. Lit frames are
/// watched films in their poster colours, or picks in gold; the rest stay
/// dark. Accented and vibrant rendering drop the film and keep the frames.
struct WidgetFilmStrip: View {
    let face: WidgetFace
    let posters: [WidgetSnapshot.PosterColor]
    var frames = 8
    var height: CGFloat = 36
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.colorScheme) private var colorScheme

    private var lit: Int { Int((face.fraction * Double(frames)).rounded()) }

    var body: some View {
        if mode == .fullColor {
            VStack(spacing: 0) {
                sprockets
                frameRow.padding(.vertical, 1)
                sprockets
            }
            .padding(.horizontal, 10)
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .background(Color.black)
            .accessibilityHidden(true)
        } else {
            frameRow
                .frame(height: height * 0.4)
                .padding(.horizontal, Theme.Space.m)
                .padding(.top, Theme.Space.s)
                .accessibilityHidden(true)
        }
    }

    private var frameRow: some View {
        HStack(spacing: 3) {
            ForEach(0..<frames, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(fill(index))
                    .widgetAccentable(index < lit)
            }
        }
    }

    private func fill(_ index: Int) -> AnyShapeStyle {
        guard index < lit else {
            return mode == .fullColor ? AnyShapeStyle(Color.white.opacity(0.13)) : AnyShapeStyle(.primary.opacity(0.25))
        }
        guard mode == .fullColor else { return AnyShapeStyle(.primary) }
        if face.frames == .picks || posters.isEmpty { return AnyShapeStyle(Theme.goldGradient) }
        let poster = posters[index % posters.count]
        let color = Color(red: poster.red, green: poster.green, blue: poster.blue)
        return AnyShapeStyle(LinearGradient(colors: [color, color.mix(with: .black, by: 0.3)], startPoint: .top, endPoint: .bottom))
    }

    private var sprockets: some View {
        Canvas { context, size in
            let hole = CGSize(width: 3.5, height: 3)
            var x: CGFloat = 1
            while x + hole.width <= size.width {
                let rect = CGRect(origin: CGPoint(x: x, y: (size.height - hole.height) / 2), size: hole)
                context.fill(Path(roundedRect: rect, cornerRadius: 1), with: .color(.white.opacity(colorScheme == .dark ? 0.24 : 0.8)))
                x += 9
            }
        }
        .frame(maxHeight: .infinity)
    }
}

/// The count, gold in full colour: you earned it.
private struct WidgetCount: View {
    let face: WidgetFace
    var size: CGFloat
    @Environment(\.widgetRenderingMode) private var mode

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(verbatim: "\(face.count)")
                .font(.system(size: size, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(mode == .fullColor ? AnyShapeStyle(Theme.goldGradient) : AnyShapeStyle(.primary))
                .widgetAccentable()
            if face.of > 0 {
                Text(verbatim: "/\(face.of)")
                    .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.inkMuted)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    }
}

// MARK: - Home Screen

struct SmallWidgetView: View {
    let entry: WidgetEntry

    var body: some View {
        let face = WidgetCopy.face(entry)
        VStack(alignment: .leading, spacing: 0) {
            WidgetFilmStrip(face: face, posters: entry.posters, frames: 8)
            VStack(alignment: .leading, spacing: 2) {
                WidgetCount(face: face, size: 46)
                Text(face.unit).font(.caption).foregroundStyle(.inkMuted).lineLimit(1)
                Spacer(minLength: 0)
                Text(face.foot).font(.caption.weight(.semibold)).foregroundStyle(.ink).lineLimit(1).minimumScaleFactor(0.8)
            }
            .padding(EdgeInsets(top: Theme.Space.s, leading: 15, bottom: 14, trailing: 15))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(Color.surface, for: .widget)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(face.accessibility)
    }
}

struct MediumWidgetView: View {
    let entry: WidgetEntry

    var body: some View {
        let face = WidgetCopy.face(entry)
        VStack(alignment: .leading, spacing: 0) {
            WidgetFilmStrip(face: face, posters: entry.posters, frames: 16, height: 40)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: Theme.Space.m) {
                    VStack(alignment: .leading, spacing: 2) {
                        WidgetCount(face: face, size: 46)
                        Text(face.unit).font(.caption).foregroundStyle(.inkMuted).lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Rectangle().fill(.hairline).frame(width: 1)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(face.eyebrow).font(.caption2.weight(.semibold)).textCase(.uppercase).tracking(0.6)
                            .foregroundStyle(.inkMuted).lineLimit(1)
                        Group {
                            if let deadline = face.countdownTo, deadline > entry.date {
                                Text(timerInterval: entry.date...deadline, countsDown: true)
                            } else {
                                Text(face.headline)
                            }
                        }
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        Text(face.detail).font(.caption).foregroundStyle(.inkMuted).lineLimit(1)
                    }
                    .frame(width: 128, alignment: .leading)
                }
                Spacer(minLength: 0)
                if let bottom = face.bottom {
                    Text(bottom).font(.caption.weight(.semibold)).foregroundStyle(.ink).lineLimit(1)
                }
            }
            .padding(EdgeInsets(top: Theme.Space.s, leading: Theme.Space.m, bottom: 14, trailing: Theme.Space.m))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(Color.surface, for: .widget)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(face.accessibility)
    }
}

// MARK: - Lock Screen

struct CircularAccessoryView: View {
    let entry: WidgetEntry
    private let segments = 20

    var body: some View {
        let face = WidgetCopy.face(entry)
        let lit = Int((face.fraction * Double(segments)).rounded())
        ZStack {
            AccessoryWidgetBackground()
            ForEach(0..<segments, id: \.self) { index in
                Circle()
                    .trim(from: Double(index) / Double(segments) + 0.008, to: Double(index + 1) / Double(segments) - 0.008)
                    .stroke(.primary, lineWidth: 4.5)
                    .rotationEffect(.degrees(-90))
                    .opacity(index < lit ? 1 : 0.3)
                    .widgetAccentable(index < lit)
            }
            .padding(3)
            VStack(spacing: 0) {
                Text(verbatim: "\(face.count)")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .widgetAccentable()
                Text(face.caption).font(.system(size: 8, weight: .bold)).lineLimit(1).minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 10)
        }
        .containerBackground(.clear, for: .widget)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(face.accessibility)
    }
}

struct RectangularAccessoryView: View {
    let entry: WidgetEntry
    private let frames = 12

    var body: some View {
        let face = WidgetCopy.face(entry)
        let lit = Int((face.fraction * Double(frames)).rounded())
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 2) {
                ForEach(0..<frames, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(.primary)
                        .opacity(index < lit ? 1 : 0.3)
                        .widgetAccentable(index < lit)
                }
            }
            .frame(height: 9)
            .padding(.bottom, 2)
            .accessibilityHidden(true)
            Text(face.rectangularTitle)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .lineLimit(1).minimumScaleFactor(0.8)
                .widgetAccentable()
            Text(face.rectangularLine).font(.subheadline).lineLimit(1).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(.clear, for: .widget)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(face.accessibility)
    }
}

struct InlineAccessoryView: View {
    let entry: WidgetEntry

    var body: some View {
        let face = WidgetCopy.face(entry)
        Label(face.inline, systemImage: face.frames == .picks ? "checklist" : "film")
            .containerBackground(.clear, for: .widget)
            .accessibilityLabel(face.accessibility)
    }
}

// MARK: - Previews

/// Every state in one family, at its Home Screen size.
private struct WidgetStates<Content: View>: View {
    let width: CGFloat
    let content: (WidgetEntry) -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.m) {
                ForEach(WidgetEntry.allSamples, id: \.name) { sample in
                    Text(sample.name).font(.caption).foregroundStyle(.inkMuted)
                    content(sample.entry)
                        .frame(width: width, height: 170)
                        .background(.surface)
                        .clipShape(.rect(cornerRadius: 26, style: .continuous))
                }
            }
            .padding()
        }
        .background(Color.ground)
    }
}

#Preview("Small, dark") {
    WidgetStates(width: 170) { SmallWidgetView(entry: $0) }.preferredColorScheme(.dark)
}

#Preview("Small, light") {
    WidgetStates(width: 170) { SmallWidgetView(entry: $0) }.preferredColorScheme(.light)
}

#Preview("Medium, dark") {
    WidgetStates(width: 364) { MediumWidgetView(entry: $0) }.preferredColorScheme(.dark)
}

#Preview("Medium, light") {
    WidgetStates(width: 364) { MediumWidgetView(entry: $0) }.preferredColorScheme(.light)
}

#Preview("Medium, large text") {
    WidgetStates(width: 364) { MediumWidgetView(entry: $0) }.dynamicTypeSize(.accessibility2)
}

#Preview("Small, accented") {
    WidgetStates(width: 170) { SmallWidgetView(entry: $0) }.environment(\.widgetRenderingMode, .accented)
}

#Preview("Lock Screen, vibrant") {
    ScrollView {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(WidgetEntry.allSamples, id: \.name) { sample in
                Text(sample.name).font(.caption)
                InlineAccessoryView(entry: sample.entry)
                HStack(spacing: 12) {
                    CircularAccessoryView(entry: sample.entry).frame(width: 72, height: 72)
                    RectangularAccessoryView(entry: sample.entry).frame(width: 172, height: 76)
                }
            }
        }
        .padding()
    }
    .background(Color.black).foregroundStyle(.white)
    .environment(\.widgetRenderingMode, .vibrant)
}
