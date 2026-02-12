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
        async let eventData = loadContextEventData(userId)
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
            conflictingEvents: eventData.conflicts.map { EventConflict(event1: $0.0, event2: $0.1) },
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
        return try await db.fetchUser(userId)
    }

    /// 加载目标数据
    private func loadGoalData(_ userId: String) async throws -> GoalData {
        // 并行加载目标数据
        async let activeGoals = db.fetchActiveGoals(userId: userId)
        async let completedCount = db.countCompletedGoals(userId: userId)
        async let totalCount = db.countTotalGoals(userId: userId)

        let goals = try await activeGoals
        let completed = try await completedCount
        let total = try await totalCount

        let rate = total > 0 ? Double(completed) / Double(total) : 0.0

        return GoalData(
            goals: goals,
            completedCount: completed,
            totalCount: total,
            completionRate: rate
        )
    }

    /// 加载习惯数据
    private func loadHabitData(_ userId: String) async throws -> HabitData {
        // 并行加载习惯数据
        async let activeHabits = db.fetchActiveHabits(userId: userId)
        async let todayCompletions = db.fetchTodayCompletions(userId: userId)

        let habits = try await activeHabits
        let completions = try await todayCompletions

        // 构建今日连续状态
        var streakStatus: [String: Int] = [:]
        for habit in habits {
            streakStatus[habit.id] = habit.streak
        }

        // 计算总体成功率
        let totalRate = habits.isEmpty ? 0.0 : habits.reduce(0.0) { $0 + $1.successRate } / Double(habits.count)

        return HabitData(
            habits: habits,
            todayCompletions: completions,
            streakStatus: streakStatus,
            successRate: totalRate
        )
    }

    /// 加载财务数据
    private func loadFinancialData(_ userId: String) async throws -> FinancialData {
        // 并行加载财务数据
        async let budget = db.fetchCurrentBudget(userId: userId)
        async let records = db.fetchRecentFinancials(userId: userId, days: 30)

        let currentBudget = try await budget
        let financialRecords = try await records

        // 计算分类支出
        let now = Date()
        let monthStart = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        let categorySpending = try await db.calculateCategorySpending(userId: userId, from: monthStart, to: now)

        // 计算总支出
        let totalSpent = financialRecords.reduce(0.0) { $0 + $1.amount }

        // 生成预算警告
        var alerts: [BudgetAlert] = []
        if let budget = currentBudget {
            let usageRate = totalSpent / budget.totalBudget
            if usageRate >= budget.alertThreshold {
                let percentage = usageRate * 100
                alerts.append(BudgetAlert(
                    category: "总预算",
                    usageRate: usageRate,
                    threshold: budget.alertThreshold,
                    message: String(format: "已使用 %.0f%% 预算 (¥%.0f / ¥%.0f)", percentage, totalSpent, budget.totalBudget)
                ))
            }

            // 检查各分类预算
            if let categoryBudgets = budget.categoryBudgets {
                for (category, categoryBudget) in categoryBudgets {
                    let categorySpent = categorySpending[category] ?? 0
                    let categoryRate = categorySpent / categoryBudget
                    if categoryRate >= budget.alertThreshold {
                        let percentage = categoryRate * 100
                        alerts.append(BudgetAlert(
                            category: category,
                            usageRate: categoryRate,
                            threshold: budget.alertThreshold,
                            message: String(format: "%@ 已使用 %.0f%% 预算 (¥%.0f / ¥%.0f)", category, percentage, categorySpent, categoryBudget)
                        ))
                    }
                }
            }
        }

        return FinancialData(
            budget: currentBudget,
            records: financialRecords,
            categorySpending: categorySpending,
            alerts: alerts,
            totalSpent: totalSpent
        )
    }

    /// 加载情绪数据
    private func loadEmotionData(_ userId: String) async throws -> EmotionData {
        // 并行加载情绪数据
        async let records = db.fetchRecentEmotions(userId: userId, days: 7)
        async let average = db.calculateAverageEmotion(userId: userId, days: 7)

        let emotionRecords = try await records
        let avgScore = try await average

        // 提取触发因素（出现频率最高的前3个）
        let triggerFrequency = emotionRecords.reduce(into: [String: Int]()) { counts, record in
            if let trigger = record.trigger {
                counts[trigger, default: 0] += 1
            }
        }
        let triggers = triggerFrequency.sorted { $0.value > $1.value }.prefix(3).map { $0.key }

        // 计算趋势（对比最近3天和之前4天的平均值）
        let trend: EmotionTrend
        if emotionRecords.count >= 2 {
            let recentRecords = emotionRecords.prefix(3)
            let olderRecords = emotionRecords.dropFirst(3)

            let recentAvg = recentRecords.isEmpty ? 0.0 : recentRecords.reduce(0.0) { $0 + $1.score } / Double(recentRecords.count)
            let olderAvg = olderRecords.isEmpty ? 0.0 : olderRecords.reduce(0.0) { $0 + $1.score } / Double(olderRecords.count)

            let diff = recentAvg - olderAvg
            if diff > 0.1 {
                trend = .improving
            } else if diff < -0.1 {
                trend = .declining
            } else {
                trend = .stable
            }
        } else {
            trend = .stable
        }

        return EmotionData(
            records: emotionRecords,
            average: avgScore,
            triggers: triggers,
            trend: trend
        )
    }

    /// 加载事件数据
    private func loadContextEventData(_ userId: String) async throws -> ContextEventData {
        // 加载未来14天的事件
        let upcomingEvents = try await db.fetchUpcomingEvents(userId: userId, days: 14)

        // 筛选今日事件
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        let todayEvents = upcomingEvents.filter { event in
            event.startTime >= today && event.startTime < tomorrow
        }

        // 检测时间冲突（两个事件时间重叠）
        var conflicts: [(Event, Event)] = []
        for i in 0..<upcomingEvents.count {
            for j in (i+1)..<upcomingEvents.count {
                let event1 = upcomingEvents[i]
                let event2 = upcomingEvents[j]

                // 检查时间是否重叠
                if let end1 = event1.endTime {
                    if event2.startTime < end1 && event1.startTime < (event2.endTime ?? event2.startTime.addingTimeInterval(3600)) {
                        conflicts.append((event1, event2))
                    }
                }
            }
        }

        return ContextEventData(
            upcoming: upcomingEvents,
            today: todayEvents,
            conflicts: conflicts
        )
    }

    /// 加载洞察数据
    private func loadInsightData(_ userId: String) async throws -> InsightData {
        // 并行加载洞察数据
        async let insights = db.fetchInsights(userId: userId, limit: 10)
        async let urgent = db.fetchUrgentInsights(userId: userId)

        let allInsights = try await insights
        let urgentInsights = try await urgent

        return InsightData(
            insights: allInsights,
            urgent: urgentInsights
        )
    }

    /// 加载关联数据
    private func loadCorrelations(_ userId: String) async throws -> [Correlation] {
        return try await db.fetchCorrelations(userId: userId)
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

private struct ContextEventData {
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
