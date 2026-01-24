import SwiftUI

/// Hero view displaying movie watching progress with countdown to Oscars.
struct ProgressHeroView: View {
    let watchedCount: Int
    let totalCount: Int
    let oscarDate: Date
    let minutesRemaining: Int

    private var percentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(watchedCount) / Double(totalCount)
    }

    private var percentageString: String {
        let percent = percentage * 100
        return String(format: "%.0f%%", percent)
    }

    private var daysRemaining: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let oscar = calendar.startOfDay(for: oscarDate)
        let components = calendar.dateComponents([.day], from: today, to: oscar)
        return max(0, components.day ?? 0)
    }

    private var moviesPerDay: Double {
        guard daysRemaining > 0 else { return 0 }
        let remaining = totalCount - watchedCount
        return Double(remaining) / Double(daysRemaining)
    }

    private var moviesPerDayString: String {
        if moviesPerDay <= 0 {
            return "All caught up!"
        } else if moviesPerDay < 1 {
            return String(format: "%.1f movies/day", moviesPerDay)
        } else {
            return String(format: "%.1f movies/day", moviesPerDay)
        }
    }

    private var formattedMinutesRemaining: String {
        let hours = minutesRemaining / 60
        let mins = minutesRemaining % 60
        if hours == 0 {
            return "\(mins)m"
        } else if mins == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(mins)m"
    }

    var body: some View {
        VStack(spacing: 20) {
            // Progress section
            VStack(spacing: 12) {
                // Main percentage
                Text(percentageString)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(LinearGradient.gold)
                    .goldGlow()

                // Watched count
                Text("\(watchedCount) of \(totalCount) movies watched")
                    .font(.headingMedium)
                    .foregroundStyle(Color.textPrimary)

                // Progress bar
                ProgressBarView(progress: percentage)
                    .frame(height: 12)
            }

            Divider()
                .background(Color.borderColor)

            // Stats section
            HStack(spacing: 16) {
                // Days remaining
                VStack(spacing: 4) {
                    Text("\(daysRemaining)")
                        .font(.displayMedium)
                        .foregroundStyle(Color.goldPrimary)
                    Text("days left")
                        .font(.bodySmall)
                        .foregroundStyle(Color.textMuted)
                }

                Divider()
                    .frame(height: 40)
                    .background(Color.borderColor)

                // Movies per day
                VStack(spacing: 4) {
                    Text(moviesPerDayString)
                        .font(.headingMedium)
                        .foregroundStyle(Color.goldPrimary)
                    Text("to finish on time")
                        .font(.bodySmall)
                        .foregroundStyle(Color.textMuted)
                }

                Divider()
                    .frame(height: 40)
                    .background(Color.borderColor)

                // Minutes remaining
                VStack(spacing: 4) {
                    Text(formattedMinutesRemaining)
                        .font(.headingMedium)
                        .foregroundStyle(Color.goldPrimary)
                    Text("remaining")
                        .font(.bodySmall)
                        .foregroundStyle(Color.textMuted)
                }
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Progress: \(watchedCount) of \(totalCount) movies watched, \(daysRemaining) days until Oscars, \(formattedMinutesRemaining) remaining")
    }
}

/// Gold gradient progress bar component.
struct ProgressBarView: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.borderColor)

                // Progress fill
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient.gold)
                    .frame(width: max(0, geometry.size.width * progress))
                    .animation(.easeInOut(duration: 0.5), value: progress)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        ProgressHeroView(
            watchedCount: 15,
            totalCount: 42,
            oscarDate: Calendar.current.date(byAdding: .day, value: 68, to: Date())!,
            minutesRemaining: 2970
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}
