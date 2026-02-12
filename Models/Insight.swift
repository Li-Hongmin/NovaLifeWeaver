import Foundation

/// 洞察模型 - AI 生成的可执行建议
struct Insight: Codable, Identifiable {
    // MARK: - 基础信息
    let id: String
    let userId: String
    var type: InsightType
    var category: InsightCategory
    var title: String
    var description: String

    // MARK: - 优先级和紧急度
    var priority: Int              // 1-5
    var urgency: Double            // 0.0-1.0
    var impact: Double             // 预期影响 0.0-1.0
    var confidence: Double         // AI 信心度 0.0-1.0

    // MARK: - 可执行性
    var actionable: Bool
    var suggestedActions: [SuggestedAction]?

    // MARK: - 状态和反馈
    var status: InsightStatus
    var userFeedback: String?

    // MARK: - 时间戳
    var generatedAt: Date
    var validUntil: Date?

    // MARK: - 初始化
    init(
        id: String = UUID().uuidString,
        userId: String,
        type: InsightType,
        category: InsightCategory,
        title: String,
        description: String,
        priority: Int = 3,
        urgency: Double = 0.5,
        impact: Double = 0.5,
        confidence: Double = 0.8,
        actionable: Bool = true,
        suggestedActions: [SuggestedAction]? = nil,
        status: InsightStatus = .new,
        userFeedback: String? = nil,
        generatedAt: Date = Date(),
        validUntil: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.category = category
        self.title = title
        self.description = description
        self.priority = priority
        self.urgency = urgency
        self.impact = impact
        self.confidence = confidence
        self.actionable = actionable
        self.suggestedActions = suggestedActions
        self.status = status
        self.userFeedback = userFeedback
        self.generatedAt = generatedAt
        self.validUntil = validUntil
    }

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type
        case category
        case title
        case description
        case priority
        case urgency
        case impact
        case confidence
        case actionable
        case suggestedActions = "suggested_actions"
        case status
        case userFeedback = "user_feedback"
        case generatedAt = "generated_at"
        case validUntil = "valid_until"
    }
}

// MARK: - 业务逻辑扩展
extension Insight {
    /// 是否需要立即关注
    var needsImmediateAttention: Bool {
        urgency > 0.8 || type == .warning
    }

    /// 是否仍然有效
    var isValid: Bool {
        guard let validUntil = validUntil else { return true }
        return Date() <= validUntil
    }

    /// 综合评分（用于排序）
    var overallScore: Double {
        (urgency * 0.4 + impact * 0.3 + confidence * 0.2 + Double(priority) / 5.0 * 0.1)
    }
}

// MARK: - 枚举定义

/// 洞察类型
enum InsightType: String, Codable {
    case warning            // 警告
    case pattern            // 模式发现
    case recommendation     // 建议
    case achievement        // 成就庆祝
    case opportunity        // 机会发现
}

/// 洞察分类
enum InsightCategory: String, Codable {
    case financial          // 财务
    case health             // 健康/情绪
    case habit              // 习惯
    case goal               // 目标
    case time               // 时间管理
    case general            // 综合
}

/// 洞察状态
enum InsightStatus: String, Codable {
    case new                // 新生成
    case viewed             // 已查看
    case acted              // 已执行
    case dismissed          // 已忽略
}

/// 建议的行动
struct SuggestedAction: Codable, Identifiable {
    let id: String
    var action: String          // 行动描述
    var type: String            // "create_event", "update_goal", "set_reminder"
    var parameters: [String: String]?
    var priority: Int

    init(
        id: String = UUID().uuidString,
        action: String,
        type: String,
        parameters: [String: String]? = nil,
        priority: Int = 3
    ) {
        self.id = id
        self.action = action
        self.type = type
        self.parameters = parameters
        self.priority = priority
    }
}
