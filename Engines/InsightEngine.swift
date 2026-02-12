import Foundation

/// 洞察生成引擎 - 基于上下文和关联生成可执行的 AI 建议
/// 实现智能分析：预算警告、模式发现、行动建议、习惯庆祝
final class InsightEngine: InsightEngineProtocol {

    // MARK: - Singleton
    static let shared = InsightEngine()

    // MARK: - Properties
    private let calendar = Calendar.current

    // MARK: - Initialization
    private init() {}

    // MARK: - InsightEngineProtocol Implementation

    /// 基于用户上下文生成所有类型的洞察
    /// - Parameter context: 用户全局上下文
    /// - Returns: 按优先级排序的洞察数组
    func generateInsights(context: UserContext) async throws -> [Insight] {
        var insights: [Insight] = []

        // 1. 生成各类型洞察
        insights.append(contentsOf: generateBudgetWarnings(context: context))
        insights.append(contentsOf: generateDeadlineReminders(context: context))
        insights.append(contentsOf: generatePatternInsights(context: context))
        insights.append(contentsOf: generateRecommendations(context: context))
        insights.append(contentsOf: generateAchievements(context: context))

        // 2. 计算优先级并排序
        return prioritizeInsights(insights)
    }

    /// 生成特定类型的洞察
    /// - Parameters:
    ///   - type: 洞察类型
    ///   - category: 洞察分类
    ///   - context: 用户上下文
    /// - Returns: 生成的洞察（如果适用）
    func generateInsight(
        type: InsightType,
        category: InsightCategory,
        context: UserContext
    ) async throws -> Insight? {
        switch (type, category) {
        case (.warning, .financial):
            return generateBudgetWarnings(context: context).first
        case (.warning, .goal):
            return generateDeadlineReminders(context: context).first
        case (.pattern, _):
            return generatePatternInsights(context: context).first
        case (.recommendation, _):
            return generateRecommendations(context: context).first
        case (.achievement, .habit):
            return generateAchievements(context: context).first
        default:
            return nil
        }
    }

    /// 优先级排序算法
    /// 公式: urgency * 0.4 + impact * 0.3 + confidence * 0.2 + priority/5 * 0.1
    /// - Parameter insights: 未排序的洞察数组
    /// - Returns: 按优先级降序排列的洞察数组
    func prioritizeInsights(_ insights: [Insight]) -> [Insight] {
        return insights.sorted { insight1, insight2 in
            insight1.overallScore > insight2.overallScore
        }
    }

    // MARK: - Warning Insights (预警类洞察)

    /// 生成预算警告洞察
    private func generateBudgetWarnings(context: UserContext) -> [Insight] {
        var warnings: [Insight] = []

        // 遍历预算预警
        for alert in context.budgetAlerts {
            guard alert.usageRate >= alert.threshold else { continue }

            let urgency = calculateBudgetUrgency(usageRate: alert.usageRate)
            let impact = 0.8 // 预算超支影响较大
            let confidence = 0.95 // 基于实际数据，信心度高

            // 计算建议行动
            let actions = generateBudgetActions(
                category: alert.category,
                usageRate: alert.usageRate,
                context: context
            )

            let insight = Insight(
                userId: context.user.id,
                type: .warning,
                category: .financial,
                title: "\(alert.category) 预算预警",
                description: alert.message,
                priority: calculatePriority(urgency: urgency, impact: impact),
                urgency: urgency,
                impact: impact,
                confidence: confidence,
                actionable: true,
                suggestedActions: actions,
                status: .new,
                generatedAt: Date(),
                validUntil: calendar.date(byAdding: .day, value: 7, to: Date())
            )

            warnings.append(insight)
        }

        return warnings
    }

    /// 生成截止日期提醒
    private func generateDeadlineReminders(context: UserContext) -> [Insight] {
        var reminders: [Insight] = []
        let now = Date()

        // 检查即将到期的目标
        for goal in context.activeGoals {
            guard let deadline = goal.deadline else { continue }

            let daysUntilDeadline = calendar.dateComponents([.day], from: now, to: deadline).day ?? 0

            // 只提醒 7 天内到期的目标
            guard daysUntilDeadline >= 0 && daysUntilDeadline <= 7 else { continue }

            let urgency = 1.0 - (Double(daysUntilDeadline) / 7.0) // 越近越紧急
            let progress = goal.targetValue ?? 0 > 0 ? goal.currentValue / (goal.targetValue ?? 1) : 0
            let impact = progress < 0.5 ? 0.9 : 0.6 // 进度低则影响大
            let confidence = 0.95

            let actions = generateDeadlineActions(goal: goal, daysLeft: daysUntilDeadline)

            let insight = Insight(
                userId: context.user.id,
                type: .warning,
                category: .goal,
                title: "⏰ \(goal.title) 即将到期",
                description: "还有 \(daysUntilDeadline) 天到期，当前进度 \(Int(progress * 100))%",
                priority: calculatePriority(urgency: urgency, impact: impact),
                urgency: urgency,
                impact: impact,
                confidence: confidence,
                actionable: true,
                suggestedActions: actions,
                status: .new,
                generatedAt: Date(),
                validUntil: deadline
            )

            reminders.append(insight)
        }

        return reminders
    }

    // MARK: - Pattern Insights (模式发现类洞察)

    /// 生成模式发现洞察
    private func generatePatternInsights(context: UserContext) -> [Insight] {
        var patterns: [Insight] = []

        // 基于关联分析生成洞察
        for correlation in context.correlations {
            guard correlation.isSignificant else { continue }
            guard correlation.strength != .none && correlation.strength != .weak else { continue }

            let impact = calculateCorrelationImpact(correlation: correlation)
            let confidence = 1.0 - (correlation.significance ?? 0.05) // p-value 越小信心越高
            let urgency = correlation.strength == .strong ? 0.7 : 0.5

            let actions = generatePatternActions(correlation: correlation, context: context)

            let insight = Insight(
                userId: context.user.id,
                type: .pattern,
                category: categorizeCorrelation(correlation),
                title: "📊 发现行为模式",
                description: correlation.description ?? correlation.generateDescription(),
                priority: calculatePriority(urgency: urgency, impact: impact),
                urgency: urgency,
                impact: impact,
                confidence: min(confidence, 0.95), // 上限 0.95
                actionable: true,
                suggestedActions: actions,
                status: .new,
                generatedAt: Date(),
                validUntil: calendar.date(byAdding: .day, value: 30, to: Date())
            )

            patterns.append(insight)
        }

        // 情绪支出模式特殊检测
        if context.isStressed && !context.recentFinancials.isEmpty {
            if let emotionSpendingInsight = generateEmotionSpendingInsight(context: context) {
                patterns.append(emotionSpendingInsight)
            }
        }

        return patterns
    }

    // MARK: - Recommendation Insights (建议类洞察)

    /// 生成可执行建议
    private func generateRecommendations(context: UserContext) -> [Insight] {
        var recommendations: [Insight] = []

        // 1. 习惯优化建议
        recommendations.append(contentsOf: generateHabitOptimizationRecommendations(context: context))

        // 2. 目标推进建议
        recommendations.append(contentsOf: generateGoalProgressRecommendations(context: context))

        // 3. 时间管理建议
        recommendations.append(contentsOf: generateTimeManagementRecommendations(context: context))

        return recommendations
    }

    /// 习惯优化建议
    private func generateHabitOptimizationRecommendations(context: UserContext) -> [Insight] {
        var recommendations: [Insight] = []

        for habit in context.activeHabits {
            // 检测连续失败的习惯
            if habit.successRate < 0.5 && habit.totalCompletions > 7 {
                let actions = [
                    SuggestedAction(
                        action: "降低目标难度（从每天 \(habit.targetCount) 次改为 1 次）",
                        type: "update_habit",
                        parameters: ["habit_id": habit.id, "target_count": "1"],
                        priority: 4
                    ),
                    SuggestedAction(
                        action: "设置提醒（基于历史最佳时间：\(habit.bestTime ?? "早上")）",
                        type: "create_reminder",
                        parameters: ["habit_id": habit.id, "time": habit.bestTime ?? "morning"],
                        priority: 3
                    )
                ]

                let insight = Insight(
                    userId: context.user.id,
                    type: .recommendation,
                    category: .habit,
                    title: "优化建议：\(habit.name)",
                    description: "当前成功率 \(Int(habit.successRate * 100))%，建议降低难度或调整时间",
                    priority: 3,
                    urgency: 0.6,
                    impact: 0.7,
                    confidence: 0.8,
                    actionable: true,
                    suggestedActions: actions,
                    status: .new
                )

                recommendations.append(insight)
            }
        }

        return recommendations
    }

    /// 目标推进建议
    private func generateGoalProgressRecommendations(context: UserContext) -> [Insight] {
        var recommendations: [Insight] = []

        for goal in context.activeGoals {
            guard let deadline = goal.deadline, let targetValue = goal.targetValue else { continue }

            let now = Date()
            let totalDays = calendar.dateComponents([.day], from: goal.createdAt, to: deadline).day ?? 1
            let remainingDays = calendar.dateComponents([.day], from: now, to: deadline).day ?? 0

            guard remainingDays > 0 else { continue }

            let progress = goal.currentValue / targetValue
            let expectedProgress = Double(totalDays - remainingDays) / Double(totalDays)

            // 进度落后
            if progress < expectedProgress - 0.1 {
                let dailyRequired = (targetValue - goal.currentValue) / Double(remainingDays)

                let actions = [
                    SuggestedAction(
                        action: "加快进度：每天需要完成 \(String(format: "%.1f", dailyRequired)) 单位",
                        type: "update_goal_plan",
                        parameters: ["goal_id": goal.id, "daily_target": String(dailyRequired)],
                        priority: 4
                    )
                ]

                let insight = Insight(
                    userId: context.user.id,
                    type: .recommendation,
                    category: .goal,
                    title: "📈 \(goal.title) 需要提速",
                    description: "进度落后预期 \(Int((expectedProgress - progress) * 100))%",
                    priority: 4,
                    urgency: 0.7,
                    impact: 0.8,
                    confidence: 0.9,
                    actionable: true,
                    suggestedActions: actions,
                    status: .new
                )

                recommendations.append(insight)
            }
        }

        return recommendations
    }

    /// 时间管理建议
    private func generateTimeManagementRecommendations(context: UserContext) -> [Insight] {
        var recommendations: [Insight] = []

        // 检测日程冲突
        if !context.conflictingEvents.isEmpty {
            let conflictCount = context.conflictingEvents.count

            let actions = context.conflictingEvents.prefix(3).map { conflict in
                SuggestedAction(
                    action: "重新安排：\(conflict.0.title) 或 \(conflict.1.title)",
                    type: "resolve_conflict",
                    parameters: [
                        "event1_id": conflict.0.id,
                        "event2_id": conflict.1.id
                    ],
                    priority: 5
                )
            }

            let insight = Insight(
                userId: context.user.id,
                type: .recommendation,
                category: .time,
                title: "⚠️ 发现 \(conflictCount) 个日程冲突",
                description: "建议重新安排避免时间重叠",
                priority: 4,
                urgency: 0.8,
                impact: 0.7,
                confidence: 1.0,
                actionable: true,
                suggestedActions: actions,
                status: .new
            )

            recommendations.append(insight)
        }

        return recommendations
    }

    // MARK: - Achievement Insights (成就类洞察)

    /// 生成习惯成就庆祝
    private func generateAchievements(context: UserContext) -> [Insight] {
        var achievements: [Insight] = []

        for habit in context.activeHabits {
            // 21 天习惯养成
            if habit.streak == 21 {
                let insight = Insight(
                    userId: context.user.id,
                    type: .achievement,
                    category: .habit,
                    title: "🎉 习惯已养成！",
                    description: "\(habit.name) 连续 21 天完成，恭喜你成功养成新习惯！",
                    priority: 3,
                    urgency: 0.3,
                    impact: 0.6,
                    confidence: 1.0,
                    actionable: false,
                    status: .new
                )
                achievements.append(insight)
            }

            // 66 天自动化习惯
            if habit.streak == 66 {
                let insight = Insight(
                    userId: context.user.id,
                    type: .achievement,
                    category: .habit,
                    title: "🏆 习惯已自动化！",
                    description: "\(habit.name) 连续 66 天！这个习惯已经成为你的一部分了。",
                    priority: 2,
                    urgency: 0.2,
                    impact: 0.5,
                    confidence: 1.0,
                    actionable: false,
                    status: .new
                )
                achievements.append(insight)
            }

            // 突破最长记录
            if habit.streak > habit.longestStreak && habit.streak > 7 {
                let insight = Insight(
                    userId: context.user.id,
                    type: .achievement,
                    category: .habit,
                    title: "🔥 创造新记录！",
                    description: "\(habit.name) 已连续 \(habit.streak) 天，突破历史最佳！",
                    priority: 3,
                    urgency: 0.3,
                    impact: 0.5,
                    confidence: 1.0,
                    actionable: false,
                    status: .new
                )
                achievements.append(insight)
            }
        }

        // 目标完成成就
        let recentlyCompletedGoals = context.activeGoals.filter { goal in
            guard let completedAt = goal.completedAt else { return false }
            let daysSinceCompletion = calendar.dateComponents([.day], from: completedAt, to: Date()).day ?? 999
            return daysSinceCompletion <= 1
        }

        for goal in recentlyCompletedGoals {
            let insight = Insight(
                userId: context.user.id,
                type: .achievement,
                category: .goal,
                title: "✅ 目标达成！",
                description: "恭喜完成「\(goal.title)」！",
                priority: 2,
                urgency: 0.2,
                impact: 0.7,
                confidence: 1.0,
                actionable: false,
                status: .new
            )
            achievements.append(insight)
        }

        return achievements
    }

    // MARK: - Helper Methods (辅助方法)

    /// 计算预算紧急度
    private func calculateBudgetUrgency(usageRate: Double) -> Double {
        if usageRate >= 1.0 {
            return 1.0 // 已超支
        } else if usageRate >= 0.9 {
            return 0.9 // 即将超支
        } else if usageRate >= 0.8 {
            return 0.7 // 警告线
        } else {
            return 0.5 // 正常监控
        }
    }

    /// 计算优先级（1-5）
    private func calculatePriority(urgency: Double, impact: Double) -> Int {
        let score = urgency * 0.6 + impact * 0.4

        if score >= 0.8 {
            return 5
        } else if score >= 0.6 {
            return 4
        } else if score >= 0.4 {
            return 3
        } else if score >= 0.2 {
            return 2
        } else {
            return 1
        }
    }

    /// 生成预算行动建议
    private func generateBudgetActions(
        category: String,
        usageRate: Double,
        context: UserContext
    ) -> [SuggestedAction] {
        var actions: [SuggestedAction] = []

        // 根据类别生成具体建议
        switch category {
        case "餐饮", "food":
            if usageRate >= 0.8 {
                actions.append(SuggestedAction(
                    action: "本周自己做饭 5 次（预计节省 ¥5,000）",
                    type: "create_event",
                    parameters: ["type": "meal_prep", "count": "5"],
                    priority: 5
                ))
                actions.append(SuggestedAction(
                    action: "减少外出就餐频率",
                    type: "set_limit",
                    parameters: ["category": "food", "frequency": "reduce"],
                    priority: 4
                ))
            }
        case "娱乐", "entertainment":
            actions.append(SuggestedAction(
                action: "本月暂停非必要订阅服务",
                type: "review_subscriptions",
                parameters: ["category": "entertainment"],
                priority: 4
            ))
        default:
            actions.append(SuggestedAction(
                action: "审查 \(category) 类支出",
                type: "review_spending",
                parameters: ["category": category],
                priority: 3
            ))
        }

        return actions
    }

    /// 生成截止日期行动建议
    private func generateDeadlineActions(goal: Goal, daysLeft: Int) -> [SuggestedAction] {
        var actions: [SuggestedAction] = []

        let progress = goal.targetValue ?? 0 > 0 ? goal.currentValue / (goal.targetValue ?? 1) : 0

        if progress < 0.5 {
            // 进度严重落后
            actions.append(SuggestedAction(
                action: "立即制定冲刺计划",
                type: "create_sprint_plan",
                parameters: ["goal_id": goal.id, "days_left": String(daysLeft)],
                priority: 5
            ))
            actions.append(SuggestedAction(
                action: "考虑申请延期或调整目标",
                type: "adjust_goal",
                parameters: ["goal_id": goal.id, "action": "extend_or_adjust"],
                priority: 4
            ))
        } else {
            // 进度正常，加速完成
            actions.append(SuggestedAction(
                action: "每天增加 30 分钟专注时间",
                type: "add_daily_block",
                parameters: ["goal_id": goal.id, "duration": "30"],
                priority: 4
            ))
        }

        return actions
    }

    /// 生成模式行动建议
    private func generatePatternActions(
        correlation: Correlation,
        context: UserContext
    ) -> [SuggestedAction] {
        var actions: [SuggestedAction] = []

        // 情绪-支出关联
        if correlation.dimensionA.contains("emotion") && correlation.dimensionB.contains("spending") {
            if correlation.direction == .positive {
                actions.append(SuggestedAction(
                    action: "情绪低落时，先运动 30 分钟再决定是否消费",
                    type: "set_emotional_rule",
                    parameters: ["trigger": "low_emotion", "action": "exercise_first"],
                    priority: 4
                ))
                actions.append(SuggestedAction(
                    action: "设置情绪消费警报（单日支出超过平均值 50%）",
                    type: "create_alert",
                    parameters: ["type": "emotional_spending", "threshold": "1.5"],
                    priority: 3
                ))
            }
        }

        // 习惯-情绪关联
        if correlation.dimensionA.contains("habit") && correlation.dimensionB.contains("emotion") {
            if correlation.direction == .positive {
                actions.append(SuggestedAction(
                    action: "保持当前习惯（对情绪有积极影响）",
                    type: "reinforce_habit",
                    parameters: ["correlation_id": correlation.id],
                    priority: 3
                ))
            }
        }

        return actions
    }

    /// 生成情绪支出洞察
    private func generateEmotionSpendingInsight(context: UserContext) -> Insight? {
        // 计算最近 7 天的情绪和支出
        let recentDays = 7
        guard context.recentEmotions.count >= 3 && context.recentFinancials.count >= 3 else {
            return nil
        }

        // 简化的相关性检测
        let avgEmotion = context.averageEmotion
        let avgSpending = context.recentFinancials.map { $0.amount }.reduce(0, +) / Double(context.recentFinancials.count)

        // 最近 3 天的支出
        let recentSpending = context.recentFinancials.prefix(3).map { $0.amount }.reduce(0, +) / 3.0

        if avgEmotion < -0.2 && recentSpending > avgSpending * 1.3 {
            let actions = [
                SuggestedAction(
                    action: "先去运动 30 分钟（历史数据显示运动后情绪提升 40%）",
                    type: "suggest_exercise",
                    parameters: ["duration": "30", "reason": "emotional_spending"],
                    priority: 5
                ),
                SuggestedAction(
                    action: "如果还想购物，选择预算内的小奖励（¥2,000）",
                    type: "suggest_budget_reward",
                    parameters: ["max_amount": "2000"],
                    priority: 4
                )
            ]

            return Insight(
                userId: context.user.id,
                type: .pattern,
                category: .health,
                title: "⚠️ 检测到情绪消费风险",
                description: "你的数据显示：情绪低落时支出增加 \(Int((recentSpending / avgSpending - 1) * 100))%",
                priority: 5,
                urgency: 0.8,
                impact: 0.8,
                confidence: 0.85,
                actionable: true,
                suggestedActions: actions,
                status: .new
            )
        }

        return nil
    }

    /// 计算关联影响度
    private func calculateCorrelationImpact(correlation: Correlation) -> Double {
        // 基于相关系数强度和显著性
        let strengthImpact: Double
        switch correlation.strength {
        case .strong:
            strengthImpact = 0.9
        case .moderate:
            strengthImpact = 0.7
        case .weak:
            strengthImpact = 0.5
        case .none:
            strengthImpact = 0.3
        }

        let significanceImpact = correlation.isSignificant ? 0.2 : 0.0

        return min(strengthImpact + significanceImpact, 1.0)
    }

    /// 分类关联类型
    private func categorizeCorrelation(_ correlation: Correlation) -> InsightCategory {
        if correlation.dimensionA.contains("financial") || correlation.dimensionB.contains("financial") {
            return .financial
        } else if correlation.dimensionA.contains("emotion") || correlation.dimensionB.contains("emotion") {
            return .health
        } else if correlation.dimensionA.contains("habit") || correlation.dimensionB.contains("habit") {
            return .habit
        } else if correlation.dimensionA.contains("goal") || correlation.dimensionB.contains("goal") {
            return .goal
        } else {
            return .general
        }
    }
}
