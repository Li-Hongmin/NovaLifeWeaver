import Foundation
import SQLite

/// 关联分析引擎 - NovaLife Weaver 的核心创新功能
/// 发现跨领域数据关联（情绪 ↔ 消费 ↔ 习惯 ↔ 学习效率）
class CorrelationEngine: CorrelationEngineProtocol {
    static let shared = CorrelationEngine()

    private let db = DatabaseService.shared

    // 统计阈值
    private let minDataPoints = 30           // 最少数据点
    private let minCorrelation = 0.4         // 最小相关系数
    private let significanceLevel = 0.05     // p < 0.05

    private init() {}

    // MARK: - 公开接口

    /// 分析所有可能的关联
    func analyzeCorrelations(userId: String) async throws -> [Correlation] {
        var correlations: [Correlation] = []

        // 1. 情绪 vs 消费（核心关联）
        if let emotionSpending = try await analyzeEmotionSpending(userId: userId) {
            correlations.append(emotionSpending)
        }

        // 2. 习惯（运动）vs 情绪
        if let exerciseEmotion = try await analyzeExerciseEmotion(userId: userId) {
            correlations.append(exerciseEmotion)
        }

        // 3. 习惯（学习）vs 目标进度
        if let studyProgress = try await analyzeStudyProgress(userId: userId) {
            correlations.append(studyProgress)
        }

        print("📊 Discovered \(correlations.count) correlations for user \(userId)")

        return correlations
    }

    /// 分析特定维度的关联
    func analyzeCorrelation(
        userId: String,
        dimensionA: String,
        dimensionB: String
    ) async throws -> Correlation? {
        // 根据维度类型路由到相应的分析方法
        if dimensionA.contains("emotion") && dimensionB.contains("financial") {
            return try await analyzeEmotionSpending(userId: userId)
        } else if dimensionA.contains("habit.exercise") && dimensionB.contains("emotion") {
            return try await analyzeExerciseEmotion(userId: userId)
        } else if dimensionA.contains("habit.study") && dimensionB.contains("goal") {
            return try await analyzeStudyProgress(userId: userId)
        }

        return nil
    }

    /// 验证已有关联是否仍然有效
    func verifyCorrelation(_ correlation: Correlation) async throws -> Bool {
        guard let coefficient = correlation.correlationCoefficient else { return false }
        guard correlation.significance != nil else { return false }

        // 重新计算关联
        if let newCorrelation = try await analyzeCorrelation(
            userId: correlation.userId,
            dimensionA: correlation.dimensionA,
            dimensionB: correlation.dimensionB
        ) {
            // 检查新的相关系数是否在原来的 ±0.2 范围内
            if let newCoefficient = newCorrelation.correlationCoefficient {
                let diff = abs(newCoefficient - coefficient)
                return diff < 0.2 && newCorrelation.isSignificant
            }
        }

        return false
    }

    // MARK: - 具体关联分析

    /// 1. 情绪 vs 消费关联分析（核心创新功能）
    private func analyzeEmotionSpending(userId: String) async throws -> Correlation? {
        // 查询最近 60 天的数据
        let data = try await fetchEmotionSpendingData(userId: userId, days: 60)

        guard data.count >= minDataPoints else {
            print("⚠️ Not enough data points for emotion-spending analysis: \(data.count) < \(minDataPoints)")
            return nil
        }

        // 提取两个维度的数据
        let emotionScores = data.map { $0.emotionScore }
        let spendingAmounts = data.map { $0.spending }

        // 计算 Pearson 相关系数
        let coefficient = calculatePearsonCorrelation(x: emotionScores, y: spendingAmounts)

        // 计算统计显著性
        let significance = calculateSignificance(
            correlation: coefficient,
            sampleSize: data.count
        )

        // 检查是否满足阈值
        guard abs(coefficient) >= minCorrelation && significance < significanceLevel else {
            print("⚠️ Emotion-spending correlation not significant: r=\(coefficient), p=\(significance)")
            return nil
        }

        // 生成描述和案例
        let description = generateEmotionSpendingDescription(
            coefficient: coefficient,
            data: data
        )

        let examples = generateExamples(from: data, limit: 3)

        let correlation = Correlation(
            userId: userId,
            dimensionA: "emotion.score",
            dimensionB: "financial.spending",
            correlationCoefficient: coefficient,
            significance: significance,
            description: description,
            examples: examples,
            lastVerified: Date()
        )

        print("✅ Found emotion-spending correlation: r=\(String(format: "%.3f", coefficient)), p=\(String(format: "%.4f", significance))")

        return correlation
    }

    /// 2. 运动习惯 vs 情绪关联
    private func analyzeExerciseEmotion(userId: String) async throws -> Correlation? {
        let data = try await fetchExerciseEmotionData(userId: userId, days: 60)

        guard data.count >= minDataPoints else {
            print("⚠️ Not enough data for exercise-emotion analysis: \(data.count)")
            return nil
        }

        // 0 = 未运动, 1 = 已运动
        let exerciseStatus = data.map { $0.exercised ? 1.0 : 0.0 }
        let emotionScores = data.map { $0.emotionScore }

        let coefficient = calculatePearsonCorrelation(x: exerciseStatus, y: emotionScores)
        let significance = calculateSignificance(correlation: coefficient, sampleSize: data.count)

        guard abs(coefficient) >= minCorrelation && significance < significanceLevel else {
            print("⚠️ Exercise-emotion correlation not significant: r=\(coefficient)")
            return nil
        }

        let description = generateExerciseEmotionDescription(coefficient: coefficient, data: data)
        let examples = generateExerciseEmotionExamples(from: data, limit: 3)

        return Correlation(
            userId: userId,
            dimensionA: "habit.exercise",
            dimensionB: "emotion.score",
            correlationCoefficient: coefficient,
            significance: significance,
            description: description,
            examples: examples,
            lastVerified: Date()
        )
    }

    /// 3. 学习习惯 vs 目标进度关联
    private func analyzeStudyProgress(userId: String) async throws -> Correlation? {
        let data = try await fetchStudyProgressData(userId: userId, days: 60)

        guard data.count >= minDataPoints else {
            print("⚠️ Not enough data for study-progress analysis: \(data.count)")
            return nil
        }

        let studyHours = data.map { $0.studyHours }
        let progressRates = data.map { $0.progressRate }

        let coefficient = calculatePearsonCorrelation(x: studyHours, y: progressRates)
        let significance = calculateSignificance(correlation: coefficient, sampleSize: data.count)

        guard abs(coefficient) >= minCorrelation && significance < significanceLevel else {
            print("⚠️ Study-progress correlation not significant: r=\(coefficient)")
            return nil
        }

        let description = generateStudyProgressDescription(coefficient: coefficient, data: data)
        let examples = generateStudyProgressExamples(from: data, limit: 3)

        return Correlation(
            userId: userId,
            dimensionA: "habit.study",
            dimensionB: "goal.progress",
            correlationCoefficient: coefficient,
            significance: significance,
            description: description,
            examples: examples,
            lastVerified: Date()
        )
    }

    // MARK: - 数据查询

    /// 查询情绪-消费数据
    private func fetchEmotionSpendingData(userId: String, days: Int) async throws -> [EmotionSpendingPair] {
        // 这里需要实现实际的数据库查询
        // 暂时返回空数组，后续在 DatabaseService 中实现具体查询
        // TODO: Implement database query
        return []
    }

    /// 查询运动-情绪数据
    private func fetchExerciseEmotionData(userId: String, days: Int) async throws -> [ExerciseEmotionPair] {
        // TODO: Implement database query
        return []
    }

    /// 查询学习-进度数据
    private func fetchStudyProgressData(userId: String, days: Int) async throws -> [StudyProgressPair] {
        // TODO: Implement database query
        return []
    }

    // MARK: - 统计计算

    /// 计算 Pearson 相关系数
    /// r = Σ[(xi - x̄)(yi - ȳ)] / √[Σ(xi - x̄)² · Σ(yi - ȳ)²]
    private func calculatePearsonCorrelation(x: [Double], y: [Double]) -> Double {
        guard x.count == y.count && x.count > 1 else { return 0.0 }

        let n = Double(x.count)

        // 计算均值
        let meanX = x.reduce(0, +) / n
        let meanY = y.reduce(0, +) / n

        // 计算协方差和方差
        var covariance = 0.0
        var varianceX = 0.0
        var varianceY = 0.0

        for i in 0..<x.count {
            let diffX = x[i] - meanX
            let diffY = y[i] - meanY

            covariance += diffX * diffY
            varianceX += diffX * diffX
            varianceY += diffY * diffY
        }

        // 计算相关系数
        let denominator = sqrt(varianceX * varianceY)
        guard denominator > 0 else { return 0.0 }

        return covariance / denominator
    }

    /// 计算统计显著性（t-test）
    /// t = r√(n-2) / √(1-r²)
    /// p-value from t-distribution
    private func calculateSignificance(correlation r: Double, sampleSize n: Int) -> Double {
        guard n > 2 else { return 1.0 }

        let df = Double(n - 2)
        let t = r * sqrt(df) / sqrt(1 - r * r)

        // 简化的 p-value 估算（双尾检验）
        // 完整实现需要 t-distribution 累积分布函数
        let absT = abs(t)

        // 使用近似公式（基于经验值）
        if absT > 2.576 { return 0.01 }   // p < 0.01
        if absT > 1.96 { return 0.05 }    // p < 0.05
        if absT > 1.645 { return 0.10 }   // p < 0.10
        return 0.20  // p > 0.10
    }

    // MARK: - 描述生成

    /// 生成情绪-消费描述
    private func generateEmotionSpendingDescription(coefficient: Double, data: [EmotionSpendingPair]) -> String {
        let avgLowMoodSpending = data.filter { $0.emotionScore < -0.3 }
            .map { $0.spending }
            .reduce(0, +) / Double(max(data.filter { $0.emotionScore < -0.3 }.count, 1))

        let avgNormalSpending = data.filter { $0.emotionScore >= -0.3 }
            .map { $0.spending }
            .reduce(0, +) / Double(max(data.filter { $0.emotionScore >= -0.3 }.count, 1))

        let increase = ((avgLowMoodSpending - avgNormalSpending) / avgNormalSpending) * 100

        if coefficient < -0.4 {
            return String(format: "情绪低落时，支出平均增加 %.0f%%（相关系数: %.2f）", abs(increase), coefficient)
        } else if coefficient > 0.4 {
            return String(format: "情绪良好时，支出平均增加 %.0f%%（相关系数: %.2f）", increase, coefficient)
        }

        return String(format: "情绪与支出相关性: %.2f", coefficient)
    }

    /// 生成运动-情绪描述
    private func generateExerciseEmotionDescription(coefficient: Double, data: [ExerciseEmotionPair]) -> String {
        let avgEmotionWithExercise = data.filter { $0.exercised }
            .map { $0.emotionScore }
            .reduce(0, +) / Double(max(data.filter { $0.exercised }.count, 1))

        let avgEmotionWithoutExercise = data.filter { !$0.exercised }
            .map { $0.emotionScore }
            .reduce(0, +) / Double(max(data.filter { !$0.exercised }.count, 1))

        let improvement = ((avgEmotionWithExercise - avgEmotionWithoutExercise) / abs(avgEmotionWithoutExercise)) * 100

        return String(format: "运动后情绪平均提升 %.0f%%（相关系数: %.2f）", improvement, coefficient)
    }

    /// 生成学习-进度描述
    private func generateStudyProgressDescription(coefficient: Double, data: [StudyProgressPair]) -> String {
        let avgProgress = data.map { $0.progressRate }.reduce(0, +) / Double(data.count)
        return String(format: "学习时长与目标进度正相关，平均进度 %.1f%%（相关系数: %.2f）", avgProgress * 100, coefficient)
    }

    // MARK: - 案例生成

    /// 生成情绪-消费案例
    private func generateExamples(from data: [EmotionSpendingPair], limit: Int) -> [CorrelationExample] {
        // 选择最极端的案例（情绪最低时的支出）
        let sortedData = data.sorted { $0.emotionScore < $1.emotionScore }
        let topExamples = Array(sortedData.prefix(limit))

        return topExamples.map { pair in
            CorrelationExample(
                date: pair.date,
                valueA: pair.emotionScore,
                valueB: pair.spending,
                description: String(format: "情绪 %.1f，支出 ¥%.0f", pair.emotionScore, pair.spending)
            )
        }
    }

    /// 生成运动-情绪案例
    private func generateExerciseEmotionExamples(from data: [ExerciseEmotionPair], limit: Int) -> [CorrelationExample] {
        // 选择有运动且情绪提升最明显的案例
        let withExercise = data.filter { $0.exercised }.sorted { $0.emotionScore > $1.emotionScore }
        let topExamples = Array(withExercise.prefix(limit))

        return topExamples.map { pair in
            CorrelationExample(
                date: pair.date,
                valueA: pair.exercised ? 1.0 : 0.0,
                valueB: pair.emotionScore,
                description: String(format: "运动后情绪 %.1f", pair.emotionScore)
            )
        }
    }

    /// 生成学习-进度案例
    private func generateStudyProgressExamples(from data: [StudyProgressPair], limit: Int) -> [CorrelationExample] {
        let sortedData = data.sorted { $0.progressRate > $1.progressRate }
        let topExamples = Array(sortedData.prefix(limit))

        return topExamples.map { pair in
            CorrelationExample(
                date: pair.date,
                valueA: pair.studyHours,
                valueB: pair.progressRate,
                description: String(format: "学习 %.1f 小时，进度 %.0f%%", pair.studyHours, pair.progressRate * 100)
            )
        }
    }
}

// MARK: - 数据结构

/// 情绪-消费数据对
private struct EmotionSpendingPair {
    let date: Date
    let emotionScore: Double    // -1.0 to 1.0
    let spending: Double        // JPY
}

/// 运动-情绪数据对
private struct ExerciseEmotionPair {
    let date: Date
    let exercised: Bool         // 是否运动
    let emotionScore: Double    // -1.0 to 1.0
}

/// 学习-进度数据对
private struct StudyProgressPair {
    let date: Date
    let studyHours: Double      // 学习时长（小时）
    let progressRate: Double    // 进度率 0.0 to 1.0
}
