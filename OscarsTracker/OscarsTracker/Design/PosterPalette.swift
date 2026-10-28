import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

/// The colours of the posters behind a screen, for the ambient mesh. Each
/// poster is shrunk to 64 points and clustered into three colours with
/// `CIKMeans`, off the main actor; the most vivid cluster stands for the
/// poster. Results are cached per poster for the life of the app.
actor PosterPalette {
    static let shared = PosterPalette()

    private var cache: [URL: Cluster] = [:]
    private let context = CIContext(options: [.workingColorSpace: NSNull()])

    /// One colour per poster that loads, in order; posters that fail are skipped.
    func colors(for urls: [URL]) async -> [Color] {
        await clusters(for: urls).map { Color(red: $0.red, green: $0.green, blue: $0.blue) }
    }

    /// The same colours as components, for the widgets' snapshot (P11-02).
    func clusters(for urls: [URL]) async -> [Cluster] {
        var clusters: [Cluster] = []
        for url in urls {
            if let cluster = await cluster(for: url) { clusters.append(cluster) }
        }
        return clusters
    }

    private func cluster(for url: URL) async -> Cluster? {
        if let cached = cache[url] { return cached }
        guard let (data, _) = try? await URLSession.posters.data(for: URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)),
              let image = UIImage(data: data)?.preparingThumbnail(of: CGSize(width: 64, height: 96)),
              let cgImage = image.cgImage,
              let clusters = Self.clusters(in: CIImage(cgImage: cgImage), context: context),
              let vivid = clusters.max(by: { $0.vividness < $1.vividness })
        else { return nil }
        cache[url] = vivid
        return vivid
    }

    struct Cluster: Equatable {
        var red: Double
        var green: Double
        var blue: Double
        /// Saturation times brightness, so a dark or grey cluster loses to a coloured one.
        var vividness: Double {
            let high = max(red, green, blue), low = min(red, green, blue)
            return high == 0 ? 0 : (high - low) / high * high
        }
    }

    /// Three k-means clusters of the image's colours.
    static func clusters(in image: CIImage, context: CIContext) -> [Cluster]? {
        let filter = CIFilter.kMeans()
        filter.inputImage = image
        filter.extent = image.extent
        filter.count = 3
        filter.passes = 5
        filter.perceptual = true
        guard let output = filter.outputImage?.settingAlphaOne(in: CGRect(x: 0, y: 0, width: 3, height: 1)) else { return nil }
        var pixels = [Float](repeating: 0, count: 12)
        context.render(output, toBitmap: &pixels, rowBytes: 3 * 4 * MemoryLayout<Float>.size,
                       bounds: CGRect(x: 0, y: 0, width: 3, height: 1), format: .RGBAf, colorSpace: nil)
        return (0..<3).map { index in
            Cluster(red: Double(pixels[index * 4]), green: Double(pixels[index * 4 + 1]), blue: Double(pixels[index * 4 + 2]))
        }
    }
}
