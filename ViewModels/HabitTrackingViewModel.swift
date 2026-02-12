import Foundation
import SwiftUI

/// 习惯追踪 ViewModel
@MainActor
class HabitTrackingViewModel: ObservableObject {
    @Published var habits: [Habit] = []
    @Published var todayCompletions: [HabitCompletion] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = DatabaseService.shared
    private let userId = "default_user" // TODO: 从用户登录获取

    // MARK: - Public Methods

    /// 加载习惯列表
    func loadHabits() async {
        isLoading = true
        errorMessage = nil

        do {
            // TODO: 从数据库加载
            // habits = try await db.fetchHabits(userId: userId, status: .active)
            // todayCompletions = try await db.fetchTodayCompletions(userId: userId)

            // 临时: 使用模拟数据
            habits = createMockHabits()
            todayCompletions = []

            print("✅ Loaded \(habits.count) habits")
        } catch {
            errorMessage = "加载习惯失败: \(error.localizedDescription)"
            print("❌ Failed to load habits: \(error)")
        }

        isLoading = false
    }

    /// 切换今日完成状态
    func toggleCompletion(_ habitId: String) async {
        guard let habit = habits.first(where: { $0.id == habitId }) else {
            return
        }

        let isCompleted = isCompletedToday(habitId)

        if isCompleted {
            // 取消完成
            todayCompletions.removeAll { $0.habitId == habitId }

            // TODO: 从数据库删除
            // try await db.deleteCompletion(habitId, date: Date())

            print("⏪ Uncompleted habit: \(habit.name)")
        } else {
            // 标记完成
            let completion = HabitCompletion(
                habitId: habitId,
                completedAt: Date()
            )
            todayCompletions.append(completion)

            // TODO: 保存到数据库
            // try await db.insertCompletion(completion)

            // 更新习惯的连续天数
            if var updatedHabit = habits.first(where: { $0.id == habitId }) {
                updatedHabit.updateStreak(completed: true)
                if let index = habits.firstIndex(where: { $0.id == habitId }) {
                    habits[index] = updatedHabit
                }
            }

            print("✅ Completed habit: \(habit.name)")
        }
    }

    /// 检查今日是否已完成
    func isCompletedToday(_ habitId: String) -> Bool {
        todayCompletions.contains { $0.habitId == habitId }
    }

    /// 添加新习惯
    func addHabit(_ habit: Habit) async {
        do {
            // TODO: 保存到数据库
            // try await db.insertHabit(habit)

            habits.append(habit)
            print("✅ Added habit: \(habit.name)")
        } catch {
            errorMessage = "添加习惯失败: \(error.localizedDescription)"
            print("❌ Failed to add habit: \(error)")
        }
    }

    /// 更新习惯
    func updateHabit(_ habit: Habit) async {
        do {
            // TODO: 更新数据库
            // try await db.updateHabit(habit)

            if let index = habits.firstIndex(where: { $0.id == habit.id }) {
                habits[index] = habit
            }

            print("✅ Updated habit: \(habit.name)")
        } catch {
            errorMessage = "更新习惯失败: \(error.localizedDescription)"
            print("❌ Failed to update habit: \(error)")
        }
    }

    /// 删除习惯
    func deleteHabit(_ habitId: String) async {
        do {
            // TODO: 从数据库删除
            // try await db.deleteHabit(habitId)

            habits.removeAll { $0.id == habitId }
            print("✅ Deleted habit: \(habitId)")
        } catch {
            errorMessage = "删除习惯失败: \(error.localizedDescription)"
            print("❌ Failed to delete habit: \(error)")
        }
    }

    // MARK: - Private Methods

    private func createMockHabits() -> [Habit] {
        [
            Habit(
                userId: userId,
                name: "早起",
                description: "7:00 前起床",
                category: "健康",
                frequency: .daily,
                streak: 15,
                longestStreak: 21,
                totalCompletions: 45,
                successRate: 0.75,
                bestTime: "morning"
            ),
            Habit(
                userId: userId,
                name: "日语学习",
                description: "学习 1 小时",
                category: "学习",
                frequency: .daily,
                streak: 7,
                longestStreak: 12,
                totalCompletions: 30,
                successRate: 0.65,
                bestTime: "evening"
            ),
            Habit(
                userId: userId,
                name: "健身",
                description: "运动 30 分钟",
                category: "健康",
                frequency: .weekly,
                targetCount: 3,
                streak: 3,
                longestStreak: 8,
                totalCompletions: 24,
                successRate: 0.80,
                bestTime: "afternoon"
            ),
            Habit(
                userId: userId,
                name: "阅读",
                description: "读书 30 分钟",
                category: "学习",
                frequency: .daily,
                streak: 0,
                longestStreak: 5,
                totalCompletions: 12,
                successRate: 0.40,
                bestTime: "evening"
            )
        ]
    }
}
