import SwiftUI

/// Oscar-night live mode (P6-02; screens.md, live mode and section 5): each
/// winner plays the envelope. On compact widths the envelope is a full-screen
/// cover. On regular widths (the iPhone Duo's inner screen, iPad) the cover
/// is an arrangement, the envelope beside the live board when flat and above
/// it when a Duo stands in tabletop pose (the system splits it vertically
/// because the arrangement is taller than wide).
extension View {
    /// Presents the next envelope once no sheet is open, so it never fights
    /// a sheet for the screen; envelopes that arrive meanwhile wait in line.
    func liveReveals() -> some View {
        modifier(LiveReveals())
    }
}

private struct LiveReveals: ViewModifier {
    @Environment(AppModel.self) private var model

    func body(content: Content) -> some View {
        content.fullScreenCover(isPresented: Binding {
            model.live.current != nil && model.navigation.sheet == nil
        } set: { _ in
            // Only Continue moves on, so a dismissal never skips an envelope.
        }) {
            LiveRevealScreen()
        }
    }
}

/// The envelope, alone or beside the live board.
struct LiveRevealScreen: View {
    @Environment(AppModel.self) private var model
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        if let reveal = model.live.current {
            let envelope = EnvelopeReveal(category: reveal.category, winner: reveal.winner, detail: reveal.detail,
                                          outcome: reveal.outcome) {
                model.live.dismissCurrent()
            }
            // A new category is a new envelope, sealed again.
            .id(reveal.categoryID)

            if sizeClass == .regular {
                SplitArrangement {
                    envelope
                } secondary: {
                    NavigationStack { LiveBoard() }
                }
            } else {
                envelope
            }
        }
    }
}

/// The ballot as the night goes: your score, your place, each winner with
/// your pick marked right or wrong, and the categories still to come.
struct LiveBoard: View {
    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy

    private var decided: [BallotCategory] { model.ballot.categories.filter { !$0.winnerIDs.isEmpty } }
    private var toCome: [BallotCategory] { model.ballot.categories.filter { $0.winnerIDs.isEmpty } }

    var body: some View {
        List {
            Section {
                header
                if model.live.decidedCount > 0 { tally }
            }
            if !decided.isEmpty {
                Section("Announced") {
                    ForEach(decided) { category in
                        LiveBoardRow(category: category, pick: model.ballot.pick(for: category.id))
                    }
                }
            }
            if !toCome.isEmpty {
                Section("Still to come") {
                    ForEach(toCome) { category in
                        LiveBoardRow(category: category, pick: model.ballot.pick(for: category.id))
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(.ground)
        .navigationTitle("Live")
        .navigationSubtitle(model.season.ceremony?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.smooth, value: model.ballot.categories)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                Text("Your score").font(.subheadline).foregroundStyle(.inkMuted)
                // Gold: points you earned.
                Text(model.ballot.score, format: .number)
                    .font(.system(.largeTitle, design: .serif, weight: .bold))
                    .foregroundStyle(.goldText)
                    .contentTransition(.numericText())
            }
            Spacer()
            VStack(alignment: .trailing, spacing: Theme.Space.xxs) {
                Text("\(model.live.decidedCount) of \(model.ballot.categories.count)")
                    .font(.headline)
                Text("announced").font(.subheadline).foregroundStyle(.inkMuted)
                if let userID = model.session.userID,
                   let standing = model.leaderboard.standing(in: nil, userID: userID, metric: .predictions) {
                    Text("#\(standing.rank) of \(standing.size)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.inkMuted)
                        .contentTransition(.numericText())
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var tally: some View {
        Text(copy.callTally(model.ballot.calledCount, model.live.decidedCount, toCome.isEmpty))
            .font(.subheadline).foregroundStyle(.inkMuted)
    }
}

extension BallotStore {
    /// Winners announced in categories where you picked one of them.
    var calledCount: Int { categories.count { outcome(for: $0) == .correct } }
}

struct LiveBoardRow: View {
    let category: BallotCategory
    let pick: Int?
    @Environment(\.copy) private var copy

    private var winners: [BallotNominee] { category.nominations.filter(\.isWinner) }
    private var picked: BallotNominee? { category.nominations.first { $0.id == pick } }
    private var isCorrect: Bool { pick.map(category.winnerIDs.contains) ?? false }

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Space.s) {
            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                Text(category.name).font(.footnote.weight(.semibold)).foregroundStyle(.inkMuted)
                if winners.isEmpty {
                    nominee(picked, fallback: copy.liveNoPick)
                } else {
                    ForEach(winners) { nominee($0, fallback: "") }
                    if !isCorrect, let picked {
                        Text("Your pick: \(name(picked))").font(.footnote).foregroundStyle(.inkMuted)
                    }
                }
            }
            Spacer(minLength: 0)
            status
        }
        .padding(.vertical, Theme.Space.xxs)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func nominee(_ nominee: BallotNominee?, fallback: String) -> some View {
        if let nominee {
            VStack(alignment: .leading, spacing: 0) {
                Text(name(nominee)).font(.body.weight(.medium))
                // Acting categories lead with the person; the film goes underneath.
                if let person = nominee.personName, !person.isEmpty, let film = nominee.movie?.title {
                    Text(film).font(.footnote).foregroundStyle(.inkMuted)
                }
            }
        } else {
            Text(fallback).font(.body).foregroundStyle(.inkMuted)
        }
    }

    private func name(_ nominee: BallotNominee) -> String {
        if let person = nominee.personName, !person.isEmpty { return person }
        return nominee.movie?.title ?? ""
    }

    /// A symbol as well as a colour, so it reads without colour.
    @ViewBuilder
    private var status: some View {
        if winners.isEmpty {
            if pick != nil {
                Image(systemName: "envelope").foregroundStyle(.inkMuted).accessibilityLabel("Waiting")
            }
        } else if pick == nil {
            Image(systemName: "minus").foregroundStyle(.inkMuted).accessibilityLabel(copy.liveNoPick)
        } else if isCorrect {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.goldText).accessibilityLabel(copy.correct)
        } else {
            Image(systemName: "xmark.circle").foregroundStyle(.inkMuted).accessibilityLabel(copy.wrong)
        }
    }
}

// MARK: - Previews

extension AppModel {
    /// Live mode on the rehearsal with Best Picture (your pick) and Actress
    /// (not your pick) announced; `queued` leaves their envelopes waiting.
    static func livePreview(queued: Bool = true) -> AppModel {
        let data = SampleDataSource()
        data.isRehearsal = true
        data.config.featureFlags[AppConfig.liveMode] = true
        let model = AppModel(data: data)
        Task {
            await model.start()
            data.announce([103], inCategory: 1)
            data.announce([202], inCategory: 2)
            try? await Task.sleep(for: .milliseconds(500))
            if !queued {
                while model.live.current != nil { model.live.dismissCurrent() }
            }
        }
        return model
    }
}

#Preview("Dark") {
    NavigationStack { LiveBoard() }
        .environment(AppModel.livePreview(queued: false))
        .preferredColorScheme(.dark)
}

#Preview("Light") {
    NavigationStack { LiveBoard() }
        .environment(AppModel.livePreview(queued: false))
        .preferredColorScheme(.light)
}

#Preview("Large text") {
    NavigationStack { LiveBoard() }
        .environment(AppModel.livePreview(queued: false))
        .preferredColorScheme(.dark)
        .dynamicTypeSize(.accessibility2)
}

#Preview("Before any winner") {
    NavigationStack { LiveBoard() }
        .environment(AppModel.preview { $0.config.featureFlags[AppConfig.liveMode] = true })
        .preferredColorScheme(.dark)
}

#Preview("Reveal, compact") {
    LiveRevealScreen()
        .environment(AppModel.livePreview())
        .preferredColorScheme(.dark)
}

#Preview("Reveal and board, regular", traits: .landscapeLeft) {
    LiveRevealScreen()
        .environment(AppModel.livePreview())
        .environment(\.horizontalSizeClass, .regular)
        .preferredColorScheme(.dark)
}

#Preview("Reveal, light") {
    LiveRevealScreen()
        .environment(AppModel.livePreview())
        .preferredColorScheme(.light)
}

#Preview("Reveal, large text") {
    LiveRevealScreen()
        .environment(AppModel.livePreview())
        .preferredColorScheme(.dark)
        .dynamicTypeSize(.accessibility2)
}
