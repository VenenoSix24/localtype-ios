import SwiftUI

@main
struct LocalTypeApp: App {
    @State private var appState = AppState()

    private var resolvedColorScheme: ColorScheme? {
        switch appState.colorScheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .preferredColorScheme(resolvedColorScheme)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    appState.onAppResume()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    appState.onAppBackground()
                }
        }
    }
}
