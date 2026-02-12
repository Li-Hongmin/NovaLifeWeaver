import Foundation

/// 习惯模型 - 习惯追踪和养成
struct Habit: Codable, Identifiable {
    // MARK: - 基础信息
    let id: String
    let userId: String
    var name: String
    var description: String?
    var category: String?

    // MARK: - 频率设置
    var frequency: HabitFrequency  // daily, weekly, monthly
    var targetCount: Int           // 每个周期的目标次数

    // MARK: - 状态
    var status: HabitStatus        // active, paused, archived

    // MARK: - 统计数据
    var streak: Int                // 当前连续天数
    var longestStreak: Int         // 最长连续天数
    var totalCompletions: Int      // 总完成次数
    var successRate: Double        // 成功率 0.0-1.0

    // MARK: - AI 发现的最佳时间
    var bestTime: String?          // "morning", "afternoon", "evening"
    var bestDay: String?           // "Mon", "Tue", ...

    // MARK: - 关联信息
    var relatedGoals: [String]?    // Goal IDs
    var triggers: [HabitTrigger]?  // 触发器

    // MARK: - 时间戳
    let createdAt: Date
    var updatedAt: Date

    // MARK: - 初始化
    init(
        id: String = UUID().uuidString,
        userId: String,
        name: String,
        description: String? = nil,
        category: String? = nil,
        frequency: HabitFrequency = .daily,
        targetCount: Int = 1,
        status: HabitStatus = .active,
        streak: Int = 0,
        longestStreak: Int = 0,
        totalCompletions: Int = 0,
        successRate: Double = 0.0,
        bestTime: String? = nil,
        bestDay: String? = nil,
        relatedGoals: [String]? = nil,
        triggers: [HabitTrigger]? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.description = description
        self.category = category
        self.frequency = frequency
        self.targetCount = targetCount
        self.status = status
        self.streak = streak
        self.longestStreak = longestStreak
        self.totalCompletions = totalCompletions
        self.successRate = successRate
        self.bestTime = bestTime
        self.bestDay = bestDay
        self.relatedGoals = relatedGoals
        self.triggers = triggers
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case description
        case category
        case frequency
        case targetCount = "target_count"
        case status
        case streak
        case longestStreak = "longest_streak"
        case totalCompletions = "total_completions"
        case successRate = "success_rate"
        case bestTime = "best_time"
        case bestDay = "best_day"
        case relatedGoals = "related_goals"
        case triggers
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - 业务逻辑扩展
extension Habit {
    /// 是否正在连续中
    var isStreaking: Bool {
        streak > 0
    }

    /// 习惯是否已养成（连续 21 天）
    var isEstablished: Bool {
        streak >= 21
    }

    /// 习惯是否稳固（连续 66 天）
    var isSolid: Bool {
        streak >= 66
    }

    /// 今日是否需要完成
    var isDueToday: Bool {
        switch frequency {
        case .daily:
            return true
        case .weekly:
            // 检查是否是指定的星期
            return bestDay == nil || bestDay == currentDayOfWeek
        case .monthly:
            // 检查是否是月初
            return Calendar.current.component(.day, from: Date()) == 1
        }
    }

    /// 当前星期几
    private var currentDayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: Date())
    }

    /// 更新连续天数
    mutating func updateStreak(completed: Bool) {
        if completed {
            streak += 1
            if streak > longestStreak {
                longestStreak = streak
            }
            totalCompletions += 1
        } else {
            streak = 0
        }

        // 重新计算成功率
        let daysSinceCreation = Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 1
        successRate = Double(totalCompletions) / Double(max(daysSinceCreation, 1))

        updatedAt = Date()
    }
}

// MARK: - 枚举定义

/// 习惯频率
enum HabitFrequency: String, Codable {
    case daily      // 每日
    case weekly     // 每周
    case monthly    // 每月
}

/// 习惯状态
enum HabitStatus: String, Codable {
    case active     // 活跃
    case paused     // 暂停
    case archived   // 归档
}

/// 习惯触发器
struct HabitTrigger: Codable {
    let type: String        // "time", "location", "event"
    let value: String       // "8:00", "gym", "after_breakfast"
}

// MARK: - 习惯完成记录

/// 习惯完成记录
struct HabitCompletion: Codable, Identifiable {
    let id: String
    let habitId: String
    let completedAt: Date
    var completionTime: String?  // "08:30"
    var moodBefore: Double?      // -1.0 to 1.0
    var moodAfter: Double?       // -1.0 to 1.0
    var notes: String?

    init(
        id: String = UUID().uuidString,
        habitId: String,
        completedAt: Date = Date(),
        completionTime: String? = nil,
        moodBefore: Double? = nil,
        moodAfter: Double? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.habitId = habitId
        self.completedAt = completedAt
        self.completionTime = completionTime
        self.moodBefore = moodBefore
        self.moodAfter = moodAfter
        self.notes = notes
    }

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case habitId = "habit_id"
        case completedAt = "completed_at"
        case completionTime = "completion_time"
        case moodBefore = "mood_before"
        case moodAfter = "mood_after"
        case notes
    }
}
