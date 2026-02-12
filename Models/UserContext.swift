import Foundation

/// 用户全局上下文 - Context Engine 的核心数据结构
/// 聚合用户所有相关数据，支持全方位 AI 分析
struct UserContext: Codable {
    // MARK: - 用户画像
    let user: User

    // MARK: - 目标数据
    let activeGoals: [Goal]
    let completedGoalsCount: Int
    let goalCompletionRate: Double

    // MARK: - 习惯数据
    let activeHabits: [Habit]
    let todayHabitCompletions: [HabitCompletion]
    let streakStatus: [String: Int]        // habit_id -> streak
    let habitSuccessRate: Double

    // MARK: - 财务数据
    let currentBudget: Budget?
    let recentFinancials: [FinancialRecord]  // 最近 30 天
    let categorySpending: [String: Double]
    let budgetAlerts: [BudgetAlert]

    // MARK: - 情绪数据
    let recentEmotions: [EmotionRecord]      // 最近 7 天
    let averageEmotion: Double
    let stressTriggers: [String]
    let emotionTrend: EmotionTrend

    // MARK: - 日程数据
    let upcomingEvents: [Event]              // 未来 14 天
    let todaySchedule: [Event]
    let conflictingEvents: [(Event, Event)]

    // MARK: - AI 洞察
    let recentInsights: [Insight]            // 最新 5 条
    let urgentInsights: [Insight]
    let correlations: [Correlation]          // 发现的关联

    // MARK: - 统计摘要
    let summary: ContextSummary

    // MARK: - 加载时间戳
    let loadedAt: Date

    // MARK: - 初始化
    init(
        user: User,
        activeGoals: [Goal],
        completedGoalsCount: Int,
        goalCompletionRate: Double,
        activeHabits: [Habit],
        todayHabitCompletions: [HabitCompletion],
        streakStatus: [String: Int],
        habitSuccessRate: Double,
        currentBudget: Budget?,
        recentFinancials: [FinancialRecord],
        categorySpending: [String: Double],
        budgetAlerts: [BudgetAlert],
        recentEmotions: [EmotionRecord],
        averageEmotion: Double,
        stressTriggers: [String],
        emotionTrend: EmotionTrend,
        upcomingEvents: [Event],
        todaySchedule: [Event],
        conflictingEvents: [(Event, Event)],
        recentInsights: [Insight],
        urgentInsights: [Insight],
        correlations: [Correlation],
        summary: ContextSummary,
        loadedAt: Date = Date()
    ) {
        self.user = user
        self.activeGoals = activeGoals
        self.completedGoalsCount = completedGoalsCount
        self.goalCompletionRate = goalCompletionRate
        self.activeHabits = activeHabits
        self.todayHabitCompletions = todayHabitCompletions
        self.streakStatus = streakStatus
        self.habitSuccessRate = habitSuccessRate
        self.currentBudget = currentBudget
        self.recentFinancials = recentFinancials
        self.categorySpending = categorySpending
        self.budgetAlerts = budgetAlerts
        self.recentEmotions = recentEmotions
        self.averageEmotion = averageEmotion
        self.stressTriggers = stressTriggers
        self.emotionTrend = emotionTrend
        self.upcomingEvents = upcomingEvents
        self.todaySchedule = todaySchedule
        self.conflictingEvents = conflictingEvents
        self.recentInsights = recentInsights
        self.urgentInsights = urgentInsights
        self.correlations = correlations
        self.summary = summary
        self.loadedAt = loadedAt
    }

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case user
        case activeGoals = "active_goals"
        case completedGoalsCount = "completed_goals_count"
        case goalCompletionRate = "goal_completion_rate"
        case activeHabits = "active_habits"
        case todayHabitCompletions = "today_habit_completions"
        case streakStatus = "streak_status"
        case habitSuccessRate = "habit_success_rate"
        case currentBudget = "current_budget"
        case recentFinancials = "recent_financials"
        case categorySpending = "category_spending"
        case budgetAlerts = "budget_alerts"
        case recentEmotions = "recent_emotions"
        case averageEmotion = "average_emotion"
        case stressTriggers = "stress_triggers"
        case emotionTrend = "emotion_trend"
        case upcomingEvents = "upcoming_events"
        case todaySchedule = "today_schedule"
        case conflictingEvents = "conflicting_events"
        case recentInsights = "recent_insights"
        case urgentInsights = "urgent_insights"
        case correlations
        case summary
        case loadedAt = "loaded_at"
    }
}

// MARK: - 业务逻辑扩展
extension UserContext {
    /// 是否处于压力状态
    var isStressed: Bool {
        averageEmotion < -0.3 || !stressTriggers.isEmpty
    }

    /// 是否有紧急事项
    var hasUrgentMatters: Bool {
        !urgentInsights.isEmpty || !budgetAlerts.isEmpty
    }

    /// 今日待办数量
    var todayTodoCount: Int {
        todaySchedule.filter { !$0.completed }.count
    }

    /// 今日习惯完成率
    var todayHabitCompletionRate: Double {
        guard !activeHabits.isEmpty else { return 0 }
        return Double(todayHabitCompletions.count) / Double(activeHabits.count)
    }

    /// 生成简短摘要文本
    func generateBriefSummary() -> String {
        var parts: [String] = []

        // 目标进度
        if !activeGoals.isEmpty {
            parts.append("\(activeGoals.count) 个活跃目标")
        }

        // 习惯状态
        if !activeHabits.isEmpty {
            let streaking = activeHabits.filter { $0.streak > 0 }.count
            parts.append("\(streaking) 个习惯连续中")
        }

        // 情绪状态
        if averageEmotion > 0.3 {
            parts.append("情绪良好 😊")
        } else if averageEmotion < -0.3 {
            parts.append("压力较大 😔")
        }

        // 预算状态
        if let budget = currentBudget, budget.shouldAlert {
            parts.append("预算预警 ⚠️")
        }

        return parts.joined(separator: " | ")
    }
}

// MARK: - 辅助结构

/// 上下文摘要
struct ContextSummary: Codable {
    var totalGoals: Int
    var completedGoals: Int
    var activeHabits: Int
    var totalSpending: Double
    var averageEmotion: Double
    var upcomingEventsCount: Int
    var urgentInsightsCount: Int
    var significantCorrelations: Int

    init(
        totalGoals: Int = 0,
        completedGoals: Int = 0,
        activeHabits: Int = 0,
        totalSpending: Double = 0,
        averageEmotion: Double = 0,
        upcomingEventsCount: Int = 0,
        urgentInsightsCount: Int = 0,
        significantCorrelations: Int = 0
    ) {
        self.totalGoals = totalGoals
        self.completedGoals = completedGoals
        self.activeHabits = activeHabits
        self.totalSpending = totalSpending
        self.averageEmotion = averageEmotion
        self.upcomingEventsCount = upcomingEventsCount
        self.urgentInsightsCount = urgentInsightsCount
        self.significantCorrelations = significantCorrelations
    }

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case totalGoals = "total_goals"
        case completedGoals = "completed_goals"
        case activeHabits = "active_habits"
        case totalSpending = "total_spending"
        case averageEmotion = "average_emotion"
        case upcomingEventsCount = "upcoming_events_count"
        case urgentInsightsCount = "urgent_insights_count"
        case significantCorrelations = "significant_correlations"
    }
}

/// 预算预警
struct BudgetAlert: Codable {
    var category: String
    var usageRate: Double
    var threshold: Double
    var message: String
}

/// 情绪趋势
enum EmotionTrend: String, Codable {
    case improving      // 改善中
    case stable         // 稳定
    case declining      // 下降中
    case volatile       // 波动
}
