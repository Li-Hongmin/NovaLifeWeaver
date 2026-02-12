import Foundation

/// CorrelationEngine 测试和使用示例
/// 展示如何使用关联分析引擎发现跨领域数据模式
class TestCorrelationEngine {
    let engine = CorrelationEngine.shared

    /// 测试：分析所有关联
    func testAnalyzeAllCorrelations() async {
        print("\n📊 Testing Correlation Engine - Analyze All Correlations")
        print("=" * 60)

        let testUserId = "test-user-123"

        do {
            let correlations = try await engine.analyzeCorrelations(userId: testUserId)

            print("\n✅ Found \(correlations.count) correlations:")

            for correlation in correlations {
                print("\n" + "-" * 50)
                print("📍 Correlation: \(correlation.dimensionA) ↔ \(correlation.dimensionB)")

                if let coefficient = correlation.correlationCoefficient {
                    print("   Coefficient: \(String(format: "%.3f", coefficient))")
                    print("   Strength: \(correlation.strength.description)")
                    print("   Direction: \(correlation.direction.description)")
                }

                if let significance = correlation.significance {
                    print("   P-value: \(String(format: "%.4f", significance))")
                    print("   Significant: \(correlation.isSignificant ? "Yes ✓" : "No ✗")")
                }

                if let description = correlation.description {
                    print("   Description: \(description)")
                }

                if let examples = correlation.examples, !examples.isEmpty {
                    print("\n   📋 Examples:")
                    for example in examples {
                        print("      • \(example.description ?? "No description")")
                    }
                }
            }

            print("\n" + "=" * 60)

        } catch {
            print("❌ Error: \(error)")
        }
    }

    /// 测试：分析特定维度关联
    func testSpecificCorrelation() async {
        print("\n📊 Testing Specific Correlation - Emotion vs Spending")
        print("=" * 60)

        let testUserId = "test-user-123"

        do {
            if let correlation = try await engine.analyzeCorrelation(
                userId: testUserId,
                dimensionA: "emotion.score",
                dimensionB: "financial.spending"
            ) {
                print("\n✅ Emotion-Spending Correlation Found:")
                print("   \(correlation.generateDescription())")

                if let examples = correlation.examples {
                    print("\n   Case Studies:")
                    for (index, example) in examples.enumerated() {
                        let date = DateFormatter.localizedString(
                            from: example.date,
                            dateStyle: .short,
                            timeStyle: .none
                        )
                        print("   \(index + 1). \(date): Emotion=\(String(format: "%.1f", example.valueA)), Spending=¥\(String(format: "%.0f", example.valueB))")
                    }
                }
            } else {
                print("⚠️ No significant correlation found (need more data or r < 0.4)")
            }

        } catch {
            print("❌ Error: \(error)")
        }
    }

    /// 测试：验证已有关联
    func testVerifyCorrelation() async {
        print("\n📊 Testing Correlation Verification")
        print("=" * 60)

        // 创建一个测试关联
        let testCorrelation = Correlation(
            userId: "test-user-123",
            dimensionA: "emotion.score",
            dimensionB: "financial.spending",
            correlationCoefficient: -0.65,
            significance: 0.003,
            description: "情绪低落时支出增加 42%",
            lastVerified: Date().addingTimeInterval(-60 * 60 * 24 * 35) // 35 days ago
        )

        print("Original correlation: r=\(testCorrelation.correlationCoefficient ?? 0)")
        print("Last verified: \(testCorrelation.lastVerified?.description ?? "Never")")
        print("Needs revalidation: \(testCorrelation.needsRevalidation ? "Yes" : "No")")

        do {
            let isValid = try await engine.verifyCorrelation(testCorrelation)
            print("\n✅ Verification result: \(isValid ? "Still Valid ✓" : "No Longer Valid ✗")")

        } catch {
            print("❌ Error: \(error)")
        }
    }

    /// 演示：关联分析的实际应用场景
    func demonstrateRealWorldUsage() {
        print("\n🌟 Real-World Usage Scenarios")
        print("=" * 60)

        print("""

        1️⃣ Emotion-Spending Analysis (情绪消费分析)
           Use Case: 发现用户在情绪低落时是否有冲动消费倾向
           Benefit: 在检测到负面情绪时发送预算提醒
           Example: "压力大时，您的支出平均增加 42%，今天要注意控制预算"

        2️⃣ Exercise-Mood Correlation (运动情绪关联)
           Use Case: 分析运动对情绪的影响
           Benefit: 在用户情绪低落时推荐运动
           Example: "运动后您的情绪平均提升 35%，要不要去健身房？"

        3️⃣ Study-Progress Correlation (学习进度关联)
           Use Case: 分析学习时长与目标进度的关系
           Benefit: 优化学习计划，提高效率
           Example: "每多学习 1 小时，目标进度平均提升 8%"

        4️⃣ Sleep-Productivity Correlation (睡眠效率关联)
           Use Case: 发现睡眠质量对工作效率的影响
           Benefit: 提醒用户调整作息
           Example: "睡眠少于 6 小时时，您的任务完成率下降 25%"

        5️⃣ Weather-Mood Correlation (天气情绪关联)
           Use Case: 分析天气对情绪的影响
           Benefit: 在阴雨天主动关心用户
           Example: "雨天时您的情绪平均降低 0.3 分，今天要多关注自己"

        """)

        print("=" * 60)
    }

    /// 运行所有测试
    func runAllTests() async {
        print("\n🧪 CorrelationEngine Test Suite")
        print("================================\n")

        await testAnalyzeAllCorrelations()
        await testSpecificCorrelation()
        await testVerifyCorrelation()
        demonstrateRealWorldUsage()

        print("\n✅ All tests completed!")
    }
}

// MARK: - Usage Example

/*
 使用示例：

 // 在 App 启动后，定期运行关联分析
 Task {
     let tester = TestCorrelationEngine()
     await tester.runAllTests()
 }

 // 或者在特定场景触发：
 // 1. 每天凌晨 3 点自动分析（后台任务）
 // 2. 用户记录情绪时实时更新
 // 3. 用户查看洞察页面时按需分析
 */

// MARK: - Expected Output

/*
 预期输出示例：

 📊 Testing Correlation Engine - Analyze All Correlations
 ============================================================

 ✅ Found 3 correlations:

 --------------------------------------------------
 📍 Correlation: emotion.score ↔ financial.spending
    Coefficient: -0.658
    Strength: 强
    Direction: 负
    P-value: 0.0032
    Significant: Yes ✓
    Description: 情绪低落时，支出平均增加 42%（相关系数: -0.66）

    📋 Examples:
       • 情绪 -0.8，支出 ¥8500
       • 情绪 -0.6，支出 ¥6200
       • 情绪 -0.5，支出 ¥5800

 --------------------------------------------------
 📍 Correlation: habit.exercise ↔ emotion.score
    Coefficient: 0.523
    Strength: 中等
    Direction: 正
    P-value: 0.0180
    Significant: Yes ✓
    Description: 运动后情绪平均提升 35%（相关系数: 0.52）

 ============================================================
 */
