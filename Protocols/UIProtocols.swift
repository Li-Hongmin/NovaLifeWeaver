import Foundation
import SwiftUI

// MARK: - Menu Bar Application Protocol

/// Menu Bar 应用管理器协议
protocol MenuBarManagerProtocol {
    /// 初始化 Menu Bar 图标
    func setupMenuBar()

    /// 显示/隐藏弹出面板
    func togglePopover()

    /// 更新 Menu Bar 图标状态
    func updateIcon(status: AppStatus)
}

/// 应用状态
enum AppStatus {
    case normal         // 正常状态
    case hasAlert       // 有警告
    case syncing        // 同步中
    case offline        // 离线
}

// MARK: - View Protocols

/// 主视图协议
protocol MainViewProtocol {
    /// 刷新视图数据
    func refresh() async

    /// 处理用户输入
    func handleInput(_ input: String) async
}

/// 对话视图协议
protocol ConversationViewProtocol {
    /// 发送消息
    func sendMessage(_ message: String) async

    /// 添加多模态输入（语音/图片）
    func addVoiceInput(_ audioData: Data) async
    func addImageInput(_ imageData: Data) async
}

/// 上下文展示协议
protocol ContextDisplayProtocol {
    /// 加载用户上下文
    func loadContext(userId: String) async

    /// 刷新特定部分
    func refreshSection(_ section: ContextSection)
}

enum ContextSection {
    case goals
    case habits
    case finance
    case emotion
    case schedule
}

// MARK: - Intent Router Protocol

/// 意图路由器协议 - 分析用户输入意图
protocol IntentRouterProtocol {
    /// 分析用户输入，返回意图类型
    func analyze(input: String) async throws -> UserIntent

    /// 路由到对应的处理器
    func route(intent: UserIntent, context: UserContext) async throws -> IntentResult
}

/// 用户意图类型
enum UserIntent {
    case createGoal(String)           // "我想考 JLPT N2"
    case createHabit(String)          // "每天跑步"
    case recordEmotion(String)        // "今天有点累"
    case recordExpense(String)        // "午餐花了 800"
    case queryStatus(String)          // "我的目标进度如何"
    case planSchedule(String)         // "帮我安排本周"
    case general(String)              // 一般对话
}

/// 意图处理结果
struct IntentResult {
    let success: Bool
    let message: String
    let actions: [SuggestedAction]?
    let dataUpdated: [String]?        // 更新的数据类型
}

// MARK: - State Management Protocol

/// 应用状态管理协议
@MainActor
protocol AppStateProtocol: ObservableObject {
    var currentUser: User? { get set }
    var context: UserContext? { get set }
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }

    /// 加载用户状态
    func loadUserState() async

    /// 刷新上下文
    func refreshContext() async
}
