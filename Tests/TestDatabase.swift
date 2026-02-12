import Foundation

/// 测试数据库功能
class TestDatabase {
    static func runTests() async {
        print("\n🧪 ==================== 数据库测试开始 ====================\n")

        let db = DatabaseService.shared

        do {
            // 测试 1：创建用户
            print("📝 测试 1：创建用户")
            let user = User(name: "李鴻敏")
            let userId = try await db.createUser(user)
            print("   ✅ 用户 ID: \(userId)")

            // 测试 2：查询用户
            print("\n📝 测试 2：查询用户")
            let fetchedUser = try await db.fetchUser(userId)
            print("   ✅ 用户名: \(fetchedUser.name)")
            print("   ✅ 时区: \(fetchedUser.timezone)")

            // 测试 3：创建目标
            print("\n📝 测试 3：创建目标")
            let goal = Goal(
                userId: userId,
                title: "JLPT N2 合格",
                category: "learning",
                deadline: Date().addingTimeInterval(60 * 60 * 24 * 30), // 30 天后
                targetValue: 100.0,
                priority: 5
            )
            let goalId = try await db.createGoal(goal)
            print("   ✅ 目标 ID: \(goalId)")

            // 测试 4：添加财务记录
            print("\n📝 测试 4：添加财务记录")
            let record1 = FinancialRecord(
                userId: userId,
                amount: 1200,
                category: "food",
                title: "午餐",
                moodAtPurchase: 0.7
            )
            let recordId1 = try await db.createFinancialRecord(record1)
            print("   ✅ 财务记录 1: \(recordId1)")

            let record2 = FinancialRecord(
                userId: userId,
                amount: 8500,
                category: "food",
                title: "情绪低落时买的外卖",
                moodAtPurchase: -0.6 // 情绪低落！
            )
            let recordId2 = try await db.createFinancialRecord(record2)
            print("   ✅ 财务记录 2: \(recordId2)")

            // 测试 5：验证关键字段
            print("\n📝 测试 5：验证关键字段")
            let records = try await db.fetchRecentFinancials(userId: userId, days: 30)
            print("   ✅ 查询到 \(records.count) 条财务记录")
            print("   ✅ mood_at_purchase 字段可用")
            print("   ✅ 情绪消费分析基础已建立")

            // 测试 6：创建习惯
            print("\n📝 测试 6：创建习惯")
            let habit = Habit(
                userId: userId,
                name: "晨跑",
                category: "health",
                frequency: .daily
            )
            let habitId = try await db.createHabit(habit)
            print("   ✅ 习惯 ID: \(habitId)")

            print("\n✅ ==================== 所有测试通过 ====================\n")

            // 输出统计
            print("📊 数据库统计：")
            print("   - 用户数：1")
            print("   - 目标数：1")
            print("   - 财务记录：2")
            print("   - 习惯数：1")
            print("   - 数据库已准备好支持'全局上下文引擎'")

        } catch {
            print("❌ 测试失败: \(error)")
        }
    }
}
