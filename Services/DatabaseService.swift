import Foundation
import SQLite

// Import all model types
// Note: In Xcode, make sure all Model files are added to the target

/// 数据库服务 - NovaLife 的核心
class DatabaseService {
    static let shared = DatabaseService()
    
    private var db: Connection?
    private let dbPath: String
    
    // 表定义
    private let users = Table("users")
    private let goals = Table("goals")
    private let habits = Table("habits")
    private let habitCompletions = Table("habit_completions")
    private let financialRecords = Table("financial_records")
    private let budgets = Table("budgets")
    private let emotionRecords = Table("emotion_records")
    private let events = Table("events")
    private let records = Table("records")
    private let insights = Table("insights")
    private let correlations = Table("correlations")
    
    // 通用列
    private let id = Expression<String>("id")
    private let userId = Expression<String>("user_id")
    private let createdAt = Expression<Int64>("created_at")
    private let updatedAt = Expression<Int64>("updated_at")
    private let transaction_date = Expression<Int64>("transaction_date")
    
    private init() {
        // 数据库路径（存储在用户目录）
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupportURL.appendingPathComponent("NovaLifeWeaver", isDirectory: true)
        
        // 创建目录
        try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        
        self.dbPath = appDir.appendingPathComponent("NovaLife.db").path
        
        print("📦 Database path: \(dbPath)")
        
        // 初始化数据库
        do {
            db = try Connection(dbPath)
            db?.busyTimeout = 5.0
            
            // 启用外键约束
            try db?.execute("PRAGMA foreign_keys = ON")
            
            print("✅ Database connected")
            
            // 创建所有表
            try createTables()
            
        } catch {
            print("❌ Database connection failed: \(error)")
        }
    }
    
    // MARK: - 创建表
    
    private func createTables() throws {
        print("📋 Creating tables...")
        
        // 1. users 表
        try db?.run(users.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(Expression<String>("name"))
            t.column(Expression<String?>("timezone"), defaultValue: "Asia/Tokyo")
            t.column(Expression<String?>("language"), defaultValue: "zh-CN")
            t.column(Expression<String?>("preferences")) // JSON
            t.column(Expression<String?>("productive_times")) // JSON
            t.column(Expression<String?>("stress_patterns")) // JSON
            t.column(Expression<String?>("motivation_type"))
            t.column(Expression<Int>("total_goals"), defaultValue: 0)
            t.column(Expression<Int>("completed_goals"), defaultValue: 0)
            t.column(Expression<Int>("active_habits"), defaultValue: 0)
            t.column(createdAt, defaultValue: Int64(Date().timeIntervalSince1970))
            t.column(updatedAt, defaultValue: Int64(Date().timeIntervalSince1970))
        })
        
        // 2. goals 表
        try db?.run(goals.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(userId)
            t.column(Expression<String>("title"))
            t.column(Expression<String?>("description"))
            t.column(Expression<String?>("category"))
            t.column(Expression<Int64?>("deadline"))
            t.column(Expression<String?>("measurable_metric"))
            t.column(Expression<Double?>("target_value"))
            t.column(Expression<Double>("current_value"), defaultValue: 0.0)
            t.column(Expression<String>("status"), defaultValue: "active")
            t.column(Expression<Int>("priority"), defaultValue: 3)
            t.column(Expression<String?>("subtasks")) // JSON
            t.column(Expression<String?>("related_habits")) // JSON
            t.column(Expression<Double?>("budget"))
            t.column(Expression<String?>("ai_suggestions"))
            t.column(Expression<Double?>("confidence"))
            t.column(createdAt, defaultValue: Int64(Date().timeIntervalSince1970))
            t.column(Expression<Int64?>("completed_at"))
            t.column(updatedAt, defaultValue: Int64(Date().timeIntervalSince1970))
            t.foreignKey(userId, references: users, id, delete: .cascade)
        })
        
        // 3. habits 表
        try db?.run(habits.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(userId)
            t.column(Expression<String>("name"))
            t.column(Expression<String?>("description"))
            t.column(Expression<String?>("category"))
            t.column(Expression<String>("frequency"), defaultValue: "daily")
            t.column(Expression<Int>("target_count"), defaultValue: 1)
            t.column(Expression<String>("status"), defaultValue: "active")
            t.column(Expression<Int>("streak"), defaultValue: 0)
            t.column(Expression<Int>("longest_streak"), defaultValue: 0)
            t.column(Expression<Int>("total_completions"), defaultValue: 0)
            t.column(Expression<String?>("best_time"))
            t.column(Expression<String?>("best_day"))
            t.column(Expression<Double>("success_rate"), defaultValue: 0.0)
            t.column(Expression<String?>("related_goals")) // JSON
            t.column(Expression<String?>("triggers")) // JSON
            t.column(createdAt, defaultValue: Int64(Date().timeIntervalSince1970))
            t.column(updatedAt, defaultValue: Int64(Date().timeIntervalSince1970))
            t.foreignKey(userId, references: users, id, delete: .cascade)
        })
        
        // 4. habit_completions 表
        try db?.run(habitCompletions.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(Expression<String>("habit_id"))
            t.column(Expression<Int64>("completed_at"))
            t.column(Expression<String?>("completion_time"))
            t.column(Expression<Double?>("mood_before"))
            t.column(Expression<Double?>("mood_after"))
            t.column(Expression<String?>("photo_path"))
            t.column(Expression<String?>("note"))
            t.column(Expression<String?>("location"))
            t.foreignKey(Expression<String>("habit_id"), references: habits, id, delete: .cascade)
        })
        
        // 5. financial_records 表 💰
        try db?.run(financialRecords.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(userId)
            t.column(Expression<Double>("amount"))
            t.column(Expression<String>("currency"), defaultValue: "JPY")
            t.column(Expression<String>("category"))
            t.column(Expression<String?>("subcategory"))
            t.column(Expression<String?>("title"))
            t.column(Expression<String?>("description"))
            t.column(Expression<String?>("merchant"))
            t.column(Expression<String?>("location"))
            t.column(Expression<String?>("related_goal_id"))
            t.column(Expression<String?>("related_event_id"))
            t.column(Expression<Double?>("mood_at_purchase")) // 关键字段！
            t.column(Expression<String?>("purchase_type"))
            t.column(Expression<Double?>("satisfaction"))
            t.column(Expression<String?>("receipt_photo_path"))
            t.column(Expression<String?>("ocr_data")) // JSON
            t.column(Expression<Int64>("transaction_date"))
            t.column(createdAt, defaultValue: Int64(Date().timeIntervalSince1970))
            t.column(updatedAt, defaultValue: Int64(Date().timeIntervalSince1970))
            t.foreignKey(userId, references: users, id, delete: .cascade)
        })
        
        // 6. budgets 表
        try db?.run(budgets.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(userId)
            t.column(Expression<Int64>("period_start"))
            t.column(Expression<Int64>("period_end"))
            t.column(Expression<Double>("total_budget"))
            t.column(Expression<String?>("category_budgets")) // JSON
            t.column(Expression<Double>("total_spent"), defaultValue: 0.0)
            t.column(Expression<String?>("category_spent")) // JSON
            t.column(Expression<Double>("alert_threshold"), defaultValue: 0.8)
            t.column(createdAt, defaultValue: Int64(Date().timeIntervalSince1970))
            t.column(updatedAt, defaultValue: Int64(Date().timeIntervalSince1970))
            t.foreignKey(userId, references: users, id, delete: .cascade)
        })
        
        // 7. emotion_records 表 🧠
        try db?.run(emotionRecords.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(userId)
            t.column(Expression<Double>("score")) // -1 到 1
            t.column(Expression<Double?>("intensity"))
            t.column(Expression<String?>("emotions")) // JSON
            t.column(Expression<String?>("trigger"))
            t.column(Expression<String?>("trigger_description"))
            t.column(Expression<String?>("activity"))
            t.column(Expression<String?>("location"))
            t.column(Expression<String?>("weather"))
            t.column(Expression<String?>("voice_recording_path"))
            t.column(Expression<String?>("transcription"))
            t.column(Expression<String?>("photo_path"))
            t.column(Expression<String?>("note"))
            t.column(Expression<String?>("sentiment_analysis")) // JSON
            t.column(Expression<String?>("recommended_actions"))
            t.column(Expression<Int64>("recorded_at"))
            t.column(createdAt, defaultValue: Int64(Date().timeIntervalSince1970))
            t.foreignKey(userId, references: users, id, delete: .cascade)
        })
        
        // 8. events 表
        try db?.run(events.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(userId)
            t.column(Expression<String>("title"))
            t.column(Expression<String?>("description"))
            t.column(Expression<String?>("location"))
            t.column(Expression<Int64>("start_time"))
            t.column(Expression<Int64?>("end_time"))
            t.column(Expression<Int?>("duration"))
            t.column(Expression<Bool>("all_day"), defaultValue: false)
            t.column(Expression<String?>("category"))
            t.column(Expression<Int>("priority"), defaultValue: 3)
            t.column(Expression<String?>("related_goal_id"))
            t.column(Expression<String?>("related_habit_id"))
            t.column(Expression<String>("source"), defaultValue: "manual")
            t.column(Expression<String?>("calendar_id"))
            t.column(Expression<Bool>("synced_to_calendar"), defaultValue: false)
            t.column(Expression<Bool>("completed"), defaultValue: false)
            t.column(Expression<String?>("completion_note"))
            t.column(Expression<Bool>("suggested_by_ai"), defaultValue: false)
            t.column(Expression<String?>("ai_reasoning"))
            t.column(createdAt, defaultValue: Int64(Date().timeIntervalSince1970))
            t.column(updatedAt, defaultValue: Int64(Date().timeIntervalSince1970))
            t.foreignKey(userId, references: users, id, delete: .cascade)
        })
        
        // 9. insights 表 (AI 洞察)
        try db?.run(insights.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(userId)
            t.column(Expression<String>("type"))
            t.column(Expression<String?>("category"))
            t.column(Expression<String>("title"))
            t.column(Expression<String?>("description"))
            t.column(Expression<String?>("evidence")) // JSON
            t.column(Expression<Double?>("confidence"))
            t.column(Expression<Int>("priority"), defaultValue: 3)
            t.column(Expression<Bool>("actionable"), defaultValue: true)
            t.column(Expression<String?>("suggested_actions")) // JSON
            t.column(Expression<String>("status"), defaultValue: "new")
            t.column(Expression<String?>("user_feedback"))
            t.column(Expression<Int64>("generated_at"))
            t.column(Expression<Int64?>("valid_until"))
            t.foreignKey(userId, references: users, id, delete: .cascade)
        })
        
        // 10. correlations 表 (关联发现)
        try db?.run(correlations.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(userId)
            t.column(Expression<String>("dimension_a"))
            t.column(Expression<String>("dimension_b"))
            t.column(Expression<Double?>("correlation_coefficient"))
            t.column(Expression<Double?>("significance"))
            t.column(Expression<String?>("description"))
            t.column(Expression<String?>("examples")) // JSON
            t.column(Expression<Int64>("discovered_at"))
            t.column(Expression<Int64?>("last_verified"))
            t.foreignKey(userId, references: users, id, delete: .cascade)
        })
        
        // 创建索引
        try createIndexes()
        
        print("✅ All tables created successfully")
    }
    
    private func createIndexes() throws {
        // 财务记录索引
        try db?.run(financialRecords.createIndex(userId, transaction_date, ifNotExists: true))
        try db?.run(financialRecords.createIndex(Expression<String>("category"), ifNotExists: true))
        
        // 情绪记录索引
        try db?.run(emotionRecords.createIndex(userId, Expression<Int64>("recorded_at"), ifNotExists: true))
        
        // 目标索引
        try db?.run(goals.createIndex(userId, Expression<String>("status"), ifNotExists: true))
        
        // 习惯索引
        try db?.run(habits.createIndex(userId, Expression<String>("status"), ifNotExists: true))
        
        print("✅ Indexes created")
    }
    
    // MARK: - 辅助方法
    
    private func generateUUID() -> String {
        return UUID().uuidString.lowercased()
    }
    
    private func currentTimestamp() -> Int64 {
        return Int64(Date().timeIntervalSince1970)
    }
}

// MARK: - Helper Methods

extension DatabaseService {
    /// JSON 编码辅助方法
    private func encodeJSON<T: Codable>(_ value: T?) -> String? {
        guard let value = value else { return nil }
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(value) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// JSON 解码辅助方法
    private func decodeJSON<T: Codable>(_ string: String?, as type: T.Type) -> T? {
        guard let string = string, let data = string.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(type, from: data)
    }
}

// MARK: - DatabaseProtocol Implementation

extension DatabaseService: DatabaseProtocol {

    // MARK: - User Operations

    func createUser(_ user: User) async throws -> String {
        guard let db = db else { throw DatabaseError.notConnected }

        let timestamp = currentTimestamp()

        let insert = users.insert(
            id <- user.id,
            Expression<String>("name") <- user.name,
            Expression<String?>("timezone") <- user.timezone,
            Expression<String?>("language") <- user.language,
            Expression<String?>("preferences") <- encodeJSON(user.preferences),
            Expression<String?>("productive_times") <- encodeJSON(user.productiveTimes),
            Expression<String?>("stress_patterns") <- encodeJSON(user.stressPatterns),
            Expression<String?>("motivation_type") <- user.motivationType,
            Expression<Int>("total_goals") <- user.totalGoals,
            Expression<Int>("completed_goals") <- user.completedGoals,
            Expression<Int>("active_habits") <- user.activeHabits,
            createdAt <- Int64(user.createdAt.timeIntervalSince1970),
            updatedAt <- timestamp
        )

        try db.run(insert)
        print("✅ User created: \(user.name)")
        return user.id
    }

    func fetchUser(_ userId: String) async throws -> User {
        guard let db = db else { throw DatabaseError.notConnected }

        guard let row = try db.pluck(users.filter(id == userId)) else {
            throw DatabaseError.notFound
        }

        return User(
            id: row[id],
            name: row[Expression<String>("name")],
            timezone: row[Expression<String?>("timezone")] ?? "Asia/Tokyo",
            language: row[Expression<String?>("language")] ?? "zh-CN",
            preferences: decodeJSON(row[Expression<String?>("preferences")], as: UserPreferences.self),
            productiveTimes: decodeJSON(row[Expression<String?>("productive_times")], as: [ProductiveTime].self),
            stressPatterns: decodeJSON(row[Expression<String?>("stress_patterns")], as: [StressPattern].self),
            motivationType: row[Expression<String?>("motivation_type")],
            totalGoals: row[Expression<Int>("total_goals")],
            completedGoals: row[Expression<Int>("completed_goals")],
            activeHabits: row[Expression<Int>("active_habits")],
            createdAt: Date(timeIntervalSince1970: TimeInterval(row[createdAt])),
            updatedAt: Date(timeIntervalSince1970: TimeInterval(row[updatedAt]))
        )
    }

    func updateUser(_ user: User) async throws {
        guard let db = db else { throw DatabaseError.notConnected }

        let timestamp = currentTimestamp()
        let userRow = users.filter(id == user.id)

        try db.run(userRow.update(
            Expression<String>("name") <- user.name,
            Expression<String?>("timezone") <- user.timezone,
            Expression<String?>("language") <- user.language,
            Expression<String?>("preferences") <- encodeJSON(user.preferences),
            Expression<String?>("productive_times") <- encodeJSON(user.productiveTimes),
            Expression<String?>("stress_patterns") <- encodeJSON(user.stressPatterns),
            Expression<String?>("motivation_type") <- user.motivationType,
            Expression<Int>("total_goals") <- user.totalGoals,
            Expression<Int>("completed_goals") <- user.completedGoals,
            Expression<Int>("active_habits") <- user.activeHabits,
            updatedAt <- timestamp
        ))

        print("✅ User updated: \(user.name)")
    }

    // MARK: - Goal Operations

    func createGoal(_ goal: Goal) async throws -> String {
        guard let db = db else { throw DatabaseError.notConnected }

        let timestamp = currentTimestamp()

        let insert = goals.insert(
            id <- goal.id,
            userId <- goal.userId,
            Expression<String>("title") <- goal.title,
            Expression<String?>("description") <- goal.description,
            Expression<String?>("category") <- goal.category,
            Expression<Int64?>("deadline") <- goal.deadline.map { Int64($0.timeIntervalSince1970) },
            Expression<String?>("measurable_metric") <- goal.measurableMetric,
            Expression<Double?>("target_value") <- goal.targetValue,
            Expression<Double>("current_value") <- goal.currentValue,
            Expression<String>("status") <- goal.status.rawValue,
            Expression<Int>("priority") <- goal.priority,
            Expression<String?>("subtasks") <- encodeJSON(goal.subtasks),
            Expression<String?>("related_habits") <- encodeJSON(goal.relatedHabits),
            Expression<Double?>("budget") <- goal.budget,
            Expression<String?>("ai_suggestions") <- goal.aiSuggestions,
            Expression<Double?>("confidence") <- goal.confidence,
            createdAt <- Int64(goal.createdAt.timeIntervalSince1970),
            Expression<Int64?>("completed_at") <- goal.completedAt.map { Int64($0.timeIntervalSince1970) },
            updatedAt <- timestamp
        )

        try db.run(insert)
        print("✅ Goal created: \(goal.title)")
        return goal.id
    }

    func fetchGoals(userId: String, status: GoalStatus?) async throws -> [Goal] {
        guard let db = db else { throw DatabaseError.notConnected }

        var query = goals.filter(self.userId == userId)
        if let status = status {
            query = query.filter(Expression<String>("status") == status.rawValue)
        }

        return try db.prepare(query.order(Expression<Int>("priority").desc, updatedAt.desc)).map { row in
            try mapGoal(row)
        }
    }

    func fetchActiveGoals(userId: String) async throws -> [Goal] {
        return try await fetchGoals(userId: userId, status: .active)
    }

    func updateGoal(_ goal: Goal) async throws {
        guard let db = db else { throw DatabaseError.notConnected }

        let timestamp = currentTimestamp()
        let goalRow = goals.filter(id == goal.id)

        try db.run(goalRow.update(
            Expression<String>("title") <- goal.title,
            Expression<String?>("description") <- goal.description,
            Expression<String?>("category") <- goal.category,
            Expression<Int64?>("deadline") <- goal.deadline.map { Int64($0.timeIntervalSince1970) },
            Expression<String?>("measurable_metric") <- goal.measurableMetric,
            Expression<Double?>("target_value") <- goal.targetValue,
            Expression<Double>("current_value") <- goal.currentValue,
            Expression<String>("status") <- goal.status.rawValue,
            Expression<Int>("priority") <- goal.priority,
            Expression<String?>("subtasks") <- encodeJSON(goal.subtasks),
            Expression<String?>("related_habits") <- encodeJSON(goal.relatedHabits),
            Expression<Double?>("budget") <- goal.budget,
            Expression<String?>("ai_suggestions") <- goal.aiSuggestions,
            Expression<Double?>("confidence") <- goal.confidence,
            Expression<Int64?>("completed_at") <- goal.completedAt.map { Int64($0.timeIntervalSince1970) },
            updatedAt <- timestamp
        ))

        print("✅ Goal updated: \(goal.title)")
    }

    func deleteGoal(_ goalId: String) async throws {
        guard let db = db else { throw DatabaseError.notConnected }

        let goalRow = goals.filter(id == goalId)
        try db.run(goalRow.delete())

        print("✅ Goal deleted: \(goalId)")
    }

    func countCompletedGoals(userId: String) async throws -> Int {
        guard let db = db else { throw DatabaseError.notConnected }

        return try db.scalar(goals.filter(self.userId == userId && Expression<String>("status") == GoalStatus.completed.rawValue).count)
    }

    func countTotalGoals(userId: String) async throws -> Int {
        guard let db = db else { throw DatabaseError.notConnected }

        return try db.scalar(goals.filter(self.userId == userId).count)
    }

    // MARK: - Habit Operations

    func createHabit(_ habit: Habit) async throws -> String {
        guard let db = db else { throw DatabaseError.notConnected }

        let timestamp = currentTimestamp()

        let insert = habits.insert(
            id <- habit.id,
            userId <- habit.userId,
            Expression<String>("name") <- habit.name,
            Expression<String?>("description") <- habit.description,
            Expression<String?>("category") <- habit.category,
            Expression<String>("frequency") <- habit.frequency.rawValue,
            Expression<Int>("target_count") <- habit.targetCount,
            Expression<String>("status") <- habit.status.rawValue,
            Expression<Int>("streak") <- habit.streak,
            Expression<Int>("longest_streak") <- habit.longestStreak,
            Expression<Int>("total_completions") <- habit.totalCompletions,
            Expression<String?>("best_time") <- habit.bestTime,
            Expression<String?>("best_day") <- habit.bestDay,
            Expression<Double>("success_rate") <- habit.successRate,
            Expression<String?>("related_goals") <- encodeJSON(habit.relatedGoals),
            Expression<String?>("triggers") <- encodeJSON(habit.triggers),
            createdAt <- Int64(habit.createdAt.timeIntervalSince1970),
            updatedAt <- timestamp
        )

        try db.run(insert)
        print("✅ Habit created: \(habit.name)")
        return habit.id
    }

    func fetchHabits(userId: String, status: HabitStatus?) async throws -> [Habit] {
        guard let db = db else { throw DatabaseError.notConnected }

        var query = habits.filter(self.userId == userId)
        if let status = status {
            query = query.filter(Expression<String>("status") == status.rawValue)
        }

        return try db.prepare(query.order(Expression<Int>("streak").desc)).map { row in
            try mapHabit(row)
        }
    }

    func fetchActiveHabits(userId: String) async throws -> [Habit] {
        return try await fetchHabits(userId: userId, status: .active)
    }

    func updateHabit(_ habit: Habit) async throws {
        guard let db = db else { throw DatabaseError.notConnected }

        let timestamp = currentTimestamp()
        let habitRow = habits.filter(id == habit.id)

        try db.run(habitRow.update(
            Expression<String>("name") <- habit.name,
            Expression<String?>("description") <- habit.description,
            Expression<String?>("category") <- habit.category,
            Expression<String>("frequency") <- habit.frequency.rawValue,
            Expression<Int>("target_count") <- habit.targetCount,
            Expression<String>("status") <- habit.status.rawValue,
            Expression<Int>("streak") <- habit.streak,
            Expression<Int>("longest_streak") <- habit.longestStreak,
            Expression<Int>("total_completions") <- habit.totalCompletions,
            Expression<String?>("best_time") <- habit.bestTime,
            Expression<String?>("best_day") <- habit.bestDay,
            Expression<Double>("success_rate") <- habit.successRate,
            Expression<String?>("related_goals") <- encodeJSON(habit.relatedGoals),
            Expression<String?>("triggers") <- encodeJSON(habit.triggers),
            updatedAt <- timestamp
        ))

        print("✅ Habit updated: \(habit.name)")
    }

    func deleteHabit(_ habitId: String) async throws {
        guard let db = db else { throw DatabaseError.notConnected }

        let habitRow = habits.filter(id == habitId)
        try db.run(habitRow.delete())

        print("✅ Habit deleted: \(habitId)")
    }

    // MARK: - Habit Completion Operations

    func recordHabitCompletion(_ completion: HabitCompletion) async throws -> String {
        guard let db = db else { throw DatabaseError.notConnected }

        let insert = habitCompletions.insert(
            id <- completion.id,
            Expression<String>("habit_id") <- completion.habitId,
            Expression<Int64>("completed_at") <- Int64(completion.completedAt.timeIntervalSince1970),
            Expression<String?>("completion_time") <- completion.completionTime,
            Expression<Double?>("mood_before") <- completion.moodBefore,
            Expression<Double?>("mood_after") <- completion.moodAfter,
            Expression<String?>("photo_path") <- nil,
            Expression<String?>("note") <- completion.notes,
            Expression<String?>("location") <- nil
        )

        try db.run(insert)
        print("✅ Habit completion recorded: \(completion.habitId)")
        return completion.id
    }

    func fetchHabitCompletions(habitId: String, from: Date, to: Date) async throws -> [HabitCompletion] {
        guard let db = db else { throw DatabaseError.notConnected }

        let fromTimestamp = Int64(from.timeIntervalSince1970)
        let toTimestamp = Int64(to.timeIntervalSince1970)

        let query = habitCompletions.filter(
            Expression<String>("habit_id") == habitId &&
            Expression<Int64>("completed_at") >= fromTimestamp &&
            Expression<Int64>("completed_at") <= toTimestamp
        )

        return try db.prepare(query.order(Expression<Int64>("completed_at").desc)).map { row in
            HabitCompletion(
                id: row[id],
                habitId: row[Expression<String>("habit_id")],
                completedAt: Date(timeIntervalSince1970: TimeInterval(row[Expression<Int64>("completed_at")])),
                completionTime: row[Expression<String?>("completion_time")],
                moodBefore: row[Expression<Double?>("mood_before")],
                moodAfter: row[Expression<Double?>("mood_after")],
                notes: row[Expression<String?>("note")]
            )
        }
    }

    func fetchTodayCompletions(userId: String) async throws -> [HabitCompletion] {
        guard let db = db else { throw DatabaseError.notConnected }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        // Join habits and completions to filter by userId
        let query = habitCompletions
            .join(habits, on: habits[id] == habitCompletions[Expression<String>("habit_id")])
            .filter(habits[userId] == userId)
            .filter(habitCompletions[Expression<Int64>("completed_at")] >= Int64(startOfDay.timeIntervalSince1970))
            .filter(habitCompletions[Expression<Int64>("completed_at")] < Int64(endOfDay.timeIntervalSince1970))

        return try db.prepare(query).map { row in
            HabitCompletion(
                id: row[habitCompletions[id]],
                habitId: row[habitCompletions[Expression<String>("habit_id")]],
                completedAt: Date(timeIntervalSince1970: TimeInterval(row[habitCompletions[Expression<Int64>("completed_at")]])),
                completionTime: row[habitCompletions[Expression<String?>("completion_time")]],
                moodBefore: row[habitCompletions[Expression<Double?>("mood_before")]],
                moodAfter: row[habitCompletions[Expression<Double?>("mood_after")]],
                notes: row[habitCompletions[Expression<String?>("note")]]
            )
        }
    }

    // MARK: - Financial Operations

    func createFinancialRecord(_ record: FinancialRecord) async throws -> String {
        guard let db = db else { throw DatabaseError.notConnected }

        let timestamp = currentTimestamp()

        let insert = financialRecords.insert(
            id <- record.id,
            userId <- record.userId,
            Expression<Double>("amount") <- record.amount,
            Expression<String>("currency") <- record.currency,
            Expression<String>("category") <- record.category,
            Expression<String?>("subcategory") <- record.subcategory,
            Expression<String?>("title") <- record.title,
            Expression<String?>("description") <- record.description,
            Expression<String?>("merchant") <- record.merchant,
            Expression<String?>("location") <- record.location,
            Expression<String?>("related_goal_id") <- record.relatedGoalId,
            Expression<String?>("related_event_id") <- record.relatedEventId,
            Expression<Double?>("mood_at_purchase") <- record.moodAtPurchase,
            Expression<String?>("purchase_type") <- record.purchaseType?.rawValue,
            Expression<Double?>("satisfaction") <- record.satisfaction,
            Expression<String?>("receipt_photo_path") <- record.receiptPhotoPath,
            Expression<String?>("ocr_data") <- encodeJSON(record.ocrData),
            transaction_date <- Int64(record.transactionDate.timeIntervalSince1970),
            createdAt <- timestamp,
            updatedAt <- timestamp
        )

        try db.run(insert)
        print("✅ Financial record created: ¥\(record.amount)")
        return record.id
    }

    func fetchFinancialRecords(userId: String, from: Date, to: Date) async throws -> [FinancialRecord] {
        guard let db = db else { throw DatabaseError.notConnected }

        let fromTimestamp = Int64(from.timeIntervalSince1970)
        let toTimestamp = Int64(to.timeIntervalSince1970)

        let query = financialRecords.filter(
            self.userId == userId &&
            transaction_date >= fromTimestamp &&
            transaction_date <= toTimestamp
        )

        return try db.prepare(query.order(transaction_date.desc)).map { row in
            try mapFinancialRecord(row)
        }
    }

    func fetchRecentFinancials(userId: String, days: Int) async throws -> [FinancialRecord] {
        let to = Date()
        let from = Calendar.current.date(byAdding: .day, value: -days, to: to)!
        return try await fetchFinancialRecords(userId: userId, from: from, to: to)
    }

    func updateFinancialRecord(_ record: FinancialRecord) async throws {
        guard let db = db else { throw DatabaseError.notConnected }

        let timestamp = currentTimestamp()
        let recordRow = financialRecords.filter(id == record.id)

        try db.run(recordRow.update(
            Expression<Double>("amount") <- record.amount,
            Expression<String>("currency") <- record.currency,
            Expression<String>("category") <- record.category,
            Expression<String?>("subcategory") <- record.subcategory,
            Expression<String?>("title") <- record.title,
            Expression<String?>("description") <- record.description,
            Expression<String?>("merchant") <- record.merchant,
            Expression<String?>("location") <- record.location,
            Expression<String?>("related_goal_id") <- record.relatedGoalId,
            Expression<String?>("related_event_id") <- record.relatedEventId,
            Expression<Double?>("mood_at_purchase") <- record.moodAtPurchase,
            Expression<String?>("purchase_type") <- record.purchaseType?.rawValue,
            Expression<Double?>("satisfaction") <- record.satisfaction,
            Expression<String?>("receipt_photo_path") <- record.receiptPhotoPath,
            Expression<String?>("ocr_data") <- encodeJSON(record.ocrData),
            transaction_date <- Int64(record.transactionDate.timeIntervalSince1970),
            updatedAt <- timestamp
        ))

        print("✅ Financial record updated")
    }

    func deleteFinancialRecord(_ recordId: String) async throws {
        guard let db = db else { throw DatabaseError.notConnected }

        let recordRow = financialRecords.filter(id == recordId)
        try db.run(recordRow.delete())

        print("✅ Financial record deleted")
    }

    func calculateCategorySpending(userId: String, from: Date, to: Date) async throws -> [String: Double] {
        guard let db = db else { throw DatabaseError.notConnected }

        let fromTimestamp = Int64(from.timeIntervalSince1970)
        let toTimestamp = Int64(to.timeIntervalSince1970)

        let query = financialRecords.filter(
            self.userId == userId &&
            transaction_date >= fromTimestamp &&
            transaction_date <= toTimestamp
        )

        var result: [String: Double] = [:]
        for row in try db.prepare(query) {
            let category = row[Expression<String>("category")]
            let amount = row[Expression<Double>("amount")]
            result[category, default: 0] += amount
        }

        return result
    }

    // MARK: - Budget Operations

    func createBudget(_ budget: Budget) async throws -> String {
        guard let db = db else { throw DatabaseError.notConnected }

        let timestamp = currentTimestamp()

        let insert = budgets.insert(
            id <- budget.id,
            userId <- budget.userId,
            Expression<Int64>("period_start") <- Int64(budget.periodStart.timeIntervalSince1970),
            Expression<Int64>("period_end") <- Int64(budget.periodEnd.timeIntervalSince1970),
            Expression<Double>("total_budget") <- budget.totalBudget,
            Expression<String?>("category_budgets") <- encodeJSON(budget.categoryBudgets),
            Expression<Double>("total_spent") <- budget.totalSpent,
            Expression<String?>("category_spent") <- encodeJSON(budget.categorySpent),
            Expression<Double>("alert_threshold") <- budget.alertThreshold,
            createdAt <- timestamp,
            updatedAt <- timestamp
        )

        try db.run(insert)
        print("✅ Budget created")
        return budget.id
    }

    func fetchCurrentBudget(userId: String) async throws -> Budget? {
        guard let db = db else { throw DatabaseError.notConnected }

        let now = Int64(Date().timeIntervalSince1970)
        let query = budgets.filter(
            self.userId == userId &&
            Expression<Int64>("period_start") <= now &&
            Expression<Int64>("period_end") >= now
        )

        guard let row = try db.pluck(query) else { return nil }

        return Budget(
            id: row[id],
            userId: row[self.userId],
            periodStart: Date(timeIntervalSince1970: TimeInterval(row[Expression<Int64>("period_start")])),
            periodEnd: Date(timeIntervalSince1970: TimeInterval(row[Expression<Int64>("period_end")])),
            totalBudget: row[Expression<Double>("total_budget")],
            categoryBudgets: decodeJSON(row[Expression<String?>("category_budgets")], as: [String: Double].self),
            totalSpent: row[Expression<Double>("total_spent")],
            categorySpent: decodeJSON(row[Expression<String?>("category_spent")], as: [String: Double].self),
            alertThreshold: row[Expression<Double>("alert_threshold")],
            createdAt: Date(timeIntervalSince1970: TimeInterval(row[createdAt])),
            updatedAt: Date(timeIntervalSince1970: TimeInterval(row[updatedAt]))
        )
    }

    func updateBudget(_ budget: Budget) async throws {
        guard let db = db else { throw DatabaseError.notConnected }

        let timestamp = currentTimestamp()
        let budgetRow = budgets.filter(id == budget.id)

        try db.run(budgetRow.update(
            Expression<Int64>("period_start") <- Int64(budget.periodStart.timeIntervalSince1970),
            Expression<Int64>("period_end") <- Int64(budget.periodEnd.timeIntervalSince1970),
            Expression<Double>("total_budget") <- budget.totalBudget,
            Expression<String?>("category_budgets") <- encodeJSON(budget.categoryBudgets),
            Expression<Double>("total_spent") <- budget.totalSpent,
            Expression<String?>("category_spent") <- encodeJSON(budget.categorySpent),
            Expression<Double>("alert_threshold") <- budget.alertThreshold,
            updatedAt <- timestamp
        ))

        print("✅ Budget updated")
    }

    // MARK: - Emotion Operations

    func createEmotionRecord(_ record: EmotionRecord) async throws -> String {
        guard let db = db else { throw DatabaseError.notConnected }

        let timestamp = currentTimestamp()

        let insert = emotionRecords.insert(
            id <- record.id,
            userId <- record.userId,
            Expression<Double>("score") <- record.score,
            Expression<Double?>("intensity") <- record.intensity,
            Expression<String?>("emotions") <- encodeJSON(record.emotions),
            Expression<String?>("trigger") <- record.trigger,
            Expression<String?>("trigger_description") <- record.triggerDescription,
            Expression<String?>("activity") <- record.activity,
            Expression<String?>("location") <- record.location,
            Expression<String?>("weather") <- record.weather,
            Expression<String?>("voice_recording_path") <- record.voiceRecordingPath,
            Expression<String?>("transcription") <- record.transcription,
            Expression<String?>("photo_path") <- record.photoPath,
            Expression<String?>("note") <- record.note,
            Expression<String?>("sentiment_analysis") <- encodeJSON(record.sentimentAnalysis),
            Expression<String?>("recommended_actions") <- record.recommendedActions,
            Expression<Int64>("recorded_at") <- Int64(record.recordedAt.timeIntervalSince1970),
            createdAt <- timestamp
        )

        try db.run(insert)
        print("✅ Emotion record created")
        return record.id
    }

    func fetchEmotionRecords(userId: String, from: Date, to: Date) async throws -> [EmotionRecord] {
        guard let db = db else { throw DatabaseError.notConnected }

        let fromTimestamp = Int64(from.timeIntervalSince1970)
        let toTimestamp = Int64(to.timeIntervalSince1970)

        let query = emotionRecords.filter(
            self.userId == userId &&
            Expression<Int64>("recorded_at") >= fromTimestamp &&
            Expression<Int64>("recorded_at") <= toTimestamp
        )

        return try db.prepare(query.order(Expression<Int64>("recorded_at").desc)).map { row in
            try mapEmotionRecord(row)
        }
    }

    func fetchRecentEmotions(userId: String, days: Int) async throws -> [EmotionRecord] {
        let to = Date()
        let from = Calendar.current.date(byAdding: .day, value: -days, to: to)!
        return try await fetchEmotionRecords(userId: userId, from: from, to: to)
    }

    func calculateAverageEmotion(userId: String, days: Int) async throws -> Double {
        let emotions = try await fetchRecentEmotions(userId: userId, days: days)
        guard !emotions.isEmpty else { return 0.0 }
        let sum = emotions.reduce(0.0) { $0 + $1.score }
        return sum / Double(emotions.count)
    }

    // MARK: - Event Operations

    func createEvent(_ event: Event) async throws -> String {
        guard let db = db else { throw DatabaseError.notConnected }

        let timestamp = currentTimestamp()

        let insert = events.insert(
            id <- event.id,
            userId <- event.userId,
            Expression<String>("title") <- event.title,
            Expression<String?>("description") <- event.description,
            Expression<String?>("location") <- event.location,
            Expression<Int64>("start_time") <- Int64(event.startTime.timeIntervalSince1970),
            Expression<Int64?>("end_time") <- event.endTime.map { Int64($0.timeIntervalSince1970) },
            Expression<Int?>("duration") <- event.duration,
            Expression<Bool>("all_day") <- event.allDay,
            Expression<String?>("category") <- event.category,
            Expression<Int>("priority") <- event.priority,
            Expression<String?>("related_goal_id") <- event.relatedGoalId,
            Expression<String?>("related_habit_id") <- event.relatedHabitId,
            Expression<String>("source") <- event.source.rawValue,
            Expression<String?>("calendar_id") <- event.calendarId,
            Expression<Bool>("synced_to_calendar") <- event.syncedToCalendar,
            Expression<Bool>("completed") <- event.completed,
            Expression<String?>("completion_note") <- event.completionNote,
            Expression<Bool>("suggested_by_ai") <- event.suggestedByAI,
            Expression<String?>("ai_reasoning") <- event.aiReasoning,
            createdAt <- timestamp,
            updatedAt <- timestamp
        )

        try db.run(insert)
        print("✅ Event created: \(event.title)")
        return event.id
    }

    func fetchEvents(userId: String, from: Date, to: Date) async throws -> [Event] {
        guard let db = db else { throw DatabaseError.notConnected }

        let fromTimestamp = Int64(from.timeIntervalSince1970)
        let toTimestamp = Int64(to.timeIntervalSince1970)

        let query = events.filter(
            self.userId == userId &&
            Expression<Int64>("start_time") >= fromTimestamp &&
            Expression<Int64>("start_time") <= toTimestamp
        )

        return try db.prepare(query.order(Expression<Int64>("start_time").asc)).map { row in
            try mapEvent(row)
        }
    }

    func fetchUpcomingEvents(userId: String, days: Int) async throws -> [Event] {
        let from = Date()
        let to = Calendar.current.date(byAdding: .day, value: days, to: from)!
        return try await fetchEvents(userId: userId, from: from, to: to)
    }

    func updateEvent(_ event: Event) async throws {
        guard let db = db else { throw DatabaseError.notConnected }

        let timestamp = currentTimestamp()
        let eventRow = events.filter(id == event.id)

        try db.run(eventRow.update(
            Expression<String>("title") <- event.title,
            Expression<String?>("description") <- event.description,
            Expression<String?>("location") <- event.location,
            Expression<Int64>("start_time") <- Int64(event.startTime.timeIntervalSince1970),
            Expression<Int64?>("end_time") <- event.endTime.map { Int64($0.timeIntervalSince1970) },
            Expression<Int?>("duration") <- event.duration,
            Expression<Bool>("all_day") <- event.allDay,
            Expression<String?>("category") <- event.category,
            Expression<Int>("priority") <- event.priority,
            Expression<String?>("related_goal_id") <- event.relatedGoalId,
            Expression<String?>("related_habit_id") <- event.relatedHabitId,
            Expression<String>("source") <- event.source.rawValue,
            Expression<String?>("calendar_id") <- event.calendarId,
            Expression<Bool>("synced_to_calendar") <- event.syncedToCalendar,
            Expression<Bool>("completed") <- event.completed,
            Expression<String?>("completion_note") <- event.completionNote,
            Expression<Bool>("suggested_by_ai") <- event.suggestedByAI,
            Expression<String?>("ai_reasoning") <- event.aiReasoning,
            updatedAt <- timestamp
        ))

        print("✅ Event updated: \(event.title)")
    }

    func deleteEvent(_ eventId: String) async throws {
        guard let db = db else { throw DatabaseError.notConnected }

        let eventRow = events.filter(id == eventId)
        try db.run(eventRow.delete())

        print("✅ Event deleted")
    }

    // MARK: - Insight Operations

    func saveInsight(_ insight: Insight) async throws -> String {
        guard let db = db else { throw DatabaseError.notConnected }

        let insert = insights.insert(
            id <- insight.id,
            userId <- insight.userId,
            Expression<String>("type") <- insight.type.rawValue,
            Expression<String?>("category") <- insight.category.rawValue,
            Expression<String>("title") <- insight.title,
            Expression<String?>("description") <- insight.description,
            Expression<String?>("evidence") <- nil,
            Expression<Double?>("confidence") <- insight.confidence,
            Expression<Int>("priority") <- insight.priority,
            Expression<Bool>("actionable") <- insight.actionable,
            Expression<String?>("suggested_actions") <- encodeJSON(insight.suggestedActions),
            Expression<String>("status") <- insight.status.rawValue,
            Expression<String?>("user_feedback") <- insight.userFeedback,
            Expression<Int64>("generated_at") <- Int64(insight.generatedAt.timeIntervalSince1970),
            Expression<Int64?>("valid_until") <- insight.validUntil.map { Int64($0.timeIntervalSince1970) }
        )

        try db.run(insert)
        print("✅ Insight saved: \(insight.title)")
        return insight.id
    }

    func fetchInsights(userId: String, limit: Int) async throws -> [Insight] {
        guard let db = db else { throw DatabaseError.notConnected }

        let query = insights.filter(self.userId == userId)
            .order(Expression<Int>("priority").desc, Expression<Int64>("generated_at").desc)
            .limit(limit)

        return try db.prepare(query).map { row in
            try mapInsight(row)
        }
    }

    func fetchUrgentInsights(userId: String) async throws -> [Insight] {
        guard let db = db else { throw DatabaseError.notConnected }

        let query = insights.filter(
            self.userId == userId &&
            Expression<String>("type") == InsightType.warning.rawValue &&
            Expression<String>("status") != InsightStatus.dismissed.rawValue
        ).order(Expression<Int>("priority").desc)

        return try db.prepare(query).map { row in
            try mapInsight(row)
        }
    }

    // MARK: - Correlation Operations

    func saveCorrelation(_ correlation: Correlation) async throws -> String {
        guard let db = db else { throw DatabaseError.notConnected }

        let insert = correlations.insert(
            id <- correlation.id,
            userId <- correlation.userId,
            Expression<String>("dimension_a") <- correlation.dimensionA,
            Expression<String>("dimension_b") <- correlation.dimensionB,
            Expression<Double?>("correlation_coefficient") <- correlation.correlationCoefficient,
            Expression<Double?>("significance") <- correlation.significance,
            Expression<String?>("description") <- correlation.description,
            Expression<String?>("examples") <- encodeJSON(correlation.examples),
            Expression<Int64>("discovered_at") <- Int64(correlation.discoveredAt.timeIntervalSince1970),
            Expression<Int64?>("last_verified") <- correlation.lastVerified.map { Int64($0.timeIntervalSince1970) }
        )

        try db.run(insert)
        print("✅ Correlation saved: \(correlation.dimensionA) ↔ \(correlation.dimensionB)")
        return correlation.id
    }

    func fetchCorrelations(userId: String) async throws -> [Correlation] {
        guard let db = db else { throw DatabaseError.notConnected }

        let query = correlations.filter(self.userId == userId)
            .order(Expression<Double?>("correlation_coefficient").desc)

        return try db.prepare(query).map { row in
            Correlation(
                id: row[id],
                userId: row[self.userId],
                dimensionA: row[Expression<String>("dimension_a")],
                dimensionB: row[Expression<String>("dimension_b")],
                correlationCoefficient: row[Expression<Double?>("correlation_coefficient")],
                significance: row[Expression<Double?>("significance")],
                description: row[Expression<String?>("description")],
                examples: decodeJSON(row[Expression<String?>("examples")], as: [CorrelationExample].self),
                discoveredAt: Date(timeIntervalSince1970: TimeInterval(row[Expression<Int64>("discovered_at")])),
                lastVerified: row[Expression<Int64?>("last_verified")].map { Date(timeIntervalSince1970: TimeInterval($0)) }
            )
        }
    }

    func fetchSignificantCorrelations(userId: String) async throws -> [Correlation] {
        let allCorrelations = try await fetchCorrelations(userId: userId)
        return allCorrelations.filter { correlation in
            guard let coefficient = correlation.correlationCoefficient else { return false }
            return abs(coefficient) >= 0.4 && correlation.isSignificant
        }
    }

    // MARK: - Row Mapping Helpers

    private func mapGoal(_ row: Row) throws -> Goal {
        Goal(
            id: row[id],
            userId: row[userId],
            title: row[Expression<String>("title")],
            description: row[Expression<String?>("description")],
            category: row[Expression<String?>("category")],
            deadline: row[Expression<Int64?>("deadline")].map { Date(timeIntervalSince1970: TimeInterval($0)) },
            measurableMetric: row[Expression<String?>("measurable_metric")],
            targetValue: row[Expression<Double?>("target_value")],
            currentValue: row[Expression<Double>("current_value")],
            status: GoalStatus(rawValue: row[Expression<String>("status")]) ?? .active,
            priority: row[Expression<Int>("priority")],
            subtasks: decodeJSON(row[Expression<String?>("subtasks")], as: [Subtask].self),
            relatedHabits: decodeJSON(row[Expression<String?>("related_habits")], as: [String].self),
            budget: row[Expression<Double?>("budget")],
            aiSuggestions: row[Expression<String?>("ai_suggestions")],
            confidence: row[Expression<Double?>("confidence")],
            createdAt: Date(timeIntervalSince1970: TimeInterval(row[createdAt])),
            completedAt: row[Expression<Int64?>("completed_at")].map { Date(timeIntervalSince1970: TimeInterval($0)) },
            updatedAt: Date(timeIntervalSince1970: TimeInterval(row[updatedAt]))
        )
    }

    private func mapHabit(_ row: Row) throws -> Habit {
        Habit(
            id: row[id],
            userId: row[userId],
            name: row[Expression<String>("name")],
            description: row[Expression<String?>("description")],
            category: row[Expression<String?>("category")],
            frequency: HabitFrequency(rawValue: row[Expression<String>("frequency")]) ?? .daily,
            targetCount: row[Expression<Int>("target_count")],
            status: HabitStatus(rawValue: row[Expression<String>("status")]) ?? .active,
            streak: row[Expression<Int>("streak")],
            longestStreak: row[Expression<Int>("longest_streak")],
            totalCompletions: row[Expression<Int>("total_completions")],
            successRate: row[Expression<Double>("success_rate")],
            bestTime: row[Expression<String?>("best_time")],
            bestDay: row[Expression<String?>("best_day")],
            relatedGoals: decodeJSON(row[Expression<String?>("related_goals")], as: [String].self),
            triggers: decodeJSON(row[Expression<String?>("triggers")], as: [HabitTrigger].self),
            createdAt: Date(timeIntervalSince1970: TimeInterval(row[createdAt])),
            updatedAt: Date(timeIntervalSince1970: TimeInterval(row[updatedAt]))
        )
    }

    private func mapFinancialRecord(_ row: Row) throws -> FinancialRecord {
        FinancialRecord(
            id: row[id],
            userId: row[userId],
            amount: row[Expression<Double>("amount")],
            currency: row[Expression<String>("currency")],
            category: row[Expression<String>("category")],
            subcategory: row[Expression<String?>("subcategory")],
            title: row[Expression<String?>("title")],
            description: row[Expression<String?>("description")],
            merchant: row[Expression<String?>("merchant")],
            location: row[Expression<String?>("location")],
            relatedGoalId: row[Expression<String?>("related_goal_id")],
            relatedEventId: row[Expression<String?>("related_event_id")],
            moodAtPurchase: row[Expression<Double?>("mood_at_purchase")],
            purchaseType: row[Expression<String?>("purchase_type")].flatMap { PurchaseType(rawValue: $0) },
            satisfaction: row[Expression<Double?>("satisfaction")],
            receiptPhotoPath: row[Expression<String?>("receipt_photo_path")],
            ocrData: decodeJSON(row[Expression<String?>("ocr_data")], as: OCRData.self),
            transactionDate: Date(timeIntervalSince1970: TimeInterval(row[transaction_date])),
            createdAt: Date(timeIntervalSince1970: TimeInterval(row[createdAt])),
            updatedAt: Date(timeIntervalSince1970: TimeInterval(row[updatedAt]))
        )
    }

    private func mapEmotionRecord(_ row: Row) throws -> EmotionRecord {
        EmotionRecord(
            id: row[id],
            userId: row[userId],
            score: row[Expression<Double>("score")],
            intensity: row[Expression<Double?>("intensity")],
            emotions: decodeJSON(row[Expression<String?>("emotions")], as: [String].self),
            trigger: row[Expression<String?>("trigger")],
            triggerDescription: row[Expression<String?>("trigger_description")],
            activity: row[Expression<String?>("activity")],
            location: row[Expression<String?>("location")],
            weather: row[Expression<String?>("weather")],
            voiceRecordingPath: row[Expression<String?>("voice_recording_path")],
            transcription: row[Expression<String?>("transcription")],
            photoPath: row[Expression<String?>("photo_path")],
            note: row[Expression<String?>("note")],
            sentimentAnalysis: decodeJSON(row[Expression<String?>("sentiment_analysis")], as: SentimentAnalysis.self),
            recommendedActions: row[Expression<String?>("recommended_actions")],
            recordedAt: Date(timeIntervalSince1970: TimeInterval(row[Expression<Int64>("recorded_at")])),
            createdAt: Date(timeIntervalSince1970: TimeInterval(row[createdAt]))
        )
    }

    private func mapEvent(_ row: Row) throws -> Event {
        Event(
            id: row[id],
            userId: row[userId],
            title: row[Expression<String>("title")],
            description: row[Expression<String?>("description")],
            location: row[Expression<String?>("location")],
            startTime: Date(timeIntervalSince1970: TimeInterval(row[Expression<Int64>("start_time")])),
            endTime: row[Expression<Int64?>("end_time")].map { Date(timeIntervalSince1970: TimeInterval($0)) },
            duration: row[Expression<Int?>("duration")],
            allDay: row[Expression<Bool>("all_day")],
            category: row[Expression<String?>("category")],
            priority: row[Expression<Int>("priority")],
            relatedGoalId: row[Expression<String?>("related_goal_id")],
            relatedHabitId: row[Expression<String?>("related_habit_id")],
            source: EventSource(rawValue: row[Expression<String>("source")]) ?? .manual,
            calendarId: row[Expression<String?>("calendar_id")],
            syncedToCalendar: row[Expression<Bool>("synced_to_calendar")],
            completed: row[Expression<Bool>("completed")],
            completionNote: row[Expression<String?>("completion_note")],
            suggestedByAI: row[Expression<Bool>("suggested_by_ai")],
            aiReasoning: row[Expression<String?>("ai_reasoning")],
            createdAt: Date(timeIntervalSince1970: TimeInterval(row[createdAt])),
            updatedAt: Date(timeIntervalSince1970: TimeInterval(row[updatedAt]))
        )
    }

    private func mapInsight(_ row: Row) throws -> Insight {
        Insight(
            id: row[id],
            userId: row[userId],
            type: InsightType(rawValue: row[Expression<String>("type")]) ?? .recommendation,
            category: InsightCategory(rawValue: row[Expression<String?>("category")] ?? "general") ?? .general,
            title: row[Expression<String>("title")],
            description: row[Expression<String?>("description")] ?? "",
            priority: row[Expression<Int>("priority")],
            urgency: 0.5,
            impact: 0.5,
            confidence: row[Expression<Double?>("confidence")] ?? 0.8,
            actionable: row[Expression<Bool>("actionable")],
            suggestedActions: decodeJSON(row[Expression<String?>("suggested_actions")], as: [SuggestedAction].self),
            status: InsightStatus(rawValue: row[Expression<String>("status")]) ?? .new,
            userFeedback: row[Expression<String?>("user_feedback")],
            generatedAt: Date(timeIntervalSince1970: TimeInterval(row[Expression<Int64>("generated_at")])),
            validUntil: row[Expression<Int64?>("valid_until")].map { Date(timeIntervalSince1970: TimeInterval($0)) }
        )
    }
}

// MARK: - Errors

enum DatabaseError: Error {
    case notConnected
    case insertFailed
    case queryFailed
    case notFound
}
