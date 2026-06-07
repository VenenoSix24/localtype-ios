import Foundation

final class WebSocketService: NSObject, @unchecked Sendable, URLSessionDelegate, URLSessionWebSocketDelegate {
    private var session: URLSession?
    private var task: URLSessionWebSocketTask?
    private var heartbeatTimer: DispatchSourceTimer?
    private var reconnectTimer: DispatchSourceTimer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private var isDisconnecting = false

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
        isDisconnecting = false
        lastConnectedIP = ip
        reconnectAttempts = 0
        doConnect(ip: ip)
    }

    func disconnect(sendClose: Bool = true) {
        isDisconnecting = true
        stopReconnect()
        stopHeartbeat()
        if sendClose, let task {
            // Send WebSocket close frame so server knows we're disconnecting
            task.send(.string("{\"type\":\"close\"}")) { _ in }
            task.cancel(with: .goingAway, reason: nil)
        }
        task = nil
        lastConnectedIP = nil
        reconnectAttempts = 0
    }

    func send(_ message: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let str = String(data: data, encoding: .utf8) else { return }
        task?.send(.string(str)) { [weak self] error in
            if let error {
                Task { @MainActor [weak self] in
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
        guard !isDisconnecting else { return }
        guard let url = URL(string: "wss://\(ip):8765") else { return }
        let newTask = session?.webSocketTask(with: url)
        self.task = newTask
        newTask?.resume()
        receiveLoop()
    }

    private func receiveLoop() {
        guard let currentTask = task, !isDisconnecting else { return }
        currentTask.receive { [weak self] result in
            // receive() callback may fire on URLSession's internal queue, NOT on delegateQueue.
            // Dispatch ALL state access to MainActor.
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard self.task === currentTask, !self.isDisconnecting else { return }
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
                    self.onDisconnected?()
                    self.tryReconnect()
                }
            }
        }
    }

    private func handleText(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        Task { @MainActor [weak self] in
            self?.onMessage?(json)
        }
    }

    // MARK: - Heartbeat

    func startHeartbeat() {
        stopHeartbeat()
        let timer = DispatchSource.makeTimerSource(queue: .main)
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
        guard !isDisconnecting,
              reconnectAttempts < maxReconnectAttempts,
              let ip = lastConnectedIP else {
            stopReconnect()
            return
        }
        reconnectAttempts += 1
        stopReconnect()
        let timer = DispatchSource.makeTimerSource(queue: .main)
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
        Task { @MainActor [weak self] in
            guard let self, !self.isDisconnecting else { return }
            self.stopReconnect()
            self.reconnectAttempts = 0
            self.startHeartbeat()
            self.onConnected?()
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
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
