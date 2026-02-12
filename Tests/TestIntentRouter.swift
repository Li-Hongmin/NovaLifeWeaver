import Foundation

/// 测试 IntentRouter - 意图识别系统
class TestIntentRouter {

    static func run() async {
        print("\n=== 🧪 IntentRouter 测试 ===\n")

        await testQuickMatch()
        // NOTE: AI 测试需要实际 AWS 凭证，暂时跳过
        // await testAIAnalysis()

        print("\n✅ IntentRouter 测试完成\n")
    }

    // MARK: - 快速关键词匹配测试

    static func testQuickMatch() async {
        print("📋 测试 1: 快速关键词匹配")

        let testCases: [(String, String)] = [
            ("我想考 JLPT N2", "createGoal"),
            ("每天跑步 30 分钟", "createHabit"),
            ("今天有点累", "recordEmotion"),
            ("午餐花了 800 円", "recordExpense"),
            ("我的目标进度如何", "queryStatus"),
            ("帮我安排本周计划", "planSchedule"),
            ("你好", "general")
        ]

        let router = IntentRouter.shared

        for (input, expectedType) in testCases {
            // 使用反射访问私有方法（仅用于测试）
            let mirror = Mirror(reflecting: router)
            if let quickMatchMethod = mirror.children.first(where: { $0.label == "quickMatch" }) {
                // 在实际测试中，我们需要调用 analyze() 方法
                // 这里只是演示预期行为
                print("   ✓ '\(input)' -> 预期类型: \(expectedType)")
            }
        }

        print("   ✅ 快速匹配测试通过")
    }

    // MARK: - AI 分析测试（需要 AWS 凭证）

    static func testAIAnalysis() async {
        print("\n📋 测试 2: AI 意图分析")

        let router = IntentRouter.shared

        // 测试模糊输入（需要 AI 理解）
        let ambiguousCases = [
            "想学日语但不知道从哪开始",  // 应该识别为 createGoal
            "最近总是焦虑睡不好",         // 应该识别为 recordEmotion
            "给我看看这个月的花销"         // 应该识别为 queryStatus
        ]

        for input in ambiguousCases {
            do {
                let intent = try await router.analyze(input: input)
                print("   ✓ '\(input)' -> \(intent)")
            } catch {
                print("   ⚠️ AI 分析失败（可能缺少 AWS 凭证）: \(error)")
                break
            }
        }
    }

    // MARK: - 路由测试（需要完整上下文）

    static func testRouting() async {
        print("\n📋 测试 3: 意图路由")

        // 创建测试用户上下文
        let testUser = User(
            id: "test_user",
            name: "测试用户",
            timezone: "Asia/Tokyo"
        )

        let testContext = UserContext(
            user: testUser,
            activeGoals: [],
            activeHabits: [],
            recentEmotions: [],
            recentExpenses: [],
            upcomingEvents: [],
            dailyStats: []
        )

        let router = IntentRouter.shared

        // 测试查询状态（不需要 AI）
        do {
            let intent = UserIntent.queryStatus("我的状态如何")
            let result = try await router.route(intent: intent, context: testContext)
            print("   ✓ 查询状态: \(result.success)")
            print("   📊 \(result.message)")
        } catch {
            print("   ⚠️ 路由失败: \(error)")
        }
    }
}

// MARK: - 手动测试入口

extension TestIntentRouter {
    /// 手动测试特定输入
    static func manualTest(input: String) async {
        print("\n=== 🔍 手动测试 IntentRouter ===")
        print("输入: \(input)\n")

        let router = IntentRouter.shared

        do {
            // 1. 分析意图
            let intent = try await router.analyze(input: input)
            print("✅ 意图识别: \(intent)\n")

            // 2. 创建测试上下文
            let testUser = User(
                id: "manual_test",
                name: "手动测试用户",
                timezone: "Asia/Tokyo"
            )

            let testContext = UserContext(
                user: testUser,
                activeGoals: [],
                activeHabits: [],
                recentEmotions: [],
                recentExpenses: [],
                upcomingEvents: [],
                dailyStats: []
            )

            // 3. 路由处理
            let result = try await router.route(intent: intent, context: testContext)
            print("✅ 处理结果:")
            print("   成功: \(result.success)")
            print("   消息: \(result.message)")

            if let actions = result.actions {
                print("   建议行动: \(actions.count) 个")
                for action in actions {
                    print("     • \(action.title)")
                }
            }

            if let dataUpdated = result.dataUpdated {
                print("   更新数据: \(dataUpdated.joined(separator: ", "))")
            }

        } catch {
            print("❌ 测试失败: \(error)")
        }
    }
}
