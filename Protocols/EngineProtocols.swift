import Foundation

/// Context Engine 协议 - 全局上下文加载
protocol ContextEngineProtocol {
    /// 加载用户完整上下文（目标：<100ms）
    func loadContext(userId: String) async throws -> UserContext

    /// 清除缓存
    func invalidateCache(userId: String)

    /// 清除所有缓存
    func clearAllCache()
}

/// Correlation Engine 协议 - 关联分析
protocol CorrelationEngineProtocol {
    /// 分析所有可能的关联
    func analyzeCorrelations(userId: String) async throws -> [Correlation]

    /// 分析特定维度的关联
    func analyzeCorrelation(
        userId: String,
        dimensionA: String,
        dimensionB: String
    ) async throws -> Correlation?

    /// 验证已有关联是否仍然有效
    func verifyCorrelation(_ correlation: Correlation) async throws -> Bool
}

/// Insight Engine 协议 - 洞察生成
protocol InsightEngineProtocol {
    /// 基于上下文生成洞察
    func generateInsights(context: UserContext) async throws -> [Insight]

    /// 生成特定类型的洞察
    func generateInsight(
        type: InsightType,
        category: InsightCategory,
        context: UserContext
    ) async throws -> Insight?

    /// 优先级排序
    func prioritizeInsights(_ insights: [Insight]) -> [Insight]
}
