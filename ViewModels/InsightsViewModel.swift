import Foundation
import SwiftUI
import Combine

/// 洞察视图模型 - 管理关联分析和洞察
@MainActor
class InsightsViewModel: ObservableObject {
    @Published var correlations: [Correlation] = []
    @Published var insights: [Insight] = []
    @Published var isAnalyzing = false
    @Published var errorMessage: String?

    private let correlationEngine = CorrelationEngine.shared
    private let insightEngine = InsightEngine.shared
    private let db = DatabaseService.shared

    /// 分析关联
    func analyzeCorrelations(userId: String) async {
        isAnalyzing = true

        do {
            correlations = try await correlationEngine.analyzeCorrelations(userId: userId)
            print("✅ 发现 \(correlations.count) 个关联模式")
        } catch {
            errorMessage = "分析失败：\(error.localizedDescription)"
            correlations = []
        }

        isAnalyzing = false
    }

    /// 生成洞察
    func generateInsights(context: UserContext) async {
        do {
            insights = try await insightEngine.generateInsights(context: context)
            print("✅ 生成 \(insights.count) 条洞察")
        } catch {
            errorMessage = "生成洞察失败：\(error.localizedDescription)"
            insights = []
        }
    }

    /// 加载已保存的关联和洞察
    func loadData(userId: String) async {
        // 暂时使用空数据（数据库方法待实现）
        correlations = []
        insights = []
        print("⚠️ 关联和洞察数据加载待实现")
    }
}
