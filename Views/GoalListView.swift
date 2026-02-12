import SwiftUI

/// 目标列表视图 - 显示和管理目标
struct GoalListView: View {
    @StateObject private var viewModel = GoalListViewModel()
    @State private var showingAddGoal = false
    @State private var selectedGoal: Goal?

    var body: some View {
        VStack(spacing: 0) {
            // 头部
            HStack {
                Text("我的目标")
                    .font(.headline)

                Spacer()

                Button(action: { showingAddGoal.toggle() }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding()

            Divider()

            // 目标列表
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.goals) { goal in
                        GoalCard(goal: goal)
                            .onTapGesture {
                                selectedGoal = goal
                            }
                    }
                }
                .padding()
            }
        }
        .frame(width: 400, height: 600)
        .onAppear {
            Task {
                await viewModel.loadGoals()
            }
        }
        .sheet(isPresented: $showingAddGoal) {
            AddGoalView(onSave: { goal in
                await viewModel.addGoal(goal)
                showingAddGoal = false
            })
        }
        .sheet(item: $selectedGoal) { goal in
            GoalDetailView(goal: goal)
        }
    }
}

// MARK: - Goal Card

struct GoalCard: View {
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    if let category = goal.category {
                        Text(category)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // 状态指示器
                statusBadge
            }

            // 进度条
            if let targetValue = goal.targetValue {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(goal.measurableMetric ?? "进度")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("\(Int(goal.currentValue)) / \(Int(targetValue))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    ProgressView(value: goal.progress)
                        .tint(progressColor)
                }
            }

            // 截止日期和优先级
            HStack {
                if let deadline = goal.deadline {
                    HStack(spacing: 4) {
                        Image(systemName: deadlineIcon)
                            .font(.caption)
                            .foregroundColor(deadlineColor)

                        Text(formatDeadline(deadline))
                            .font(.caption)
                            .foregroundColor(deadlineColor)
                    }
                }

                Spacer()

                // 优先级
                HStack(spacing: 2) {
                    ForEach(0..<goal.priority, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                }
            }
        }
        .padding(12)
        .background(cardBackgroundColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private var statusBadge: some View {
        Text(statusText)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusBackgroundColor)
            .foregroundColor(statusForegroundColor)
            .cornerRadius(4)
    }

    private var statusText: String {
        switch goal.status {
        case .active:
            if goal.isCompleted {
                return "完成"
            } else if goal.isOverdue {
                return "逾期"
            } else if goal.isDueSoon {
                return "即将到期"
            } else {
                return "进行中"
            }
        case .paused:
            return "暂停"
        case .completed:
            return "完成"
        case .cancelled:
            return "取消"
        }
    }

    private var statusBackgroundColor: Color {
        switch goal.status {
        case .active:
            if goal.isOverdue {
                return .red.opacity(0.2)
            } else if goal.isDueSoon {
                return .orange.opacity(0.2)
            } else {
                return .green.opacity(0.2)
            }
        case .paused:
            return .gray.opacity(0.2)
        case .completed:
            return .blue.opacity(0.2)
        case .cancelled:
            return .secondary.opacity(0.2)
        }
    }

    private var statusForegroundColor: Color {
        switch goal.status {
        case .active:
            if goal.isOverdue {
                return .red
            } else if goal.isDueSoon {
                return .orange
            } else {
                return .green
            }
        case .paused:
            return .gray
        case .completed:
            return .blue
        case .cancelled:
            return .secondary
        }
    }

    private var progressColor: Color {
        if goal.isOverdue {
            return .red
        } else if goal.isDueSoon {
            return .orange
        } else {
            return .green
        }
    }

    private var cardBackgroundColor: Color {
        if goal.isCompleted {
            return Color(NSColor.controlBackgroundColor).opacity(0.5)
        } else {
            return Color(NSColor.controlBackgroundColor)
        }
    }

    private var borderColor: Color {
        if goal.isOverdue {
            return .red.opacity(0.3)
        } else if goal.isDueSoon {
            return .orange.opacity(0.3)
        } else {
            return Color.clear
        }
    }

    private var deadlineIcon: String {
        if goal.isOverdue {
            return "exclamationmark.triangle.fill"
        } else if goal.isDueSoon {
            return "clock.fill"
        } else {
            return "calendar"
        }
    }

    private var deadlineColor: Color {
        if goal.isOverdue {
            return .red
        } else if goal.isDueSoon {
            return .orange
        } else {
            return .secondary
        }
    }

    private func formatDeadline(_ date: Date) -> String {
        if let days = goal.daysRemaining {
            if days == 0 {
                return "今天"
            } else if days == 1 {
                return "明天"
            } else if days < 0 {
                return "逾期 \(abs(days)) 天"
            } else {
                return "\(days) 天后"
            }
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Add Goal View (Placeholder)

struct AddGoalView: View {
    @Environment(\.dismiss) var dismiss
    let onSave: (Goal) async -> Void

    @State private var title = ""
    @State private var description = ""
    @State private var deadline = Date()
    @State private var priority = 3

    var body: some View {
        VStack(spacing: 20) {
            Text("添加目标")
                .font(.headline)

            TextField("目标名称", text: $title)
                .textFieldStyle(.roundedBorder)

            TextField("描述", text: $description)
                .textFieldStyle(.roundedBorder)

            DatePicker("截止日期", selection: $deadline, displayedComponents: .date)

            Picker("优先级", selection: $priority) {
                ForEach(1...5, id: \.self) { priority in
                    Text("\(priority) 星").tag(priority)
                }
            }

            HStack {
                Button("取消") {
                    dismiss()
                }

                Spacer()

                Button("保存") {
                    Task {
                        // TODO: 创建 Goal 对象并保存
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 400)
    }
}

// MARK: - Goal Detail View (Placeholder)

struct GoalDetailView: View {
    let goal: Goal
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text(goal.title)
                .font(.headline)

            Text(goal.description ?? "无描述")
                .font(.body)

            // TODO: 显示详细信息和子任务

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
    GoalListView()
}
