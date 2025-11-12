import SwiftUI

@main
struct SystemMonitorApp: App {
    @StateObject private var systemMonitor = SystemMonitorViewModel()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(systemMonitor)
                .frame(minWidth: 1000, minHeight: 700)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
