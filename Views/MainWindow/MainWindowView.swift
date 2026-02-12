import SwiftUI

/// 主窗口视图 - 应用主界面（侧边栏 + 内容区域 + 固定对话栏）
struct MainWindowView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var navigationState: NavigationStateManager
    @StateObject private var conversationViewModel = MenuBarViewModel()

    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        VStack(spacing: 0) {
            // 主内容区域（侧边栏 + 详情）
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

            Divider()

            // 底部固定对话栏
            FixedConversationBar(viewModel: conversationViewModel)
        }
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

// MARK: - Fixed Conversation Bar

/// 固定对话栏 - 在主窗口底部始终可见
struct FixedConversationBar: View {
    @ObservedObject var viewModel: MenuBarViewModel
    @State private var userInput: String = ""
    @State private var isProcessing: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // AI 响应显示（如果有）
            if let response = viewModel.lastResponse {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "brain")
                        .font(.title3)
                        .foregroundColor(.accentColor)

                    Text(response)
                        .font(.callout)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        viewModel.lastResponse = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }

            // 对话输入区域
            HStack(spacing: 12) {
                // AI 图标
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.accentColor)

                // 输入框
                TextField("与 NovaLife AI 对话... (例如：我想在3月考过 JLPT N2)", text: $userInput)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .disabled(isProcessing)
                    .onSubmit {
                        handleSubmit()
                    }

                // 语音按钮（暂时禁用）
                Button {
                    // TODO: 打开语音录制
                } label: {
                    Image(systemName: "mic.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(true)
                .help("语音输入（即将推出）")

                // 图片按钮（暂时禁用）
                Button {
                    // TODO: 打开图片选择
                } label: {
                    Image(systemName: "photo.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(true)
                .help("图片输入（即将推出）")

                // 发送按钮
                Button {
                    handleSubmit()
                } label: {
                    Image(systemName: isProcessing ? "arrow.circlepath" : "paperplane.circle.fill")
                        .font(.title2)
                        .foregroundColor(userInput.isEmpty ? .secondary : .accentColor)
                }
                .buttonStyle(.plain)
                .disabled(userInput.isEmpty || isProcessing)
                .help("发送")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(height: 60)
    }

    private func handleSubmit() {
        guard !userInput.isEmpty else { return }

        let input = userInput
        userInput = ""
        isProcessing = true

        Task {
            await viewModel.handleUserInput(input)
            isProcessing = false
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
