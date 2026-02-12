import SwiftUI

/// 主窗口视图 - 对话驱动的界面
struct MainWindowView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        // 对话界面占据整个窗口
        ChatView()
            .environmentObject(appState)
            .frame(minWidth: 800, minHeight: 600)
            .task {
                // 窗口打开时加载用户状态
                if appState.currentUser == nil {
                    await appState.loadUserState()
                }
            }
    }
}

// MARK: - Preview

#Preview {
    MainWindowView()
        .environmentObject(AppState.shared)
        .frame(width: 1000, height: 700)
}
