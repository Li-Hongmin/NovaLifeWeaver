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
        // 暂时使用空数据
        emotions = []
        print("⚠️ 情绪数据加载待实现")
        isLoading = false
    }

    /// 添加情绪记录
    func addEmotion(_ record: EmotionRecord) async {
        // 暂时只更新UI
        emotions.insert(record, at: 0)
        print("⚠️ 情绪记录保存待实现（仅UI显示）")
    }
}
