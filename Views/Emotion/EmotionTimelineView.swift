import SwiftUI

/// 情绪时间线视图
struct EmotionTimelineView: View {
    @ObservedObject var viewModel: EmotionViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12, pinnedViews: [.sectionHeaders]) {
                ForEach(groupedByDate, id: \.key) { date, records in
                    Section {
                        ForEach(records) { record in
                            EmotionRowView(record: record)
                        }
                    } header: {
                        Text(formatDateHeader(date))
                            .font(.headline)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(NSColor.controlBackgroundColor))
                    }
                }
            }
            .padding()
        }
    }

    /// 按日期分组
    private var groupedByDate: [(key: String, value: [EmotionRecord])] {
        let grouped = Dictionary(grouping: viewModel.emotions) { record in
            Calendar.current.startOfDay(for: record.recordedAt)
        }
        return grouped.sorted { $0.key > $1.key }.map { (formatDate($0.key), $0.value) }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func formatDateHeader(_ dateStr: String) -> String {
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        if dateStr == formatDate(today) {
            return "今天"
        } else if dateStr == formatDate(yesterday) {
            return "昨天"
        } else {
            return dateStr
        }
    }
}

/// 情绪记录行视图
struct EmotionRowView: View {
    let record: EmotionRecord

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 情绪图标
            Text(Mood(score: record.score).emoji)
                .font(.system(size: 32))

            VStack(alignment: .leading, spacing: 6) {
                // 时间
                Text(record.recordedAt, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)

                // 触发因素
                if let trigger = record.trigger {
                    Text(trigger)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }

                // 备注
                if let note = record.note {
                    Text(note)
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            // 情绪分数
            VStack {
                Text(String(format: "%.1f", record.score))
                    .font(.caption.monospacedDigit())
                    .foregroundColor(scoreColor(record.score))
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }

    private func scoreColor(_ score: Double) -> Color {
        if score > 0.5 { return .green }
        if score > 0 { return .mint }
        if score > -0.5 { return .orange }
        return .red
    }
}
