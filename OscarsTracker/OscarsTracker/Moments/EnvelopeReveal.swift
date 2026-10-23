import SwiftUI

/// How a winner is revealed on Oscar night (P3-08; live mode uses it in
/// P6-02): a velvet envelope with a gold seal. The flap opens, the card rises
/// with "And the Oscar goes to…" and the winner, then your pick is marked
/// right or wrong in your voice. With Reduce Motion the card simply fades in.
struct EnvelopeReveal: View {
    enum Outcome { case correct, wrong }

    let category: String
    let winner: String
    /// The film, when the winner is a person.
    var detail: String?
    /// nil when you made no pick in this category.
    var outcome: Outcome?
    var onDone: () -> Void

    @Environment(\.copy) private var copy
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var stage = 0  // 0 sealed, 1 open, 2 card, 3 verdict
    @State private var burst = 0

    var body: some View {
        ZStack {
            RadialGradient(colors: [.velvet.opacity(0.35), .clear], center: .center, startRadius: 0, endRadius: 420)
                .background(.ground.opacity(0.97))
                .ignoresSafeArea()

            VStack(spacing: Theme.Space.xl) {
                Text(category).eyebrowStyle()
                envelope
                    .padding(.top, 110)
                verdict
                    .goldDust(trigger: burst)
                Button("Continue", action: onDone)
                    .buttonStyle(.glass)
                    .controlSize(.large)
            }
            .padding(Theme.Space.l)
            .centeredBesideFold()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(category): \(winner)")
        .moment(.envelopeOpen, trigger: stage == 1)
        .moment(outcome == .wrong ? .wrong : .correct, trigger: stage == 3 && outcome != nil)
        .task {
            if reduceMotion {
                stage = 3
            } else {
                for (next, delay) in [(1, 450), (2, 550), (3, 900)] {
                    try? await Task.sleep(for: .milliseconds(delay))
                    withAnimation(.smooth(duration: next == 2 ? 0.8 : 0.55)) { stage = next }
                }
            }
            if outcome == .correct { burst += 1 }
        }
    }

    private var envelope: some View {
        ZStack {
            Theme.shape(10).fill(velvet).frame(width: 300, height: 200)
                .shadow(color: .black.opacity(0.5), radius: 30, y: 20)

            card
                .offset(y: stage >= 2 ? -120 : 0)
                .opacity(reduceMotion && stage < 3 ? 0 : 1)

            EnvelopePocket().fill(velvet).frame(width: 300, height: 200)
                .overlay(EnvelopePocket().stroke(.goldMid.opacity(0.35), lineWidth: 1))

            if !reduceMotion {
                EnvelopeFlap().fill(velvet).brightness(0.06).frame(width: 300, height: 200)
                    .rotation3DEffect(.degrees(stage >= 1 ? 180 : 0), axis: (x: 1, y: 0, z: 0), anchor: .top, perspective: 0.6)
                    .zIndex(stage >= 1 ? -1 : 2)
                Circle()
                    .fill(RadialGradient(colors: [.goldStart, .goldMid, .gold], center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0, endRadius: 22))
                    .frame(width: 40, height: 40)
                    .offset(y: 24)
                    .opacity(stage == 0 ? 1 : 0)
                    .zIndex(3)
            }
        }
        .frame(width: 300, height: 200)
        .accessibilityHidden(true)
    }

    private var card: some View {
        VStack(spacing: Theme.Space.xxs) {
            Text("And the Oscar goes to…")
                .font(.system(.body, design: .serif).italic())
                .foregroundStyle(.inkMuted)
            if stage >= 2 {
                Text(winner)
                    .font(.system(.title, design: .serif, weight: .bold))
                    .foregroundStyle(.ink)
                    .multilineTextAlignment(.center)
                if let detail {
                    Text(detail).font(.footnote).foregroundStyle(.inkMuted)
                }
            }
        }
        .padding(Theme.Space.m)
        .frame(width: 264, height: 172, alignment: .top)
        .background(.surface, in: Theme.shape(6))
        .overlay(Theme.shape(6).strokeBorder(.gold.opacity(0.5), lineWidth: 1))
    }

    @ViewBuilder
    private var verdict: some View {
        Group {
            switch outcome {
            case .correct:
                Label(copy.correct, systemImage: "checkmark")
                    .font(.headline)
                    .foregroundStyle(.goldOnGlass)
                    .padding(.horizontal, Theme.Space.m).padding(.vertical, Theme.Space.xs)
                    .background(.goldMid.opacity(0.15), in: Capsule())
            case .wrong:
                Label(copy.wrong, systemImage: "xmark")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.inkMuted)
                    .padding(.horizontal, Theme.Space.m).padding(.vertical, Theme.Space.xs)
                    .background(.raised, in: Theme.shape(Theme.Radius.row))
            case nil:
                EmptyView()
            }
        }
        .frame(minHeight: 44)
        .opacity(stage >= 3 ? 1 : 0)
        .offset(y: stage >= 3 || reduceMotion ? 0 : 6)
    }

    private var velvet: LinearGradient {
        LinearGradient(colors: [Color(red: 0.64, green: 0.20, blue: 0.25), .velvet, Color(red: 0.40, green: 0.12, blue: 0.15)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

/// The envelope's front pocket: a V cut into the top edge.
private nonisolated struct EnvelopePocket: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.height * 0.32))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.height * 0.64))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.32))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

/// The flap: a triangle hinged at the top edge.
private nonisolated struct EnvelopeFlap: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: rect.maxX, y: 0))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.height * 0.62))
            path.closeSubpath()
        }
    }
}

#Preview("Correct pick") {
    EnvelopeReveal(category: "Best Picture", winner: "Hamnet", outcome: .correct, onDone: {})
        .preferredColorScheme(.dark)
}

#Preview("Wrong pick, acting") {
    EnvelopeReveal(category: "Actress in a Leading Role", winner: "Jessie Buckley", detail: "Hamnet", outcome: .wrong, onDone: {})
        .preferredColorScheme(.dark)
}
