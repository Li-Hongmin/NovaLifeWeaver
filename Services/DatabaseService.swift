import Foundation
import SQLite

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
        try db?.run(financialRecords.createIndex(userId, ifNotExists: true))
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

// MARK: - User Operations

extension DatabaseService {
    func createUser(name: String) throws -> String {
        guard let db = db else { throw DatabaseError.notConnected }
        
        let userId = generateUUID()
        let timestamp = currentTimestamp()
        
        let insert = users.insert(
            id <- userId,
            Expression<String>("name") <- name,
            createdAt <- timestamp,
            updatedAt <- timestamp
        )
        
        try db.run(insert)
        print("✅ User created: \(userId)")
        return userId
    }
    
    func getUser(id: String) async throws -> User? {
        guard let db = db else { throw DatabaseError.notConnected }

        guard let row = try db.pluck(users.filter(self.id == id)) else {
            return nil
        }

        return User(
            id: row[self.id],
            name: row[Expression<String>("name")],
            timezone: row[Expression<String?>("timezone")] ?? "Asia/Tokyo",
            language: row[Expression<String?>("language")] ?? "zh-CN",
            totalGoals: row[Expression<Int?>("total_goals")] ?? 0,
            completedGoals: row[Expression<Int?>("completed_goals")] ?? 0,
            activeHabits: row[Expression<Int?>("active_habits")] ?? 0,
            createdAt: Date(timeIntervalSince1970: TimeInterval(row[createdAt])),
            updatedAt: Date(timeIntervalSince1970: TimeInterval(row[updatedAt]))
        )
    }
}

// MARK: - Goal Operations

extension DatabaseService {
    func createGoal(userId: String, title: String, deadline: Date? = nil) throws -> String {
        guard let db = db else { throw DatabaseError.notConnected }
        
        let goalId = generateUUID()
        let timestamp = currentTimestamp()
        
        let insert = goals.insert(
            id <- goalId,
            self.userId <- userId,
            Expression<String>("title") <- title,
            Expression<Int64?>("deadline") <- deadline.map { Int64($0.timeIntervalSince1970) },
            createdAt <- timestamp,
            updatedAt <- timestamp
        )
        
        try db.run(insert)
        print("✅ Goal created: \(title)")
        return goalId
    }
}

// MARK: - Financial Operations

extension DatabaseService {
    func addFinancialRecord(
        userId: String,
        amount: Double,
        category: String,
        title: String? = nil,
        moodAtPurchase: Double? = nil
    ) throws -> String {
        guard let db = db else { throw DatabaseError.notConnected }
        
        let recordId = generateUUID()
        let timestamp = currentTimestamp()
        
        let insert = financialRecords.insert(
            id <- recordId,
            self.userId <- userId,
            Expression<Double>("amount") <- amount,
            Expression<String>("category") <- category,
            Expression<String?>("title") <- title,
            Expression<Double?>("mood_at_purchase") <- moodAtPurchase,
            Expression<Int64>("transaction_date") <- timestamp,
            createdAt <- timestamp,
            updatedAt <- timestamp
        )
        
        try db.run(insert)
        print("✅ Financial record added: ¥\(amount) - \(category)")
        return recordId
    }
}

// MARK: - Helper Models
// Note: Main models are in Models/ folder
// This section removed to avoid conflicts with Models/User.swift

// MARK: - Errors

enum DatabaseError: Error {
    case notConnected
    case insertFailed
    case queryFailed
}
