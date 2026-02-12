import Foundation

/// Tool Use 服务 - AI 可调用的工具系统
class ToolUseService {
    static let shared = ToolUseService()

    private let db = DatabaseService.shared

    private init() {}

    // MARK: - 工具定义（提供给 AI 的 Schema）

    /// 获取所有可用工具的定义
    func getToolDefinitions() -> [[String: Any]] {
        return [
            createGoalTool,
            createHabitTool,
            recordExpenseTool,
            recordEmotionTool,
            analyzeCorrelationTool
        ]
    }

    // MARK: - Tool Schemas

    private var createGoalTool: [String: Any] {
        [
            "name": "create_goal",
            "description": "创建一个新的目标。将用户的目标想法转化为SMART目标并保存到数据库。",
            "input_schema": [
                "type": "object",
                "properties": [
                    "title": [
                        "type": "string",
                        "description": "目标标题，简洁明确"
                    ],
                    "category": [
                        "type": "string",
                        "description": "目标类别：learning(学习), health(健康), finance(财务), career(职业), personal(个人)"
                    ],
                    "deadline": [
                        "type": "string",
                        "description": "截止日期，ISO 8601 格式，例如：2026-03-31"
                    ],
                    "targetValue": [
                        "type": "number",
                        "description": "目标值（如果可量化），例如：100(表示100%)"
                    ],
                    "priority": [
                        "type": "integer",
                        "description": "优先级 1-5，5最高"
                    ]
                ],
                "required": ["title", "category"]
            ]
        ]
    }

    private var createHabitTool: [String: Any] {
        [
            "name": "create_habit",
            "description": "创建一个新的习惯追踪项。帮助用户养成好习惯。",
            "input_schema": [
                "type": "object",
                "properties": [
                    "name": [
                        "type": "string",
                        "description": "习惯名称，例如：晨跑、读书30分钟"
                    ],
                    "category": [
                        "type": "string",
                        "description": "习惯类别：health(健康), learning(学习), productivity(效率), social(社交)"
                    ],
                    "frequency": [
                        "type": "string",
                        "description": "频率：daily(每天), weekly(每周), custom(自定义)"
                    ],
                    "targetCount": [
                        "type": "integer",
                        "description": "目标次数（每周或每月）"
                    ]
                ],
                "required": ["name", "category", "frequency"]
            ]
        ]
    }

    private var recordExpenseTool: [String: Any] {
        [
            "name": "record_expense",
            "description": "记录一笔支出。会自动关联情绪以进行关联分析。",
            "input_schema": [
                "type": "object",
                "properties": [
                    "amount": [
                        "type": "number",
                        "description": "金额，数字"
                    ],
                    "category": [
                        "type": "string",
                        "description": "分类：food(食品), transport(交通), shopping(购物), entertainment(娱乐), education(教育), other(其他)"
                    ],
                    "title": [
                        "type": "string",
                        "description": "简短描述，例如：午餐、地铁"
                    ],
                    "mood": [
                        "type": "number",
                        "description": "购买时的心情，-1.0(很难过)到1.0(很开心)"
                    ]
                ],
                "required": ["amount", "category"]
            ]
        ]
    }

    private var recordEmotionTool: [String: Any] {
        [
            "name": "record_emotion",
            "description": "记录当前的情绪状态。用于情绪追踪和关联分析。",
            "input_schema": [
                "type": "object",
                "properties": [
                    "score": [
                        "type": "number",
                        "description": "情绪分数，-1.0(很难过)到1.0(很开心)"
                    ],
                    "trigger": [
                        "type": "string",
                        "description": "触发因素，例如：工作压力、论文截止"
                    ],
                    "note": [
                        "type": "string",
                        "description": "详细记录（可选）"
                    ]
                ],
                "required": ["score"]
            ]
        ]
    }

    private var analyzeCorrelationTool: [String: Any] {
        [
            "name": "analyze_correlation",
            "description": "分析用户数据中的关联模式，例如情绪与消费的关系。需要足够的历史数据（至少30条记录）。",
            "input_schema": [
                "type": "object",
                "properties": [:],
                "required": []
            ]
        ]
    }

    // MARK: - 工具执行

    /// 执行工具调用
    func executeTool(name: String, parameters: [String: Any], userId: String) async throws -> ToolResult {
        print("🔧 执行工具：\(name)")
        print("📋 参数：\(parameters)")

        switch name {
        case "create_goal":
            return try await executeCreateGoal(parameters: parameters, userId: userId)

        case "create_habit":
            return try await executeCreateHabit(parameters: parameters, userId: userId)

        case "record_expense":
            return try await executeRecordExpense(parameters: parameters, userId: userId)

        case "record_emotion":
            return try await executeRecordEmotion(parameters: parameters, userId: userId)

        case "analyze_correlation":
            return try await executeAnalyzeCorrelation(userId: userId)

        default:
            throw ToolUseError.unknownTool(name)
        }
    }

    // MARK: - Tool Implementations

    private func executeCreateGoal(parameters: [String: Any], userId: String) async throws -> ToolResult {
        guard let title = parameters["title"] as? String,
              let category = parameters["category"] as? String else {
            throw ToolUseError.missingParameter("title or category")
        }

        let deadline: Date? = {
            if let dateStr = parameters["deadline"] as? String,
               let date = ISO8601DateFormatter().date(from: dateStr) {
                return date
            }
            return nil
        }()

        let goal = Goal(
            id: UUID().uuidString,
            userId: userId,
            title: title,
            description: nil,
            category: category,
            deadline: deadline,
            measurableMetric: nil,
            targetValue: parameters["targetValue"] as? Double ?? 100.0,
            currentValue: 0.0,
            status: GoalStatus.active,
            priority: parameters["priority"] as? Int ?? 3,
            subtasks: nil,
            relatedHabits: nil,
            budget: nil,
            aiSuggestions: nil,
            confidence: 0.8,
            createdAt: Date(),
            completedAt: nil,
            updatedAt: Date()
        )

        let goalId = try await db.createGoal(goal)

        return ToolResult(
            success: true,
            message: "✅ 已创建目标：\(title)",
            data: ["goalId": goalId, "goal": goal]
        )
    }

    private func executeCreateHabit(parameters: [String: Any], userId: String) async throws -> ToolResult {
        guard let name = parameters["name"] as? String,
              let category = parameters["category"] as? String,
              let frequencyStr = parameters["frequency"] as? String else {
            throw ToolUseError.missingParameter("name, category, or frequency")
        }

        let frequency: HabitFrequency = {
            switch frequencyStr.lowercased() {
            case "daily": return .daily
            case "weekly": return .weekly
            default: return .daily
            }
        }()

        let habit = Habit(
            id: UUID().uuidString,
            userId: userId,
            name: name,
            description: nil,
            category: category,
            frequency: frequency,
            targetCount: 1,
            status: HabitStatus.active,
            streak: 0,
            longestStreak: 0,
            totalCompletions: 0,
            successRate: 0.0,
            bestTime: nil,
            bestDay: nil,
            relatedGoals: nil,
            triggers: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        let habitId = try await db.createHabit(habit)

        return ToolResult(
            success: true,
            message: "✅ 已创建习惯：\(name)",
            data: ["habitId": habitId, "habit": habit]
        )
    }

    private func executeRecordExpense(parameters: [String: Any], userId: String) async throws -> ToolResult {
        guard let amount = parameters["amount"] as? Double,
              let category = parameters["category"] as? String else {
            throw ToolUseError.missingParameter("amount or category")
        }

        let record = FinancialRecord(
            userId: userId,
            amount: amount,
            category: category,
            title: parameters["title"] as? String,
            moodAtPurchase: parameters["mood"] as? Double
        )

        let recordId = try await db.createFinancialRecord(record)

        return ToolResult(
            success: true,
            message: "✅ 已记录支出：¥\(amount) - \(category)",
            data: ["recordId": recordId, "record": record]
        )
    }

    private func executeRecordEmotion(parameters: [String: Any], userId: String) async throws -> ToolResult {
        guard let score = parameters["score"] as? Double else {
            throw ToolUseError.missingParameter("score")
        }

        let record = EmotionRecord(
            id: UUID().uuidString,
            userId: userId,
            score: score,
            intensity: 0.7,
            emotions: [],
            trigger: parameters["trigger"] as? String,
            triggerDescription: nil,
            activity: nil,
            location: nil,
            weather: nil,
            voiceRecordingPath: nil,
            transcription: nil,
            photoPath: nil,
            note: parameters["note"] as? String,
            sentimentAnalysis: nil,
            recommendedActions: nil,
            recordedAt: Date(),
            createdAt: Date()
        )

        _ = try await db.createEmotionRecord(record)

        return ToolResult(
            success: true,
            message: "✅ 已记录情绪：\(score > 0 ? "😊" : "😔")",
            data: ["record": record]
        )
    }

    private func executeAnalyzeCorrelation(userId: String) async throws -> ToolResult {
        let correlationEngine = CorrelationEngine.shared
        let correlations = try await correlationEngine.analyzeCorrelations(userId: userId)

        return ToolResult(
            success: true,
            message: "✅ 已分析关联，发现 \(correlations.count) 个模式",
            data: ["correlations": correlations]
        )
    }
}

// MARK: - Supporting Types

/// 工具执行结果
struct ToolResult {
    let success: Bool
    let message: String
    let data: [String: Any]?

    init(success: Bool, message: String, data: [String: Any]? = nil) {
        self.success = success
        self.message = message
        self.data = data
    }
}

/// 工具使用错误
enum ToolUseError: Error, LocalizedError {
    case unknownTool(String)
    case missingParameter(String)
    case executionFailed(String)

    var errorDescription: String? {
        switch self {
        case .unknownTool(let name):
            return "未知工具：\(name)"
        case .missingParameter(let param):
            return "缺少必需参数：\(param)"
        case .executionFailed(let reason):
            return "执行失败：\(reason)"
        }
    }
}
