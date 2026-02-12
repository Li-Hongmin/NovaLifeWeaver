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
                FinancialDashboardView()

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

/// 财务管理视图（占位符）
struct FinancialDashboardView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "yensign.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("财务管理")
                .font(.title)

            Text("Day 2 上午实现")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("功能：交易记录、预算管理、分类图表")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// 情绪记录视图（占位符）
struct EmotionDashboardView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.pink)

            Text("情绪记录")
                .font(.title)

            Text("Day 2 下午实现")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("功能：情绪打卡、语音日记、趋势分析")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
