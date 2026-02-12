import Foundation
import EventKit

/// Planner Agent - 智能日程规划（使用 Nova 2 Lite）
class PlannerAgent {
    static let shared = PlannerAgent()

    private let bedrock: BedrockService
    private let contextEngine: ContextEngine
    private let eventKit: EventKitService

    private init() {
        self.bedrock = BedrockService.shared
        self.contextEngine = ContextEngine.shared
        self.eventKit = EventKitService.shared
    }

    // MARK: - 主要接口

    /// 规划目标（自然语言输入）
    func plan(
        goal: String,
        userId: String
    ) async throws -> PlanResult {

        print("🎯 开始规划: \(goal)")

        // 1. 加载用户完整上下文
        let context = try await contextEngine.loadContext(userId: userId)
        print("   ✅ Context loaded")

        // 2. 获取现有日程（避免冲突）
        let existingEvents = try await eventKit.fetchUpcomingEvents(days: 14)
        print("   ✅ Loaded \(existingEvents.count) existing events")

        // 3. 构建 AI Prompt
        let prompt = buildPlanningPrompt(
            goal: goal,
            context: context,
            existingEvents: existingEvents
        )

        // 4. 调用 Nova 2 Lite
        let response = try await bedrock.invokeWithRetry(
            prompt: prompt,
            model: .lite,
            maxRetries: 3
        )
        print("   ✅ Nova response received")

        // 5. 解析响应
        let plan = try parsePlan(from: response, userId: userId)
        print("   ✅ Plan parsed: \(plan.events.count) events")

        return plan
    }

    // MARK: - Prompt 构建

    /// 构建规划 Prompt
    private func buildPlanningPrompt(
        goal: String,
        context: UserContext,
        existingEvents: [EKEvent]
    ) -> String {

        // 格式化现有事件
        let eventsDesc = existingEvents.prefix(10).map { event in
            let start = event.startDate.formatted(.dateTime.month().day().hour().minute())
            let end = event.endDate.formatted(.dateTime.hour().minute())
            return "• \(start)-\(end): \(event.title)"
        }.joined(separator: "\n")

        let prompt = """
        你是 NovaLife Weaver，一个专业的时间管理和目标规划助手。

        === 用户画像 ===
        姓名：\(context.user.name)
        时区：\(context.user.timezone)
        活跃目标：\(context.activeGoals.count) 个
        活跃习惯：\(context.activeHabits.count) 个
        近期情绪：\(String(format: "%.1f", context.averageEmotion))/10 \(context.isStressed ? "(压力较大)" : "(状态良好)")

        === 当前活跃目标 ===
        \(context.activeGoals.prefix(3).map { "• \($0.title): \($0.progressPercentage)%" }.joined(separator: "\n"))

        === 现有日程（未来 14 天）===
        \(eventsDesc.isEmpty ? "（无）" : eventsDesc)

        === 新目标 ===
        用户输入："\(goal)"

        === 任务要求 ===

        请基于以上信息，生成一个可执行的规划。要求：

        1. **目标分解**：
           - 将目标拆解为 SMART 子任务
           - 每个子任务有明确的时间安排
           - 考虑用户现有目标和习惯

        2. **时间安排**：
           - 避开现有日程冲突
           - 符合用户时区和作息习惯
           - 分布合理，不要集中在同一天

        3. **考虑因素**：
           - 用户当前情绪状态
           - 已有目标的优先级
           - 习惯养成的可行性

        4. **输出格式**（严格 JSON）：
        ```json
        {
            "goal_analysis": {
                "title": "目标标题",
                "category": "learning|health|finance|career|personal",
                "deadline": "YYYY-MM-DD",
                "estimated_effort": "小时数",
                "priority": 1-5
            },
            "subtasks": [
                {
                    "title": "子任务标题",
                    "description": "详细描述",
                    "deadline": "YYYY-MM-DD",
                    "estimated_time": 60
                }
            ],
            "events": [
                {
                    "title": "事件标题",
                    "start_time": "YYYY-MM-DD HH:MM",
                    "duration": 60,
                    "location": "地点（可选）",
                    "notes": "AI 建议理由"
                }
            ],
            "related_habits": [
                {
                    "name": "习惯名称",
                    "frequency": "daily|weekly",
                    "suggested_time": "HH:MM"
                }
            ],
            "budget_estimate": 10000,
            "insights": "为什么这样规划的理由",
            "confidence": 0.0-1.0
        }
        ```

        请开始规划！
        """

        return prompt
    }

    // MARK: - 响应解析

    /// 解析规划结果
    private func parsePlan(
        from response: String,
        userId: String
    ) throws -> PlanResult {

        // 提取 JSON（处理 Markdown 代码块）
        let jsonString = extractJSON(from: response)

        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PlannerError.invalidJSON
        }

        // 解析目标分析
        var goalAnalysis: GoalAnalysis?
        if let analysisDict = json["goal_analysis"] as? [String: Any] {
            goalAnalysis = try parseGoalAnalysis(analysisDict)
        }

        // 解析事件
        var events: [Event] = []
        if let eventsArray = json["events"] as? [[String: Any]] {
            for eventDict in eventsArray {
                if let event = try? parseEvent(eventDict, userId: userId) {
                    events.append(event)
                }
            }
        }

        // 解析子任务
        var subtasks: [Subtask] = []
        if let subtasksArray = json["subtasks"] as? [[String: Any]] {
            for taskDict in subtasksArray {
                if let subtask = try? parseSubtask(taskDict) {
                    subtasks.append(subtask)
                }
            }
        }

        // 解析建议的习惯
        var suggestedHabits: [SuggestedHabit] = []
        if let habitsArray = json["related_habits"] as? [[String: Any]] {
            for habitDict in habitsArray {
                if let habit = try? parseSuggestedHabit(habitDict) {
                    suggestedHabits.append(habit)
                }
            }
        }

        let budgetEstimate = json["budget_estimate"] as? Double
        let insights = json["insights"] as? String
        let confidence = json["confidence"] as? Double ?? 0.8

        return PlanResult(
            goalAnalysis: goalAnalysis,
            events: events,
            subtasks: subtasks,
            suggestedHabits: suggestedHabits,
            budgetEstimate: budgetEstimate,
            insights: insights,
            confidence: confidence
        )
    }

    /// 提取 JSON 字符串
    private func extractJSON(from response: String) -> String {
        // 如果响应包含 ```json ... ``` 代码块
        if let jsonRange = response.range(of: "```json\\s*(.+?)```", options: .regularExpression) {
            let jsonBlock = String(response[jsonRange])
            return jsonBlock
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // 尝试查找 {...} 模式
        if let startIndex = response.firstIndex(of: "{"),
           let endIndex = response.lastIndex(of: "}") {
            return String(response[startIndex...endIndex])
        }

        return response
    }

    /// 解析目标分析
    private func parseGoalAnalysis(_ dict: [String: Any]) throws -> GoalAnalysis {
        let title = dict["title"] as? String ?? ""
        let category = dict["category"] as? String ?? "personal"
        let deadlineStr = dict["deadline"] as? String
        let effort = dict["estimated_effort"] as? String
        let priority = dict["priority"] as? Int ?? 3

        var deadline: Date?
        if let deadlineStr = deadlineStr {
            let formatter = ISO8601DateFormatter()
            deadline = formatter.date(from: deadlineStr + "T23:59:59Z")
        }

        return GoalAnalysis(
            title: title,
            category: category,
            deadline: deadline,
            estimatedEffort: effort,
            priority: priority
        )
    }

    /// 解析事件
    private func parseEvent(_ dict: [String: Any], userId: String) throws -> Event {
        guard let title = dict["title"] as? String,
              let startTimeStr = dict["start_time"] as? String else {
            throw PlannerError.invalidEventData
        }

        let formatter = ISO8601DateFormatter()
        guard let startTime = formatter.date(from: startTimeStr.replacingOccurrences(of: " ", with: "T") + ":00Z") else {
            throw PlannerError.invalidDateFormat
        }

        let duration = dict["duration"] as? Int ?? 60
        let endTime = startTime.addingTimeInterval(TimeInterval(duration * 60))

        return Event(
            userId: userId,
            title: title,
            description: dict["notes"] as? String,
            location: dict["location"] as? String,
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            source: .planner,
            suggestedByAI: true,
            aiReasoning: dict["notes"] as? String
        )
    }

    /// 解析子任务
    private func parseSubtask(_ dict: [String: Any]) throws -> Subtask {
        guard let title = dict["title"] as? String else {
            throw PlannerError.invalidSubtaskData
        }

        var deadline: Date?
        if let deadlineStr = dict["deadline"] as? String {
            let formatter = ISO8601DateFormatter()
            deadline = formatter.date(from: deadlineStr + "T23:59:59Z")
        }

        return Subtask(
            title: title,
            completed: false,
            deadline: deadline
        )
    }

    /// 解析建议的习惯
    private func parseSuggestedHabit(_ dict: [String: Any]) throws -> SuggestedHabit {
        guard let name = dict["name"] as? String else {
            throw PlannerError.invalidHabitData
        }

        let frequency = dict["frequency"] as? String ?? "daily"
        let suggestedTime = dict["suggested_time"] as? String

        return SuggestedHabit(
            name: name,
            frequency: frequency,
            suggestedTime: suggestedTime
        )
    }
}

// MARK: - 数据结构

/// 规划结果
struct PlanResult {
    let goalAnalysis: GoalAnalysis?
    let events: [Event]
    let subtasks: [Subtask]
    let suggestedHabits: [SuggestedHabit]
    let budgetEstimate: Double?
    let insights: String?
    let confidence: Double
}

/// 目标分析
struct GoalAnalysis {
    let title: String
    let category: String
    let deadline: Date?
    let estimatedEffort: String?
    let priority: Int
}

/// 建议的习惯
struct SuggestedHabit {
    let name: String
    let frequency: String
    let suggestedTime: String?
}

/// Planner 错误类型
enum PlannerError: Error {
    case invalidJSON
    case invalidEventData
    case invalidSubtaskData
    case invalidHabitData
    case invalidDateFormat
    case contextLoadFailed

    var localizedDescription: String {
        switch self {
        case .invalidJSON:
            return "无法解析 AI 响应"
        case .invalidEventData:
            return "事件数据格式错误"
        case .invalidSubtaskData:
            return "子任务数据格式错误"
        case .invalidHabitData:
            return "习惯数据格式错误"
        case .invalidDateFormat:
            return "日期格式错误"
        case .contextLoadFailed:
            return "加载用户上下文失败"
        }
    }
}
