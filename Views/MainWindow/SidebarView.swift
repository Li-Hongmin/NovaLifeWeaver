import SwiftUI

/// 侧边栏视图 - 主窗口导航
struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var navigationState: NavigationStateManager

    var body: some View {
        List(selection: $navigationState.selectedSection) {
            // 导航区域
            Section {
                ForEach(NavigationSection.allCases) { section in
                    NavigationLink(value: section) {
                        Label {
                            HStack {
                                Text(section.displayName)
                                Spacer()
                                // 显示徽章（如果有）
                                if let badge = getBadgeCount(for: section) {
                                    Text("\(badge)")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.accentColor)
                                        .clipShape(Capsule())
                                }
                            }
                        } icon: {
                            Image(systemName: section.iconName)
                                .foregroundColor(navigationState.selectedSection == section ? .accentColor : .secondary)
                        }
                    }
                    .help(section.displayName)
                }
            }

            // 底部操作区域
            Section {
                // 刷新按钮
                Button {
                    Task {
                        await appState.refreshContext()
                    }
                } label: {
                    Label("刷新数据", systemImage: "arrow.clockwise")
                }

                // 设置按钮
                Button {
                    openSettings()
                } label: {
                    Label("设置", systemImage: "gear")
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("NovaLife")
        .frame(minWidth: 200)
    }

    // MARK: - Helper Methods

    /// 获取徽章数量
    private func getBadgeCount(for section: NavigationSection) -> Int? {
        guard let context = appState.context else { return nil }

        switch section {
        case .goals:
            let count = context.activeGoals.count
            return count > 0 ? count : nil

        case .habits:
            let count = context.activeHabits.count
            return count > 0 ? count : nil

        case .finance:
            // 显示预算警告数量
            let alerts = context.budgetAlerts.count
            return alerts > 0 ? alerts : nil

        case .emotions:
            return nil

        case .calendar:
            // 显示今日事件数量
            let count = context.todaySchedule.count
            return count > 0 ? count : nil

        case .insights:
            // 显示紧急洞察数量
            let count = context.urgentInsights.count
            return count > 0 ? count : nil
        }
    }

    /// 打开设置窗口
    private func openSettings() {
        // 使用 SwiftUI 的 Settings 场景
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}

// MARK: - Preview

#Preview {
    SidebarView()
        .environmentObject(AppState.shared)
        .environmentObject(NavigationStateManager.shared)
        .frame(width: 200, height: 400)
}
