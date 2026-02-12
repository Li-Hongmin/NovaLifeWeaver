import Foundation

/// 对话交互测试 - 验证 AI-First 流程
class TestConversation {

    static func runTests() async {
        print("\n🧪 ==================== 对话交互测试开始 ====================\n")

        let conversationService = ConversationService.shared
        let userId = "test-user"

        // 测试 1：创建目标（真实 AI 调用）
        print("📝 测试 1：AI 创建目标")
        print("   输入：\"我想在3月考过 JLPT N2\"")

        let result1 = await conversationService.processInput(
            "我想在3月考过 JLPT N2",
            userId: userId,
            context: nil
        )

        if result1.success {
            print("   ✅ 成功：\(result1.message)")
            print("   🔧 工具：\(result1.toolUsed ?? "none")")
        } else {
            print("   ❌ 失败：\(result1.message)")
        }

        // 等待一下
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        // 测试 2：创建习惯
        print("\n📝 测试 2：AI 创建习惯")
        print("   输入：\"每天晨跑30分钟\"")

        let result2 = await conversationService.processInput(
            "每天晨跑30分钟",
            userId: userId,
            context: nil
        )

        if result2.success {
            print("   ✅ 成功：\(result2.message)")
            print("   🔧 工具：\(result2.toolUsed ?? "none")")
        } else {
            print("   ❌ 失败：\(result2.message)")
        }

        try? await Task.sleep(nanoseconds: 1_000_000_000)

        // 测试 3：记录支出
        print("\n📝 测试 3：AI 记录支出")
        print("   输入：\"今天午餐花了800日元\"")

        let result3 = await conversationService.processInput(
            "今天午餐花了800日元",
            userId: userId,
            context: nil
        )

        if result3.success {
            print("   ✅ 成功：\(result3.message)")
            print("   🔧 工具：\(result3.toolUsed ?? "none")")
        } else {
            print("   ❌ 失败：\(result3.message)")
        }

        try? await Task.sleep(nanoseconds: 1_000_000_000)

        // 测试 4：记录情绪
        print("\n📝 测试 4：AI 记录情绪")
        print("   输入：\"今天工作压力很大\"")

        let result4 = await conversationService.processInput(
            "今天工作压力很大",
            userId: userId,
            context: nil
        )

        if result4.success {
            print("   ✅ 成功：\(result4.message)")
            print("   🔧 工具：\(result4.toolUsed ?? "none")")
        } else {
            print("   ❌ 失败：\(result4.message)")
        }

        try? await Task.sleep(nanoseconds: 1_000_000_000)

        // 测试 5：一般对话
        print("\n📝 测试 5：一般对话")
        print("   输入：\"你好\"")

        let result5 = await conversationService.processInput(
            "你好",
            userId: userId,
            context: nil
        )

        if result5.success {
            print("   ✅ 成功：\(result5.message)")
        } else {
            print("   ❌ 失败：\(result5.message)")
        }

        print("\n✅ ==================== 对话测试完成 ====================\n")

        // 总结
        let successCount = [result1, result2, result3, result4, result5].filter { $0.success }.count
        print("📊 测试统计：")
        print("   - 成功：\(successCount)/5")
        print("   - 失败：\(5 - successCount)/5")
        print("   - Tool Use 系统：\(successCount >= 4 ? "✅ 工作正常" : "⚠️ 需要检查")")
    }

    // MARK: - 测试 Nova API 直接调用

    static func testNovaAPI() async {
        print("\n🧪 ==================== Nova API 测试 ====================\n")

        let bedrock = BedrockService.shared

        print("📝 测试：Nova Lite 文本生成")
        print("   提示：\"用一句话介绍 NovaLife Weaver\"")

        do {
            let response = try await bedrock.invokeNova(
                prompt: "用一句话介绍 NovaLife Weaver（一个 AI 生活助手应用）",
                model: .lite,
                maxTokens: 100,
                temperature: 0.7
            )

            print("   ✅ Nova 响应：\(response)")

        } catch {
            print("   ❌ API 调用失败：\(error)")
        }

        print("\n✅ ==================== API 测试完成 ====================\n")
    }
}
