import SwiftUI

/// 习惯追踪视图 - 显示和管理习惯
struct HabitTrackingView: View {
    @StateObject private var viewModel = HabitTrackingViewModel()
    @State private var showingAddHabit = false
    @State private var selectedHabit: Habit?

    var body: some View {
        VStack(spacing: 0) {
            // 头部
            HStack {
                Text("我的习惯")
                    .font(.headline)

                Spacer()

                Button(action: { showingAddHabit.toggle() }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding()

            Divider()

            // 今日概览
            TodaySummaryCard(
                habits: viewModel.habits,
                completions: viewModel.todayCompletions
            )
            .padding()

            Divider()

            // 习惯列表
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.habits) { habit in
                        HabitCard(
                            habit: habit,
                            isCompleted: viewModel.isCompletedToday(habit.id),
                            onToggle: {
                                await viewModel.toggleCompletion(habit.id)
                            }
                        )
                        .onTapGesture {
                            selectedHabit = habit
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 400, height: 600)
        .onAppear {
            Task {
                await viewModel.loadHabits()
            }
        }
        .sheet(isPresented: $showingAddHabit) {
            AddHabitView(onSave: { habit in
                await viewModel.addHabit(habit)
                showingAddHabit = false
            })
        }
        .sheet(item: $selectedHabit) { habit in
            HabitDetailView(habit: habit)
        }
    }
}

// MARK: - Today Summary Card

struct TodaySummaryCard: View {
    let habits: [Habit]
    let completions: [HabitCompletion]

    private var completionRate: Double {
        guard !habits.isEmpty else { return 0 }
        return Double(completions.count) / Double(habits.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日完成率")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                // 环形进度指示器
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)

                    Circle()
                        .trim(from: 0, to: completionRate)
                        .stroke(completionRateColor, lineWidth: 8)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(completionRate * 100))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(completionRateColor)
                }
                .frame(width: 80, height: 80)

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("\(completions.count) 已完成")
                            .font(.caption)
                    }

                    HStack {
                        Image(systemName: "circle")
                            .foregroundColor(.secondary)
                        Text("\(habits.count - completions.count) 待完成")
                            .font(.caption)
                    }

                    if streakCount > 0 {
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("\(streakCount) 个连续中")
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    private var completionRateColor: Color {
        if completionRate >= 0.8 {
            return .green
        } else if completionRate >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }

    private var streakCount: Int {
        habits.filter { $0.streak > 0 }.count
    }
}

// MARK: - Habit Card

struct HabitCard: View {
    let habit: Habit
    let isCompleted: Bool
    let onToggle: () async -> Void

    @State private var isToggling = false

    var body: some View {
        HStack(spacing: 12) {
            // 完成按钮
            Button(action: {
                Task {
                    isToggling = true
                    await onToggle()
                    isToggling = false
                }
            }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(isToggling)

            // 习惯信息
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .strikethrough(isCompleted)

                if let description = habit.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                // 频率和分类
                HStack(spacing: 8) {
                    if let category = habit.category {
                        Text(category)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.2))
                            .cornerRadius(4)
                    }

                    Text(frequencyText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // 连续天数
            if habit.streak > 0 {
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundColor(.orange)

                        Text("\(habit.streak)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }

                    if habit.isEstablished {
                        Image(systemName: "trophy.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                }
            }
        }
        .padding(12)
        .background(isCompleted ? Color.green.opacity(0.1) : Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    private var frequencyText: String {
        switch habit.frequency {
        case .daily:
            return "每日"
        case .weekly:
            return "每周 \(habit.targetCount) 次"
        case .monthly:
            return "每月 \(habit.targetCount) 次"
        }
    }
}

// MARK: - Add Habit View (Placeholder)

struct AddHabitView: View {
    @Environment(\.dismiss) var dismiss
    let onSave: (Habit) async -> Void

    @State private var name = ""
    @State private var description = ""
    @State private var frequency: HabitFrequency = .daily
    @State private var category = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("添加习惯")
                .font(.headline)

            TextField("习惯名称", text: $name)
                .textFieldStyle(.roundedBorder)

            TextField("描述", text: $description)
                .textFieldStyle(.roundedBorder)

            TextField("分类", text: $category)
                .textFieldStyle(.roundedBorder)

            Picker("频率", selection: $frequency) {
                Text("每日").tag(HabitFrequency.daily)
                Text("每周").tag(HabitFrequency.weekly)
                Text("每月").tag(HabitFrequency.monthly)
            }

            HStack {
                Button("取消") {
                    dismiss()
                }

                Spacer()

                Button("保存") {
                    Task {
                        // TODO: 创建 Habit 对象并保存
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 400)
    }
}

// MARK: - Habit Detail View (Placeholder)

struct HabitDetailView: View {
    let habit: Habit
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text(habit.name)
                .font(.headline)

            // 连续天数
            HStack {
                VStack {
                    Text("\(habit.streak)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("当前连续")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack {
                    Text("\(habit.longestStreak)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("最长连续")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()

            // TODO: 显示历史记录和统计

            Button("关闭") {
                dismiss()
            }
        }
        .padding()
        .frame(width: 400, height: 500)
    }
}

// MARK: - Preview

#Preview {
    HabitTrackingView()
}
