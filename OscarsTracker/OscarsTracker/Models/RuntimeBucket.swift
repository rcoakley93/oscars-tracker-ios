import Foundation

/// A runtime range for "What can I watch?", from `app_config.runtime_buckets`
/// (`{"short": [0, 40], "medium": [41, 90], "standard": [91, 120]}`), so the
/// season can change them without a release.
nonisolated struct RuntimeBucket: Codable, Hashable, Identifiable, Sendable {
    var id: String { name }
    let name: String
    let minutes: ClosedRange<Int>

    /// Used until the server's buckets load, or if they can't.
    static let defaults = [
        RuntimeBucket(name: "short", minutes: 0...40),
        RuntimeBucket(name: "medium", minutes: 41...90),
        RuntimeBucket(name: "standard", minutes: 91...120),
    ]

    /// The buckets in `app_config`'s shape, shortest first; malformed ones are skipped.
    static func parse(_ value: [String: [Int]]) -> [RuntimeBucket] {
        value.compactMap { name, bounds in
            guard bounds.count == 2, bounds[0] <= bounds[1] else { return nil }
            return RuntimeBucket(name: name, minutes: bounds[0]...bounds[1])
        }
        .sorted { $0.minutes.upperBound < $1.minutes.upperBound }
    }
}
