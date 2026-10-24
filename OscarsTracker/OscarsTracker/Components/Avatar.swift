import SwiftUI

/// A person's picture, or their initial on a solid circle. Your own avatar
/// carries a gold ring (gold is earned: it marks you on the board).
struct Avatar: View {
    let name: String
    var url: String?
    var size: CGFloat = 36
    var isYou = false

    var body: some View {
        Group {
            if let url, let link = URL(string: url) {
                AsyncImage(url: link) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    initial
                }
            } else {
                initial
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
        .overlay {
            Circle().strokeBorder(isYou ? AnyShapeStyle(.gold) : AnyShapeStyle(.hairline), lineWidth: isYou ? 3 : 0.5)
        }
        .accessibilityHidden(true)
    }

    private var initial: some View {
        Text(name.prefix(1).uppercased())
            .font(.system(size: size * 0.42, weight: .semibold, design: .rounded))
            .foregroundStyle(.ink)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.raised)
    }
}

#Preview {
    HStack {
        Avatar(name: "Sam", size: 64)
        Avatar(name: "filmbuff", size: 52, isYou: true)
        Avatar(name: "Jordan")
    }
    .padding()
    .background(.ground)
}
