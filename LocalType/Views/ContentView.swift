import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

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
    }
}

