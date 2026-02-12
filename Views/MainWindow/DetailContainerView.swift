import SwiftUI

/// 详情容器视图 - 根据选中的导航区域显示对应内容
struct DetailContainerView: View {
    @EnvironmentObject var navigationState: NavigationStateManager
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            switch navigationState.selectedSection {
            case .goals:
                GoalListView()

            case .habits:
                HabitTrackingView()

            case .finance:
                FinancialDashboardView(userId: appState.currentUser?.id ?? "default-user")

            case .emotions:
                EmotionDashboardView()

            case .calendar:
                CalendarDashboardView()

            case .insights:
                InsightDashboardView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Placeholder Views (待实现)

/// 财务管理视图
struct FinancialDashboardView: View {
    let userId: String

    @StateObject private var viewModel = FinancialViewModel()

    var body: some View {
        TransactionListView(viewModel: viewModel, userId: userId)
            .task {
                await viewModel.loadTransactions(userId: userId)
                await viewModel.loadBudgets(userId: userId)
            }
    }
}

/// 情绪记录视图
struct EmotionDashboardView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = EmotionViewModel()
    @State private var showingRecorder = false

    var body: some View {
        VStack(spacing: 0) {
            // 时间线
            EmotionTimelineView(viewModel: viewModel)

            Divider()

            // 底部按钮
            HStack {
                Spacer()

                Button {
                    showingRecorder = true
                } label: {
                    Label("记录情绪", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
        .sheet(isPresented: $showingRecorder) {
            EmotionRecorderView(
                viewModel: viewModel,
                userId: appState.currentUser?.id ?? "default-user"
            )
        }
        .task {
            await viewModel.loadEmotions(
                userId: appState.currentUser?.id ?? "default-user"
            )
        }
    }
}

/// 日历视图（占位符）
struct CalendarDashboardView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.blue)

            Text("日历管理")
                .font(.title)

            Text("待实现")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("功能：日程查看、事件添加、冲突检测")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// 洞察仪表盘视图（占位符）
struct InsightDashboardView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lightbulb.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.yellow)

            Text("智能洞察")
                .font(.title)

            Text("Day 3 下午实现")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("功能：关联分析、模式发现、AI 建议")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    DetailContainerView()
        .environmentObject(NavigationStateManager.shared)
        .environmentObject(AppState.shared)
        .frame(width: 600, height: 400)
}
