import Foundation
import SwiftUI
import EventKit
import Combine

/// 日历视图模型 - 管理日历事件
@MainActor
class CalendarViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var selectedDate: Date = Date()
    @Published var viewMode: CalendarViewMode = .month
    @Published var conflicts: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let eventKitService = EventKitService.shared
    private let db = DatabaseService.shared

    // MARK: - View Modes

    enum CalendarViewMode: String, CaseIterable {
        case day = "日"
        case week = "周"
        case month = "月"
    }

    // MARK: - Computed Properties

    /// 当前选中日期的事件
    var selectedDayEvents: [Event] {
        let calendar = Calendar.current
        return events.filter { event in
            calendar.isDate(event.startTime, inSameDayAs: selectedDate)
        }
    }

    /// 当月事件
    var monthEvents: [Event] {
        let calendar = Calendar.current
        let month = calendar.dateInterval(of: .month, for: selectedDate)!

        return events.filter { event in
            event.startTime >= month.start && event.startTime < month.end
        }
    }

    // MARK: - Public Methods

    /// 加载事件
    func loadEvents(userId: String) async {
        isLoading = true

        do {
            // 1. 从数据库加载
            events = try await db.fetchEvents(userId: userId, from: monthStart, to: monthEnd)

            // 2. 从 EventKit 同步
            if let ekEvents = try? await eventKitService.fetchEvents(from: monthStart, to: monthEnd) {
                // 合并 EventKit 事件
                for ekEvent in ekEvents {
                    if !events.contains(where: { $0.eventKitId == ekEvent.eventIdentifier }) {
                        events.append(Event(from: ekEvent, userId: userId))
                    }
                }
            }

            print("✅ 加载了 \(events.count) 个事件")
        } catch {
            errorMessage = "加载事件失败：\(error.localizedDescription)"
            events = []
        }

        isLoading = false
    }

    /// 添加事件
    func addEvent(_ event: Event) async {
        do {
            // 1. 检查冲突
            let foundConflicts = try await eventKitService.checkConflict(
                start: event.startTime,
                end: event.endTime
            )

            if !foundConflicts.isEmpty {
                conflicts = foundConflicts.map { Event(from: $0, userId: event.userId) }
                print("⚠️ 发现 \(conflicts.count) 个冲突事件")
                return
            }

            // 2. 保存到数据库
            _ = try await db.createEvent(event)

            // 3. 同步到 EventKit（如果配置）
            if let ekEvent = try? await eventKitService.addEvent(event) {
                // 更新 eventKitId
                var updatedEvent = event
                updatedEvent.eventKitId = ekEvent.eventIdentifier
                try? await db.updateEvent(updatedEvent)
            }

            // 4. 更新列表
            events.append(event)
            print("✅ 事件已添加：\(event.title)")

        } catch {
            errorMessage = "添加事件失败：\(error.localizedDescription)"
        }
    }

    /// 删除事件
    func deleteEvent(_ event: Event) async {
        do {
            // 1. 从数据库删除
            try await db.deleteEvent(event.id)

            // 2. 从 EventKit 删除（如果有）
            if let ekId = event.eventKitId {
                try? await eventKitService.deleteEvent(ekId)
            }

            // 3. 从列表移除
            events.removeAll { $0.id == event.id }

            print("✅ 事件已删除")
        } catch {
            errorMessage = "删除失败：\(error.localizedDescription)"
        }
    }

    /// 清除冲突
    func clearConflicts() {
        conflicts = []
    }

    // MARK: - Helper Methods

    private var monthStart: Date {
        let calendar = Calendar.current
        return calendar.dateInterval(of: .month, for: selectedDate)!.start
    }

    private var monthEnd: Date {
        let calendar = Calendar.current
        return calendar.dateInterval(of: .month, for: selectedDate)!.end
    }
}

// MARK: - Event Extension

extension Event {
    /// 从 EKEvent 创建
    init(from ekEvent: EKEvent, userId: String) {
        self.init(
            id: UUID().uuidString,
            userId: userId,
            title: ekEvent.title ?? "无标题",
            startTime: ekEvent.startDate,
            endTime: ekEvent.endDate,
            location: ekEvent.location,
            notes: ekEvent.notes,
            isAllDay: ekEvent.isAllDay,
            eventKitId: ekEvent.eventIdentifier,
            createdAt: ekEvent.creationDate ?? Date()
        )
    }
}
