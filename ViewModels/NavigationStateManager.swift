import Foundation
import SwiftUI
import Combine

/// 导航状态管理器 - 统一管理主窗口和菜单栏之间的导航
@MainActor
class NavigationStateManager: ObservableObject {
    // MARK: - Singleton
    static let shared = NavigationStateManager()

    // MARK: - Published State

    /// 当前选中的导航区域
    @Published var selectedSection: NavigationSection = .goals

    /// 详细视图的选中项 ID（用于深度链接）
    @Published var detailSelection: String?

    /// 主窗口是否可见
    @Published var isMainWindowVisible = false

    // MARK: - Private Properties

    private let windowStateKey = "mainWindowState"
    private let selectedSectionKey = "selectedSection"

    // MARK: - Initialization

    private init() {
        // 恢复上次的导航状态
        restoreNavigationState()
    }

    // MARK: - Public Methods

    /// 导航到指定区域（支持深度链接）
    func navigateTo(section: NavigationSection, itemId: String? = nil) {
        selectedSection = section
        detailSelection = itemId

        // 显示主窗口
        showMainWindow()

        // 保存导航状态
        saveNavigationState()

        print("📍 导航到：\(section.rawValue)" + (itemId.map { " (项目: \($0))" } ?? ""))
    }

    /// 显示主窗口
    func showMainWindow() {
        // 发送通知给 AppDelegate
        NotificationCenter.default.post(
            name: .showMainWindow,
            object: nil
        )

        isMainWindowVisible = true
    }

    /// 隐藏主窗口
    func hideMainWindow() {
        NotificationCenter.default.post(
            name: .hideMainWindow,
            object: nil
        )

        isMainWindowVisible = false
    }

    /// 切换主窗口显示/隐藏
    func toggleMainWindow() {
        if isMainWindowVisible {
            hideMainWindow()
        } else {
            showMainWindow()
        }
    }

    // MARK: - State Persistence

    /// 保存导航状态
    private func saveNavigationState() {
        UserDefaults.standard.set(selectedSection.rawValue, forKey: selectedSectionKey)

        if let itemId = detailSelection {
            UserDefaults.standard.set(itemId, forKey: "\(selectedSectionKey)_detail")
        }
    }

    /// 恢复导航状态
    private func restoreNavigationState() {
        if let sectionRaw = UserDefaults.standard.string(forKey: selectedSectionKey),
           let section = NavigationSection(rawValue: sectionRaw) {
            selectedSection = section
        }

        detailSelection = UserDefaults.standard.string(forKey: "\(selectedSectionKey)_detail")

        print("✅ 导航状态已恢复：\(selectedSection.rawValue)")
    }

    /// 重置导航状态
    func resetNavigation() {
        selectedSection = .goals
        detailSelection = nil
        saveNavigationState()
    }
}

// MARK: - Navigation Section

/// 导航区域枚举
enum NavigationSection: String, CaseIterable, Identifiable {
    case goals      // 目标
    case habits     // 习惯
    case finance    // 财务
    case emotions   // 情绪
    case calendar   // 日历
    case insights   // 洞察

    var id: String { rawValue }

    /// 显示名称
    var displayName: String {
        switch self {
        case .goals:    return "目标"
        case .habits:   return "习惯"
        case .finance:  return "财务"
        case .emotions: return "情绪"
        case .calendar: return "日历"
        case .insights: return "洞察"
        }
    }

    /// 图标名称
    var iconName: String {
        switch self {
        case .goals:    return "target"
        case .habits:   return "repeat.circle"
        case .finance:  return "yensign.circle"
        case .emotions: return "heart.circle"
        case .calendar: return "calendar"
        case .insights: return "lightbulb.circle"
        }
    }

    /// 快捷键（⌘+数字）
    var keyboardShortcut: KeyEquivalent? {
        switch self {
        case .goals:    return "1"
        case .habits:   return "2"
        case .finance:  return "3"
        case .emotions: return "4"
        case .calendar: return "5"
        case .insights: return "6"
        }
    }
}

// MARK: - Custom Notifications

extension Notification.Name {
    /// 显示主窗口通知
    static let showMainWindow = Notification.Name("showMainWindow")

    /// 隐藏主窗口通知
    static let hideMainWindow = Notification.Name("hideMainWindow")
}
