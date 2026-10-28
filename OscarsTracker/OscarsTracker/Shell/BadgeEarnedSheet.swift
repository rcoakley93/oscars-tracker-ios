import SwiftUI

/// A badge arrived (screens.md 3.8 and 4, P12-04): the one-time reveal, one
/// badge at a time from `BadgeStore.queue`. The art scales in with gold dust
/// and a `.success` haptic; under Reduce Motion it fades in with no dust.
/// Each badge is marked seen as it appears, so it never shows twice.
struct BadgeEarnedSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.copy) private var copy
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let queue = model.badges.queue
        NavigationStack {
            Group {
                if let badge = queue.first {
                    BadgeReveal(badge: badge, title: copy.badgeRevealTitle)
                        .id(badge.momentKey)
                        .onAppear {
                            if let userID = model.session.userID { model.badges.shown(badge, userID: userID) }
                        }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .cancellationAction) {
                    Button("Done", systemImage: "checkmark") { dismiss() }
                }
                .visibilityPriority(.high)
                ToolbarItemGroup(placement: .confirmationAction) {
                    if queue.count > 1 {
                        Button("Next", systemImage: "chevron.forward") { model.badges.advance() }
                    } else if let badge = queue.first {
                        BadgeShareButton(badge: badge)
                    }
                }
                .visibilityPriority(.low)
            }
        }
        .presentationDetents([.medium, .large])
        .onDisappear { model.badges.closeReveal() }
        .onChange(of: queue.isEmpty) { _, empty in if empty { dismiss() } }
    }
}

/// The art, the title, the name, tier and description.
struct BadgeReveal: View {
    let badge: UserBadge
    let title: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(Voice.storageKey) private var voice: Voice = .host
    @State private var shown = false
    @State private var burst = 0

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Space.s) {
                Text(title).font(.headline).foregroundStyle(.inkMuted)
                ZStack {
                    GoldDust(trigger: burst)
                        .frame(width: 320, height: 240)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                    BadgeArt(badge: badge, size: 140)
                        .scaleEffect(shown || reduceMotion ? 1 : 0.6)
                        .opacity(shown ? 1 : 0)
                }
                .frame(height: 180)
                if let catalogue = badge.badge {
                    Text(catalogue.name(voice)).font(.title2.bold()).foregroundStyle(.ink).multilineTextAlignment(.center)
                    if let tier = catalogue.tierLabel(badge.tier) {
                        Text(tier).font(.headline).foregroundStyle(.goldText)
                    }
                    Text(catalogue.description(voice)).font(.body).foregroundStyle(.ink).multilineTextAlignment(.center)
                }
            }
            .padding(Theme.Space.l)
            .frame(maxWidth: .infinity)
        }
        .background(.ground)
        .accessibilityElement(children: .combine)
        .moment(.badgeEarned, trigger: shown)
        .onAppear {
            withAnimation(reduceMotion ? .easeIn(duration: 0.3) : .spring(duration: 0.6, bounce: 0.3)) { shown = true }
            if !reduceMotion { burst += 1 }
        }
    }
}

#if DEBUG
private struct BadgeEarnedPreview: View {
    var badges = [SampleData.badge("films_watched", tier: 2, earnedAt: .now)]
    var voice = Voice.host

    var body: some View {
        Color.ground.sheet(isPresented: .constant(true)) { BadgeEarnedSheet().environment(\.copy, .for(voice)) }
            .environment(AppModel.preview { $0.badgeRows[SampleDataSource.userID] = badges })
    }
}

#Preview("Reveal") { BadgeEarnedPreview().preferredColorScheme(.dark) }
#Preview("Reveal, two waiting") {
    BadgeEarnedPreview(badges: [SampleData.badge("full_ballot", earnedAt: .now), SampleData.badge("correct_picks", tier: 1, earnedAt: .now)])
        .preferredColorScheme(.dark)
}
#Preview("Reveal · Classic") { BadgeEarnedPreview(voice: .classic).preferredColorScheme(.light) }
#Preview("Light") { BadgeEarnedPreview().preferredColorScheme(.light) }
#Preview("Large text") { BadgeEarnedPreview().preferredColorScheme(.dark).dynamicTypeSize(.accessibility2) }
#endif
