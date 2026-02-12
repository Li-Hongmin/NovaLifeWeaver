import Foundation

/// 目标模型 - SMART 目标管理
struct Goal: Codable, Identifiable {
    // MARK: - 基础信息
    let id: String
    let userId: String
    var title: String
    var description: String?
    var category: String?

    // MARK: - 时间相关
    var deadline: Date?
    var completedAt: Date?

    // MARK: - SMART 属性
    var measurableMetric: String?  // 可衡量指标
    var targetValue: Double?       // 目标值
    var currentValue: Double       // 当前进度

    // MARK: - 状态和优先级
    var status: GoalStatus         // active, paused, completed, cancelled
    var priority: Int              // 1-5, 5 最高

    // MARK: - 关联信息
    var subtasks: [Subtask]?
    var relatedHabits: [String]?   // Habit IDs
    var budget: Double?

    // MARK: - AI 辅助
    var aiSuggestions: String?
    var confidence: Double?        // AI 信心度 0.0-1.0

    // MARK: - 时间戳
    let createdAt: Date
    var updatedAt: Date

    // MARK: - 初始化
    init(
        id: String = UUID().uuidString,
        userId: String,
        title: String,
        description: String? = nil,
        category: String? = nil,
        deadline: Date? = nil,
        measurableMetric: String? = nil,
        targetValue: Double? = nil,
        currentValue: Double = 0.0,
        status: GoalStatus = .active,
        priority: Int = 3,
        subtasks: [Subtask]? = nil,
        relatedHabits: [String]? = nil,
        budget: Double? = nil,
        aiSuggestions: String? = nil,
        confidence: Double? = nil,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.description = description
        self.category = category
        self.deadline = deadline
        self.measurableMetric = measurableMetric
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.status = status
        self.priority = priority
        self.subtasks = subtasks
        self.relatedHabits = relatedHabits
        self.budget = budget
        self.aiSuggestions = aiSuggestions
        self.confidence = confidence
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.updatedAt = updatedAt
    }

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case category
        case deadline
        case measurableMetric = "measurable_metric"
        case targetValue = "target_value"
        case currentValue = "current_value"
        case status
        case priority
        case subtasks
        case relatedHabits = "related_habits"
        case budget
        case aiSuggestions = "ai_suggestions"
        case confidence
        case createdAt = "created_at"
        case completedAt = "completed_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - 业务逻辑扩展
extension Goal {
    /// 完成进度（0.0 - 1.0）
    var progress: Double {
        guard let target = targetValue, target > 0 else { return 0 }
        return min(currentValue / target, 1.0)
    }

    /// 完成百分比（0-100）
    var progressPercentage: Int {
        Int(progress * 100)
    }

    /// 是否已完成
    var isCompleted: Bool {
        status == .completed
    }

    /// 是否即将到期（7天内）
    var isDueSoon: Bool {
        guard let deadline = deadline else { return false }
        let daysUntilDeadline = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
        return daysUntilDeadline >= 0 && daysUntilDeadline <= 7
    }

    /// 是否已逾期
    var isOverdue: Bool {
        guard let deadline = deadline else { return false }
        return Date() > deadline && status != .completed
    }

    /// 剩余天数
    var daysRemaining: Int? {
        guard let deadline = deadline else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: deadline).day
    }

    /// 标记为完成
    mutating func markCompleted() {
        status = .completed
        completedAt = Date()
        currentValue = targetValue ?? currentValue
        updatedAt = Date()
    }

    /// 更新进度
    mutating func updateProgress(_ value: Double) {
        currentValue = value
        updatedAt = Date()

        // 如果达到目标值，自动标记为完成
        if let target = targetValue, currentValue >= target {
            markCompleted()
        }
    }
}

// MARK: - 枚举定义

/// 目标状态
enum GoalStatus: String, Codable {
    case active      // 进行中
    case paused      // 暂停
    case completed   // 已完成
    case cancelled   // 已取消
}

/// 子任务
struct Subtask: Codable, Identifiable {
    let id: String
    var title: String
    var completed: Bool
    var deadline: Date?

    init(
        id: String = UUID().uuidString,
        title: String,
        completed: Bool = false,
        deadline: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.completed = completed
        self.deadline = deadline
    }
}
