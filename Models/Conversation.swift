import Foundation

// MARK: - Conversation（对话）

/// 对话模型 - 代表一个完整的对话线程
struct Conversation: Identifiable, Codable {
    let id: String
    var title: String              // 对话标题（自动生成或用户命名）
    var messages: [Message]        // 消息列表
    let createdAt: Date
    var updatedAt: Date
    var isActive: Bool             // 是否是当前活跃对话

    init(
        id: String = UUID().uuidString,
        title: String = "新对话",
        messages: [Message] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isActive = isActive
    }
}

// MARK: - Message（消息）

/// 消息模型 - 对话中的单条消息
struct Message: Identifiable, Codable {
    let id: String
    let role: MessageRole          // AI 或用户
    var content: String            // 文本内容
    var toolCards: [ToolCard]?     // 嵌入的工具卡片
    let timestamp: Date

    init(
        id: String = UUID().uuidString,
        role: MessageRole,
        content: String,
        toolCards: [ToolCard]? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.toolCards = toolCards
        self.timestamp = timestamp
    }
}

/// 消息角色
enum MessageRole: String, Codable {
    case user       // 用户
    case assistant  // AI 助手
    case system     // 系统消息
}

// MARK: - ToolCard（工具卡片）

/// 工具卡片 - 在对话中展示的可交互工具
struct ToolCard: Identifiable, Codable {
    let id: String
    var type: ToolCardType         // 卡片类型
    var data: [String: String]     // 卡片数据（简化为字符串字典）
    var status: CardStatus         // 卡片状态

    init(
        id: String = UUID().uuidString,
        type: ToolCardType,
        data: [String: String],
        status: CardStatus = .pending
    ) {
        self.id = id
        self.type = type
        self.data = data
        self.status = status
    }
}

/// 工具卡片类型
enum ToolCardType: String, Codable {
    case goalPreview      // 目标预览
    case habitPreview     // 习惯预览
    case expensePreview   // 支出预览
    case emotionPreview   // 情绪预览
    case goalList         // 目标列表
    case habitList        // 习惯列表
    case expenseList      // 支出列表
    case emotionTimeline  // 情绪时间线
    case correlationChart // 关联图表
    case insightCard      // 洞察卡片

    var displayName: String {
        switch self {
        case .goalPreview:      return "目标预览"
        case .habitPreview:     return "习惯预览"
        case .expensePreview:   return "支出预览"
        case .emotionPreview:   return "情绪预览"
        case .goalList:         return "目标列表"
        case .habitList:        return "习惯列表"
        case .expenseList:      return "支出列表"
        case .emotionTimeline:  return "情绪时间线"
        case .correlationChart: return "关联分析"
        case .insightCard:      return "智能洞察"
        }
    }

    var icon: String {
        switch self {
        case .goalPreview, .goalList:           return "target"
        case .habitPreview, .habitList:         return "repeat.circle"
        case .expensePreview, .expenseList:     return "yensign.circle"
        case .emotionPreview, .emotionTimeline: return "heart.circle"
        case .correlationChart:                 return "chart.xyaxis.line"
        case .insightCard:                      return "lightbulb.circle"
        }
    }
}

/// 卡片状态
enum CardStatus: String, Codable {
    case pending    // 等待用户确认
    case confirmed  // 已确认
    case cancelled  // 已取消
    case editing    // 编辑中
}
