import Foundation
import SwiftUI
import Combine

/// AppState - 全局应用状态管理器
/// 职责：管理用户状态、上下文、洞察和错误处理
@MainActor
class AppState: ObservableObject {
    // MARK: - Singleton
    static let shared = AppState()

    // MARK: - Published State Variables

    /// 当前用户
    @Published var currentUser: User?

    /// 用户全局上下文
    @Published var context: UserContext?

    /// 洞察列表
    @Published var insights: [Insight] = []

    /// 加载状态
    @Published var isLoading: Bool = false

    /// 错误消息
    @Published var errorMessage: String?

    /// 应用状态（用于 Menu Bar 图标更新）
    @Published var appStatus: AppStatus = .normal

    // MARK: - Private Properties

    private let contextEngine: ContextEngine
    private let db: DatabaseService
    private var refreshTimer: Timer?
    private let autoRefreshInterval: TimeInterval = 300 // 5 分钟

    // MARK: - Initialization

    init() {
        self.contextEngine = ContextEngine.shared
        self.db = DatabaseService.shared
    }

    // MARK: - Public Methods

    /// 加载用户状态（应用启动时调用）
    func loadUserState() async {
        isLoading = true
        errorMessage = nil

        do {
            // 1. 获取或创建默认用户
            let userId = await getOrCreateDefaultUser()

            // 2. 加载用户信息
            currentUser = try await loadUser(userId: userId)

            // 3. 刷新上下文
            await refreshContext()

            // 4. 启动自动刷新
            startAutoRefresh()

            print("✅ AppState: 用户状态加载成功 - \(currentUser?.name ?? "Unknown")")

        } catch {
            handleError(error, context: "加载用户状态失败")
        }

        isLoading = false
    }

    /// 刷新上下文（手动或自动触发）
    func refreshContext() async {
        guard let userId = currentUser?.id else {
            handleError(AppStateError.noUser, context: "刷新上下文失败")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // 使用 ContextEngine 加载完整上下文
            context = try await contextEngine.loadContext(userId: userId)

            // 更新洞察列表
            insights = context?.recentInsights ?? []

            // 更新应用状态
            updateAppStatus()

            print("✅ AppState: 上下文刷新成功 - \(context?.summary.totalGoals ?? 0) 个目标")

        } catch {
            handleError(error, context: "刷新上下文失败")
        }

        isLoading = false
    }

    /// 处理错误（统一错误处理入口）
    func handleError(_ error: Error, context: String? = nil) {
        let errorContext = context ?? "操作失败"
        let errorDescription = error.localizedDescription

        errorMessage = "\(errorContext): \(errorDescription)"
        appStatus = .offline

        print("❌ AppState Error: \(errorContext) - \(errorDescription)")

        // 记录错误日志（可以扩展为发送到分析服务）
        logError(error: error, context: errorContext)
    }

    /// 清除错误消息
    func clearError() {
        errorMessage = nil
        if appStatus == .offline {
            appStatus = .normal
        }
    }

    /// 使缓存失效并刷新
    func invalidateCacheAndRefresh() async {
        guard let userId = currentUser?.id else { return }

        contextEngine.invalidateCache(userId: userId)
        await refreshContext()
    }

    // MARK: - Convenience Access Methods

    /// 获取当前活跃目标
    var activeGoals: [Goal] {
        context?.activeGoals ?? []
    }

    /// 获取当前活跃习惯
    var activeHabits: [Habit] {
        context?.activeHabits ?? []
    }

    /// 获取今日待办事项
    var todaySchedule: [Event] {
        context?.todaySchedule ?? []
    }

    /// 获取紧急洞察
    var urgentInsights: [Insight] {
        context?.urgentInsights ?? []
    }

    /// 获取预算预警
    var budgetAlerts: [BudgetAlert] {
        context?.budgetAlerts ?? []
    }

    /// 是否有紧急事项
    var hasUrgentMatters: Bool {
        context?.hasUrgentMatters ?? false
    }

    /// 是否处于压力状态
    var isStressed: Bool {
        context?.isStressed ?? false
    }

    /// 生成简短摘要
    var briefSummary: String {
        context?.generateBriefSummary() ?? "暂无数据"
    }

    // MARK: - Private Helper Methods

    /// 获取或创建默认用户
    private func getOrCreateDefaultUser() async -> String {
        // TODO: 从持久化存储读取用户 ID
        // 临时使用硬编码 ID
        return "default-user"
    }

    /// 从数据库加载用户
    private func loadUser(userId: String) async throws -> User {
        // TODO: 从数据库加载用户
        // 临时返回模拟用户
        return User(
            id: userId,
            name: "李鴻敏",
            timezone: "Asia/Tokyo",
            language: "zh-CN",
            totalGoals: 0,
            completedGoals: 0,
            activeHabits: 0
        )
    }

    /// 更新应用状态
    private func updateAppStatus() {
        guard let context = context else {
            appStatus = .offline
            return
        }

        // 根据上下文更新状态
        if !context.urgentInsights.isEmpty || !context.budgetAlerts.isEmpty {
            appStatus = .hasAlert
        } else if isLoading {
            appStatus = .syncing
        } else {
            appStatus = .normal
        }
    }

    /// 启动自动刷新定时器
    private func startAutoRefresh() {
        // 清除旧定时器
        refreshTimer?.invalidate()

        // 创建新定时器（每 5 分钟刷新一次）
        refreshTimer = Timer.scheduledTimer(withTimeInterval: autoRefreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshContext()
            }
        }

        print("✅ AppState: 自动刷新已启动（间隔: \(Int(autoRefreshInterval/60)) 分钟）")
    }

    /// 记录错误日志
    private func logError(error: Error, context: String) {
        // TODO: 实现错误日志记录
        // 可以写入文件或发送到分析服务
        let timestamp = ISO8601DateFormatter().string(from: Date())
        print("📝 Error Log [\(timestamp)]: \(context) - \(error)")
    }

    // MARK: - Cleanup

    deinit {
        refreshTimer?.invalidate()
    }
}

// MARK: - AppStateProtocol Conformance

extension AppState: AppStateProtocol {
    // 协议要求的方法已在上面实现
}

// MARK: - Error Definitions

enum AppStateError: LocalizedError {
    case noUser
    case contextLoadFailed
    case databaseError(String)

    var errorDescription: String? {
        switch self {
        case .noUser:
            return "未找到当前用户"
        case .contextLoadFailed:
            return "上下文加载失败"
        case .databaseError(let message):
            return "数据库错误: \(message)"
        }
    }
}

// MARK: - Public Extensions for SwiftUI Views

extension AppState {
    /// 创建绑定用于 SwiftUI
    var errorBinding: Binding<Bool> {
        Binding(
            get: { self.errorMessage != nil },
            set: { if !$0 { self.clearError() } }
        )
    }

    /// 错误显示文本
    var errorDisplayText: String {
        errorMessage ?? ""
    }
}
