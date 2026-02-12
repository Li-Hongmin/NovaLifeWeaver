import Foundation

/// 测试 InsightEngine 功能
/// 验证洞察生成的正确性和优先级排序
class TestInsightEngine {

    /// 运行所有测试
    static func runTests() async {
        print("========================================")
        print("InsightEngine Tests")
        print("========================================\n")

        await testBasicInsightGeneration()
        await testPriorityScoring()
        await testBudgetWarnings()
        await testDeadlineReminders()
        await testPatternInsights()
        await testAchievements()
        await testRecommendations()

        print("\n========================================")
        print("All InsightEngine Tests Completed")
        print("========================================")
    }

    // MARK: - Test Cases

    /// 测试基础洞察生成
    static func testBasicInsightGeneration() async {
        print("Test 1: Basic Insight Generation")

        let context = createMockContext()
        let engine = InsightEngine.shared

        do {
            let insights = try await engine.generateInsights(context: context)

            print("✅ Generated \(insights.count) insights")

            // 验证洞察按优先级排序
            var lastScore = 1.0
            var sortedCorrectly = true
            for insight in insights {
                if insight.overallScore > lastScore {
                    sortedCorrectly = false
                    break
                }
                lastScore = insight.overallScore
            }

            print(sortedCorrectly ? "✅ Insights correctly sorted by priority" : "❌ Insights NOT sorted correctly")

            // 显示前 3 个洞察
            print("\nTop 3 Insights:")
            for (index, insight) in insights.prefix(3).enumerated() {
                print("  \(index + 1). [\(insight.type.rawValue)] \(insight.title)")
                print("     Priority: \(insight.priority), Urgency: \(String(format: "%.2f", insight.urgency)), Impact: \(String(format: "%.2f", insight.impact))")
                print("     Overall Score: \(String(format: "%.3f", insight.overallScore))")
            }

        } catch {
            print("❌ Error: \(error)")
        }

        print()
    }

    /// 测试优先级评分算法
    static func testPriorityScoring() async {
        print("Test 2: Priority Scoring Algorithm")

        let testCases: [(urgency: Double, impact: Double, confidence: Double, expectedPriority: Int)] = [
            (1.0, 1.0, 1.0, 5),      // 最高优先级
            (0.8, 0.8, 0.8, 4),      // 高优先级
            (0.5, 0.5, 0.5, 3),      // 中优先级
            (0.3, 0.3, 0.3, 2),      // 低优先级
            (0.1, 0.1, 0.1, 1),      // 最低优先级
        ]

        let engine = InsightEngine.shared
        var allPassed = true

        for (index, testCase) in testCases.enumerated() {
            let insight = Insight(
                userId: "test-user",
                type: .recommendation,
                category: .general,
                title: "Test Insight \(index + 1)",
                description: "Test",
                priority: 3, // 初始值，会被重新计算
                urgency: testCase.urgency,
                impact: testCase.impact,
                confidence: testCase.confidence
            )

            // 计算实际优先级
            let score = insight.overallScore
            let expectedScore = testCase.urgency * 0.4 + testCase.impact * 0.3 + testCase.confidence * 0.2 + Double(testCase.expectedPriority) / 5.0 * 0.1

            let passed = abs(score - expectedScore) < 0.01

            if !passed {
                allPassed = false
                print("❌ Test Case \(index + 1) FAILED:")
                print("   Expected score: \(String(format: "%.3f", expectedScore)), Got: \(String(format: "%.3f", score))")
            }
        }

        if allPassed {
            print("✅ All priority scoring tests passed")
        }

        print()
    }

    /// 测试预算警告
    static func testBudgetWarnings() async {
        print("Test 3: Budget Warning Insights")

        var context = createMockContext()

        // 添加预算警告
        context = UserContext(
            user: context.user,
            activeGoals: context.activeGoals,
            completedGoalsCount: context.completedGoalsCount,
            goalCompletionRate: context.goalCompletionRate,
            activeHabits: context.activeHabits,
            todayHabitCompletions: context.todayHabitCompletions,
            streakStatus: context.streakStatus,
            habitSuccessRate: context.habitSuccessRate,
            currentBudget: context.currentBudget,
            recentFinancials: context.recentFinancials,
            categorySpending: context.categorySpending,
            budgetAlerts: [
                BudgetAlert(
                    category: "餐饮",
                    usageRate: 0.85,
                    threshold: 0.8,
                    message: "本月餐饮已用 85%"
                )
            ],
            recentEmotions: context.recentEmotions,
            averageEmotion: context.averageEmotion,
            stressTriggers: context.stressTriggers,
            emotionTrend: context.emotionTrend,
            upcomingEvents: context.upcomingEvents,
            todaySchedule: context.todaySchedule,
            conflictingEvents: context.conflictingEvents,
            recentInsights: context.recentInsights,
            urgentInsights: context.urgentInsights,
            correlations: context.correlations,
            summary: context.summary
        )

        let engine = InsightEngine.shared

        do {
            let insights = try await engine.generateInsights(context: context)
            let budgetWarnings = insights.filter { $0.type == .warning && $0.category == .financial }

            print("✅ Generated \(budgetWarnings.count) budget warning(s)")

            for warning in budgetWarnings {
                print("   - \(warning.title)")
                print("     \(warning.description)")
                if let actions = warning.suggestedActions {
                    print("     Actions: \(actions.count)")
                    for action in actions {
                        print("       • \(action.action)")
                    }
                }
            }

        } catch {
            print("❌ Error: \(error)")
        }

        print()
    }

    /// 测试截止日期提醒
    static func testDeadlineReminders() async {
        print("Test 4: Deadline Reminder Insights")

        let context = createMockContextWithUpcomingDeadline()
        let engine = InsightEngine.shared

        do {
            let insights = try await engine.generateInsights(context: context)
            let deadlineReminders = insights.filter { $0.type == .warning && $0.category == .goal }

            print("✅ Generated \(deadlineReminders.count) deadline reminder(s)")

            for reminder in deadlineReminders {
                print("   - \(reminder.title)")
                print("     \(reminder.description)")
                print("     Urgency: \(String(format: "%.2f", reminder.urgency))")
            }

        } catch {
            print("❌ Error: \(error)")
        }

        print()
    }

    /// 测试模式洞察
    static func testPatternInsights() async {
        print("Test 5: Pattern Discovery Insights")

        let context = createMockContextWithCorrelations()
        let engine = InsightEngine.shared

        do {
            let insights = try await engine.generateInsights(context: context)
            let patternInsights = insights.filter { $0.type == .pattern }

            print("✅ Generated \(patternInsights.count) pattern insight(s)")

            for pattern in patternInsights {
                print("   - \(pattern.title)")
                print("     \(pattern.description)")
                print("     Confidence: \(String(format: "%.2f", pattern.confidence))")
            }

        } catch {
            print("❌ Error: \(error)")
        }

        print()
    }

    /// 测试成就洞察
    static func testAchievements() async {
        print("Test 6: Achievement Insights")

        let context = createMockContextWithStreaks()
        let engine = InsightEngine.shared

        do {
            let insights = try await engine.generateInsights(context: context)
            let achievements = insights.filter { $0.type == .achievement }

            print("✅ Generated \(achievements.count) achievement(s)")

            for achievement in achievements {
                print("   - \(achievement.title)")
                print("     \(achievement.description)")
            }

        } catch {
            print("❌ Error: \(error)")
        }

        print()
    }

    /// 测试推荐洞察
    static func testRecommendations() async {
        print("Test 7: Recommendation Insights")

        let context = createMockContext()
        let engine = InsightEngine.shared

        do {
            let insights = try await engine.generateInsights(context: context)
            let recommendations = insights.filter { $0.type == .recommendation }

            print("✅ Generated \(recommendations.count) recommendation(s)")

            for recommendation in recommendations.prefix(3) {
                print("   - \(recommendation.title)")
                print("     \(recommendation.description)")
                if let actions = recommendation.suggestedActions {
                    print("     Suggested actions: \(actions.count)")
                }
            }

        } catch {
            print("❌ Error: \(error)")
        }

        print()
    }

    // MARK: - Mock Data Helpers

    /// 创建模拟用户上下文
    static func createMockContext() -> UserContext {
        // 注意：这里需要实际的 User, Goal, Habit 等模型定义
        // 当前作为占位符，实际使用时需要根据真实模型创建

        return UserContext(
            user: createMockUser(),
            activeGoals: [],
            completedGoalsCount: 0,
            goalCompletionRate: 0.0,
            activeHabits: [],
            todayHabitCompletions: [],
            streakStatus: [:],
            habitSuccessRate: 0.0,
            currentBudget: nil,
            recentFinancials: [],
            categorySpending: [:],
            budgetAlerts: [],
            recentEmotions: [],
            averageEmotion: 0.0,
            stressTriggers: [],
            emotionTrend: .stable,
            upcomingEvents: [],
            todaySchedule: [],
            conflictingEvents: [],
            recentInsights: [],
            urgentInsights: [],
            correlations: [],
            summary: ContextSummary()
        )
    }

    /// 创建包含即将到期目标的上下文
    static func createMockContextWithUpcomingDeadline() -> UserContext {
        var context = createMockContext()

        // 添加一个 3 天后到期的目标
        let goal = createMockGoal(
            title: "完成 JLPT N2 备考",
            deadline: Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
            progress: 0.4
        )

        return UserContext(
            user: context.user,
            activeGoals: [goal],
            completedGoalsCount: context.completedGoalsCount,
            goalCompletionRate: context.goalCompletionRate,
            activeHabits: context.activeHabits,
            todayHabitCompletions: context.todayHabitCompletions,
            streakStatus: context.streakStatus,
            habitSuccessRate: context.habitSuccessRate,
            currentBudget: context.currentBudget,
            recentFinancials: context.recentFinancials,
            categorySpending: context.categorySpending,
            budgetAlerts: context.budgetAlerts,
            recentEmotions: context.recentEmotions,
            averageEmotion: context.averageEmotion,
            stressTriggers: context.stressTriggers,
            emotionTrend: context.emotionTrend,
            upcomingEvents: context.upcomingEvents,
            todaySchedule: context.todaySchedule,
            conflictingEvents: context.conflictingEvents,
            recentInsights: context.recentInsights,
            urgentInsights: context.urgentInsights,
            correlations: context.correlations,
            summary: context.summary
        )
    }

    /// 创建包含关联的上下文
    static func createMockContextWithCorrelations() -> UserContext {
        var context = createMockContext()

        let correlation = Correlation(
            userId: "test-user",
            dimensionA: "emotion.score",
            dimensionB: "financial.spending",
            correlationCoefficient: -0.6,
            significance: 0.02,
            description: "情绪越低落，支出越高"
        )

        return UserContext(
            user: context.user,
            activeGoals: context.activeGoals,
            completedGoalsCount: context.completedGoalsCount,
            goalCompletionRate: context.goalCompletionRate,
            activeHabits: context.activeHabits,
            todayHabitCompletions: context.todayHabitCompletions,
            streakStatus: context.streakStatus,
            habitSuccessRate: context.habitSuccessRate,
            currentBudget: context.currentBudget,
            recentFinancials: context.recentFinancials,
            categorySpending: context.categorySpending,
            budgetAlerts: context.budgetAlerts,
            recentEmotions: context.recentEmotions,
            averageEmotion: context.averageEmotion,
            stressTriggers: context.stressTriggers,
            emotionTrend: context.emotionTrend,
            upcomingEvents: context.upcomingEvents,
            todaySchedule: context.todaySchedule,
            conflictingEvents: context.conflictingEvents,
            recentInsights: context.recentInsights,
            urgentInsights: context.urgentInsights,
            correlations: [correlation],
            summary: context.summary
        )
    }

    /// 创建包含连续习惯的上下文
    static func createMockContextWithStreaks() -> UserContext {
        var context = createMockContext()

        let habit21 = createMockHabit(name: "每日阅读", streak: 21)
        let habit66 = createMockHabit(name: "晨跑", streak: 66)

        return UserContext(
            user: context.user,
            activeGoals: context.activeGoals,
            completedGoalsCount: context.completedGoalsCount,
            goalCompletionRate: context.goalCompletionRate,
            activeHabits: [habit21, habit66],
            todayHabitCompletions: context.todayHabitCompletions,
            streakStatus: [habit21.id: 21, habit66.id: 66],
            habitSuccessRate: context.habitSuccessRate,
            currentBudget: context.currentBudget,
            recentFinancials: context.recentFinancials,
            categorySpending: context.categorySpending,
            budgetAlerts: context.budgetAlerts,
            recentEmotions: context.recentEmotions,
            averageEmotion: context.averageEmotion,
            stressTriggers: context.stressTriggers,
            emotionTrend: context.emotionTrend,
            upcomingEvents: context.upcomingEvents,
            todaySchedule: context.todaySchedule,
            conflictingEvents: context.conflictingEvents,
            recentInsights: context.recentInsights,
            urgentInsights: context.urgentInsights,
            correlations: context.correlations,
            summary: context.summary
        )
    }

    // MARK: - Mock Model Helpers

    static func createMockUser() -> User {
        // 占位符 - 需要实际 User 模型
        fatalError("User model not implemented yet")
    }

    static func createMockGoal(title: String, deadline: Date, progress: Double) -> Goal {
        // 占位符 - 需要实际 Goal 模型
        fatalError("Goal model not implemented yet")
    }

    static func createMockHabit(name: String, streak: Int) -> Habit {
        // 占位符 - 需要实际 Habit 模型
        fatalError("Habit model not implemented yet")
    }
}
