import Foundation
import SwiftUI
import Combine

/// 情绪视图模型 - 管理情绪记录
@MainActor
class EmotionViewModel: ObservableObject {
    @Published var emotions: [EmotionRecord] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = DatabaseService.shared

    /// 加载情绪记录
    func loadEmotions(userId: String, days: Int = 30) async {
        isLoading = true
        do {
            emotions = try await db.fetchRecentEmotions(userId: userId, days: days)
            print("✅ 已加载 \(emotions.count) 条情绪记录")
        } catch {
            errorMessage = "加载失败：\(error.localizedDescription)"
        }
        isLoading = false
    }

    /// 添加情绪记录
    func addEmotion(_ record: EmotionRecord) async {
        do {
            _ = try await db.createEmotionRecord(record)
            emotions.insert(record, at: 0)
            print("✅ 情绪记录已添加")
        } catch {
            errorMessage = "添加失败：\(error.localizedDescription)"
        }
    }
}
