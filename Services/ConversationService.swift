import Foundation

/// 对话服务 - 处理用户输入并协调 AI 和工具调用
class ConversationService {
    static let shared = ConversationService()

    private let toolService = ToolUseService.shared
    private let bedrockService = BedrockService.shared

    private init() {}

    // MARK: - 主要接口

    /// 处理用户输入（AI-First 流程）
    func processInput(_ input: String, userId: String, context: UserContext?) async -> ConversationResult {
        print("💬 处理对话：\(input)")

        // 1. 快速意图识别（基于关键词）
        let intent = detectIntent(input)
        print("🎯 意图：\(intent)")

        // 2. 根据意图执行工具
        do {
            let toolResult = try await executeIntentTool(intent: intent, input: input, userId: userId)

            return ConversationResult(
                message: toolResult.message,
                toolUsed: intent.rawValue,
                success: toolResult.success,
                data: toolResult.data
            )
        } catch {
            return ConversationResult(
                message: "❌ 处理失败：\(error.localizedDescription)",
                toolUsed: nil,
                success: false,
                data: nil
            )
        }
    }

    // MARK: - 意图检测

    private func detectIntent(_ input: String) -> Intent {
        let lowercased = input.lowercased()

        // 目标相关
        if lowercased.contains("想") && (lowercased.contains("学") || lowercased.contains("考") || lowercased.contains("目标")) {
            return .createGoal
        }

        // 习惯相关
        if lowercased.contains("每天") || lowercased.contains("坚持") || lowercased.contains("习惯") {
            return .createHabit
        }

        // 财务相关
        if lowercased.contains("花") || lowercased.contains("买") || (lowercased.contains("元") && !lowercased.contains("想")) {
            return .recordExpense
        }

        // 情绪相关
        if lowercased.contains("心情") || lowercased.contains("感觉") || lowercased.contains("压力") || lowercased.contains("难过") || lowercased.contains("开心") {
            return .recordEmotion
        }

        // 分析相关
        if lowercased.contains("分析") || lowercased.contains("模式") || lowercased.contains("关联") {
            return .analyzeData
        }

        return .general
    }

    // MARK: - 工具执行

    private func executeIntentTool(intent: Intent, input: String, userId: String) async throws -> ToolResult {
        switch intent {
        case .createGoal:
            return try await createGoalFromText(input, userId: userId)

        case .createHabit:
            return try await createHabitFromText(input, userId: userId)

        case .recordExpense:
            return try await recordExpenseFromText(input, userId: userId)

        case .recordEmotion:
            return try await recordEmotionFromText(input, userId: userId)

        case .analyzeData:
            return try await toolService.executeTool(name: "analyze_correlation", parameters: [:], userId: userId)

        case .general:
            return ToolResult(
                success: true,
                message: "👋 我收到了您的消息！\n\n💡 提示：您可以说：\n• \"我想在3月考过JLPT N2\"（创建目标）\n• \"每天晨跑30分钟\"（创建习惯）\n• \"今天午餐花了800日元\"（记录支出）\n• \"今天工作压力大\"（记录情绪）\n• \"帮我分析数据\"（关联分析）",
                data: nil
            )
        }
    }

    // MARK: - 文本解析（简化版，待集成真实 AI）

    private func createGoalFromText(_ text: String, userId: String) async throws -> ToolResult {
        // 简单提取（待替换为 Nova AI）
        let title = text
            .replacingOccurrences(of: "我想", with: "")
            .replacingOccurrences(of: "在", with: "")
            .trimmingCharacters(in: .whitespaces)

        // 检测类别
        let category: String
        if text.contains("学") || text.contains("考") {
            category = "learning"
        } else if text.contains("健身") || text.contains("跑") {
            category = "health"
        } else {
            category = "personal"
        }

        // 检测时间
        let deadline: String? = {
            if text.contains("3月") || text.contains("三月") {
                return "2026-03-31"
            }
            return nil
        }()

        let params: [String: Any] = [
            "title": title,
            "category": category,
            "deadline": deadline as Any,
            "priority": 5
        ]

        return try await toolService.executeTool(name: "create_goal", parameters: params, userId: userId)
    }

    private func createHabitFromText(_ text: String, userId: String) async throws -> ToolResult {
        let name = text
            .replacingOccurrences(of: "每天", with: "")
            .replacingOccurrences(of: "坚持", with: "")
            .trimmingCharacters(in: .whitespaces)

        let category = text.contains("跑") || text.contains("运动") ? "health" : "productivity"

        let params: [String: Any] = [
            "name": name,
            "category": category,
            "frequency": "daily"
        ]

        return try await toolService.executeTool(name: "create_habit", parameters: params, userId: userId)
    }

    private func recordExpenseFromText(_ text: String, userId: String) async throws -> ToolResult {
        // 提取金额
        let amount: Double = {
            if let match = text.range(of: "\\d+", options: .regularExpression) {
                let numberStr = String(text[match])
                return Double(numberStr) ?? 0
            }
            return 0
        }()

        // 检测类别
        let category: String
        if text.contains("午餐") || text.contains("晚餐") || text.contains("吃") {
            category = "food"
        } else if text.contains("地铁") || text.contains("交通") {
            category = "transport"
        } else {
            category = "other"
        }

        let params: [String: Any] = [
            "amount": amount,
            "category": category,
            "title": text
        ]

        return try await toolService.executeTool(name: "record_expense", parameters: params, userId: userId)
    }

    private func recordEmotionFromText(_ text: String, userId: String) async throws -> ToolResult {
        // 检测情绪分数
        let score: Double
        if text.contains("不好") || text.contains("难过") || text.contains("压力") {
            score = -0.5
        } else if text.contains("开心") || text.contains("高兴") {
            score = 0.7
        } else {
            score = 0.0
        }

        let trigger = text.contains("工作") ? "工作压力" : (text.contains("论文") ? "论文截止" : nil)

        let params: [String: Any] = [
            "score": score,
            "trigger": trigger as Any,
            "note": text
        ]

        return try await toolService.executeTool(name: "record_emotion", parameters: params, userId: userId)
    }
}

// MARK: - Supporting Types

/// 意图类型
enum Intent: String {
    case createGoal = "create_goal"
    case createHabit = "create_habit"
    case recordExpense = "record_expense"
    case recordEmotion = "record_emotion"
    case analyzeData = "analyze_data"
    case general = "general"
}

/// 对话结果
struct ConversationResult {
    let message: String
    let toolUsed: String?
    let success: Bool
    let data: [String: Any]?
}
