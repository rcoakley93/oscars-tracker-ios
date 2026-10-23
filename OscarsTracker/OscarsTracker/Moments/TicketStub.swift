import SwiftUI

/// Marking a film watched tears an "Admit one" ticket stub (P3-08): the ticket
/// rises over the row, the stub tears off along the perforation, and both
/// fade. With Reduce Motion it simply fades in and out.
struct TicketStub: View {
    let title: String
    /// Change this to tear a stub.
    var trigger: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: Phase = .hidden

    private enum Phase { case hidden, shown, torn }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Admit one")
                    .font(.caption2.weight(.bold))
                    .textCase(.uppercase)
                    .tracking(1.2)
                    .foregroundStyle(.gold)
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .lineLimit(1)
                    .foregroundStyle(.ground)
            }
            .padding(.horizontal, Theme.Space.s)
            .frame(maxWidth: 190, minHeight: 48, alignment: .leading)
            .background(.ink, in: UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 6))
            .overlay(alignment: .trailing) {
                Rectangle().fill(.clear).frame(width: 1)
                    .overlay(Rectangle().stroke(.ground.opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [3, 3])))
            }
            Image(systemName: "checkmark")
                .font(.footnote.weight(.bold))
                .foregroundStyle(.gold)
                .frame(width: 36, height: 48)
                .background(.ink, in: UnevenRoundedRectangle(bottomTrailingRadius: 6, topTrailingRadius: 6))
                .rotationEffect(.degrees(phase == .torn && !reduceMotion ? 26 : 0), anchor: .bottomLeading)
                .offset(x: phase == .torn && !reduceMotion ? 30 : 0, y: phase == .torn && !reduceMotion ? 22 : 0)
                .opacity(phase == .torn ? 0 : 1)
        }
        .shadow(color: .black.opacity(0.35), radius: 10, y: 6)
        .offset(y: reduceMotion ? 0 : (phase == .hidden ? 8 : (phase == .torn ? -60 : -20)))
        .opacity(phase == .hidden ? 0 : (phase == .torn ? 0 : 1))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: trigger) {
            withAnimation(.smooth(duration: 0.2)) { phase = .shown }
            Task {
                try? await Task.sleep(for: .milliseconds(450))
                withAnimation(.smooth(duration: 0.65)) { phase = .torn }
                try? await Task.sleep(for: .milliseconds(700))
                phase = .hidden
            }
        }
    }
}
