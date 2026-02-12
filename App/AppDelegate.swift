import Cocoa
import SwiftUI

/// 应用程序委托 - 管理应用生命周期和 Menu Bar
class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarManager: MenuBarManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 NovaLife Weaver 启动中...")

        // 运行数据库测试
        Task {
            await TestDatabase.runTests()
        }

        // 初始化 Menu Bar
        menuBarManager = MenuBarManager()
        menuBarManager?.setupMenuBar()

        print("✅ Menu Bar 已初始化")
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("👋 NovaLife Weaver 正在退出...")
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // 当应用被重新激活时，显示 Menu Bar popover
        if !flag {
            menuBarManager?.togglePopover()
        }
        return true
    }
}
