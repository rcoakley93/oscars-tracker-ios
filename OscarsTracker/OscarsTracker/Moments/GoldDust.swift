import SwiftUI

/// A burst of gold dust (P3-08) for the moments gold is earned: a complete
/// ballot, the last nominee watched, joining a group, a correct pick. Nothing
/// else. With Reduce Motion it's a soft glow that fades.
struct GoldDust: View {
    /// Change this to fire a burst.
    var trigger: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start: Date?
    private static let duration: TimeInterval = 1.3
    private static let particles: [(angle: Double, distance: Double, size: Double, delay: Double)] = (0..<26).map { index in
        var generator = SeededGenerator(seed: UInt64(index + 1))
        let angle = Double(index) / 26 * .pi * 2 + Double.random(in: 0...0.4, using: &generator)
        return (angle, Double.random(in: 60...150, using: &generator), Double.random(in: 3...7, using: &generator), Double.random(in: 0...0.12, using: &generator))
    }

    var body: some View {
        TimelineView(.animation(paused: start == nil)) { context in
            Canvas { canvas, size in
                guard let start else { return }
                let t = context.date.timeIntervalSince(start) / Self.duration
                guard t < 1 else { return }
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let glow = max(0, 1 - t * 1.4)
                canvas.fill(Path(ellipseIn: CGRect(x: center.x - 50, y: center.y - 50, width: 100, height: 100)),
                            with: .radialGradient(Gradient(colors: [Color.goldMid.opacity(0.45 * glow), .clear]),
                                                  center: center, startRadius: 0, endRadius: 50))
                guard !reduceMotion else { return }
                for particle in Self.particles {
                    let local = max(0, min(1, (t - particle.delay) / (1 - particle.delay)))
                    let travel = 1 - pow(1 - min(local / 0.7, 1), 3)
                    let fall = max(0, local - 0.7) / 0.3 * 36
                    let x = center.x + cos(particle.angle) * particle.distance * travel
                    let y = center.y + sin(particle.angle) * particle.distance * travel - 30 * travel + fall
                    let opacity = local < 0.12 ? local / 0.12 : (local > 0.7 ? 1 - (local - 0.7) / 0.3 : 1)
                    let rect = CGRect(x: x - particle.size / 2, y: y - particle.size / 2, width: particle.size, height: particle.size)
                    var layer = canvas
                    layer.opacity = opacity
                    layer.fill(Path(roundedRect: rect, cornerRadius: 1),
                               with: .linearGradient(Gradient(colors: [.goldStart, .goldMid]), startPoint: rect.origin, endPoint: CGPoint(x: rect.maxX, y: rect.maxY)))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: trigger) {
            start = .now
            Task {
                try? await Task.sleep(for: .seconds(Self.duration))
                start = nil
            }
        }
    }
}

/// A tiny deterministic generator, so a burst looks the same every time.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &* 0x9E37_79B9_7F4A_7C15 }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

extension View {
    /// Overlays a gold-dust burst, fired whenever `trigger` changes.
    func goldDust(trigger: Int) -> some View {
        overlay { GoldDust(trigger: trigger).frame(width: 340, height: 340) }
    }
}
