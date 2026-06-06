import SwiftUI
import Network

struct ConnectionView: View {
    @Environment(AppState.self) private var appState
    @State private var showingManualConnect = false
    @State private var lastOctet = ""
    @State private var fullIP = ""
    @State private var useFullIP = false
    @State private var detectedSubnet: String?
    @State private var cardsAppeared = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 16) {
                    statusCard

                    // Paired devices
                    if !appState.pairedDevices.isEmpty {
                        sectionHeader("已配对设备")
                        ForEach(Array(appState.pairedDevices.enumerated()), id: \.element.id) { index, device in
                            DeviceCard(
                                device: device,
                                isConnected: appState.connectionStatus == .connected && appState.remoteServerId == device.id,
                                isPaired: true,
                                onTap: { appState.connect(to: device.ip) },
                                onRemove: { appState.removePairedDevice(id: device.id) }
                            )
                            .opacity(cardsAppeared ? 1 : 0)
                            .offset(y: cardsAppeared ? 0 : 20)
                            .animation(
                                .spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.08),
                                value: cardsAppeared
                            )
                        }
                    }

                    // Connect section
                    sectionHeader("连接电脑")

                    // Quick connect (subnet)
                    if let subnet = detectedSubnet {
                        Button {
                            useFullIP = false
                            showingManualConnect = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "bolt.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(appState.accentColor.color)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("快速连接")
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.primary)
                                    Text("输入 \(subnet)X 的最后一位数字")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                        .monospaced()
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.secondary.opacity(0.4))
                            }
                            .padding(14)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .glassEffect(.regular, in: .rect(cornerRadius: 20))
                    }

                    // Full IP connect
                    Button {
                        useFullIP = true
                        showingManualConnect = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(appState.accentColor.color)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("输入完整 IP")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.primary)
                                Text("输入电脑端完整 IP 地址")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.secondary.opacity(0.4))
                        }
                        .padding(14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular, in: .rect(cornerRadius: 20))

                    // Help tip
                    if appState.pairedDevices.isEmpty && appState.connectionStatus == .disconnected {
                        VStack(spacing: 8) {
                            Image(systemName: "lightbulb")
                                .font(.title3)
                                .foregroundStyle(.yellow)
                            Text("在电脑端打开 LocalType 服务，\n输入 IP 地址即可连接")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .navigationTitle("连接")
            .onAppear {
                detectSubnet()
                withAnimation {
                    cardsAppeared = true
                }
            }

            // Pairing overlay
            if appState.showingPairingSheet {
                pairingOverlay
            }
        }
        .alert("连接电脑", isPresented: $showingManualConnect) {
            if useFullIP || detectedSubnet == nil {
                TextField("IP 地址", text: $fullIP)
                    .keyboardType(.decimalPad)
                    .monospaced()
            } else if detectedSubnet != nil {
                TextField("最后一位数字", text: $lastOctet)
                    .keyboardType(.numberPad)
                    .monospaced()
            }

            Button("取消", role: .cancel) {
                lastOctet = ""
                fullIP = ""
            }

            Button("连接") {
                let ip: String
                if useFullIP || detectedSubnet == nil {
                    ip = fullIP
                } else {
                    ip = (detectedSubnet ?? "") + lastOctet
                }
                appState.connect(to: ip)
                lastOctet = ""
                fullIP = ""
            }
            .disabled(connectDisabled)
        } message: {
            if useFullIP || detectedSubnet == nil {
                Text("输入电脑端的完整 IP 地址")
            } else if detectedSubnet != nil {
                Text("输入最后一位数字即可连接")
            }
        }
    }

    // MARK: - Subnet Detection

    private func detectSubnet() {
        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrPtr) == 0, let firstAddr = ifaddrPtr else { return }
        defer { freeifaddrs(firstAddr) }

        var candidates: [(name: String, ip: String, subnet: String)] = []
        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let addr = ptr?.pointee {
            guard let sockAddr = addr.ifa_addr else {
                ptr = addr.ifa_next
                continue
            }
            if sockAddr.pointee.sa_family == UInt8(AF_INET) {
                let flags = addr.ifa_flags
                let isUp = flags & UInt32(IFF_UP) != 0
                let isLoopback = flags & UInt32(IFF_LOOPBACK) != 0
                if isUp && !isLoopback {
                    let name = String(cString: addr.ifa_name)
                    let skipPrefixes = ["pdp_ip", "bridge", "awdl", "llw", "utun", "ipsec", "gif", "stf"]
                    if skipPrefixes.contains(where: { name.hasPrefix($0) }) {
                        ptr = addr.ifa_next
                        continue
                    }

                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(sockAddr, socklen_t(sockAddr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
                    let nullIdx = hostname.firstIndex(of: 0) ?? hostname.count
                    let ip = String(decoding: hostname[..<nullIdx].map { UInt8(bitPattern: $0) }, as: UTF8.self)
                    if !ip.isEmpty {
                        let parts = ip.split(separator: ".")
                        if parts.count == 4 {
                            let subnet = "\(parts[0]).\(parts[1]).\(parts[2])."
                            candidates.append((name: name, ip: ip, subnet: subnet))
                        }
                    }
                }
            }
            ptr = addr.ifa_next
        }

        if let wifi = candidates.first(where: { $0.name == "en0" }) {
            detectedSubnet = wifi.subnet
        } else if let en = candidates.first(where: { $0.name.hasPrefix("en") }) {
            detectedSubnet = en.subnet
        } else if let best = candidates.first {
            detectedSubnet = best.subnet
        }
    }

    // MARK: - Connect Button

    private var connectDisabled: Bool {
        if useFullIP || detectedSubnet == nil {
            return fullIP.trimmingCharacters(in: .whitespaces).isEmpty
        }
        return lastOctet.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Pairing Overlay

    private var pairingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    appState.disconnect()
                }

            PairingSheet()
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.9)),
            removal: .opacity.combined(with: .scale(scale: 0.95))
        ))
        .zIndex(1)
    }

    // MARK: - Status Card

    private var statusCard: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Circle()
                        .fill(statusColor)
                        .frame(width: 10, height: 10)
                        .shadow(color: statusColor.opacity(0.5), radius: 4)
                        .animation(.easeInOut(duration: 0.4), value: appState.connectionStatus)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(statusText)
                        .font(.headline)
                        .contentTransition(.numericText())

                    switch appState.connectionStatus {
                    case .connected:
                        Text("\(appState.remoteServerName) · \(appState.remoteServerIP)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospaced()
                    case .disconnected:
                        Text("选择设备或输入 IP 连接")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    case .connecting:
                        Text("正在连接 \(appState.remoteServerIP)...")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    case .error:
                        Text("连接超时或失败")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: appState.connectionStatus)

                Spacer()

                switch appState.connectionStatus {
                case .connected:
                    Button {
                        appState.disconnect()
                    } label: {
                        Text("断开")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Color(.tertiarySystemFill), in: .capsule)
                            .foregroundStyle(.red)
                    }
                    .transition(.scale.combined(with: .opacity))
                case .connecting:
                    Button {
                        appState.cancelConnect()
                    } label: {
                        Text("取消")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Color(.tertiarySystemFill), in: .capsule)
                            .foregroundStyle(.primary)
                    }
                    .transition(.scale.combined(with: .opacity))
                default:
                    EmptyView()
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: appState.connectionStatus)
        }
    }

    private var statusColor: Color {
        switch appState.connectionStatus {
        case .connected: return .green
        case .connecting: return .orange
        case .error: return .red
        case .disconnected: return .gray
        }
    }

    private var statusText: String {
        switch appState.connectionStatus {
        case .connected: return "已连接"
        case .connecting: return "连接中"
        case .error: return "连接失败"
        case .disconnected: return "未连接"
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.top, 4)
    }
}
