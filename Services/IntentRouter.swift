import Foundation

/// 意图路由器 - 分析用户输入并路由到对应的 Agent
/// 使用 Nova Lite 进行语义理解，结合关键词快速分类
class IntentRouter: IntentRouterProtocol {
    static let shared = IntentRouter()

    private let bedrock: BedrockService
    private let contextEngine: ContextEngine
    private let plannerAgent: PlannerAgent

    private init() {
        self.bedrock = BedrockService.shared
        self.contextEngine = ContextEngine.shared
        self.plannerAgent = PlannerAgent.shared
    }

    // MARK: - 主要接口

    /// 分析用户输入，识别意图类型
    func analyze(input: String) async throws -> UserIntent {
        print("🔍 开始意图分析: \(input)")

        // 1. 快速关键词匹配（降低 API 调用成本）
        if let quickIntent = quickMatch(input: input) {
            print("   ✅ 快速匹配: \(quickIntent)")
            return quickIntent
        }

        // 2. 使用 Nova Lite 进行语义理解
        let prompt = buildIntentPrompt(input: input)
        let response = try await bedrock.invokeWithRetry(
            prompt: prompt,
            model: .lite,
            maxRetries: 2
        )

        // 3. 解析意图
        let intent = try parseIntent(from: response, input: input)
        print("   ✅ AI 分析结果: \(intent)")

        return intent
    }

    /// 路由到对应的处理器
    func route(intent: UserIntent, context: UserContext) async throws -> IntentResult {
        print("🎯 路由意图: \(intent)")

        switch intent {
        case .createGoal(let goalText):
            return try await handleCreateGoal(goalText: goalText, context: context)

        case .createHabit(let habitText):
            return try await handleCreateHabit(habitText: habitText, context: context)

        case .recordEmotion(let emotionText):
            return try await handleRecordEmotion(emotionText: emotionText, context: context)

        case .recordExpense(let expenseText):
            return try await handleRecordExpense(expenseText: expenseText, context: context)

        case .queryStatus(let queryText):
            return try await handleQueryStatus(queryText: queryText, context: context)

        case .planSchedule(let scheduleText):
            return try await handlePlanSchedule(scheduleText: scheduleText, context: context)

        case .general(let message):
            return try await handleGeneral(message: message, context: context)
        }
    }

    // MARK: - 快速关键词匹配

    /// 快速关键词匹配（避免频繁调用 AI）
    private func quickMatch(input: String) -> UserIntent? {
        let lowercased = input.lowercased()

        // 目标相关
        let goalKeywords = ["我想", "目标", "计划学", "考试", "学习", "减肥", "健身", "赚钱", "存钱"]
        if goalKeywords.contains(where: { lowercased.contains($0) }) {
            return .createGoal(input)
        }

        // 习惯相关
        let habitKeywords = ["每天", "每周", "养成", "习惯", "坚持", "打卡"]
        if habitKeywords.contains(where: { lowercased.contains($0) }) {
            return .createHabit(input)
        }

        // 情绪相关
        let emotionKeywords = ["今天", "心情", "开心", "难过", "焦虑", "压力", "累", "疲惫", "紧张", "兴奋"]
        if emotionKeywords.contains(where: { lowercased.contains($0) })
            && !lowercased.contains("花了")
            && !lowercased.contains("买了") {
            return .recordEmotion(input)
        }

        // 花费相关
        let expenseKeywords = ["花了", "买了", "消费", "支出", "购物", "¥", "元", "块"]
        if expenseKeywords.contains(where: { lowercased.contains($0) }) {
            return .recordExpense(input)
        }

        // 查询相关
        let queryKeywords = ["如何", "怎么", "进度", "完成", "统计", "查看", "显示"]
        if queryKeywords.contains(where: { lowercased.contains($0) }) {
            return .queryStatus(input)
        }

        // 规划相关
        let planKeywords = ["帮我安排", "规划", "时间表", "日程", "本周", "明天"]
        if planKeywords.contains(where: { lowercased.contains($0) }) {
            return .planSchedule(input)
        }

        return nil
    }

    // MARK: - AI 意图识别

    /// 构建意图识别 Prompt
    private func buildIntentPrompt(input: String) -> String {
        return """
        你是 NovaLife Weaver 的意图识别模块。请分析用户输入，判断意图类型。

        === 可识别的意图类型 ===

        1. **create_goal**: 创建目标
           - 示例："我想考 JLPT N2"、"减肥到 60kg"、"学会做饭"

        2. **create_habit**: 创建习惯
           - 示例："每天跑步"、"每周读一本书"、"养成早睡习惯"

        3. **record_emotion**: 记录情绪
           - 示例："今天有点累"、"心情不错"、"压力很大"

        4. **record_expense**: 记录花费
           - 示例："午餐花了 800 円"、"买了一双鞋 5000"

        5. **query_status**: 查询状态
           - 示例："我的目标进度如何"、"今天完成了什么"

        6. **plan_schedule**: 规划日程
           - 示例："帮我安排本周"、"明天的计划"

        7. **general**: 一般对话
           - 示例："你好"、"谢谢"、"再见"

        === 用户输入 ===
        "\(input)"

        === 输出格式（严格 JSON）===
        ```json
        {
            "intent": "intent_type",
            "confidence": 0.0-1.0,
            "reasoning": "判断理由"
        }
        ```

        请开始分析！
        """
    }

    /// 解析意图分析结果
    private func parseIntent(from response: String, input: String) throws -> UserIntent {
        // 提取 JSON
        let jsonString = extractJSON(from: response)

        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let intentType = json["intent"] as? String else {
            throw IntentError.invalidResponse
        }

        // 映射到 UserIntent
        switch intentType {
        case "create_goal":
            return .createGoal(input)
        case "create_habit":
            return .createHabit(input)
        case "record_emotion":
            return .recordEmotion(input)
        case "record_expense":
            return .recordExpense(input)
        case "query_status":
            return .queryStatus(input)
        case "plan_schedule":
            return .planSchedule(input)
        default:
            return .general(input)
        }
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

    // MARK: - 意图处理器

    /// 处理创建目标
    private func handleCreateGoal(
        goalText: String,
        context: UserContext
    ) async throws -> IntentResult {

        // 调用 PlannerAgent 规划目标
        let plan = try await plannerAgent.plan(
            goal: goalText,
            userId: context.user.id
        )

        // 构建建议行动
        var actions: [SuggestedAction] = []

        // 添加子任务
        for subtask in plan.subtasks {
            actions.append(SuggestedAction(
                type: .addSubtask,
                title: subtask.title,
                data: ["deadline": subtask.deadline ?? Date()]
            ))
        }

        // 添加事件
        for event in plan.events {
            actions.append(SuggestedAction(
                type: .addEvent,
                title: event.title,
                data: [
                    "start_time": event.startTime,
                    "duration": event.duration
                ]
            ))
        }

        // 添加习惯
        for habit in plan.suggestedHabits {
            actions.append(SuggestedAction(
                type: .createHabit,
                title: habit.name,
                data: ["frequency": habit.frequency]
            ))
        }

        let message = """
        ✅ 已为您规划目标：\(plan.goalAnalysis?.title ?? goalText)

        📋 子任务：\(plan.subtasks.count) 个
        📅 日程：\(plan.events.count) 个
        🎯 建议习惯：\(plan.suggestedHabits.count) 个

        💡 AI 建议：\(plan.insights ?? "")
        """

        return IntentResult(
            success: true,
            message: message,
            actions: actions,
            dataUpdated: ["goals", "events", "habits"]
        )
    }

    /// 处理创建习惯
    private func handleCreateHabit(
        habitText: String,
        context: UserContext
    ) async throws -> IntentResult {

        // 使用 AI 解析习惯参数
        let prompt = """
        用户想创建习惯："\(habitText)"

        请提取以下信息（JSON 格式）：
        ```json
        {
            "name": "习惯名称",
            "frequency": "daily|weekly|custom",
            "target_days": 7,
            "suggested_time": "HH:MM"
        }
        ```
        """

        let response = try await bedrock.invokeNova(prompt: prompt, model: .lite)
        let json = try parseHabitData(from: response)

        let action = SuggestedAction(
            type: .createHabit,
            title: json["name"] as? String ?? habitText,
            data: json
        )

        return IntentResult(
            success: true,
            message: "✅ 习惯已创建：\(json["name"] as? String ?? habitText)",
            actions: [action],
            dataUpdated: ["habits"]
        )
    }

    /// 处理记录情绪
    private func handleRecordEmotion(
        emotionText: String,
        context: UserContext
    ) async throws -> IntentResult {

        // 使用 AI 分析情绪
        let prompt = """
        用户表达情绪："\(emotionText)"

        请分析情绪并输出（JSON 格式）：
        ```json
        {
            "score": 1-10,
            "mood": "开心|平静|焦虑|疲惫|压力",
            "triggers": ["触发因素1", "触发因素2"]
        }
        ```
        """

        let response = try await bedrock.invokeNova(prompt: prompt, model: .lite)
        let json = try parseEmotionData(from: response)

        let action = SuggestedAction(
            type: .recordEmotion,
            title: "记录情绪",
            data: json
        )

        return IntentResult(
            success: true,
            message: "✅ 已记录您的情绪",
            actions: [action],
            dataUpdated: ["emotions"]
        )
    }

    /// 处理记录花费
    private func handleRecordExpense(
        expenseText: String,
        context: UserContext
    ) async throws -> IntentResult {

        // 使用 AI 解析花费信息
        let prompt = """
        用户记录花费："\(expenseText)"

        请提取信息（JSON 格式）：
        ```json
        {
            "amount": 800,
            "currency": "JPY",
            "category": "餐饮|购物|交通|娱乐|其他",
            "item": "物品名称"
        }
        ```
        """

        let response = try await bedrock.invokeNova(prompt: prompt, model: .lite)
        let json = try parseExpenseData(from: response)

        let action = SuggestedAction(
            type: .recordExpense,
            title: "记录支出",
            data: json
        )

        // 检查是否超预算
        let amount = json["amount"] as? Double ?? 0
        let category = json["category"] as? String ?? "其他"
        let budgetWarning = checkBudget(amount: amount, category: category, context: context)

        var message = "✅ 已记录支出：\(amount) \(json["currency"] ?? "JPY")"
        if let warning = budgetWarning {
            message += "\n\n⚠️ \(warning)"
        }

        return IntentResult(
            success: true,
            message: message,
            actions: [action],
            dataUpdated: ["finances"]
        )
    }

    /// 处理查询状态
    private func handleQueryStatus(
        queryText: String,
        context: UserContext
    ) async throws -> IntentResult {

        // 生成状态摘要
        let summary = """
        📊 您的状态摘要：

        🎯 活跃目标：\(context.activeGoals.count) 个
        ✅ 已完成：\(context.activeGoals.filter { $0.status == "completed" }.count) 个

        🔄 活跃习惯：\(context.activeHabits.count) 个
        🔥 最长连续：\(context.activeHabits.map { $0.currentStreak }.max() ?? 0) 天

        💰 本月支出：\(String(format: "%.0f", context.totalExpenses)) 円

        😊 近期情绪：\(String(format: "%.1f", context.averageEmotion))/10
        """

        return IntentResult(
            success: true,
            message: summary,
            actions: nil,
            dataUpdated: nil
        )
    }

    /// 处理规划日程
    private func handlePlanSchedule(
        scheduleText: String,
        context: UserContext
    ) async throws -> IntentResult {

        // 调用 PlannerAgent
        let plan = try await plannerAgent.plan(
            goal: scheduleText,
            userId: context.user.id
        )

        var actions: [SuggestedAction] = []
        for event in plan.events {
            actions.append(SuggestedAction(
                type: .addEvent,
                title: event.title,
                data: [
                    "start_time": event.startTime,
                    "duration": event.duration
                ]
            ))
        }

        return IntentResult(
            success: true,
            message: "✅ 已为您规划 \(plan.events.count) 个日程",
            actions: actions,
            dataUpdated: ["events"]
        )
    }

    /// 处理一般对话
    private func handleGeneral(
        message: String,
        context: UserContext
    ) async throws -> IntentResult {

        // 使用 Nova 生成回复
        let prompt = """
        你是 NovaLife Weaver，一个友好的 AI 生活助手。

        用户说："\(message)"

        请简短回复（30 字以内）。
        """

        let response = try await bedrock.invokeNova(prompt: prompt, model: .lite)

        return IntentResult(
            success: true,
            message: response.trimmingCharacters(in: .whitespacesAndNewlines),
            actions: nil,
            dataUpdated: nil
        )
    }

    // MARK: - 辅助方法

    /// 解析习惯数据
    private func parseHabitData(from response: String) throws -> [String: Any] {
        let jsonString = extractJSON(from: response)
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw IntentError.invalidResponse
        }
        return json
    }

    /// 解析情绪数据
    private func parseEmotionData(from response: String) throws -> [String: Any] {
        let jsonString = extractJSON(from: response)
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw IntentError.invalidResponse
        }
        return json
    }

    /// 解析花费数据
    private func parseExpenseData(from response: String) throws -> [String: Any] {
        let jsonString = extractJSON(from: response)
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw IntentError.invalidResponse
        }
        return json
    }

    /// 检查预算
    private func checkBudget(
        amount: Double,
        category: String,
        context: UserContext
    ) -> String? {
        // TODO: 实现预算检查逻辑
        // 需要查询 budgets 表并对比当前月份的支出
        return nil
    }
}

// MARK: - 建议行动类型

/// 建议行动
struct SuggestedAction {
    enum ActionType {
        case addSubtask
        case addEvent
        case createHabit
        case recordEmotion
        case recordExpense
    }

    let type: ActionType
    let title: String
    let data: [String: Any]
}

// MARK: - 错误类型

enum IntentError: Error {
    case invalidResponse
    case parsingFailed
    case unsupportedIntent

    var localizedDescription: String {
        switch self {
        case .invalidResponse:
            return "无法解析 AI 响应"
        case .parsingFailed:
            return "意图解析失败"
        case .unsupportedIntent:
            return "不支持的意图类型"
        }
    }
}
