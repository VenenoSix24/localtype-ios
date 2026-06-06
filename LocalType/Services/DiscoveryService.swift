import Foundation
import Network

nonisolated final class DiscoveryService: @unchecked Sendable {
    private var connections: [NWConnection] = []
    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "discovery", qos: .userInitiated)

    var onDeviceFound: (@MainActor @Sendable (DiscoveredDevice) -> Void)?
    var onScanComplete: (@MainActor @Sendable () -> Void)?

    func startScanning() {
        stopScanning()
        var scanCount = 0
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: .seconds(1))
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            self.sendDiscovery()
            scanCount += 1
            if scanCount >= 3 {
                self.timer?.cancel()
                self.timer = nil
                self.queue.asyncAfter(deadline: .now() + 2) { [weak self] in
                    self?.cleanup()
                    DispatchQueue.main.async { [weak self] in
                        self?.onScanComplete?()
                    }
                }
            }
        }
        self.timer = timer
        timer.resume()
    }

    func stopScanning() {
        timer?.cancel()
        timer = nil
        cleanup()
    }

    private func cleanup() {
        for conn in connections { conn.cancel() }
        connections.removeAll()
    }

    // MARK: - Discovery

    private func sendDiscovery() {
        let message = "localtype_discovery".data(using: .utf8)!

        // Subnet broadcast only (no global 255.255.255.255 — requires multicast entitlement)
        for ip in localIPv4Addresses() {
            let parts = ip.split(separator: ".")
            guard parts.count == 4 else { continue }
            let broadcast = "\(parts[0]).\(parts[1]).\(parts[2]).255"
            sendAndListen(message, to: broadcast)
        }
    }

    private func sendAndListen(_ data: Data, to host: String) {
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: 45678)
        let params = NWParameters.udp
        params.allowLocalEndpointReuse = true

        let conn = NWConnection(to: endpoint, using: params)
        connections.append(conn)

        conn.stateUpdateHandler = { [weak self] state in
            if case .ready = state {
                conn.send(content: data, completion: .contentProcessed { [weak self] error in
                    if error == nil {
                        self?.receiveResponse(conn)
                    }
                })
            }
        }

        conn.start(queue: queue)
    }

    private func receiveResponse(_ conn: NWConnection) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, _ in
            guard let data,
                  let str = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  str.hasPrefix("localtype_server:"),
                  let self else {
                conn.cancel()
                return
            }

            let content = String(str.dropFirst("localtype_server:".count))
            let parts = content.split(separator: "|").map(String.init)
            guard !parts.isEmpty else {
                conn.cancel()
                return
            }

            let device = DiscoveredDevice(
                id: parts.count > 3 ? parts[3] : String(parts[0]),
                name: parts.count > 1 ? String(parts[1]) : "LocalType Server",
                ip: String(parts[0]),
                os: parts.count > 2 ? String(parts[2]) : "desktop",
                discoveredAt: .now
            )

            DispatchQueue.main.async { [weak self] in
                self?.onDeviceFound?(device)
            }

            self.receiveResponse(conn)
        }
    }

    // MARK: - Local IP

    private func localIPv4Addresses() -> [String] {
        var addresses: [String] = []
        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrPtr) == 0, let firstAddr = ifaddrPtr else { return addresses }
        defer { freeifaddrs(firstAddr) }

        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let addr = ptr?.pointee {
            guard let sockAddr = addr.ifa_addr else {
                ptr = addr.ifa_next
                continue
            }
            if sockAddr.pointee.sa_family == UInt8(AF_INET) {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(sockAddr, socklen_t(sockAddr.pointee.sa_len),
                            &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
                let nullIdx = hostname.firstIndex(of: 0) ?? hostname.count
                let ip = String(decoding: hostname[..<nullIdx].map { UInt8(bitPattern: $0) }, as: UTF8.self)
                if !ip.hasPrefix("127.") {
                    addresses.append(ip)
                }
            }
            ptr = addr.ifa_next
        }
        return addresses
    }
}
