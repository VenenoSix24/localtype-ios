import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView {
            Tab("连接", systemImage: "wifi") {
                NavigationStack {
                    ConnectionView()
                }
            }

            Tab("输入", systemImage: "keyboard") {
                NavigationStack {
                    InputView()
                }
            }

            Tab("统计", systemImage: "trophy") {
                NavigationStack {
                    StatisticsView()
                }
            }

            Tab("设置", systemImage: "gearshape") {
                NavigationStack {
                    SettingsView()
                }
            }
        }
        .tint(.accentBlue)
    }
}

extension Color {
    static let accentBlue = Color.blue
    static let accentGreen = Color.green
    static let accentRed = Color.red
}
