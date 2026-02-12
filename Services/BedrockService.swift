import Foundation

/// AWS Bedrock 服务 - Nova AI 集成
class BedrockService {
    static let shared = BedrockService()

    private let region = "ap-northeast-1"
    private var endpoint: String {
        "https://bedrock-runtime.\(region).amazonaws.com"
    }

    // Nova 模型 IDs
    enum NovaModel: String {
        case lite = "amazon.nova-2-lite-v1:0"
        case pro = "amazon.nova-pro-v1:0"
        case premier = "amazon.nova-premier-v1:0"
        case micro = "amazon.nova-micro-v1:0"
        case sonic = "amazon.nova-sonic-v1:0"
    }

    private init() {}

    // MARK: - 文本生成

    /// 调用 Nova 文本生成（简化版，使用 AWS CLI）
    func invokeNova(
        prompt: String,
        model: NovaModel = .lite,
        maxTokens: Int = 2048,
        temperature: Double = 0.7
    ) async throws -> String {

        let requestBody: [String: Any] = [
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["text": prompt]
                    ]
                ]
            ],
            "inferenceConfig": [
                "max_new_tokens": maxTokens,
                "temperature": temperature
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        // 使用 AWS CLI 调用（临时方案，后续可改为 AWS SDK）
        let response = try await executeAWSCLI(
            modelId: model.rawValue,
            body: jsonString
        )

        return try parseTextResponse(response)
    }

    /// 调用 Nova Multimodal（图片 + 文本）
    func invokeMultimodal(
        text: String? = nil,
        image: Data? = nil,
        audio: Data? = nil
    ) async throws -> MultimodalResponse {

        var contentBlocks: [[String: Any]] = []

        // 添加文本
        if let text = text {
            contentBlocks.append([
                "text": text
            ])
        }

        // 添加图片
        if let imageData = image {
            let base64Image = imageData.base64EncodedString()
            contentBlocks.append([
                "image": [
                    "format": "png",
                    "source": [
                        "bytes": base64Image
                    ]
                ]
            ])
        }

        // TODO: 添加音频支持

        let requestBody: [String: Any] = [
            "messages": [
                [
                    "role": "user",
                    "content": contentBlocks
                ]
            ],
            "inferenceConfig": [
                "max_new_tokens": 2048,
                "temperature": 0.7
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        let response = try await executeAWSCLI(
            modelId: NovaModel.pro.rawValue,  // Multimodal 使用 Pro
            body: jsonString
        )

        return try parseMultimodalResponse(response)
    }

    // MARK: - 私有方法

    /// 执行 AWS CLI 调用
    private func executeAWSCLI(
        modelId: String,
        body: String
    ) async throws -> String {

        // 1. 写入临时文件
        let bodyPath = "/tmp/bedrock_input.json"
        let outputPath = "/tmp/bedrock_output.json"

        try body.write(toFile: bodyPath, atomically: true, encoding: .utf8)

        // 2. 执行 AWS CLI（使用文件输入）
        let command = """
        aws bedrock-runtime invoke-model \
            --model-id \(modelId) \
            --region \(region) \
            --body file://\(bodyPath) \
            \(outputPath) 2>&1
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", command]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let statusOutput = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            print("❌ AWS CLI 错误：\(statusOutput)")
            throw BedrockError.apiCallFailed(statusOutput)
        }

        // 3. 读取响应
        guard let responseData = try? Data(contentsOf: URL(fileURLWithPath: outputPath)),
              let response = String(data: responseData, encoding: .utf8) else {
            throw BedrockError.invalidResponse
        }

        print("✅ AWS API 调用成功")
        return response
    }

    /// 解析文本响应
    private func parseTextResponse(_ response: String) throws -> String {
        guard let data = response.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let output = json["output"] as? [String: Any],
              let message = output["message"] as? [String: Any],
              let content = message["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw BedrockError.invalidResponse
        }

        return text
    }

    /// 解析 Multimodal 响应
    private func parseMultimodalResponse(_ response: String) throws -> MultimodalResponse {
        // 先解析文本
        let text = try parseTextResponse(response)

        // 尝试解析为 JSON（如果 AI 返回结构化数据）
        if let data = text.data(using: .utf8),
           let json = try? JSONDecoder().decode([String: String].self, from: data) {
            return MultimodalResponse(
                text: text,
                structured: json
            )
        }

        return MultimodalResponse(text: text)
    }
}

// MARK: - 数据结构

/// Multimodal 响应
struct MultimodalResponse {
    let text: String
    let structured: [String: String]?

    init(text: String, structured: [String: String]? = nil) {
        self.text = text
        self.structured = structured
    }
}

/// Bedrock 错误类型
enum BedrockError: Error {
    case apiCallFailed(String)
    case invalidResponse
    case networkError
    case authenticationFailed
    case rateLimitExceeded

    var localizedDescription: String {
        switch self {
        case .apiCallFailed(let message):
            return "API 调用失败: \(message)"
        case .invalidResponse:
            return "无法解析 API 响应"
        case .networkError:
            return "网络连接错误"
        case .authenticationFailed:
            return "AWS 认证失败，请检查凭证配置"
        case .rateLimitExceeded:
            return "API 调用频率超限，请稍后重试"
        }
    }
}

// MARK: - 重试机制扩展
extension BedrockService {
    /// 带重试的调用
    func invokeWithRetry(
        prompt: String,
        model: NovaModel = .lite,
        maxRetries: Int = 3
    ) async throws -> String {

        var lastError: Error?

        for attempt in 1...maxRetries {
            do {
                return try await invokeNova(
                    prompt: prompt,
                    model: model
                )
            } catch {
                lastError = error
                print("⚠️ Attempt \(attempt)/\(maxRetries) failed: \(error)")

                // 指数退避
                if attempt < maxRetries {
                    let delay = pow(2.0, Double(attempt)) // 2, 4, 8 seconds
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }

        throw lastError ?? BedrockError.apiCallFailed("All retries failed")
    }
}
