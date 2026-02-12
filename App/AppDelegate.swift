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

        // 注册主窗口显示通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showMainWindow),
            name: .showMainWindow,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hideMainWindow),
            name: .hideMainWindow,
            object: nil
        )

        print("✅ Menu Bar 已初始化")
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("👋 NovaLife Weaver 正在退出...")
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // 当应用被重新激活时
        if !flag {
            // 没有可见窗口 → 显示主窗口
            showMainWindow()
        } else {
            // 有窗口 → 激活主窗口
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
        return true
    }

    // MARK: - Window Management

    /// 显示主窗口
    @objc func showMainWindow() {
        // 查找主窗口
        if let mainWindow = NSApp.windows.first(where: { $0.title == "NovaLife Weaver" }) {
            mainWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            print("🪟 主窗口已激活")
        } else {
            // 如果没有主窗口，创建新的
            NSApp.sendAction(Selector(("newDocument:")), to: nil, from: nil)
            print("🪟 创建新主窗口")
        }
    }

    /// 隐藏主窗口
    @objc func hideMainWindow() {
        NSApp.windows.first(where: { $0.title == "NovaLife Weaver" })?.orderOut(nil)
        print("🪟 主窗口已隐藏")
    }
}
