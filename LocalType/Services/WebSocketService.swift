import Foundation

final class WebSocketService: NSObject, @unchecked Sendable, URLSessionDelegate, URLSessionWebSocketDelegate {
    private var session: URLSession?
    private var task: URLSessionWebSocketTask?
    private var heartbeatTimer: DispatchSourceTimer?
    private var reconnectTimer: DispatchSourceTimer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private let queue = DispatchQueue(label: "websocket", qos: .userInitiated)

    var onMessage: (@MainActor @Sendable ([String: Any]) -> Void)?
    var onConnected: (@MainActor @Sendable () -> Void)?
    var onDisconnected: (@MainActor @Sendable () -> Void)?
    var onError: (@MainActor @Sendable (String) -> Void)?

    private var lastConnectedIP: String?

    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    // MARK: - Public API

    func connect(to ip: String) {
        lastConnectedIP = ip
        reconnectAttempts = 0
        doConnect(ip: ip)
    }

    func disconnect() {
        stopReconnect()
        stopHeartbeat()
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
        lastConnectedIP = nil
        reconnectAttempts = 0
    }

    func send(_ message: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let str = String(data: data, encoding: .utf8) else { return }
        task?.send(.string(str)) { [weak self] error in
            if let error {
                DispatchQueue.main.async {
                    self?.onError?("发送失败: \(error.localizedDescription)")
                }
            }
        }
    }

    var isConnected: Bool {
        task != nil
    }

    // MARK: - Private

    private func doConnect(ip: String) {
        guard let url = URL(string: "wss://\(ip):8765") else { return }
        let task = session?.webSocketTask(with: url)
        self.task = task
        task?.resume()
        receiveLoop()
    }

    private func receiveLoop() {
        task?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleText(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleText(text)
                    }
                @unknown default:
                    break
                }
                self.receiveLoop()
            case .failure:
                DispatchQueue.main.async {
                    self.onDisconnected?()
                }
                self.tryReconnect()
            }
        }
    }

    private func handleText(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        DispatchQueue.main.async {
            self.onMessage?(json)
        }
    }

    // MARK: - Heartbeat

    func startHeartbeat() {
        stopHeartbeat()
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + 25, repeating: 25)
        timer.setEventHandler { [weak self] in
            self?.send(["type": "ping"])
        }
        self.heartbeatTimer = timer
        timer.resume()
    }

    private func stopHeartbeat() {
        heartbeatTimer?.cancel()
        heartbeatTimer = nil
    }

    // MARK: - Reconnect

    private func tryReconnect() {
        guard reconnectAttempts < maxReconnectAttempts, let ip = lastConnectedIP else {
            stopReconnect()
            return
        }
        reconnectAttempts += 1
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + 2)
        timer.setEventHandler { [weak self] in
            self?.doConnect(ip: ip)
        }
        self.reconnectTimer = timer
        timer.resume()
    }

    private func stopReconnect() {
        reconnectTimer?.cancel()
        reconnectTimer = nil
    }

    // MARK: - URLSessionWebSocketDelegate

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) {
        stopReconnect()
        reconnectAttempts = 0
        startHeartbeat()
        DispatchQueue.main.async {
            self.onConnected?()
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Accept self-signed certificates for local network connections
        if let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    // MARK: - Convenience: build protocol messages

    static func authMessage(deviceId: String, token: String) -> [String: Any] {
        ["type": "auth", "device_id": deviceId, "token": token, "os": "ios"]
    }

    static func requestPairingMessage(deviceName: String, deviceId: String) -> [String: Any] {
        ["type": "requestpairing", "device_name": deviceName, "device_id": deviceId, "os": "ios"]
    }

    static func verifyPairingMessage(deviceId: String, deviceName: String, code: String) -> [String: Any] {
        ["type": "verifypairing", "device_id": deviceId, "device_name": deviceName, "code": code, "os": "ios"]
    }

    static func sendMessage(content: String, method: String, msgId: String) -> [String: Any] {
        ["type": "send", "content": content, "method": method, "msg_id": msgId]
    }

    static func unpairMessage() -> [String: Any] {
        ["type": "unpair"]
    }
}
