import Foundation
import UIKit

enum ConnectionStatus: String {
    case disconnected, connecting, connected, error
}

enum AuthStatus: String {
    case unauthenticated, pairingRequired, authenticated
}

@Observable
@MainActor
final class AppState {
    // MARK: - Connection
    var connectionStatus: ConnectionStatus = .disconnected
    var authStatus: AuthStatus = .unauthenticated
    var remoteServerName: String = ""
    var remoteServerIP: String = ""
    var remoteServerId: String = ""
    var remoteServerOS: String = ""

    // MARK: - Devices
    var discoveredDevices: [DiscoveredDevice] = []
    var pairedDevices: [DiscoveredDevice] = []
    var isScanning: Bool = false

    // MARK: - Messages
    var messages: [Message] = []
    var inputText: String = ""

    // MARK: - Quick Phrases
    var quickPhrases: [QuickPhrase] = []

    // MARK: - Statistics
    var totalChars: Int = 0
    var todayChars: Int = 0
    private var todayDate: String = ""
    var streakDays: Int = 0
    private var lastInputDate: String = ""
    var isProbing: Bool = false

    // MARK: - Achievements
    var showingAchievement: Bool = false
    var newAchievement: Milestone?

    // MARK: - Device Identity
    let deviceId: String
    var deviceName: String {
        didSet { storage.deviceName = deviceName }
    }

    // MARK: - Injection
    var injectionMethod: String = "unicode" {
        didSet { storage.injectionMethod = injectionMethod }
    }

    // MARK: - Update
    var currentVersion: String = ""
    var updateInfo: UpdateInfo?
    var isCheckingUpdate: Bool = false

    // MARK: - Appearance
    var colorScheme: String = "system" {
        didSet { storage.colorScheme = colorScheme }
    }
    var accentColor: ThemeColor = .blue {
        didSet { storage.accentColor = accentColor.rawValue }
    }
    var bubbleStyle: BubbleStyle = .liquidGlass {
        didSet { storage.bubbleStyle = bubbleStyle.rawValue }
    }
    var autoJumpToInput: Bool = false {
        didSet { storage.autoJumpToInput = autoJumpToInput }
    }

    var hapticEnabled: Bool = true {
        didSet { storage.hapticEnabled = hapticEnabled }
    }

    // MARK: - Pairing
    var showingPairingSheet: Bool = false

    // MARK: - Navigation
    var selectedTab: Int = 0

    // MARK: - Private
    private let storage = StorageService.shared
    private let discovery = DiscoveryService()
    private let ws = WebSocketService()
    private var lastConnectedIP: String?
    private var connectTimer: DispatchSourceTimer?
    private var triedServerId: String?  // serverId whose token was used for auth

    init() {
        deviceId = storage.deviceId
        deviceName = storage.deviceName
        loadState()
        setupWebSocket()
        setupDiscovery()
        checkToday()
    }

    // MARK: - State Loading

    private func loadState() {
        pairedDevices = storage.loadPairedDevices()
        // Default to offline until probed
        for idx in pairedDevices.indices {
            pairedDevices[idx].isOnline = false
        }
        quickPhrases = storage.loadQuickPhrases()
        totalChars = storage.totalChars
        todayChars = storage.todayChars
        todayDate = storage.todayDate
        streakDays = storage.streakDays
        lastInputDate = storage.lastInputDate
        injectionMethod = storage.injectionMethod
        colorScheme = storage.colorScheme
        accentColor = ThemeColor(rawValue: storage.accentColor) ?? .blue
        bubbleStyle = BubbleStyle(rawValue: storage.bubbleStyle) ?? .liquidGlass
        autoJumpToInput = storage.autoJumpToInput
        hapticEnabled = storage.hapticEnabled
        currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    // MARK: - Discovery

    private func setupDiscovery() {
        discovery.onDeviceFound = { [weak self] device in
            guard let self else { return }
            if let idx = self.discoveredDevices.firstIndex(where: { $0.id == device.id }) {
                self.discoveredDevices[idx] = device
            } else {
                self.discoveredDevices.append(device)
            }
            if let pIdx = self.pairedDevices.firstIndex(where: { $0.id == device.id }) {
                self.pairedDevices[pIdx].ip = device.ip
                self.pairedDevices[pIdx].name = device.name
                self.pairedDevices[pIdx].os = device.os
                self.pairedDevices[pIdx].isOnline = true
            }
        }
        discovery.onScanComplete = { [weak self] in
            self?.isScanning = false
        }
    }

    func startScanning() {
        isScanning = true
        discoveredDevices.removeAll()
        discovery.startScanning()
    }

    func stopScanning() {
        discovery.stopScanning()
        isScanning = false
    }

    // MARK: - Device Probe (TCP reachability check)

    func probeAllDevices() {
        guard !isProbing else { return }
        isProbing = true
        let startTime = Date()
        let group = DispatchGroup()
        for device in pairedDevices {
            group.enter()
            probeDevice(ip: device.ip) { online in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if let idx = self.pairedDevices.firstIndex(where: { $0.id == device.id }) {
                        self.pairedDevices[idx].isOnline = online
                    }
                    group.leave()
                }
            }
        }
        group.notify(queue: .main) { [weak self] in
            self?.storage.savePairedDevices(self?.pairedDevices ?? [])
            let elapsed = Date().timeIntervalSince(startTime)
            let remaining = max(0, 3.0 - elapsed)
            DispatchQueue.main.asyncAfter(deadline: .now() + remaining) {
                self?.isProbing = false
            }
        }
    }

    private func probeDevice(ip: String, completion: @escaping @Sendable (Bool) -> Void) {
        guard let url = URL(string: "https://\(ip):8765") else {
            completion(false)
            return
        }
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 2
        let session = URLSession(configuration: config, delegate: InsecureDelegate(), delegateQueue: nil)
        let task = session.dataTask(with: url) { _, _, error in
            // Any response (even error) means the port is open
            completion(error == nil || (error as? URLError)?.code != .cannotConnectToHost)
        }
        task.resume()
    }

    // Allow self-signed certificates for probe
    private class InsecureDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
        func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            if let trust = challenge.protectionSpace.serverTrust {
                completionHandler(.useCredential, URLCredential(trust: trust))
            } else {
                completionHandler(.performDefaultHandling, nil)
            }
        }
    }

    // MARK: - WebSocket

    private func setupWebSocket() {
        ws.onConnected = { [weak self] in
            guard let self else { return }
            self.connectionStatus = .connected
            let cleanName: String
            if let range = self.remoteServerName.range(of: " (") {
                cleanName = String(self.remoteServerName[..<range.lowerBound])
            } else if let range = self.remoteServerName.range(of: "(") {
                cleanName = String(self.remoteServerName[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
            } else {
                cleanName = self.remoteServerName
            }
            self.addSystemMessage("已连接到 \(cleanName)")
            let tokens = self.storage.loadTokens()
            // Find token: by serverId → by IP → by any paired device (IP may have changed)
            let token: String?
            var matchedServerId: String? = nil
            if !self.remoteServerId.isEmpty {
                token = tokens[self.remoteServerId]
            } else if let t = tokens[self.remoteServerIP] {
                token = t
            } else {
                // IP changed — try paired devices with serverId-based tokens
                let match = self.pairedDevices
                    .filter { !$0.id.isEmpty && $0.id != $0.ip }
                    .first { tokens[$0.id] != nil }
                token = match.flatMap { tokens[$0.id] }
                matchedServerId = match?.id
            }
            self.triedServerId = matchedServerId
            if let token {
                self.ws.send(WebSocketService.authMessage(deviceId: self.deviceId, token: token))
            } else {
                self.ws.send(WebSocketService.requestPairingMessage(deviceName: self.deviceName, deviceId: self.deviceId))
            }
        }

        ws.onDisconnected = { [weak self] in
            guard let self else { return }
            if self.connectionStatus != .disconnected {
                self.connectionStatus = .disconnected
                self.authStatus = .unauthenticated
                self.addSystemMessage("已断开连接")
            }
        }

        ws.onMessage = { [weak self] json in
            self?.handleMessage(json)
        }

        ws.onError = { [weak self] _ in
            self?.connectionStatus = .error
            // Mark device as offline
            if let self, let idx = self.pairedDevices.firstIndex(where: { $0.ip == self.remoteServerIP }) {
                self.pairedDevices[idx].isOnline = false
            }
        }
    }

    // MARK: - Connection

    func connect(to ip: String) {
        // Fully clean up any existing connection attempt
        connectTimer?.cancel()
        connectTimer = nil
        ws.disconnect()

        if let d = discoveredDevices.first(where: { $0.ip == ip }) {
            // Found via discovery — has serverId
            remoteServerName = d.name
            remoteServerId = d.id
            remoteServerOS = d.os ?? ""
        } else if let d = pairedDevices.first(where: { $0.ip == ip }) {
            // Found in paired list by IP
            remoteServerName = d.name
            remoteServerId = d.id
            remoteServerOS = d.os ?? ""
        } else {
            // New IP — serverId unknown, will be set after auth
            remoteServerName = "桌面端"
            remoteServerId = ""
        }

        remoteServerIP = ip
        lastConnectedIP = ip
        connectionStatus = .connecting
        authStatus = .unauthenticated
        ws.connect(to: ip)

        // 5 second timeout
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 5)
        timer.setEventHandler { [weak self] in
            guard let self, self.connectionStatus == .connecting else { return }
            self.connectionStatus = .error
            self.ws.disconnect()
            // Mark device as offline
            if let idx = self.pairedDevices.firstIndex(where: { $0.ip == ip }) {
                self.pairedDevices[idx].isOnline = false
            }
            self.addSystemMessage("连接失败，请检查电脑端是否在线或 IP 地址是否正确")
            HapticManager.error()
        }
        self.connectTimer = timer
        timer.resume()
    }

    func cancelConnect() {
        connectTimer?.cancel()
        connectTimer = nil
        ws.disconnect(sendClose: false)  // Connection not fully established, no close frame needed
        if connectionStatus == .connecting {
            connectionStatus = .disconnected
            authStatus = .unauthenticated
        }
        showingPairingSheet = false
    }

    func disconnect() {
        connectTimer?.cancel()
        connectTimer = nil
        ws.disconnect()
        if connectionStatus == .connected {
            HapticManager.warning()
        }
        connectionStatus = .disconnected
        authStatus = .unauthenticated
        lastConnectedIP = nil
        remoteServerName = ""
        triedServerId = nil
        showingPairingSheet = false
    }

    // MARK: - Message Handling

    private func handleMessage(_ json: [String: Any]) {
        let type = json["type"] as? String ?? ""

        switch type {
        case "pong":
            break

        case "pairingcoderequired":
            authStatus = .pairingRequired
            showingPairingSheet = true

        case "pairingsuccess":
            connectTimer?.cancel()
            connectTimer = nil
            // Recover serverId from the token we tried (IP may have changed)
            if remoteServerId.isEmpty, let tried = triedServerId {
                remoteServerId = tried
            }
            // Read server name from response
            if let name = json["name"] as? String, !name.isEmpty {
                remoteServerName = name
            }
            // Restore device name from paired devices if still generic
            if remoteServerName == "桌面端", !remoteServerId.isEmpty,
               let matched = pairedDevices.first(where: { $0.id == remoteServerId }) {
                remoteServerName = matched.name
            }
            if let token = json["token"] as? String {
                let key = remoteServerId.isEmpty ? remoteServerIP : remoteServerId
                var tokens = storage.loadTokens()
                tokens[key] = token
                storage.saveTokens(tokens)
            }
            if let os = json["os"] as? String { remoteServerOS = os }
            authStatus = .authenticated
            savePairedDevice()
            // Mark connected device as online
            if let idx = pairedDevices.firstIndex(where: { $0.id == remoteServerId || $0.ip == remoteServerIP }) {
                pairedDevices[idx].isOnline = true
            }
            triedServerId = nil
            HapticManager.success()
            if autoJumpToInput { selectedTab = 1 }

        case "authsuccess":
            connectTimer?.cancel()
            connectTimer = nil
            // Recover serverId from the token we tried (IP may have changed)
            if remoteServerId.isEmpty, let tried = triedServerId {
                remoteServerId = tried
            }
            // Read server name from response
            if let name = json["name"] as? String, !name.isEmpty {
                remoteServerName = name
            }
            // Restore device name from paired devices if still generic
            if remoteServerName == "桌面端", !remoteServerId.isEmpty,
               let matched = pairedDevices.first(where: { $0.id == remoteServerId }) {
                remoteServerName = matched.name
            }
            if let os = json["os"] as? String { remoteServerOS = os }
            authStatus = .authenticated
            savePairedDevice()
            // Mark connected device as online
            if let idx = pairedDevices.firstIndex(where: { $0.id == remoteServerId || $0.ip == remoteServerIP }) {
                pairedDevices[idx].isOnline = true
            }
            triedServerId = nil
            HapticManager.success()
            if autoJumpToInput { selectedTab = 1 }

        case "authfailed":
            authStatus = .unauthenticated
            let key = remoteServerId.isEmpty ? remoteServerIP : remoteServerId
            var tokens = storage.loadTokens()
            tokens.removeValue(forKey: key)
            storage.saveTokens(tokens)
            HapticManager.error()
            disconnect()

        case "unpaired":
            let key = remoteServerId.isEmpty ? remoteServerIP : remoteServerId
            pairedDevices.removeAll(where: { $0.id == key })
            storage.savePairedDevices(pairedDevices)
            var tokens = storage.loadTokens()
            tokens.removeValue(forKey: key)
            storage.saveTokens(tokens)
            disconnect()

        case "ack":
            if let msgId = json["msg_id"] as? String,
               let idx = messages.firstIndex(where: { $0.id == msgId }) {
                messages[idx].status = .acked
            }

        default:
            break
        }
    }

    // MARK: - Pairing

    func submitPairingCode(_ code: String) {
        ws.send(WebSocketService.verifyPairingMessage(
            deviceId: deviceId, deviceName: deviceName, code: code))
        showingPairingSheet = false
        HapticManager.impact(.medium)
    }

    // MARK: - Paired Devices

    private func savePairedDevice() {
        guard !remoteServerIP.isEmpty else { return }
        let deviceId = remoteServerId.isEmpty ? remoteServerIP : remoteServerId
        let cleanName: String
        if let range = remoteServerName.range(of: " (") {
            cleanName = String(remoteServerName[..<range.lowerBound])
        } else if let range = remoteServerName.range(of: "(") {
            cleanName = String(remoteServerName[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
        } else {
            cleanName = remoteServerName
        }
        let device = DiscoveredDevice(
            id: deviceId,
            name: cleanName,
            ip: remoteServerIP,
            os: remoteServerOS,
            discoveredAt: .now
        )

        // Match by serverId first (stable identity), then by IP, then by name
        let idx: Int?
        if !remoteServerId.isEmpty {
            idx = pairedDevices.firstIndex(where: { $0.id == remoteServerId })
        } else {
            idx = pairedDevices.firstIndex(where: { $0.ip == remoteServerIP })
                ?? pairedDevices.firstIndex(where: { $0.name == cleanName && !cleanName.isEmpty })
        }

        if let idx {
            // Update existing device (IP may have changed)
            pairedDevices[idx] = device
        } else {
            pairedDevices.insert(device, at: 0)
        }
        storage.savePairedDevices(pairedDevices)
    }

    func toggleFavorite(_ device: DiscoveredDevice) {
        if let idx = pairedDevices.firstIndex(where: { $0.id == device.id }) {
            pairedDevices.remove(at: idx)
        } else {
            pairedDevices.append(device)
        }
        storage.savePairedDevices(pairedDevices)
    }

    func isPaired(_ device: DiscoveredDevice) -> Bool {
        pairedDevices.contains(where: { $0.id == device.id })
    }

    func removePairedDevice(id: String) {
        if connectionStatus == .connected && (remoteServerId == id || remoteServerIP == id) {
            ws.send(WebSocketService.unpairMessage())
            disconnect()
        }
        pairedDevices.removeAll(where: { $0.id == id })
        storage.savePairedDevices(pairedDevices)
        var tokens = storage.loadTokens()
        tokens.removeValue(forKey: id)
        storage.saveTokens(tokens)
    }

    // MARK: - Sending Text

    func sendText() {
        guard connectionStatus == .connected, authStatus == .authenticated else { return }
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let msgId = "\(Int(Date().timeIntervalSince1970 * 1000))"
        let message = Message(id: msgId, text: text, status: .sending)
        messages.append(message)

        ws.send(WebSocketService.sendMessage(content: text, method: injectionMethod, msgId: msgId))
        if let idx = messages.firstIndex(where: { $0.id == msgId }) {
            messages[idx].status = .sent
        }

        inputText = ""
        HapticManager.success()
        addCharCount(text.count)
    }

    // MARK: - Statistics

    private func checkToday() {
        let key = Self.todayKey()
        if todayDate != key {
            todayDate = key
            todayChars = 0
            storage.todayDate = key
            storage.todayChars = 0
        }
    }

    private func addCharCount(_ count: Int) {
        let previousLevel = currentMilestone
        checkToday()
        updateStreak()
        totalChars += count
        todayChars += count
        storage.totalChars = totalChars
        storage.todayChars = todayChars

        // Check for milestone unlock
        let newLevel = currentMilestone
        if newLevel.threshold > previousLevel.threshold {
            newAchievement = newLevel
            showingAchievement = true
            HapticManager.celebrate()
        }
    }

    var currentMilestone: Milestone {
        Milestone.allCases.last { totalChars >= $0.threshold } ?? .newbie
    }

    var nextMilestone: Milestone? {
        Milestone.allCases.first { totalChars < $0.threshold }
    }

    var milestoneProgress: Double {
        guard let next = nextMilestone else { return 1.0 }
        let current = currentMilestone
        if current == next { return 0 }
        let range = Double(next.threshold - current.threshold)
        let progress = Double(totalChars - current.threshold) / range
        return min(max(progress, 0), 1.0)
    }

    private func updateStreak() {
        let today = Self.todayKey()
        if lastInputDate.isEmpty {
            // First time
            streakDays = 1
        } else if lastInputDate == today {
            // Already counted today
        } else {
            // Check if yesterday
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let lastDate = formatter.date(from: lastInputDate),
               let todayDate = formatter.date(from: today) {
                let days = Calendar.current.dateComponents([.day], from: lastDate, to: todayDate).day ?? 0
                if days == 1 {
                    streakDays += 1
                } else if days > 1 {
                    streakDays = 1
                }
            }
        }
        lastInputDate = today
        storage.streakDays = streakDays
        storage.lastInputDate = lastInputDate
    }

    private static func todayKey() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    // MARK: - System Messages

    private func addSystemMessage(_ text: String) {
        messages.append(Message(text: text, type: .system, status: .acked))
    }

    // MARK: - Update Check

    func checkForUpdate(silent: Bool = false) async {
        isCheckingUpdate = true
        do {
            let info = try await UpdateService.checkForUpdate()
            // Manual check: always show if update exists, ignore skip
            if !silent && info.skipped {
                updateInfo = UpdateInfo(
                    currentVersion: info.currentVersion,
                    latestVersion: info.latestVersion,
                    releaseNotes: info.releaseNotes,
                    downloadUrl: info.downloadUrl,
                    repoUrl: info.repoUrl,
                    available: true,
                    skipped: false
                )
            } else {
                updateInfo = info
            }
        } catch {
            if !silent { updateInfo = nil }
        }
        isCheckingUpdate = false
    }

    func skipCurrentUpdate() {
        guard let info = updateInfo else { return }
        UpdateService.skipVersion(info.latestVersion)
        updateInfo = nil
    }

    // MARK: - Quick Phrases

    func addQuickPhrase(label: String, content: String) {
        quickPhrases.append(QuickPhrase(label: label, content: content))
        storage.saveQuickPhrases(quickPhrases)
    }

    func removeQuickPhrase(id: String) {
        quickPhrases.removeAll(where: { $0.id == id })
        storage.saveQuickPhrases(quickPhrases)
    }

    func updateQuickPhrase(id: String, label: String, content: String) {
        if let idx = quickPhrases.firstIndex(where: { $0.id == id }) {
            quickPhrases[idx].label = label
            quickPhrases[idx].content = content
            storage.saveQuickPhrases(quickPhrases)
        }
    }

    // MARK: - Device Alias

    func renamePairedDevice(id: String, alias: String) {
        if let idx = pairedDevices.firstIndex(where: { $0.id == id }) {
            pairedDevices[idx].alias = alias.isEmpty ? nil : alias
            storage.savePairedDevices(pairedDevices)
        }
    }

    // MARK: - App Lifecycle

    func onAppResume() {
        if let ip = lastConnectedIP, connectionStatus == .disconnected {
            connect(to: ip)
        }
    }

    func onAppBackground() {
        // Disconnect cleanly so server knows we're gone
        if connectionStatus == .connected || connectionStatus == .connecting {
            connectTimer?.cancel()
            connectTimer = nil
            ws.disconnect()
            connectionStatus = .disconnected
            authStatus = .unauthenticated
            addSystemMessage("已断开连接（进入后台）")
        }
    }
}
