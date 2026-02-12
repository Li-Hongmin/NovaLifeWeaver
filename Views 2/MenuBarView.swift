import SwiftUI

/// Menu Bar 主界面 - 应用主入口
struct MenuBarView: View {
    @StateObject private var viewModel = MenuBarViewModel()
    @State private var isLoading = false
    @State private var showingSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // 头部 - 用户状态摘要
            HeaderView(context: viewModel.userContext)
                .padding(.horizontal, 16)
                .padding(.top, 12)

            Divider()
                .padding(.vertical, 8)

            // 主内容区域
            ScrollView {
                VStack(spacing: 12) {
                    // 紧急洞察卡片
                    if !viewModel.urgentInsights.isEmpty {
                        ForEach(viewModel.urgentInsights) { insight in
                            InsightCardView(insight: insight)
                                .onTapGesture {
                                    viewModel.handleInsightTap(insight)
                                }
                        }
                    }

                    // 对话输入区域
                    ConversationView(
                        onSubmit: { input in
                            await viewModel.handleUserInput(input)
                        }
                    )

                    // 上下文展示区域
                    if let context = viewModel.userContext {
                        ContextDisplayView(context: context)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }

            Divider()

            // 底部操作栏
            HStack {
                Button(action: { showingSettings.toggle() }) {
                    Image(systemName: "gear")
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: { viewModel.refreshContext() }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(width: 400, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            Task {
                await viewModel.loadInitialContext()
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

// MARK: - Header View

/// 头部视图 - 显示用户状态摘要
struct HeaderView: View {
    let context: UserContext?

    var body: some View {
        HStack(spacing: 12) {
            // 用户头像/图标
            Image(systemName: "brain")
                .font(.system(size: 24))
                .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(context?.user.name ?? "NovaLife Weaver")
                    .font(.headline)

                if let context = context {
                    Text(context.generateBriefSummary())
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // 状态指示器
            if let context = context {
                StatusIndicator(context: context)
            }
        }
    }
}

// MARK: - Status Indicator

/// 状态指示器 - 显示关键状态
struct StatusIndicator: View {
    let context: UserContext

    var body: some View {
        HStack(spacing: 8) {
            // 情绪状态
            emotionIndicator

            // 紧急事项提示
            if context.hasUrgentMatters {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
            }

            // 待办数量
            if context.todayTodoCount > 0 {
                Text("\(context.todayTodoCount)")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.2))
                    .cornerRadius(8)
            }
        }
    }

    private var emotionIndicator: some View {
        Group {
            if context.averageEmotion > 0.3 {
                Image(systemName: "face.smiling")
                    .foregroundColor(.green)
            } else if context.averageEmotion < -0.3 {
                Image(systemName: "face.frowning")
                    .foregroundColor(.orange)
            } else {
                Image(systemName: "face.neutral")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Insight Card View

/// 洞察卡片 - 显示单个洞察
struct InsightCardView: View {
    let insight: Insight

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                insightIcon

                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(insight.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                // 优先级指示器
                if insight.priority >= 4 {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(insight.priority == 5 ? .red : .orange)
                }
            }

            // 建议的行动
            if let actions = insight.suggestedActions, !actions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(actions.prefix(2)) { action in
                        Text("• \(action.action)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(12)
        .background(insightBackgroundColor)
        .cornerRadius(8)
    }

    private var insightIcon: some View {
        Group {
            switch insight.type {
            case .warning:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
            case .pattern:
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
            case .recommendation:
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
            case .achievement:
                Image(systemName: "trophy.fill")
                    .foregroundColor(.green)
            case .opportunity:
                Image(systemName: "star.fill")
                    .foregroundColor(.purple)
            }
        }
        .font(.title3)
    }

    private var insightBackgroundColor: Color {
        switch insight.type {
        case .warning:
            return Color.orange.opacity(0.1)
        case .achievement:
            return Color.green.opacity(0.1)
        default:
            return Color.accentColor.opacity(0.05)
        }
    }
}

// MARK: - Preview

#Preview {
    MenuBarView()
}
