import SwiftUI

/// 主窗口视图 - 应用主界面（侧边栏 + 内容区域）
struct MainWindowView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var navigationState: NavigationStateManager

    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // 侧边栏
            SidebarView()
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        Button(action: toggleSidebar) {
                            Image(systemName: "sidebar.left")
                        }
                        .help("切换侧边栏")
                    }
                }

        } detail: {
            // 主内容区域
            DetailContainerView()
                .toolbar {
                    ToolbarItemGroup(placement: .navigation) {
                        // 面包屑导航
                        Text(navigationState.selectedSection.displayName)
                            .font(.headline)
                    }

                    ToolbarItemGroup(placement: .automatic) {
                        // 右侧操作按钮
                        refreshButton
                        contextStatusView
                    }
                }
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 900, minHeight: 600)
        .task {
            // 窗口打开时加载用户状态（如果未加载）
            if appState.currentUser == nil {
                await appState.loadUserState()
            }
        }
        .alert(isPresented: appState.errorBinding) {
            Alert(
                title: Text("错误"),
                message: Text(appState.errorDisplayText),
                primaryButton: .default(Text("重试")) {
                    Task {
                        await appState.refreshContext()
                    }
                },
                secondaryButton: .cancel(Text("关闭"))
            )
        }
    }

    // MARK: - Toolbar Components

    /// 刷新按钮
    private var refreshButton: some View {
        Button {
            Task {
                await appState.refreshContext()
            }
        } label: {
            Image(systemName: "arrow.clockwise")
        }
        .help("刷新数据")
        .disabled(appState.isLoading)
    }

    /// 上下文状态指示器
    private var contextStatusView: some View {
        HStack(spacing: 8) {
            if appState.isLoading {
                ProgressView()
                    .scaleEffect(0.6)
                Text("加载中...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if let context = appState.context {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text(context.generateBriefSummary())
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("未加载")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Actions

    /// 切换侧边栏显示/隐藏
    private func toggleSidebar() {
        withAnimation {
            if columnVisibility == .all {
                columnVisibility = .detailOnly
            } else {
                columnVisibility = .all
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MainWindowView()
        .environmentObject(AppState.shared)
        .environmentObject(NavigationStateManager.shared)
        .frame(width: 1200, height: 800)
}
