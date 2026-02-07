import SwiftUI

@main
struct QSwitchApp: App {
    @StateObject var displayManager = DisplayManager()
    @StateObject var audioManager = AudioManager()
    @StateObject var launchManager = LaunchAtLoginManager()
    
    var body: some Scene {
        MenuBarExtra("", systemImage: "display") {
            MenuBarView(
                displayManager: displayManager,
                audioManager: audioManager,
                launchManager: launchManager
            )
        }
        .menuBarExtraStyle(.window)
    }
}
