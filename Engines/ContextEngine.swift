import Foundation

/// Context Engine - 全局上下文加载引擎（核心创新）
/// 目标：<100ms 加载完整用户上下文
class ContextEngine {
    static let shared = ContextEngine()

    private let db: DatabaseService
    private var cache: [String: CachedContext] = [:]
    private let cacheExpiration: TimeInterval = 300 // 5 分钟缓存

    private init() {
        self.db = DatabaseService.shared
    }

    // MARK: - 主要接口

    /// 加载用户全局上下文（<100ms 目标）
    func loadContext(userId: String) async throws -> UserContext {
        let startTime = Date()

        // 检查缓存
        if let cached = cache[userId],
           Date().timeIntervalSince(cached.timestamp) < cacheExpiration {
            print("✅ Context loaded from cache in <1ms")
            return cached.context
        }

        // 并行加载所有数据
        async let user = loadUser(userId)
        async let goalData = loadGoalData(userId)
        async let habitData = loadHabitData(userId)
        async let financialData = loadFinancialData(userId)
        async let emotionData = loadEmotionData(userId)
        async let eventData = loadEventData(userId)
        async let insightData = loadInsightData(userId)
        async let correlations = loadCorrelations(userId)

        // 等待所有数据加载完成
        let context = try await UserContext(
            user: user,
            activeGoals: goalData.goals,
            completedGoalsCount: goalData.completedCount,
            goalCompletionRate: goalData.completionRate,
            activeHabits: habitData.habits,
            todayHabitCompletions: habitData.todayCompletions,
            streakStatus: habitData.streakStatus,
            habitSuccessRate: habitData.successRate,
            currentBudget: financialData.budget,
            recentFinancials: financialData.records,
            categorySpending: financialData.categorySpending,
            budgetAlerts: financialData.alerts,
            recentEmotions: emotionData.records,
            averageEmotion: emotionData.average,
            stressTriggers: emotionData.triggers,
            emotionTrend: emotionData.trend,
            upcomingEvents: eventData.upcoming,
            todaySchedule: eventData.today,
            conflictingEvents: eventData.conflicts,
            recentInsights: insightData.insights,
            urgentInsights: insightData.urgent,
            correlations: correlations,
            summary: ContextSummary(
                totalGoals: goalData.totalCount,
                completedGoals: goalData.completedCount,
                activeHabits: habitData.habits.count,
                totalSpending: financialData.totalSpent,
                averageEmotion: emotionData.average,
                upcomingEventsCount: eventData.upcoming.count,
                urgentInsightsCount: insightData.urgent.count,
                significantCorrelations: correlations.filter { $0.isSignificant }.count
            )
        )

        // 缓存结果
        cache[userId] = CachedContext(context: context, timestamp: Date())

        let loadTime = Date().timeIntervalSince(startTime) * 1000 // ms
        print("✅ Context loaded in \(String(format: "%.1f", loadTime))ms")

        return context
    }

    /// 清除缓存（数据更新后调用）
    func invalidateCache(userId: String) {
        cache.removeValue(forKey: userId)
    }

    /// 清除所有缓存
    func clearAllCache() {
        cache.removeAll()
    }

    // MARK: - 私有加载方法

    /// 加载用户信息
    private func loadUser(_ userId: String) async throws -> User {
        // TODO: 从数据库加载
        // 临时返回模拟数据
        return User(
            id: userId,
            name: "李鴻敏",
            timezone: "Asia/Tokyo",
            language: "zh-CN"
        )
    }

    /// 加载目标数据
    private func loadGoalData(_ userId: String) async throws -> GoalData {
        // TODO: 实现数据库查询
        // async let activeGoals = db.fetchActiveGoals(userId)
        // async let completedCount = db.countCompletedGoals(userId)
        // async let totalCount = db.countTotalGoals(userId)

        // 临时返回空数据
        return GoalData(
            goals: [],
            completedCount: 0,
            totalCount: 0,
            completionRate: 0.0
        )
    }

    /// 加载习惯数据
    private func loadHabitData(_ userId: String) async throws -> HabitData {
        // TODO: 实现数据库查询
        return HabitData(
            habits: [],
            todayCompletions: [],
            streakStatus: [:],
            successRate: 0.0
        )
    }

    /// 加载财务数据
    private func loadFinancialData(_ userId: String) async throws -> FinancialData {
        // TODO: 实现数据库查询
        // async let budget = db.fetchCurrentBudget(userId)
        // async let records = db.fetchRecentFinancials(userId, days: 30)

        return FinancialData(
            budget: nil,
            records: [],
            categorySpending: [:],
            alerts: [],
            totalSpent: 0
        )
    }

    /// 加载情绪数据
    private func loadEmotionData(_ userId: String) async throws -> EmotionData {
        // TODO: 实现数据库查询
        // async let records = db.fetchRecentEmotions(userId, days: 7)

        return EmotionData(
            records: [],
            average: 0.0,
            triggers: [],
            trend: .stable
        )
    }

    /// 加载事件数据
    private func loadEventData(_ userId: String) async throws -> EventData {
        // TODO: 实现数据库查询和 EventKit 集成
        // async let dbEvents = db.fetchUpcomingEvents(userId, days: 14)
        // async let calendarEvents = eventKitService.fetchUpcomingEvents(days: 14)

        return EventData(
            upcoming: [],
            today: [],
            conflicts: []
        )
    }

    /// 加载洞察数据
    private func loadInsightData(_ userId: String) async throws -> InsightData {
        // TODO: 实现数据库查询
        return InsightData(
            insights: [],
            urgent: []
        )
    }

    /// 加载关联数据
    private func loadCorrelations(_ userId: String) async throws -> [Correlation] {
        // TODO: 实现数据库查询
        return []
    }
}

// MARK: - 私有数据结构

private struct CachedContext {
    let context: UserContext
    let timestamp: Date
}

private struct GoalData {
    let goals: [Goal]
    let completedCount: Int
    let totalCount: Int
    let completionRate: Double
}

private struct HabitData {
    let habits: [Habit]
    let todayCompletions: [HabitCompletion]
    let streakStatus: [String: Int]
    let successRate: Double
}

private struct FinancialData {
    let budget: Budget?
    let records: [FinancialRecord]
    let categorySpending: [String: Double]
    let alerts: [BudgetAlert]
    let totalSpent: Double
}

private struct EmotionData {
    let records: [EmotionRecord]
    let average: Double
    let triggers: [String]
    let trend: EmotionTrend
}

private struct EventData {
    let upcoming: [Event]
    let today: [Event]
    let conflicts: [(Event, Event)]
}

private struct InsightData {
    let insights: [Insight]
    let urgent: [Insight]
}

// MARK: - 性能监控扩展
extension ContextEngine {
    /// 性能基准测试
    func benchmarkPerformance(userId: String, iterations: Int = 10) async {
        var times: [Double] = []

        for i in 1...iterations {
            let start = Date()

            do {
                _ = try await loadContext(userId: userId)
                let elapsed = Date().timeIntervalSince(start) * 1000
                times.append(elapsed)
                print("   Iteration \(i): \(String(format: "%.1f", elapsed))ms")
            } catch {
                print("   Iteration \(i): Failed - \(error)")
            }

            // 清除缓存以确保每次都是真实加载
            clearAllCache()

            // 短暂延迟
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        }

        if !times.isEmpty {
            let avg = times.reduce(0, +) / Double(times.count)
            let min = times.min() ?? 0
            let max = times.max() ?? 0

            print("\n📊 性能统计：")
            print("   平均: \(String(format: "%.1f", avg))ms")
            print("   最快: \(String(format: "%.1f", min))ms")
            print("   最慢: \(String(format: "%.1f", max))ms")
            print("   目标: <100ms \(avg < 100 ? "✅" : "❌")")
        }
    }
}
