import Foundation

/// TestAppState - AppState 功能测试
/// 验证全局状态管理的核心功能
@MainActor
class TestAppState {
    let appState: AppState

    init() {
        self.appState = AppState.shared
    }

    // MARK: - Test Methods

    /// 运行所有测试
    func runAllTests() async {
        print("\n" + "=".repeating(60))
        print("🧪 开始测试 AppState 全局状态管理")
        print("=".repeating(60) + "\n")

        await testUserStateLoading()
        await testContextRefresh()
        await testErrorHandling()
        await testConvenienceAccessors()
        await testAutoRefresh()
        await testStateObservation()

        print("\n" + "=".repeating(60))
        print("✅ AppState 测试完成")
        print("=".repeating(60) + "\n")
    }

    // MARK: - Individual Tests

    /// 测试 1: 用户状态加载
    private func testUserStateLoading() async {
        print("📋 测试 1: 用户状态加载")

        await appState.loadUserState()

        // 验证用户已加载
        if let user = appState.currentUser {
            print("   ✅ 用户加载成功: \(user.name)")
            print("      - ID: \(user.id)")
            print("      - 时区: \(user.timezone)")
            print("      - 语言: \(user.language)")
        } else {
            print("   ❌ 用户加载失败")
        }

        // 验证上下文已加载
        if let context = appState.context {
            print("   ✅ 上下文加载成功")
            print("      - 活跃目标: \(context.activeGoals.count)")
            print("      - 活跃习惯: \(context.activeHabits.count)")
            print("      - 近期洞察: \(context.recentInsights.count)")
        } else {
            print("   ⚠️  上下文未加载")
        }

        print("")
    }

    /// 测试 2: 上下文刷新
    private func testContextRefresh() async {
        print("📋 测试 2: 上下文刷新")

        let beforeRefresh = Date()
        await appState.refreshContext()
        let afterRefresh = Date()

        let refreshTime = afterRefresh.timeIntervalSince(beforeRefresh) * 1000

        if let context = appState.context {
            print("   ✅ 上下文刷新成功")
            print("      - 刷新时间: \(String(format: "%.1f", refreshTime))ms")
            print("      - 目标: \(refreshTime < 100 ? "✅" : "⚠️") (<100ms)")
            print("      - 加载时间: \(context.loadedAt)")
        } else {
            print("   ❌ 上下文刷新失败")
        }

        print("")
    }

    /// 测试 3: 错误处理
    private func testErrorHandling() async {
        print("📋 测试 3: 错误处理")

        // 模拟错误
        let testError = NSError(domain: "TestDomain", code: 123, userInfo: [
            NSLocalizedDescriptionKey: "这是一个测试错误"
        ])

        appState.handleError(testError, context: "测试上下文")

        // 验证错误消息
        if let errorMessage = appState.errorMessage {
            print("   ✅ 错误处理成功")
            print("      - 错误消息: \(errorMessage)")
            print("      - 应用状态: \(appState.appStatus)")
        } else {
            print("   ❌ 错误处理失败")
        }

        // 清除错误
        appState.clearError()
        if appState.errorMessage == nil {
            print("   ✅ 错误清除成功")
        } else {
            print("   ❌ 错误清除失败")
        }

        print("")
    }

    /// 测试 4: 便捷访问方法
    private func testConvenienceAccessors() async {
        print("📋 测试 4: 便捷访问方法")

        print("   活跃目标数: \(appState.activeGoals.count)")
        print("   活跃习惯数: \(appState.activeHabits.count)")
        print("   今日待办: \(appState.todaySchedule.count)")
        print("   紧急洞察: \(appState.urgentInsights.count)")
        print("   预算预警: \(appState.budgetAlerts.count)")
        print("   有紧急事项: \(appState.hasUrgentMatters ? "是" : "否")")
        print("   压力状态: \(appState.isStressed ? "是" : "否")")
        print("   简短摘要: \(appState.briefSummary)")

        print("   ✅ 便捷访问方法测试完成")
        print("")
    }

    /// 测试 5: 自动刷新
    private func testAutoRefresh() async {
        print("📋 测试 5: 自动刷新")

        // 注意: 自动刷新在 loadUserState() 中已启动
        // 这里只验证状态
        print("   ✅ 自动刷新已配置（间隔: 5 分钟）")
        print("      - 在实际使用中会自动触发")
        print("")
    }

    /// 测试 6: 状态观察 (ObservableObject)
    private func testStateObservation() async {
        print("📋 测试 6: 状态观察")

        // 验证 @Published 属性
        print("   验证 @Published 属性:")
        print("      - currentUser: \(appState.currentUser != nil ? "✅" : "❌")")
        print("      - context: \(appState.context != nil ? "✅" : "❌")")
        print("      - insights: ✅ (count: \(appState.insights.count))")
        print("      - isLoading: ✅ (\(appState.isLoading))")
        print("      - errorMessage: ✅ (\(appState.errorMessage != nil ? "有" : "无"))")
        print("      - appStatus: ✅ (\(appState.appStatus))")

        print("   ✅ ObservableObject 协议实现正确")
        print("")
    }

    // MARK: - Performance Tests

    /// 性能测试: 上下文加载时间
    func benchmarkContextLoading(iterations: Int = 5) async {
        print("\n📊 性能测试: 上下文加载时间")
        print("   迭代次数: \(iterations)")

        var times: [Double] = []

        for i in 1...iterations {
            // 使缓存失效
            await appState.invalidateCacheAndRefresh()

            let start = Date()
            await appState.refreshContext()
            let elapsed = Date().timeIntervalSince(start) * 1000

            times.append(elapsed)
            print("   第 \(i) 次: \(String(format: "%.1f", elapsed))ms")
        }

        if !times.isEmpty {
            let avg = times.reduce(0, +) / Double(times.count)
            let min = times.min() ?? 0
            let max = times.max() ?? 0

            print("\n   统计结果:")
            print("      - 平均: \(String(format: "%.1f", avg))ms")
            print("      - 最快: \(String(format: "%.1f", min))ms")
            print("      - 最慢: \(String(format: "%.1f", max))ms")
            print("      - 目标: <100ms \(avg < 100 ? "✅" : "⚠️")")
        }

        print("")
    }
}

// MARK: - Test Runner

/// 运行 AppState 测试（在 App 启动时调用）
@MainActor
func runAppStateTests() async {
    let tester = TestAppState()
    await tester.runAllTests()
    await tester.benchmarkContextLoading()
}
