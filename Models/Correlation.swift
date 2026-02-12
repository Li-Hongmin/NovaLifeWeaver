import Foundation

/// 关联关系模型 - 跨领域数据关联发现（核心创新）
struct Correlation: Codable, Identifiable {
    // MARK: - 基础信息
    let id: String
    let userId: String
    var dimensionA: String         // 维度 A: "emotion.score"
    var dimensionB: String         // 维度 B: "financial.spending"

    // MARK: - 统计数据
    var correlationCoefficient: Double?  // Pearson 相关系数 (-1.0 to 1.0)
    var significance: Double?            // 统计显著性 (p-value)

    // MARK: - 描述和示例
    var description: String?             // 可读描述
    var examples: [CorrelationExample]?  // 具体案例

    // MARK: - 时间戳
    var discoveredAt: Date
    var lastVerified: Date?

    // MARK: - 初始化
    init(
        id: String = UUID().uuidString,
        userId: String,
        dimensionA: String,
        dimensionB: String,
        correlationCoefficient: Double? = nil,
        significance: Double? = nil,
        description: String? = nil,
        examples: [CorrelationExample]? = nil,
        discoveredAt: Date = Date(),
        lastVerified: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.dimensionA = dimensionA
        self.dimensionB = dimensionB
        self.correlationCoefficient = correlationCoefficient
        self.significance = significance
        self.description = description
        self.examples = examples
        self.discoveredAt = discoveredAt
        self.lastVerified = lastVerified
    }

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case dimensionA = "dimension_a"
        case dimensionB = "dimension_b"
        case correlationCoefficient = "correlation_coefficient"
        case significance
        case description
        case examples
        case discoveredAt = "discovered_at"
        case lastVerified = "last_verified"
    }
}

// MARK: - 业务逻辑扩展
extension Correlation {
    /// 相关性强度
    var strength: CorrelationStrength {
        guard let coefficient = correlationCoefficient else { return .none }
        let absValue = abs(coefficient)

        if absValue >= 0.7 {
            return .strong
        } else if absValue >= 0.4 {
            return .moderate
        } else if absValue >= 0.2 {
            return .weak
        } else {
            return .none
        }
    }

    /// 相关性方向
    var direction: CorrelationDirection {
        guard let coefficient = correlationCoefficient else { return .none }

        if coefficient > 0.1 {
            return .positive
        } else if coefficient < -0.1 {
            return .negative
        } else {
            return .none
        }
    }

    /// 是否统计显著
    var isSignificant: Bool {
        guard let significance = significance else { return false }
        return significance < 0.05 // p < 0.05
    }

    /// 是否需要重新验证（超过 30 天）
    var needsRevalidation: Bool {
        guard let lastVerified = lastVerified else { return true }
        let daysSinceVerification = Calendar.current.dateComponents([.day], from: lastVerified, to: Date()).day ?? 0
        return daysSinceVerification > 30
    }

    /// 生成可读的关联描述
    func generateDescription() -> String {
        guard let coefficient = correlationCoefficient else {
            return "正在分析 \(dimensionA) 和 \(dimensionB) 的关系..."
        }

        let strengthDesc = strength.description
        let directionDesc = direction.description

        // 解析维度名称
        let (labelA, labelB) = (parseDimension(dimensionA), parseDimension(dimensionB))

        if direction == .negative {
            return "\(labelA)越\(directionDesc)，\(labelB)越\(strengthDesc)（相关系数: \(String(format: "%.2f", coefficient))）"
        } else {
            return "\(labelA)和\(labelB)呈\(strengthDesc)\(directionDesc)相关（相关系数: \(String(format: "%.2f", coefficient))）"
        }
    }

    /// 解析维度名称为可读文本
    private func parseDimension(_ dimension: String) -> String {
        let parts = dimension.split(separator: ".")
        guard parts.count >= 2 else { return dimension }

        let domain = String(parts[0])
        let metric = String(parts[1])

        // 领域映射
        let domainMap: [String: String] = [
            "emotion": "情绪",
            "financial": "支出",
            "habit": "习惯",
            "goal": "目标"
        ]

        // 指标映射
        let metricMap: [String: String] = [
            "score": "评分",
            "spending": "金额",
            "completion": "完成率",
            "progress": "进度"
        ]

        let domainName = domainMap[domain] ?? domain
        let metricName = metricMap[metric] ?? metric

        return "\(domainName)\(metricName)"
    }
}

// MARK: - 枚举定义

/// 相关性强度
enum CorrelationStrength: String {
    case strong     // 强相关
    case moderate   // 中等相关
    case weak       // 弱相关
    case none       // 无相关

    var description: String {
        switch self {
        case .strong: return "强"
        case .moderate: return "中等"
        case .weak: return "弱"
        case .none: return "无"
        }
    }
}

/// 相关性方向
enum CorrelationDirection: String {
    case positive   // 正相关
    case negative   // 负相关
    case none       // 无相关

    var description: String {
        switch self {
        case .positive: return "正"
        case .negative: return "负"
        case .none: return "无"
        }
    }
}

/// 关联案例
struct CorrelationExample: Codable {
    var date: Date
    var valueA: Double
    var valueB: Double
    var description: String?

    init(
        date: Date,
        valueA: Double,
        valueB: Double,
        description: String? = nil
    ) {
        self.date = date
        self.valueA = valueA
        self.valueB = valueB
        self.description = description
    }
}
