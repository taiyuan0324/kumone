import Foundation

/// Client for the third-party music API at https://music-api.gdstudio.xyz/api.php
/// Used as a fallback / alternative source for song URLs.
enum GdstudioMusicAPI {
    static let baseURL = URL(string: "https://music-api.gdstudio.xyz/api.php")!

    // MARK: - URL Fetch

    /// Get a playable URL for a track via the gdstudio API.
    /// Returns nil if the API is unavailable or returns no URL.
    static func songURL(
        id: Int,
        br: Int = 320,
        source: String = "netease"
    ) async throws -> String? {
        var components = URLComponents(
            string: baseURL.absoluteString
        )!
        components.queryItems = [
            URLQueryItem(name: "types", value: "url"),
            URLQueryItem(name: "source", value: source),
            URLQueryItem(name: "id", value: String(id)),
            URLQueryItem(name: "br", value: String(br)),
        ]
        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue("Kumone/1.0 (iOS)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode),
              !data.isEmpty else { return nil }

        // Try direct decode first
        if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let url = dict["url"] as? String, !url.isEmpty {
                return url
            }
            if let inner = dict["data"] as? [String: Any],
               let url = inner["url"] as? String, !url.isEmpty {
                return url
            }
        }
        return nil
    }
}
