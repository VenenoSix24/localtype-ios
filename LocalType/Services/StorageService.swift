import Foundation
import UIKit

final class StorageService: @unchecked Sendable {
    static let shared = StorageService()
    private let defaults = UserDefaults.standard

    private init() {}

    // MARK: - Device Identity

    var deviceId: String {
        if let saved = defaults.string(forKey: "device_id") { return saved }
        let id = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        defaults.set(id, forKey: "device_id")
        return id
    }

    var deviceName: String {
        get { defaults.string(forKey: "device_name") ?? UIDevice.current.name }
        set { defaults.set(newValue, forKey: "device_name") }
    }

    // MARK: - Paired Devices

    func loadPairedDevices() -> [DiscoveredDevice] {
        guard let data = defaults.data(forKey: "paired_devices") else { return [] }
        return (try? JSONDecoder().decode([DiscoveredDevice].self, from: data)) ?? []
    }

    func savePairedDevices(_ devices: [DiscoveredDevice]) {
        if let data = try? JSONEncoder().encode(devices) {
            defaults.set(data, forKey: "paired_devices")
        }
    }

    // MARK: - Auth Tokens

    func loadTokens() -> [String: String] {
        guard let data = defaults.data(forKey: "auth_tokens") else { return [:] }
        return (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
    }

    func saveTokens(_ tokens: [String: String]) {
        if let data = try? JSONEncoder().encode(tokens) {
            defaults.set(data, forKey: "auth_tokens")
        }
    }

    // MARK: - Quick Phrases

    func loadQuickPhrases() -> [QuickPhrase] {
        guard let data = defaults.data(forKey: "quick_phrases") else { return [] }
        return (try? JSONDecoder().decode([QuickPhrase].self, from: data)) ?? []
    }

    func saveQuickPhrases(_ phrases: [QuickPhrase]) {
        if let data = try? JSONEncoder().encode(phrases) {
            defaults.set(data, forKey: "quick_phrases")
        }
    }

    // MARK: - Statistics

    var totalChars: Int {
        get { defaults.integer(forKey: "total_chars") }
        set { defaults.set(newValue, forKey: "total_chars") }
    }

    var todayChars: Int {
        get { defaults.integer(forKey: "today_chars") }
        set { defaults.set(newValue, forKey: "today_chars") }
    }

    var todayDate: String {
        get { defaults.string(forKey: "today_date") ?? "" }
        set { defaults.set(newValue, forKey: "today_date") }
    }

    // MARK: - Injection Method

    var injectionMethod: String {
        get { defaults.string(forKey: "injection_method") ?? "unicode" }
        set { defaults.set(newValue, forKey: "injection_method") }
    }

    // MARK: - Update Skip

    var skippedVersion: String? {
        get { defaults.string(forKey: "skipped_update_version") }
        set { defaults.set(newValue, forKey: "skipped_update_version") }
    }

    // MARK: - Appearance

    var colorScheme: String {
        get { defaults.string(forKey: "color_scheme") ?? "system" }
        set { defaults.set(newValue, forKey: "color_scheme") }
    }
}
