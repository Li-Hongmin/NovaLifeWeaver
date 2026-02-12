import Foundation
import SwiftUI
import Combine

/// 对话视图模型 - 管理对话状态和 AI 交互
@MainActor
class ChatViewModel: ObservableObject {
    // MARK: - Published State

    /// 当前活跃对话
    @Published var currentConversation: Conversation

    /// 对话历史
    @Published var conversationHistory: [Conversation] = []

    /// 处理状态
    @Published var isProcessing: Bool = false

    // MARK: - Dependencies

    private let conversationService = ConversationService.shared
    private let contextEngine = ContextEngine.shared
    private var userId: String = "default-user"

    // MARK: - Initialization

    init() {
        // 创建默认对话
        self.currentConversation = Conversation(title: "新对话")

        // 添加欢迎消息
        let welcomeMessage = Message(
            role: .assistant,
            content: "👋 你好！我是 NovaLife，你的 AI 生活助手。\n\n我可以通过对话帮你管理生活的方方面面。试试对我说：\n\n\"我想在3月考过JLPT N2\"\n\"每天早上跑步30分钟\"\n\"今天午餐花了800日元\""
        )

        self.currentConversation.messages.append(welcomeMessage)
    }

    // MARK: - Public Methods

    /// 初始化
    func initialize(userId: String) async {
        self.userId = userId

        // 加载历史对话（从本地存储）
        loadConversationHistory()
    }

    /// 发送消息
    func sendMessage(_ text: String) async {
        // 1. 添加用户消息
        let userMessage = Message(role: .user, content: text)
        currentConversation.messages.append(userMessage)
        currentConversation.updatedAt = Date()

        isProcessing = true

        // 2. 调用 AI 处理
        let context = try? await contextEngine.loadContext(userId: userId)
        let result = await conversationService.processInput(text, userId: userId, context: context)

        // 3. 创建 AI 响应
        var aiMessage = Message(
            role: .assistant,
            content: result.message
        )

        // 4. 如果有工具调用，创建工具卡片
        if let toolUsed = result.toolUsed, let data = result.data {
            let toolCard = createToolCard(from: toolUsed, data: data)
            aiMessage.toolCards = [toolCard]
        }

        currentConversation.messages.append(aiMessage)
        currentConversation.updatedAt = Date()

        isProcessing = false

        // 5. 保存对话
        saveCurrentConversation()

        // 6. 更新对话标题（如果是新对话）
        if currentConversation.messages.count == 3 {  // 欢迎 + 用户 + AI
            updateConversationTitle()
        }
    }

    /// 开始新对话
    func startNewConversation() {
        // 保存当前对话
        saveCurrentConversation()

        // 创建新对话
        currentConversation = Conversation(title: "新对话")

        // 添加欢迎消息
        let welcomeMessage = Message(
            role: .assistant,
            content: "👋 新对话开始！我准备好了，有什么可以帮你？"
        )

        currentConversation.messages.append(welcomeMessage)

        print("🆕 开始新对话")
    }

    /// 切换到历史对话
    func switchToConversation(_ conversationId: String) {
        guard let conversation = conversationHistory.first(where: { $0.id == conversationId }) else {
            return
        }

        // 保存当前对话
        saveCurrentConversation()

        // 加载选中的对话
        currentConversation = conversation
        print("📖 切换到对话：\(conversation.title)")
    }

    /// 确认工具卡片
    func confirmTool(cardId: String) {
        updateToolCardStatus(cardId: cardId, status: .confirmed)
        print("✅ 工具已确认：\(cardId)")

        // AI 响应确认
        let confirmMessage = Message(
            role: .assistant,
            content: "✅ 好的！已经为你完成了。还有什么需要帮助的吗？"
        )
        currentConversation.messages.append(confirmMessage)
    }

    /// 编辑工具卡片
    func editTool(cardId: String) {
        updateToolCardStatus(cardId: cardId, status: .editing)
        print("✏️ 编辑工具：\(cardId)")

        // TODO: 打开编辑界面
    }

    /// 取消工具卡片
    func cancelTool(cardId: String) {
        updateToolCardStatus(cardId: cardId, status: .cancelled)
        print("❌ 工具已取消：\(cardId)")

        let cancelMessage = Message(
            role: .assistant,
            content: "好的，已取消。还有其他需要吗？"
        )
        currentConversation.messages.append(cancelMessage)
    }

    // MARK: - Private Methods

    private func createToolCard(from toolName: String, data: [String: Any]) -> ToolCard {
        let cardType: ToolCardType = {
            switch toolName {
            case "create_goal": return .goalPreview
            case "create_habit": return .habitPreview
            case "record_expense": return .expensePreview
            case "record_emotion": return .emotionPreview
            default: return .insightCard
            }
        }()

        // 转换数据为字符串字典（简化）
        let stringData = data.mapValues { "\($0)" }

        return ToolCard(
            type: cardType,
            data: stringData,
            status: .pending
        )
    }

    private func updateToolCardStatus(cardId: String, status: CardStatus) {
        for (messageIndex, message) in currentConversation.messages.enumerated() {
            if var toolCards = message.toolCards,
               let cardIndex = toolCards.firstIndex(where: { $0.id == cardId }) {
                toolCards[cardIndex].status = status
                currentConversation.messages[messageIndex].toolCards = toolCards
                break
            }
        }
    }

    private func updateConversationTitle() {
        // 使用第一条用户消息作为标题
        if let firstUserMessage = currentConversation.messages.first(where: { $0.role == .user }) {
            let title = String(firstUserMessage.content.prefix(20))
            currentConversation.title = title
        }
    }

    private func saveCurrentConversation() {
        // 更新或添加到历史
        if let index = conversationHistory.firstIndex(where: { $0.id == currentConversation.id }) {
            conversationHistory[index] = currentConversation
        } else {
            conversationHistory.append(currentConversation)
        }

        // TODO: 持久化到本地存储
        saveToUserDefaults()
    }

    private func loadConversationHistory() {
        // TODO: 从本地存储加载
        loadFromUserDefaults()
    }

    private func saveToUserDefaults() {
        if let data = try? JSONEncoder().encode(conversationHistory) {
            UserDefaults.standard.set(data, forKey: "conversationHistory")
        }
    }

    private func loadFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: "conversationHistory"),
           let history = try? JSONDecoder().decode([Conversation].self, from: data) {
            conversationHistory = history
        }
    }
}
