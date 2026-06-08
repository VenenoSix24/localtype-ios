import SwiftUI
import Network

struct ConnectionView: View {
    @Environment(AppState.self) private var appState
    @State private var showingManualConnect = false
    @State private var lastOctet = ""
    @State private var fullIP = ""
    @State private var useFullIP = false
    @State private var detectedSubnet: String?
    @State private var localIP: String?
    @State private var cardsAppeared = false
    @State private var showConnecting = false

    private var displayStatus: ConnectionStatus {
        if showConnecting { return .connecting }
        return appState.connectionStatus
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 16) {
                    connectionHeroCard
                    statusCard

                    // Paired devices
                    if !appState.pairedDevices.isEmpty {
                        sectionHeader("已配对设备")
                        ForEach(Array(appState.pairedDevices.enumerated()), id: \.element.id) { index, device in
                            DeviceCard(
                                device: device,
                                isConnected: appState.connectionStatus == .connected && appState.remoteServerId == device.id,
                                isPaired: true,
                                onTap: { connectWithDelay(device.ip) },
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
                    if detectedSubnet != nil {
                        Button {
                            HapticManager.impact(.light)
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
                                    Text("输入 #编号 即可连接")
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
                    }

                    // Help tip
                    if appState.pairedDevices.isEmpty && appState.connectionStatus == .disconnected {
                        VStack(spacing: 8) {
                            Image(systemName: "lightbulb")
                                .font(.title3)
                                .foregroundStyle(.yellow)
                            Text("在电脑端打开 LocalType 服务，\n输入编号即可连接")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }

                    // Full IP fallback
                    Button {
                        HapticManager.impact(.light)
                        useFullIP = true
                        showingManualConnect = true
                    } label: {
                        Text("没有找到设备？试试用完整 IP 地址连接")
                            .font(.caption)
                            .foregroundStyle(appState.accentColor.color)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .navigationTitle("连接")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticManager.impact(.light)
                        appState.probeAllDevices()
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .frame(width: 20, height: 20)
                            .rotationEffect(.degrees(appState.isProbing ? 360 : 0))
                            .animation(
                                appState.isProbing
                                    ? .linear(duration: 0.8).repeatForever(autoreverses: false)
                                    : .default,
                                value: appState.isProbing
                            )
                    }
                }
            }
            .onAppear {
                detectSubnet()
                appState.probeAllDevices()
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
                TextField("编号（如 101）", text: $lastOctet)
                    .keyboardType(.numberPad)
                    .monospaced()
            }

            Button("取消", role: .cancel) {
                lastOctet = ""
                fullIP = ""
            }

            Button("连接") {
                HapticManager.impact(.light)
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
                Text("输入电脑端显示的 #编号")
            }
        }
    }

    // MARK: - Connect with Animation Delay

    private func connectWithDelay(_ ip: String) {
        guard !showConnecting, appState.connectionStatus != .connected else { return }
        HapticManager.impact(.light)
        showConnecting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            appState.connect(to: ip)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showConnecting = false
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
            localIP = wifi.ip
        } else if let en = candidates.first(where: { $0.name.hasPrefix("en") }) {
            detectedSubnet = en.subnet
            localIP = en.ip
        } else if let best = candidates.first {
            detectedSubnet = best.subnet
            localIP = best.ip
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

    // MARK: - Connection Hero Card

    private var connectionHeroCard: some View {
        GlassCard {
            VStack(spacing: 16) {
                // Device icons + line
                HStack(spacing: 0) {
                    VStack(spacing: 4) {
                        Image(systemName: "iphone.gen3")
                            .font(.system(size: 28))
                            .foregroundStyle(appState.accentColor.color)
                        Text("本机")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text(displayStatus == .connected ? (localIP ?? " ") : " ")
                            .font(.caption2)
                            .foregroundStyle(.quaternary)
                            .monospaced()
                            .lineLimit(1)
                            .contentTransition(.opacity)
                            .animation(.easeInOut(duration: 0.4), value: displayStatus)
                    }
                    .frame(width: 100)

                    connectionLine
                        .frame(height: 24)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 10)

                    VStack(spacing: 4) {
                        ZStack {
                            Image(systemName: remoteDeviceIcon)
                                .font(.system(size: 28))
                                .foregroundStyle(Color(.tertiaryLabel))
                                .opacity(displayStatus == .connected ? 0 : 1)
                            Image(systemName: remoteDeviceIcon)
                                .font(.system(size: 28))
                                .foregroundStyle(appState.accentColor.color)
                                .opacity(displayStatus == .connected ? 1 : 0)
                        }
                        .animation(.easeInOut(duration: 0.4), value: displayStatus)
                        Text(remoteDeviceLabel)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .contentTransition(.opacity)
                            .animation(.easeInOut(duration: 0.4), value: displayStatus)
                        Text(displayStatus == .connected && !appState.remoteServerIP.isEmpty ? appState.remoteServerIP : " ")
                            .font(.caption2)
                            .foregroundStyle(.quaternary)
                            .monospaced()
                            .lineLimit(1)
                            .contentTransition(.opacity)
                            .animation(.easeInOut(duration: 0.4), value: displayStatus)
                    }
                    .frame(width: 100)
                }

                // Status message
                Text(heroStatusMessage)
                    .font(.subheadline)
                    .foregroundStyle(heroStatusColor)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.4), value: displayStatus)
            }
        }
        .opacity(cardsAppeared ? 1 : 0)
        .scaleEffect(cardsAppeared ? 1 : 0.97)
        .animation(.spring(response: 0.7, dampingFraction: 0.78), value: cardsAppeared)
    }

    private var connectionLine: some View {
        ZStack {
            // Dashed line (disconnected / error)
            HStack(spacing: 5) {
                ForEach(0..<8, id: \.self) { _ in
                    Capsule()
                        .fill(Color(.tertiaryLabel).opacity(0.4))
                        .frame(width: 10, height: 2.5)
                }
            }
            .opacity(displayStatus == .disconnected || displayStatus == .error ? 1 : 0)

            // Solid bar (connecting / connected)
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            appState.accentColor.color.opacity(displayStatus == .connected ? 0.5 : 0.25),
                            appState.accentColor.color.opacity(displayStatus == .connected ? 0.9 : 0.45),
                            appState.accentColor.color.opacity(displayStatus == .connected ? 0.5 : 0.25)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 3)
                .shadow(color: appState.accentColor.color.opacity(displayStatus == .connected ? 0.4 : 0.15), radius: 4)
                .opacity(displayStatus == .connecting || displayStatus == .connected ? 1 : 0)
        }
        .animation(.easeInOut(duration: 0.4), value: displayStatus)
    }

    private var remoteDeviceIcon: String {
        switch appState.remoteServerOS {
        case "macos": return "desktopcomputer"
        case "windows": return "pc"
        case "linux": return "terminal"
        default: return "display"
        }
    }

    private func osDisplayName(_ os: String) -> String {
        switch os {
        case "macos": return "macOS"
        case "windows": return "Windows"
        case "linux": return "Linux"
        default: return os
        }
    }

    private var remoteDeviceLabel: String {
        switch displayStatus {
        case .connected: return cleanServerName
        default: return "电脑"
        }
    }

    private var heroStatusMessage: String {
        switch displayStatus {
        case .disconnected: return "准备就绪，输入编号开始连接"
        case .connecting: return "正在连接..."
        case .connected: return "已连接 \(cleanServerName)"
        case .error: return "连接失败，请检查电脑端是否在线"
        }
    }

    private var heroStatusColor: Color {
        switch displayStatus {
        case .disconnected: return .secondary
        case .connecting: return appState.accentColor.color
        case .connected: return appState.accentColor.color
        case .error: return .red
        }
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
                        .animation(.easeInOut(duration: 0.4), value: displayStatus)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(statusText)
                        .font(.headline)
                        .contentTransition(.numericText())

                    switch displayStatus {
                    case .connected:
                        HStack(spacing: 6) {
                            Text(cleanServerName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if !appState.remoteServerOS.isEmpty {
                                Text(osDisplayName(appState.remoteServerOS))
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(appState.accentColor.color)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(appState.accentColor.color.opacity(0.1), in: .capsule)
                            }
                        }
                    case .disconnected:
                        Text("选择设备或输入 IP 连接")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    case .connecting:
                        Text("正在连接...")
                            .font(.caption)
                            .foregroundStyle(appState.accentColor.color)
                    case .error:
                        Text("电脑端离线或地址错误")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: displayStatus)

                Spacer()

                switch displayStatus {
                case .connected:
                    Button {
                        appState.disconnect()
                    } label: {
                        Text("断开")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 9)
                            .background(Color(.tertiarySystemFill), in: .capsule)
                            .foregroundStyle(.red)
                    }
                    .transition(.scale.combined(with: .opacity))
                case .connecting:
                    Button {
                        appState.cancelConnect()
                    } label: {
                        Text("取消")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 9)
                            .background(Color(.tertiarySystemFill), in: .capsule)
                            .foregroundStyle(.red)
                    }
                    .transition(.scale.combined(with: .opacity))
                default:
                    EmptyView()
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: displayStatus)
        }
    }

    private var statusColor: Color {
        switch displayStatus {
        case .connected: return appState.accentColor.color
        case .connecting: return appState.accentColor.color
        case .error: return .red
        case .disconnected: return .gray
        }
    }

    private var statusText: String {
        switch displayStatus {
        case .connected: return "已连接"
        case .connecting: return "连接中"
        case .error: return "连接失败"
        case .disconnected: return "未连接"
        }
    }

    private var cleanServerName: String {
        let name = appState.remoteServerName
        if let range = name.range(of: " (") {
            return String(name[..<range.lowerBound])
        }
        if let range = name.range(of: "(") {
            return String(name[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
        }
        return name
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
