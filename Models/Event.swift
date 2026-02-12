import Foundation

/// 事件模型 - 日程事件（与 macOS Calendar 同步）
struct Event: Codable, Identifiable {
    // MARK: - 基础信息
    let id: String
    let userId: String
    var title: String
    var description: String?
    var location: String?

    // MARK: - 时间信息
    var startTime: Date
    var endTime: Date?
    var duration: Int?             // 分钟
    var allDay: Bool

    // MARK: - 分类和优先级
    var category: String?
    var priority: Int              // 1-5

    // MARK: - 关联信息
    var relatedGoalId: String?
    var relatedHabitId: String?

    // MARK: - 同步信息
    var source: EventSource        // manual, planner, calendar
    var calendarId: String?        // EventKit calendar ID
    var syncedToCalendar: Bool

    // MARK: - 完成状态
    var completed: Bool
    var completionNote: String?

    // MARK: - AI 建议
    var suggestedByAI: Bool
    var aiReasoning: String?

    // MARK: - 时间戳
    let createdAt: Date
    var updatedAt: Date

    // MARK: - 初始化
    init(
        id: String = UUID().uuidString,
        userId: String,
        title: String,
        description: String? = nil,
        location: String? = nil,
        startTime: Date,
        endTime: Date? = nil,
        duration: Int? = nil,
        allDay: Bool = false,
        category: String? = nil,
        priority: Int = 3,
        relatedGoalId: String? = nil,
        relatedHabitId: String? = nil,
        source: EventSource = .manual,
        calendarId: String? = nil,
        syncedToCalendar: Bool = false,
        completed: Bool = false,
        completionNote: String? = nil,
        suggestedByAI: Bool = false,
        aiReasoning: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.description = description
        self.location = location
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.allDay = allDay
        self.category = category
        self.priority = priority
        self.relatedGoalId = relatedGoalId
        self.relatedHabitId = relatedHabitId
        self.source = source
        self.calendarId = calendarId
        self.syncedToCalendar = syncedToCalendar
        self.completed = completed
        self.completionNote = completionNote
        self.suggestedByAI = suggestedByAI
        self.aiReasoning = aiReasoning
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case location
        case startTime = "start_time"
        case endTime = "end_time"
        case duration
        case allDay = "all_day"
        case category
        case priority
        case relatedGoalId = "related_goal_id"
        case relatedHabitId = "related_habit_id"
        case source
        case calendarId = "calendar_id"
        case syncedToCalendar = "synced_to_calendar"
        case completed
        case completionNote = "completion_note"
        case suggestedByAI = "suggested_by_ai"
        case aiReasoning = "ai_reasoning"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - 业务逻辑扩展
extension Event {
    /// 是否即将开始（1小时内）
    var isUpcoming: Bool {
        let timeUntilStart = startTime.timeIntervalSince(Date())
        return timeUntilStart > 0 && timeUntilStart < 3600
    }

    /// 是否正在进行中
    var isOngoing: Bool {
        let now = Date()
        if let end = endTime {
            return now >= startTime && now <= end
        }
        return false
    }

    /// 是否已结束
    var isFinished: Bool {
        if let end = endTime {
            return Date() > end
        }
        return Date() > startTime
    }

    /// 持续时间（分钟）
    var actualDuration: Int {
        if let duration = duration {
            return duration
        }
        if let end = endTime {
            return Int(end.timeIntervalSince(startTime) / 60)
        }
        return 60 // 默认 1 小时
    }

    /// 与另一个事件是否有冲突
    func hasConflict(with other: Event) -> Bool {
        let thisStart = startTime
        let thisEnd = endTime ?? startTime.addingTimeInterval(TimeInterval(actualDuration * 60))
        let otherStart = other.startTime
        let otherEnd = other.endTime ?? other.startTime.addingTimeInterval(TimeInterval(other.actualDuration * 60))

        return thisStart < otherEnd && otherStart < thisEnd
    }
}

// MARK: - 枚举定义

/// 事件来源
enum EventSource: String, Codable {
    case manual         // 手动创建
    case planner        // Planner Agent 生成
    case calendar       // 从 macOS Calendar 同步
    case habit          // 习惯提醒
}
