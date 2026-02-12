import Foundation
import SwiftUI

/// MenuBar 视图的 ViewModel - 管理主界面状态
@MainActor
class MenuBarViewModel: ObservableObject {
    @Published var userContext: UserContext?
    @Published var urgentInsights: [Insight] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let contextEngine = ContextEngine.shared
    private let userId = "default_user" // TODO: 从用户登录获取

    // MARK: - Initialization

    init() {
        // 初始化时加载上下文
    }

    // MARK: - Public Methods

    /// 加载初始上下文
    func loadInitialContext() async {
        isLoading = true
        errorMessage = nil

        do {
            let context = try await contextEngine.loadContext(userId: userId)
            self.userContext = context
            self.urgentInsights = context.urgentInsights

            print("✅ Context loaded: \(context.summary)")
        } catch {
            errorMessage = "加载失败: \(error.localizedDescription)"
            print("❌ Failed to load context: \(error)")
        }

        isLoading = false
    }

    /// 刷新上下文
    func refreshContext() {
        Task {
            contextEngine.invalidateCache(userId: userId)
            await loadInitialContext()
        }
    }

    /// 处理用户输入
    func handleUserInput(_ input: String) async {
        print("📝 User input: \(input)")

        // TODO: 路由到合适的 Agent
        // 1. 分析意图 (Intent Router)
        // 2. 加载上下文
        // 3. 调用相应的 Agent (Planner/Memory/etc)
        // 4. 更新 UI

        // 临时: 显示收到的消息
        errorMessage = "收到输入: \(input)"

        // 刷新上下文
        await loadInitialContext()
    }

    /// 处理洞察点击
    func handleInsightTap(_ insight: Insight) {
        print("📊 Insight tapped: \(insight.title)")

        // TODO: 根据洞察类型执行相应操作
        // - warning: 显示详情和建议
        // - recommendation: 一键执行建议
        // - achievement: 显示庆祝动画
    }
}
