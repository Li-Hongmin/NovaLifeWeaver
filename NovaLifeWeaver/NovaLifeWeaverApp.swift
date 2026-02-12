import SwiftUI

@main
struct NovaLifeWeaverApp: App {
    // 使用 AppDelegate 管理应用生命周期
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Menu Bar 应用仅需要 Settings scene
        Settings {
            SettingsView()
        }
    }
}
