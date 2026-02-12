import Foundation

/// BedrockService 测试
class TestBedrockService {

    static func runTests() async {
        print("\n🧪 ==================== BedrockService 测试开始 ====================\n")

        let bedrock = BedrockService.shared

        // 测试 1：简单文本生成
        print("📝 测试 1：Nova Lite 文本生成")
        do {
            let response = try await bedrock.invokeNova(
                prompt: "用一句话说明 NovaLife Weaver 是什么",
                model: .lite
            )
            print("   ✅ 响应: \(response)")
        } catch {
            print("   ❌ 失败: \(error)")
        }

        // 测试 2：结构化输出
        print("\n📝 测试 2：结构化 JSON 输出")
        do {
            let prompt = """
            分析这个目标并返回 JSON：
            "3 月考过 JLPT N2"

            返回格式：
            {
                "goal": "考过 JLPT N2",
                "deadline": "2026-03-31",
                "category": "learning",
                "subtasks": ["复习语法", "练习听力", "背单词"]
            }
            """

            let response = try await bedrock.invokeNova(
                prompt: prompt,
                model: .lite
            )
            print("   ✅ 结构化响应: \(response.prefix(200))...")
        } catch {
            print("   ❌ 失败: \(error)")
        }

        // 测试 3：重试机制
        print("\n📝 测试 3：重试机制")
        do {
            let response = try await bedrock.invokeWithRetry(
                prompt: "测试重试机制",
                maxRetries: 2
            )
            print("   ✅ 重试成功: \(response.prefix(100))...")
        } catch {
            print("   ❌ 失败: \(error)")
        }

        print("\n✅ ==================== BedrockService 测试完成 ====================\n")
    }
}
