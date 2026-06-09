import Foundation

struct UpdateInfo: Sendable, Equatable {
    let currentVersion: String
    let latestVersion: String
    let releaseNotes: String
    let downloadUrl: String
    let repoUrl: String
    let available: Bool
    let skipped: Bool
}

enum UpdateService {
    private static let apiURL = URL(string: "https://api.github.com/repos/VenenoSix24/localtype-ios/releases/latest")!

    static func checkForUpdate() async throws -> UpdateInfo {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

        var request = URLRequest(url: apiURL)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let tagName = (json["tag_name"] as? String) ?? ""
        let latestVersion = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
        let releaseNotes = (json["body"] as? String) ?? ""
        let htmlUrl = (json["html_url"] as? String) ?? "https://github.com/VenenoSix24/localtype-ios/releases/latest"

        if compareVersions(latestVersion, currentVersion) <= 0 {
            return UpdateInfo(currentVersion: currentVersion, latestVersion: latestVersion,
                              releaseNotes: releaseNotes, downloadUrl: "", repoUrl: htmlUrl,
                              available: false, skipped: false)
        }

        let skipped = StorageService.shared.skippedVersion == latestVersion

        let assets = json["assets"] as? [[String: Any]] ?? []
        let downloadUrl = findDownloadUrl(assets) ?? htmlUrl

        return UpdateInfo(currentVersion: currentVersion, latestVersion: latestVersion,
                          releaseNotes: releaseNotes, downloadUrl: downloadUrl, repoUrl: htmlUrl,
                          available: true, skipped: skipped)
    }

    static func skipVersion(_ version: String) {
        StorageService.shared.skippedVersion = version
    }

    private static func findDownloadUrl(_ assets: [[String: Any]]) -> String? {
        if let ipa = assets.first(where: { ($0["name"] as? String ?? "").hasSuffix(".ipa") }) {
            return ipa["browser_download_url"] as? String
        }
        return nil
    }

    private static func compareVersions(_ a: String, _ b: String) -> Int {
        let aParts = a.split(separator: "-").first?.split(separator: ".").compactMap({ Int($0) }) ?? []
        let bParts = b.split(separator: "-").first?.split(separator: ".").compactMap({ Int($0) }) ?? []
        for i in 0..<3 {
            let av = i < aParts.count ? aParts[i] : 0
            let bv = i < bParts.count ? bParts[i] : 0
            if av != bv { return av - bv }
        }
        return 0
    }
}
