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
    @Published var lastResponse: String?

    private let contextEngine = ContextEngine.shared
    private let conversationService = ConversationService.shared
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

    /// 处理用户输入（AI-First with Tool Use）
    func handleUserInput(_ input: String) async {
        print("📝 User input: \(input)")

        isLoading = true
        lastResponse = nil

        // 使用 ConversationService 处理（支持 Tool Use）
        let result = await conversationService.processInput(
            input,
            userId: userId,
            context: userContext
        )

        lastResponse = result.message

        if result.success {
            print("✅ 工具调用成功：\(result.toolUsed ?? "none")")

            // 刷新上下文（因为数据可能已更新）
            await loadInitialContext()
        } else {
            print("⚠️ 处理失败")
        }

        isLoading = false
    }

    /// 生成快速响应（基于关键词）
    private func generateQuickResponse(for input: String) -> String {
        let lowercased = input.lowercased()

        // 财务相关
        if lowercased.contains("花") || lowercased.contains("钱") || lowercased.contains("买") {
            return "💰 我注意到这是财务相关的内容。您可以在「财务」页面添加交易记录，我会帮您跟踪支出和情绪的关系。"
        }

        // 情绪相关
        if lowercased.contains("心情") || lowercased.contains("感觉") || lowercased.contains("情绪") {
            return "🧠 我理解您想记录情绪。请前往「情绪」页面快速记录您的心情，我会帮您发现情绪模式。"
        }

        // 目标相关
        if lowercased.contains("目标") || lowercased.contains("想") || lowercased.contains("计划") {
            return "🎯 这听起来像一个新目标！请前往「目标」页面添加，我会帮您拆解成可执行的步骤。"
        }

        // 习惯相关
        if lowercased.contains("习惯") || lowercased.contains("每天") || lowercased.contains("坚持") {
            return "📅 养成习惯很棒！请前往「习惯」页面设置，我会帮您找到最佳执行时间。"
        }

        // 分析相关
        if lowercased.contains("分析") || lowercased.contains("关联") || lowercased.contains("模式") {
            return "📊 请前往「洞察」页面，点击「分析关联模式」按钮，我会帮您发现数据中的模式。"
        }

        // 默认响应
        return "👋 收到您的消息！\n\n当前功能：\n• 财务：跟踪支出和情绪\n• 情绪：记录心情和触发因素\n• 目标：管理您的目标\n• 习惯：培养好习惯\n• 洞察：发现数据关联\n\n请导航到相应页面使用功能，AI 深度集成即将推出！"
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
