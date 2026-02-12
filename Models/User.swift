import Foundation

/// 用户模型 - 用户画像和学习到的行为模式
struct User: Codable, Identifiable {
    // MARK: - 基础信息
    let id: String
    var name: String
    var timezone: String
    var language: String

    // MARK: - 个人偏好（JSON 存储）
    var preferences: UserPreferences?
    var productiveTimes: [ProductiveTime]?
    var stressPatterns: [StressPattern]?
    var motivationType: String?

    // MARK: - 统计快照
    var totalGoals: Int
    var completedGoals: Int
    var activeHabits: Int

    // MARK: - 时间戳
    let createdAt: Date
    var updatedAt: Date

    // MARK: - 初始化
    init(
        id: String = UUID().uuidString,
        name: String,
        timezone: String = "Asia/Tokyo",
        language: String = "zh-CN",
        preferences: UserPreferences? = nil,
        productiveTimes: [ProductiveTime]? = nil,
        stressPatterns: [StressPattern]? = nil,
        motivationType: String? = nil,
        totalGoals: Int = 0,
        completedGoals: Int = 0,
        activeHabits: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.timezone = timezone
        self.language = language
        self.preferences = preferences
        self.productiveTimes = productiveTimes
        self.stressPatterns = stressPatterns
        self.motivationType = motivationType
        self.totalGoals = totalGoals
        self.completedGoals = completedGoals
        self.activeHabits = activeHabits
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case timezone
        case language
        case preferences
        case productiveTimes = "productive_times"
        case stressPatterns = "stress_patterns"
        case motivationType = "motivation_type"
        case totalGoals = "total_goals"
        case completedGoals = "completed_goals"
        case activeHabits = "active_habits"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - 业务逻辑扩展
extension User {
    /// 目标完成率
    var goalCompletionRate: Double {
        guard totalGoals > 0 else { return 0 }
        return Double(completedGoals) / Double(totalGoals)
    }

    /// 是否有活跃习惯
    var hasActiveHabits: Bool {
        activeHabits > 0
    }

    /// 是否新用户（创建不到 7 天）
    var isNewUser: Bool {
        Date().timeIntervalSince(createdAt) < 7 * 24 * 60 * 60
    }
}

// MARK: - 子结构定义

/// 用户偏好设置
struct UserPreferences: Codable {
    var workHours: [Int]?           // 工作时间 [9, 18]
    var sleepTarget: Int?            // 目标睡眠时长（小时）
    var exercisePreference: String?  // 运动偏好
    var dietaryRestrictions: [String]? // 饮食限制
}

/// 高效时间段
struct ProductiveTime: Codable {
    let day: String      // "Mon", "Tue", ...
    let hours: [Int]     // [9, 10, 11]
}

/// 压力模式
struct StressPattern: Codable {
    let trigger: String     // "deadline", "social", "work"
    let intensity: Double   // 0.0 - 1.0
    let timeOfDay: String?  // "morning", "evening", ...
}
