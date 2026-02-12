import SwiftUI

/// 上下文展示视图 - 显示用户当前状态
struct ContextDisplayView: View {
    let context: UserContext

    var body: some View {
        VStack(spacing: 12) {
            // 今日概览
            TodayOverviewCard(context: context)

            // 目标进度
            if !context.activeGoals.isEmpty {
                GoalProgressCard(goals: context.activeGoals)
            }

            // 习惯追踪
            if !context.activeHabits.isEmpty {
                HabitStatusCard(
                    habits: context.activeHabits,
                    completions: context.todayHabitCompletions
                )
            }

            // 财务状态
            if let budget = context.currentBudget {
                BudgetStatusCard(
                    budget: budget,
                    categorySpending: context.categorySpending,
                    alerts: context.budgetAlerts
                )
            }

            // 情绪趋势
            if !context.recentEmotions.isEmpty {
                EmotionTrendCard(
                    emotions: context.recentEmotions,
                    average: context.averageEmotion,
                    trend: context.emotionTrend
                )
            }
        }
    }
}

// MARK: - Today Overview Card

struct TodayOverviewCard: View {
    let context: UserContext

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日概览")
                .font(.subheadline)
                .fontWeight(.semibold)

            HStack(spacing: 16) {
                // 待办数量
                StatBadge(
                    icon: "checklist",
                    value: "\(context.todayTodoCount)",
                    label: "待办",
                    color: .blue
                )

                // 习惯完成率
                StatBadge(
                    icon: "target",
                    value: "\(Int(context.todayHabitCompletionRate * 100))%",
                    label: "习惯",
                    color: .green
                )

                // 情绪状态
                StatBadge(
                    icon: emotionIcon,
                    value: emotionLabel,
                    label: "情绪",
                    color: emotionColor
                )

                Spacer()
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    private var emotionIcon: String {
        if context.averageEmotion > 0.3 {
            return "face.smiling"
        } else if context.averageEmotion < -0.3 {
            return "face.frowning"
        } else {
            return "face.neutral"
        }
    }

    private var emotionLabel: String {
        if context.averageEmotion > 0.3 {
            return "良好"
        } else if context.averageEmotion < -0.3 {
            return "压力"
        } else {
            return "平稳"
        }
    }

    private var emotionColor: Color {
        if context.averageEmotion > 0.3 {
            return .green
        } else if context.averageEmotion < -0.3 {
            return .orange
        } else {
            return .secondary
        }
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Goal Progress Card

struct GoalProgressCard: View {
    let goals: [Goal]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("活跃目标")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(goals.count) 个")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ForEach(goals.prefix(3)) { goal in
                GoalProgressRow(goal: goal)
            }

            if goals.count > 3 {
                Button(action: {
                    // TODO: 显示所有目标
                }) {
                    Text("查看全部 \(goals.count) 个目标")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct GoalProgressRow: View {
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(goal.title)
                    .font(.caption)
                    .lineLimit(1)

                Spacer()

                Text("\(goal.progressPercentage)%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: goal.progress)
                .tint(progressColor)
        }
    }

    private var progressColor: Color {
        if goal.isOverdue {
            return .red
        } else if goal.isDueSoon {
            return .orange
        } else {
            return .green
        }
    }
}

// MARK: - Habit Status Card

struct HabitStatusCard: View {
    let habits: [Habit]
    let completions: [HabitCompletion]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今日习惯")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(completions.count) / \(habits.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ForEach(habits.prefix(4)) { habit in
                HabitStatusRow(
                    habit: habit,
                    isCompleted: completions.contains { $0.habitId == habit.id }
                )
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct HabitStatusRow: View {
    let habit: Habit
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? .green : .secondary)

            Text(habit.name)
                .font(.caption)
                .lineLimit(1)

            Spacer()

            if habit.streak > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)

                    Text("\(habit.streak)")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
    }
}

// MARK: - Budget Status Card

struct BudgetStatusCard: View {
    let budget: Budget
    let categorySpending: [String: Double]
    let alerts: [BudgetAlert]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("本月预算")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                if !alerts.isEmpty {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                }
            }

            // 预算警告
            if !alerts.isEmpty {
                ForEach(alerts.prefix(2), id: \.category) { alert in
                    HStack {
                        Text(alert.message)
                            .font(.caption)
                            .foregroundColor(.orange)

                        Spacer()

                        Text("\(Int(alert.usageRate * 100))%")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Emotion Trend Card

struct EmotionTrendCard: View {
    let emotions: [EmotionRecord]
    let average: Double
    let trend: EmotionTrend

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("情绪趋势（7天）")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                trendIndicator
            }

            // 简化的情绪趋势图
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(emotions.suffix(7), id: \.id) { emotion in
                    Rectangle()
                        .fill(emotionColor(emotion.score))
                        .frame(width: 8, height: CGFloat(abs(emotion.score) * 30 + 10))
                }
            }
            .frame(height: 40)
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    private var trendIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: trendIcon)
                .font(.caption)

            Text(trendLabel)
                .font(.caption)
        }
        .foregroundColor(trendColor)
    }

    private var trendIcon: String {
        switch trend {
        case .improving:
            return "arrow.up.right"
        case .stable:
            return "arrow.right"
        case .declining:
            return "arrow.down.right"
        case .volatile:
            return "chart.line.uptrend.xyaxis"
        }
    }

    private var trendLabel: String {
        switch trend {
        case .improving: return "改善"
        case .stable: return "稳定"
        case .declining: return "下降"
        case .volatile: return "波动"
        }
    }

    private var trendColor: Color {
        switch trend {
        case .improving: return .green
        case .stable: return .secondary
        case .declining: return .orange
        case .volatile: return .yellow
        }
    }

    private func emotionColor(_ score: Double) -> Color {
        if score > 0 {
            return .green.opacity(0.5 + score * 0.5)
        } else {
            return .orange.opacity(0.5 + abs(score) * 0.5)
        }
    }
}

// MARK: - Preview

#Preview {
    let context = UserContext(
        user: User(id: "1", name: "测试用户"),
        activeGoals: [],
        completedGoalsCount: 0,
        goalCompletionRate: 0,
        activeHabits: [],
        todayHabitCompletions: [],
        streakStatus: [:],
        habitSuccessRate: 0,
        currentBudget: nil,
        recentFinancials: [],
        categorySpending: [:],
        budgetAlerts: [],
        recentEmotions: [],
        averageEmotion: 0,
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

    return ContextDisplayView(context: context)
        .padding()
}
