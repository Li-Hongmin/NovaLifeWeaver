import Cocoa
import SwiftUI

/// Menu Bar 管理器 - 负责状态栏图标和 Popover 管理
@MainActor
class MenuBarManager: NSObject, ObservableObject {
    // MARK: - Properties

    /// 状态栏项
    private var statusItem: NSStatusItem?

    /// 弹出面板
    private var popover: NSPopover?

    /// 当前应用状态
    private var currentStatus: AppStatus = .normal

    /// 全局应用状态（注入到 SwiftUI 视图）
    @Published var appState = AppState()

    /// 单例实例
    static let shared = MenuBarManager()

    // MARK: - Initialization

    private override init() {
        super.init()
    }

    // MARK: - Setup

    /// 初始化 Menu Bar
    func setupMenuBar() {
        // 创建状态栏项
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else {
            print("❌ 无法创建 Menu Bar 按钮")
            return
        }

        // 设置初始图标
        updateIcon(status: .normal)

        // 设置点击事件
        button.action = #selector(togglePopover)
        button.target = self

        // 创建 Popover
        setupPopover()

        // 注册全局快捷键
        registerGlobalShortcut()

        // 注册通知观察者
        registerNotificationObservers()

        print("✅ Menu Bar 设置完成（支持快捷键 ⌘+Shift+N）")
    }

    /// 初始化 Popover
    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 400, height: 600)
        popover?.behavior = .transient // 点击外部自动关闭
        popover?.animates = true

        // 设置内容视图 (MenuBarView)
        let contentView = MenuBarView()
            .environmentObject(appState) // 注入全局状态

        popover?.contentViewController = NSHostingController(rootView: contentView)

        print("✅ Popover 创建完成")
    }

    // MARK: - Actions

    /// 切换 Popover 显示/隐藏
    @objc func togglePopover() {
        guard let button = statusItem?.button else { return }

        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
                print("🔽 Popover 已关闭")
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

                // 激活应用（确保 Popover 获得焦点）
                NSApp.activate(ignoringOtherApps: true)

                print("🔼 Popover 已打开")
            }
        }
    }

    /// 更新 Menu Bar 图标状态
    func updateIcon(status: AppStatus) {
        guard let button = statusItem?.button else { return }

        currentStatus = status

        // 根据状态选择图标和提示文字
        let iconName: String
        let toolTip: String

        switch status {
        case .normal:
            iconName = "brain.head.profile"
            toolTip = "NovaLife Weaver - 正常"

        case .hasAlert:
            iconName = "exclamationmark.triangle.fill"
            toolTip = "NovaLife Weaver - 有重要提醒"

        case .syncing:
            iconName = "arrow.triangle.2.circlepath"
            toolTip = "NovaLife Weaver - 同步中"

        case .offline:
            iconName = "wifi.slash"
            toolTip = "NovaLife Weaver - 离线模式"
        }

        // 设置图标
        if let image = NSImage(systemSymbolName: iconName, accessibilityDescription: toolTip) {
            // 配置图标大小和粗细
            let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
            let configuredImage = image.withSymbolConfiguration(config)

            button.image = configuredImage
            button.toolTip = toolTip

            // 为不同状态设置不同的视觉效果
            switch status {
            case .hasAlert:
                // 警告状态使用橙色
                button.contentTintColor = .systemOrange

            case .syncing:
                // 同步状态使用蓝色并添加旋转动画
                button.contentTintColor = .systemBlue
                startSyncAnimation()

            case .offline:
                // 离线状态使用灰色
                button.contentTintColor = .systemGray

            case .normal:
                // 正常状态使用默认颜色
                button.contentTintColor = nil
                stopSyncAnimation()
            }
        }
    }

    /// 显示通知角标（未读数量）
    func showBadge(count: Int) {
        guard let button = statusItem?.button else { return }

        if count > 0 {
            button.title = " \(count)"
        } else {
            button.title = ""
        }
    }

    // MARK: - Private Methods

    /// 注册全局快捷键 ⌘ + Shift + N
    private func registerGlobalShortcut() {
        // 使用本地事件监听器（应用内快捷键）
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // 检查是否为 ⌘ + Shift + N
            if event.modifierFlags.contains([.command, .shift]) &&
               event.charactersIgnoringModifiers?.lowercased() == "n" {

                // 触发 toggle
                self?.togglePopover()

                // 消费此事件，阻止传递
                return nil
            }

            return event
        }

        print("✅ 全局快捷键已注册: ⌘ + Shift + N")
    }

    /// 同步动画效果（旋转）
    private func startSyncAnimation() {
        guard let button = statusItem?.button,
              button.layer?.animation(forKey: "syncRotation") == nil else {
            return
        }

        // 创建旋转动画
        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.fromValue = 0
        rotation.toValue = Double.pi * 2
        rotation.duration = 2.0
        rotation.repeatCount = .infinity

        button.layer?.add(rotation, forKey: "syncRotation")
    }

    /// 停止同步动画
    private func stopSyncAnimation() {
        guard let button = statusItem?.button else { return }
        button.layer?.removeAnimation(forKey: "syncRotation")
    }

    // MARK: - Public Utility Methods

    /// 显示面板（从代码调用）
    func showPopover() {
        guard let popover = popover,
              let button = statusItem?.button,
              !popover.isShown else {
            return
        }

        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// 隐藏面板
    func hidePopover() {
        popover?.performClose(nil)
    }

    /// 清理资源
    func cleanup() {
        popover?.close()

        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }

        print("🧹 MenuBarManager 已清理")
    }
}

// MARK: - Status Updates

extension MenuBarManager {
    /// 更新为正常状态
    func setNormalStatus() {
        updateIcon(status: .normal)
    }

    /// 更新为警告状态
    func setAlertStatus() {
        updateIcon(status: .hasAlert)
    }

    /// 开始同步
    func startSyncing() {
        updateIcon(status: .syncing)
    }

    /// 结束同步
    func endSyncing() {
        updateIcon(status: .normal)
    }

    /// 设置离线模式
    func setOfflineMode() {
        updateIcon(status: .offline)
    }

    /// 设置在线模式
    func setOnlineMode() {
        if currentStatus == .offline {
            updateIcon(status: .normal)
        }
    }
}

// MARK: - Notification Handlers

extension MenuBarManager {
    /// 注册通知观察者
    func registerNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUrgentInsight),
            name: .urgentInsightDetected,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSyncStatusChange),
            name: .syncStatusChanged,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNetworkStatusChange),
            name: .networkStatusChanged,
            object: nil
        )

        print("✅ 通知观察者已注册")
    }

    @objc private func handleUrgentInsight(_ notification: Notification) {
        // 收到紧急洞察时更新图标状态
        setAlertStatus()

        // 可选：自动显示弹出面板提醒用户
        // showPopover()
    }

    @objc private func handleSyncStatusChange(_ notification: Notification) {
        if let isSyncing = notification.userInfo?["isSyncing"] as? Bool {
            if isSyncing {
                startSyncing()
            } else {
                endSyncing()
            }
        }
    }

    @objc private func handleNetworkStatusChange(_ notification: Notification) {
        if let isOnline = notification.userInfo?["isOnline"] as? Bool {
            if isOnline {
                setOnlineMode()
            } else {
                setOfflineMode()
            }
        }
    }
}

// MARK: - Protocol Conformance

extension MenuBarManager: MenuBarManagerProtocol {
    /// 兼容协议的 updateStatusIcon 方法
    func updateStatusIcon(hasUrgentMatters: Bool) {
        if hasUrgentMatters {
            setAlertStatus()
        } else {
            setNormalStatus()
        }
    }
}

// MARK: - Custom Notifications

extension Notification.Name {
    /// 检测到紧急洞察
    static let urgentInsightDetected = Notification.Name("urgentInsightDetected")

    /// 同步状态改变
    static let syncStatusChanged = Notification.Name("syncStatusChanged")

    /// 网络状态改变
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
}
