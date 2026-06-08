import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var showUpdateSheet = false

    var body: some View {
        @Bindable var state = appState

        TabView(selection: $state.selectedTab) {
            Tab("连接", systemImage: "wifi", value: 0) {
                NavigationStack {
                    ConnectionView()
                }
            }

            Tab("输入", systemImage: "keyboard", value: 1) {
                NavigationStack {
                    InputView()
                }
            }

            Tab("统计", systemImage: "trophy", value: 2) {
                NavigationStack {
                    StatisticsView()
                }
            }

            Tab("设置", systemImage: "gearshape", value: 3) {
                NavigationStack {
                    SettingsView()
                }
            }
        }
        .tint(appState.accentColor.color)
        .onChange(of: state.selectedTab) { _, _ in HapticManager.selection() }
        .onAppear {
            Task { await appState.checkForUpdate(silent: true) }
        }
        .onChange(of: appState.updateInfo) { _, info in
            if let info, info.available {
                showUpdateSheet = true
            }
        }
        .sheet(isPresented: $showUpdateSheet) {
            if let info = appState.updateInfo, info.available {
                UpdateSheet(info: info, isPresented: $showUpdateSheet)
            }
        }
    }
}

