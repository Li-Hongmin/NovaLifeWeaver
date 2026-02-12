import Foundation
import EventKit

/// EventKit 服务 - macOS 日历集成
class EventKitService {
    static let shared = EventKitService()

    private let store = EKEventStore()
    private var hasAccess = false

    private init() {}

    // MARK: - 权限管理

    /// 请求日历访问权限
    func requestAccess() async throws -> Bool {
        if #available(macOS 14.0, *) {
            // macOS 14+ 使用新 API
            hasAccess = try await store.requestFullAccessToEvents()
        } else {
            // macOS 13 及以下使用旧 API
            hasAccess = try await withCheckedThrowingContinuation { continuation in
                store.requestAccess(to: .event) { granted, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
        }

        return hasAccess
    }

    /// 检查权限状态
    func checkAccessStatus() -> EKAuthorizationStatus {
        if #available(macOS 14.0, *) {
            return EKEventStore.authorizationStatus(for: .event)
        } else {
            return EKEventStore.authorizationStatus(for: .event)
        }
    }

    // MARK: - 事件查询

    /// 获取指定日期范围的事件
    func fetchEvents(
        from startDate: Date,
        to endDate: Date,
        calendars: [EKCalendar]? = nil
    ) async throws -> [EKEvent] {

        guard hasAccess else {
            throw EventKitError.noPermission
        }

        return await withCheckedContinuation { continuation in
            let predicate = store.predicateForEvents(
                withStart: startDate,
                end: endDate,
                calendars: calendars
            )

            let events = store.events(matching: predicate)
            continuation.resume(returning: events)
        }
    }

    /// 获取今日事件
    func fetchTodayEvents() async throws -> [EKEvent] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        return try await fetchEvents(from: startOfDay, to: endOfDay)
    }

    /// 获取未来 N 天的事件
    func fetchUpcomingEvents(days: Int = 14) async throws -> [EKEvent] {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: days, to: startDate)!

        return try await fetchEvents(from: startDate, to: endDate)
    }

    // MARK: - 冲突检测

    /// 检查指定时间是否有冲突
    func checkConflict(
        start: Date,
        end: Date,
        excludeEvent: EKEvent? = nil
    ) async throws -> [EKEvent] {

        let events = try await fetchEvents(from: start, to: end)

        // 过滤掉排除的事件
        let conflictingEvents = events.filter { event in
            if let exclude = excludeEvent, event.eventIdentifier == exclude.eventIdentifier {
                return false
            }

            // 检查时间重叠
            let eventStart = event.startDate!
            let eventEnd = event.endDate!

            return eventStart < end && start < eventEnd
        }

        return conflictingEvents
    }

    /// 是否有冲突（布尔值）
    func hasConflict(
        start: Date,
        end: Date,
        excludeEvent: EKEvent? = nil
    ) async throws -> Bool {

        let conflicts = try await checkConflict(
            start: start,
            end: end,
            excludeEvent: excludeEvent
        )

        return !conflicts.isEmpty
    }

    // MARK: - 事件操作

    /// 添加事件到日历
    func addEvent(
        title: String,
        startDate: Date,
        endDate: Date,
        notes: String? = nil,
        location: String? = nil,
        calendar: EKCalendar? = nil
    ) async throws -> String {

        guard hasAccess else {
            throw EventKitError.noPermission
        }

        // 检查冲突
        let hasConflict = try await self.hasConflict(start: startDate, end: endDate)
        if hasConflict {
            throw EventKitError.timeConflict
        }

        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.notes = notes
        event.location = location
        event.calendar = calendar ?? store.defaultCalendarForNewEvents

        try store.save(event, span: .thisEvent)

        return event.eventIdentifier
    }

    /// 批量添加事件
    func addEvents(_ events: [EventData]) async throws -> [String] {
        var eventIds: [String] = []

        for eventData in events {
            let eventId = try await addEvent(
                title: eventData.title,
                startDate: eventData.startDate,
                endDate: eventData.endDate,
                notes: eventData.notes,
                location: eventData.location
            )
            eventIds.append(eventId)
        }

        return eventIds
    }

    /// 更新事件
    func updateEvent(
        eventId: String,
        title: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        notes: String? = nil,
        location: String? = nil
    ) async throws {

        guard hasAccess else {
            throw EventKitError.noPermission
        }

        guard let event = store.event(withIdentifier: eventId) else {
            throw EventKitError.eventNotFound
        }

        if let title = title { event.title = title }
        if let startDate = startDate { event.startDate = startDate }
        if let endDate = endDate { event.endDate = endDate }
        if let notes = notes { event.notes = notes }
        if let location = location { event.location = location }

        try store.save(event, span: .thisEvent)
    }

    /// 删除事件
    func deleteEvent(eventId: String) async throws {
        guard hasAccess else {
            throw EventKitError.noPermission
        }

        guard let event = store.event(withIdentifier: eventId) else {
            throw EventKitError.eventNotFound
        }

        try store.remove(event, span: .thisEvent)
    }

    // MARK: - 日历操作

    /// 获取所有日历
    func fetchCalendars() -> [EKCalendar] {
        return store.calendars(for: .event)
    }

    /// 获取默认日历
    func getDefaultCalendar() -> EKCalendar? {
        return store.defaultCalendarForNewEvents
    }
}

// MARK: - 数据结构

/// 事件数据（用于批量创建）
struct EventData {
    let title: String
    let startDate: Date
    let endDate: Date
    let notes: String?
    let location: String?

    init(
        title: String,
        startDate: Date,
        endDate: Date,
        notes: String? = nil,
        location: String? = nil
    ) {
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.notes = notes
        self.location = location
    }
}

/// EventKit 错误类型
enum EventKitError: Error {
    case noPermission
    case eventNotFound
    case timeConflict
    case saveFailed

    var localizedDescription: String {
        switch self {
        case .noPermission:
            return "没有日历访问权限"
        case .eventNotFound:
            return "事件不存在"
        case .timeConflict:
            return "时间冲突"
        case .saveFailed:
            return "保存失败"
        }
    }
}

// MARK: - 便捷扩展
extension EventKitService {
    /// 转换 Event 模型到 EKEvent
    func convertToEKEvent(_ event: Event) async throws -> String {
        return try await addEvent(
            title: event.title,
            startDate: event.startTime,
            endDate: event.endTime ?? event.startTime.addingTimeInterval(TimeInterval(event.duration ?? 60) * 60),
            notes: event.description,
            location: event.location
        )
    }

    /// 转换 EKEvent 到 Event 模型
    func convertFromEKEvent(_ ekEvent: EKEvent, userId: String) -> Event {
        return Event(
            id: UUID().uuidString,
            userId: userId,
            title: ekEvent.title,
            description: ekEvent.notes,
            location: ekEvent.location,
            startTime: ekEvent.startDate,
            endTime: ekEvent.endDate,
            allDay: ekEvent.isAllDay,
            source: .calendar,
            calendarId: ekEvent.eventIdentifier,
            syncedToCalendar: true
        )
    }
}
