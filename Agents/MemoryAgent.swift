import Foundation

/// Memory Agent - 多模态输入处理核心
/// 使用 Nova Multimodal 提取结构化数据
class MemoryAgent {
    static let shared = MemoryAgent()

    private let bedrockService = BedrockService.shared

    private init() {}

    // MARK: - Text Processing

    /// 处理文本输入
    func processText(_ text: String, userId: String) async throws -> MemoryProcessedRecord {
        // 1. 检测领域
        let domain = detectDomain(text: text)

        // 2. 使用 Nova Lite 提取结构化数据
        let prompt = buildExtractionPrompt(text: text, domain: domain)

        do {
            let response = try await bedrockService.invokeNova(
                prompt: prompt,
                model: .lite,
                temperature: 0.3
            )

            // 3. 解析响应
            let structured = try parseJSON(from: response)

            return MemoryProcessedRecord(
                type: .text,
                content: text,
                structuredData: structured,
                domain: domain
            )
        } catch {
            print("⚠️ AI 提取失败，使用基础解析: \(error)")
            // 降级处理：基础文本解析
            return MemoryProcessedRecord(
                type: .text,
                content: text,
                structuredData: [:],
                domain: domain
            )
        }
    }

    // MARK: - Image Processing

    /// 处理图片输入（OCR）
    func processImage(_ imageData: Data, userId: String) async throws -> MemoryProcessedRecord {
        let prompt = """
        从收据图片中提取以下信息（JSON格式）：
        {
          "merchant": "商家名称",
          "amount": 金额数字,
          "currency": "JPY",
          "category": "食品/交通/购物/娱乐/其他",
          "date": "YYYY-MM-DD"
        }

        如果不是收据，返回：{"error": "not_a_receipt"}
        """

        do {
            let response = try await bedrockService.invokeMultimodal(
                text: prompt,
                image: imageData
            )

            let structured = try parseJSON(from: response.text)

            return MemoryProcessedRecord(
                type: .image,
                content: response.text,
                structuredData: structured,
                domain: .finance
            )
        } catch {
            print("⚠️ OCR 失败: \(error)")
            throw MemoryAgentError.ocrFailed
        }
    }

    // MARK: - Domain Detection

    /// 快速检测输入领域
    private func detectDomain(text: String) -> Domain {
        let keywords = text.lowercased()

        if keywords.contains("花") || keywords.contains("买") || keywords.contains("元") || keywords.contains("钱") {
            return .finance
        }
        if keywords.contains("感觉") || keywords.contains("情绪") || keywords.contains("心情") {
            return .emotion
        }
        if keywords.contains("目标") || keywords.contains("想") || keywords.contains("计划") {
            return .goal
        }

        return .general
    }

    // MARK: - Prompt Engineering

    /// 构建提取 Prompt
    private func buildExtractionPrompt(text: String, domain: Domain) -> String {
        switch domain {
        case .finance:
            return """
            从以下文本提取财务信息（严格JSON格式）：
            "\(text)"

            返回格式：
            ```json
            {
              "amount": 数字,
              "currency": "JPY",
              "category": "食品/交通/购物/娱乐/医疗/教育/其他",
              "mood": -1.0到1.0之间的情绪分数
            }
            ```

            只返回JSON，不要其他文字。
            """

        case .emotion:
            return """
            从以下文本提取情绪信息（严格JSON格式）：
            "\(text)"

            返回格式：
            ```json
            {
              "score": -1.0到1.0,
              "intensity": 0.0到1.0,
              "emotions": ["标签1", "标签2"],
              "trigger": "触发因素"
            }
            ```

            只返回JSON，不要其他文字。
            """

        default:
            return """
            分析以下文本并提取关键信息（JSON格式）：
            "\(text)"
            """
        }
    }

    // MARK: - JSON Parsing

    /// 解析 JSON
    private func parseJSON(from text: String) throws -> [String: Any] {
        // 1. 提取 JSON（可能在代码块中）
        let jsonString = extractJSON(from: text)

        // 2. 解析
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw MemoryAgentError.invalidJSON
        }

        return json
    }

    /// 提取 JSON 字符串
    private func extractJSON(from text: String) -> String {
        // 尝试提取 Markdown 代码块
        if let range = text.range(of: "```json\\s*(.+?)```", options: .regularExpression) {
            let jsonBlock = String(text[range])
            return jsonBlock
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // 尝试直接查找 { ... }
        if let start = text.firstIndex(of: "{"),
           let end = text.lastIndex(of: "}") {
            return String(text[start...end])
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Supporting Types

/// 处理结果
struct MemoryProcessedRecord {
    let type: InputType
    let content: String
    let structuredData: [String: Any]
    let domain: Domain
}

/// 输入类型
enum InputType {
    case text
    case audio
    case image
}

/// 输入领域
enum Domain {
    case finance
    case emotion
    case goal
    case schedule
    case general
}

/// Memory Agent 错误
enum MemoryAgentError: Error, LocalizedError {
    case invalidJSON
    case ocrFailed
    case audioNotSupported

    var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return "无法解析AI返回的数据"
        case .ocrFailed:
            return "图片识别失败"
        case .audioNotSupported:
            return "语音功能暂未支持"
        }
    }
}
