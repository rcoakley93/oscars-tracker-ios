import SwiftUI

/// Every design token on one screen, for review in previews (dark, light and
/// a large text size). Not part of the app's navigation.
struct TokensGallery: View {
    private let swatches: [(String, Color)] = [
        ("ground", .ground), ("surface", .surface), ("raised", .raised), ("hairline", .hairline),
        ("ink", .ink), ("inkMuted", .inkMuted), ("gold", .gold), ("goldText", .goldText),
        ("goldOnGlass", .goldOnGlass), ("velvet", .velvet), ("success", .success),
        ("warning", .warning), ("danger", .danger), ("dangerText", .dangerText),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.xl) {
                VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                    Text("99th Academy Awards").eyebrowStyle()
                    Text("Ceremony Night").displayFont()
                        .foregroundStyle(.ink)
                    Text("Design tokens for the native app.")
                        .font(.body)
                        .foregroundStyle(.inkMuted)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: Theme.Space.s)], spacing: Theme.Space.s) {
                    ForEach(swatches, id: \.0) { name, color in
                        HStack(spacing: Theme.Space.s) {
                            Theme.shape(Theme.Radius.thumbnail)
                                .fill(color)
                                .frame(width: 36, height: 36)
                                .overlay(Theme.shape(Theme.Radius.thumbnail).strokeBorder(.hairline, lineWidth: 0.5))
                            Text(name).font(.footnote).foregroundStyle(.ink)
                            Spacer(minLength: 0)
                        }
                        .padding(Theme.Space.xs)
                        .solidSurface(radius: Theme.Radius.row)
                    }
                }

                VStack(alignment: .leading, spacing: Theme.Space.xs) {
                    Text("12").displayFont(.largeTitle)
                        .foregroundStyle(Theme.goldGradient)
                    Text("Large title").font(.largeTitle.bold()).fontDesign(.rounded)
                    Text("Title 2").font(.title2.bold()).fontDesign(.rounded)
                    Text("Headline").font(.headline)
                    Text("Body text in SF Pro, which follows Dynamic Type.").font(.body)
                    Text("Footnote, muted").font(.footnote).foregroundStyle(.inkMuted)
                    Text("Your pick").font(.footnote.weight(.semibold)).foregroundStyle(.goldText)
                }
                .foregroundStyle(.ink)
                .padding(Theme.Space.m)
                .frame(maxWidth: .infinity, alignment: .leading)
                .solidSurface()

                HStack(spacing: Theme.Space.s) {
                    ForEach([("thumb", Theme.Radius.thumbnail), ("tile", Theme.Radius.tile), ("row", Theme.Radius.row), ("card", Theme.Radius.card), ("hero", Theme.Radius.hero)], id: \.0) { name, radius in
                        VStack {
                            Theme.shape(radius).fill(.raised).frame(width: 52, height: 52)
                            Text(name).font(.caption2).foregroundStyle(.inkMuted)
                        }
                    }
                }
            }
            .padding(Theme.Space.m)
        }
        .background(.ground)
    }
}

#Preview("Dark") {
    TokensGallery().preferredColorScheme(.dark)
}

#Preview("Light") {
    TokensGallery().preferredColorScheme(.light)
}

#Preview("Large text") {
    TokensGallery()
        .preferredColorScheme(.dark)
        .dynamicTypeSize(.accessibility2)
}
