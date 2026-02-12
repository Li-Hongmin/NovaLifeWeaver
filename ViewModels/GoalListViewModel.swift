import Combine
import Combine
import Foundation
import SwiftUI
import Combine

/// 目标列表 ViewModel
@MainActor
class GoalListViewModel: ObservableObject {
    @Published var goals: [Goal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = DatabaseService.shared
    private let userId = "default_user" // TODO: 从用户登录获取

    // MARK: - Public Methods

    /// 加载目标列表
    func loadGoals() async {
        isLoading = true
        errorMessage = nil

        do {
            // TODO: 从数据库加载目标
            // goals = try await db.fetchGoals(userId: userId, status: .active)

            // 临时: 使用模拟数据
            goals = createMockGoals()

            print("✅ Loaded \(goals.count) goals")
        } catch {
            errorMessage = "加载目标失败: \(error.localizedDescription)"
            print("❌ Failed to load goals: \(error)")
        }

        isLoading = false
    }

    /// 添加新目标
    func addGoal(_ goal: Goal) async {
        do {
            // TODO: 保存到数据库
            // try await db.insertGoal(goal)

            goals.append(goal)
            print("✅ Added goal: \(goal.title)")
        } catch {
            errorMessage = "添加目标失败: \(error.localizedDescription)"
            print("❌ Failed to add goal: \(error)")
        }
    }

    /// 更新目标
    func updateGoal(_ goal: Goal) async {
        do {
            // TODO: 更新数据库
            // try await db.updateGoal(goal)

            if let index = goals.firstIndex(where: { $0.id == goal.id }) {
                goals[index] = goal
            }

            print("✅ Updated goal: \(goal.title)")
        } catch {
            errorMessage = "更新目标失败: \(error.localizedDescription)"
            print("❌ Failed to update goal: \(error)")
        }
    }

    /// 删除目标
    func deleteGoal(_ goalId: String) async {
        do {
            // TODO: 从数据库删除
            // try await db.deleteGoal(goalId)

            goals.removeAll { $0.id == goalId }
            print("✅ Deleted goal: \(goalId)")
        } catch {
            errorMessage = "删除目标失败: \(error.localizedDescription)"
            print("❌ Failed to delete goal: \(error)")
        }
    }

    // MARK: - Private Methods

    private func createMockGoals() -> [Goal] {
        [
            Goal(
                userId: userId,
                title: "通过 JLPT N2",
                description: "3月考试，目标 140分以上",
                category: "学习",
                deadline: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
                measurableMetric: "模拟考试分数",
                targetValue: 140,
                currentValue: 110,
                priority: 5
            ),
            Goal(
                userId: userId,
                title: "每周健身 3 次",
                description: "保持健康体态",
                category: "健康",
                deadline: Calendar.current.date(byAdding: .month, value: 3, to: Date()),
                measurableMetric: "本周完成次数",
                targetValue: 12,
                currentValue: 8,
                priority: 4
            ),
            Goal(
                userId: userId,
                title: "读完 3 本书",
                description: "扩展知识面",
                category: "阅读",
                deadline: Calendar.current.date(byAdding: .month, value: 2, to: Date()),
                measurableMetric: "已读书本",
                targetValue: 3,
                currentValue: 1,
                priority: 3
            )
        ]
    }
}
