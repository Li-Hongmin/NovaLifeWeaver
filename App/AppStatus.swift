import Foundation

/// 应用状态枚举 - 用于 Menu Bar 图标显示
enum AppStatus {
    /// 正常状态
    case normal

    /// 有重要提醒/警告
    case hasAlert

    /// 正在同步数据
    case syncing

    /// 离线模式
    case offline

    // MARK: - Display Properties

    /// 状态图标名称
    var iconName: String {
        switch self {
        case .normal:
            return "brain.head.profile"
        case .hasAlert:
            return "exclamationmark.triangle.fill"
        case .syncing:
            return "arrow.triangle.2.circlepath"
        case .offline:
            return "wifi.slash"
        }
    }

    /// 状态提示文本
    var toolTip: String {
        switch self {
        case .normal:
            return "NovaLife Weaver - 正常"
        case .hasAlert:
            return "NovaLife Weaver - 有重要提醒"
        case .syncing:
            return "NovaLife Weaver - 同步中"
        case .offline:
            return "NovaLife Weaver - 离线模式"
        }
    }

    /// 是否需要用户关注
    var requiresAttention: Bool {
        switch self {
        case .hasAlert:
            return true
        default:
            return false
        }
    }
}

// MARK: - Protocol Definition

/// Menu Bar 管理器协议（用于测试和依赖注入）
protocol MenuBarManagerProtocol {
    func setupMenuBar()
    func togglePopover()
    func updateStatusIcon(hasUrgentMatters: Bool)
    func showBadge(count: Int)
}

/// 应用状态协议（用于测试和依赖注入）
protocol AppStateProtocol: ObservableObject {
    var currentUser: User? { get set }
    var context: UserContext? { get set }
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }
    var insights: [Insight] { get set }

    func refreshContext() async
    func handleError(_ error: Error, context: String?)
}
