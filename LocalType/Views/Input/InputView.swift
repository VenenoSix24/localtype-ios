import SwiftUI

struct InputView: View {
    @Environment(AppState.self) private var appState
    @State private var showQuickPhrases = false

    var body: some View {
        VStack(spacing: 0) {
            if appState.connectionStatus != .connected || appState.authStatus != .authenticated {
                disconnectedPlaceholder
            } else {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(appState.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .defaultScrollAnchor(.bottom)
                    .onChange(of: appState.messages.count) { _, _ in
                        if let last = appState.messages.last {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // Quick phrases
                if showQuickPhrases {
                    QuickPhrasePanel(isPresented: $showQuickPhrases)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Input bar
                InputBar(showQuickPhrases: $showQuickPhrases)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)
                    .padding(.top, 2)
            }
        }
        .navigationTitle("输入")
        .animation(.spring(response: 0.3), value: showQuickPhrases)
        .animation(.spring(response: 0.3), value: appState.connectionStatus)
    }

    private var disconnectedPlaceholder: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "keyboard")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.quaternary)
            Text("请先连接电脑")
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
            Text("在「连接」页面选择设备并连接")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            Spacer()
        }
    }
}
