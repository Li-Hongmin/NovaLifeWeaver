import Combine
import Combine
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

        do {
            let context = try await contextEngine.loadContext(userId: userId)
            self.userContext = context
            self.urgentInsights = context.urgentInsights

            print("✅ Context loaded: \(context.summary)")
        } catch {
            // 优雅处理错误 - 不显示给用户
            print("⚠️ 加载上下文失败（使用空上下文）: \(error)")
            self.userContext = nil
            self.urgentInsights = []
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

        // TODO: 集成 IntentRouter 和 AI Agents
        // 临时处理：显示确认消息
        print("✅ 收到用户输入，AI 处理功能待集成")

        // 不刷新上下文避免错误
        // await loadInitialContext()
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
