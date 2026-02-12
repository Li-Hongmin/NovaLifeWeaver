import Foundation

/// Planner Agent 协议 - 日程规划
protocol PlannerAgentProtocol {
    /// 规划目标
    func plan(goal: String, userId: String) async throws -> PlanResult

    /// 检查日程冲突
    func checkConflicts(events: [Event], userId: String) async throws -> [(Event, Event)]
}

/// Memory Agent 协议 - 多模态记录解析
protocol MemoryAgentProtocol {
    /// 处理文本输入
    func processText(_ text: String, userId: String) async throws -> ProcessedRecord

    /// 处理语音输入
    func processAudio(_ audioData: Data, userId: String) async throws -> ProcessedRecord

    /// 处理图片输入
    func processImage(_ imageData: Data, userId: String) async throws -> ProcessedRecord

    /// 提取结构化数据
    func extractStructuredData(from content: String) async throws -> [String: Any]
}

/// Act Agent 协议 - 自动化操作
protocol ActAgentProtocol {
    /// 执行操作
    func execute(_ action: Action) async throws

    /// 批量执行操作
    func executeBatch(_ actions: [Action]) async throws -> [ActionResult]
}

// MARK: - 支持类型

/// 处理后的记录
struct ProcessedRecord {
    let type: RecordType
    let content: String
    let structuredData: [String: Any]?
    let sentiment: Double?
    let tags: [String]
}

enum RecordType: String {
    case text
    case audio
    case image
}

/// 操作类型
enum Action {
    case addCalendarEvent(Event)
    case createReminder(String, Date)
    case sendNotification(String, String)
    case syncToNotion([String: Any])
}

/// 操作结果
struct ActionResult {
    let action: String
    let success: Bool
    let message: String?
}
