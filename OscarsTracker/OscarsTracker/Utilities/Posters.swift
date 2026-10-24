import Foundation

/// TMDB poster sizes (screens.md, section 2). The `movies` table stores the
/// `original` size, which is megabytes per poster; tiles ask for `w342` and
/// thumbnails (rows, the ambient colours) for `w92`.
nonisolated enum PosterSize: String, Sendable {
    case tile = "w342"
    case thumbnail = "w92"

    /// The poster at this size: any TMDB image URL (`image.tmdb.org` or
    /// `media.themoviedb.org`, any size) is rewritten to `/t/p/<size>/`.
    /// Anything else is left as it is.
    func url(_ poster: String?) -> URL? {
        guard let poster, var components = URLComponents(string: poster) else { return nil }
        let parts = components.path.split(separator: "/", omittingEmptySubsequences: true)
        let isTMDB = components.host == "image.tmdb.org" || components.host == "media.themoviedb.org"
        if isTMDB, parts.count == 4, parts[0] == "t", parts[1] == "p" {
            components.host = "image.tmdb.org"
            components.path = "/t/p/\(rawValue)/\(parts[3])"
        }
        return components.url
    }

    func request(_ poster: String?) -> URLRequest? {
        url(poster).map { URLRequest(url: $0, cachePolicy: .returnCacheDataElseLoad) }
    }
}

extension URLSession {
    /// Posters only, with their own 200 MB disk cache, so they survive
    /// relaunches and don't crowd out anything else. Set once at the root
    /// with `asyncImageURLSession(_:)`.
    nonisolated static let posters: URLSession = {
        let configuration = URLSessionConfiguration.default
        let directory = URL.cachesDirectory.appending(path: "Posters", directoryHint: .isDirectory)
        configuration.urlCache = URLCache(memoryCapacity: 32 << 20, diskCapacity: 200 << 20, directory: directory)
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: configuration)
    }()
}
