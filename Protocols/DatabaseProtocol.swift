import Foundation

/// 数据库服务协议 - 定义所有数据访问接口
protocol DatabaseProtocol {

    // MARK: - User Operations
    func createUser(_ user: User) async throws -> String
    func fetchUser(_ userId: String) async throws -> User
    func updateUser(_ user: User) async throws

    // MARK: - Goal Operations
    func createGoal(_ goal: Goal) async throws -> String
    func fetchGoals(userId: String, status: GoalStatus?) async throws -> [Goal]
    func fetchActiveGoals(userId: String) async throws -> [Goal]
    func updateGoal(_ goal: Goal) async throws
    func deleteGoal(_ goalId: String) async throws
    func countCompletedGoals(userId: String) async throws -> Int
    func countTotalGoals(userId: String) async throws -> Int

    // MARK: - Habit Operations
    func createHabit(_ habit: Habit) async throws -> String
    func fetchHabits(userId: String, status: HabitStatus?) async throws -> [Habit]
    func fetchActiveHabits(userId: String) async throws -> [Habit]
    func updateHabit(_ habit: Habit) async throws
    func deleteHabit(_ habitId: String) async throws

    // MARK: - Habit Completion Operations
    func recordHabitCompletion(_ completion: HabitCompletion) async throws -> String
    func fetchHabitCompletions(habitId: String, from: Date, to: Date) async throws -> [HabitCompletion]
    func fetchTodayCompletions(userId: String) async throws -> [HabitCompletion]

    // MARK: - Financial Operations
    func createFinancialRecord(_ record: FinancialRecord) async throws -> String
    func fetchFinancialRecords(userId: String, from: Date, to: Date) async throws -> [FinancialRecord]
    func fetchRecentFinancials(userId: String, days: Int) async throws -> [FinancialRecord]
    func updateFinancialRecord(_ record: FinancialRecord) async throws
    func deleteFinancialRecord(_ recordId: String) async throws
    func calculateCategorySpending(userId: String, from: Date, to: Date) async throws -> [String: Double]

    // MARK: - Budget Operations
    func createBudget(_ budget: Budget) async throws -> String
    func fetchCurrentBudget(userId: String) async throws -> Budget?
    func updateBudget(_ budget: Budget) async throws

    // MARK: - Emotion Operations
    func createEmotionRecord(_ record: EmotionRecord) async throws -> String
    func fetchEmotionRecords(userId: String, from: Date, to: Date) async throws -> [EmotionRecord]
    func fetchRecentEmotions(userId: String, days: Int) async throws -> [EmotionRecord]
    func calculateAverageEmotion(userId: String, days: Int) async throws -> Double

    // MARK: - Event Operations
    func createEvent(_ event: Event) async throws -> String
    func fetchEvents(userId: String, from: Date, to: Date) async throws -> [Event]
    func fetchUpcomingEvents(userId: String, days: Int) async throws -> [Event]
    func updateEvent(_ event: Event) async throws
    func deleteEvent(_ eventId: String) async throws

    // MARK: - Insight Operations
    func saveInsight(_ insight: Insight) async throws -> String
    func fetchInsights(userId: String, limit: Int) async throws -> [Insight]
    func fetchUrgentInsights(userId: String) async throws -> [Insight]

    // MARK: - Correlation Operations
    func saveCorrelation(_ correlation: Correlation) async throws -> String
    func fetchCorrelations(userId: String) async throws -> [Correlation]
    func fetchSignificantCorrelations(userId: String) async throws -> [Correlation]
}
