import SwiftUI

@main
struct NovaLifeWeaverApp: App {
    // 使用 AppDelegate 管理应用生命周期
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // 全局状态管理
    @StateObject private var appState = AppState.shared
    @StateObject private var navigationState = NavigationStateManager.shared

    var body: some Scene {
        // 主窗口场景
        WindowGroup("NovaLife Weaver", id: "main") {
            MainWindowView()
                .environmentObject(appState)
                .environmentObject(navigationState)
        }
        .commands {
            // 添加自定义命令
            CommandGroup(after: .newItem) {
                Button("显示主窗口") {
                    navigationState.showMainWindow()
                }
                .keyboardShortcut("0", modifiers: [.command])

                Divider()

                // 快速导航命令
                ForEach(NavigationSection.allCases) { section in
                    Button(section.displayName) {
                        navigationState.navigateTo(section: section)
                    }
                    .keyboardShortcut(section.keyboardShortcut ?? "1", modifiers: [.command])
                }
            }
        }
        .defaultSize(width: 1200, height: 800)

        // 设置场景
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
