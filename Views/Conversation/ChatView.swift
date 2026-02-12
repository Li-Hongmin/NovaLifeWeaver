import SwiftUI

/// 主对话界面 - 整个应用的核心
struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            ChatToolbar(viewModel: viewModel)

            Divider()

            // 消息流（主要区域）
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.currentConversation.messages) { message in
                            MessageBubbleView(message: message, viewModel: viewModel)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.currentConversation.messages.count) { _ in
                    // 自动滚动到最新消息
                    if let lastMessage = viewModel.currentConversation.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // 输入区域
            ChatInputBar(viewModel: viewModel)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await viewModel.initialize(userId: appState.currentUser?.id ?? "default-user")
        }
    }
}

// MARK: - Chat Toolbar

/// 顶部工具栏
struct ChatToolbar: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        HStack(spacing: 16) {
            // New 对话按钮
            Button {
                viewModel.startNewConversation()
            } label: {
                Label("New", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.bordered)

            // 历史对话菜单
            Menu {
                ForEach(viewModel.conversationHistory) { conversation in
                    Button {
                        viewModel.switchToConversation(conversation.id)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(conversation.title)
                            Text(conversation.createdAt, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if viewModel.conversationHistory.isEmpty {
                    Text("暂无历史对话")
                        .foregroundColor(.secondary)
                }
            } label: {
                Label("历史", systemImage: "clock.arrow.circlepath")
            }
            .buttonStyle(.bordered)

            Spacer()

            // 对话标题
            Text(viewModel.currentConversation.title)
                .font(.headline)
                .foregroundColor(.secondary)

            Spacer()

            // 设置按钮
            Button {
                openSettings()
            } label: {
                Image(systemName: "gear")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}

// MARK: - Message Bubble

/// 消息气泡
struct MessageBubbleView: View {
    let message: Message
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.role == .user {
                Spacer()
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                // 消息气泡
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(bubbleColor)
                    .foregroundColor(textColor)
                    .cornerRadius(16)
                    .frame(maxWidth: 600, alignment: alignment)

                // 工具卡片（如果有）
                if let toolCards = message.toolCards {
                    ForEach(toolCards) { card in
                        ToolCardView(card: card, viewModel: viewModel)
                    }
                }

                // 时间戳
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if message.role == .assistant {
                Spacer()
            }
        }
    }

    private var bubbleColor: Color {
        message.role == .user ? Color.accentColor : Color(NSColor.controlBackgroundColor)
    }

    private var textColor: Color {
        message.role == .user ? .white : .primary
    }

    private var alignment: Alignment {
        message.role == .user ? .trailing : .leading
    }
}

// MARK: - Tool Card View

/// 工具卡片视图 - 在对话中展示的可交互工具
struct ToolCardView: View {
    let card: ToolCard
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 卡片头部
            HStack {
                Image(systemName: card.type.icon)
                    .foregroundColor(.accentColor)

                Text(card.type.displayName)
                    .font(.headline)

                Spacer()

                statusBadge
            }

            // 卡片内容
            VStack(alignment: .leading, spacing: 8) {
                ForEach(card.data.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    HStack {
                        Text(key + ":")
                            .foregroundColor(.secondary)
                        Text(value)
                    }
                    .font(.callout)
                }
            }

            // 操作按钮（如果是 pending 状态）
            if card.status == .pending {
                HStack(spacing: 12) {
                    Button {
                        viewModel.confirmTool(cardId: card.id)
                    } label: {
                        Label("确认", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        viewModel.editTool(cardId: card.id)
                    } label: {
                        Label("编辑", systemImage: "pencil.circle.fill")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        viewModel.cancelTool(cardId: card.id)
                    } label: {
                        Label("取消", systemImage: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
        )
        .frame(maxWidth: 500)
    }

    private var statusBadge: some View {
        Group {
            switch card.status {
            case .pending:
                Text("待确认")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(8)

            case .confirmed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)

            case .cancelled:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)

            case .editing:
                Text("编辑中")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - Chat Input Bar

/// 输入栏
struct ChatInputBar: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            // 输入框
            TextField("输入消息... (例如：我想在3月考过JLPT N2)", text: $inputText)
                .textFieldStyle(.plain)
                .font(.body)
                .focused($isInputFocused)
                .disabled(viewModel.isProcessing)
                .onSubmit {
                    sendMessage()
                }

            // 多模态按钮
            HStack(spacing: 8) {
                Button {
                    // TODO: 打开语音录制
                } label: {
                    Image(systemName: "mic.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .disabled(true)
                .help("语音输入（即将推出）")

                Button {
                    // TODO: 打开图片选择
                } label: {
                    Image(systemName: "photo.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .disabled(true)
                .help("图片输入（即将推出）")
            }

            // 发送按钮
            Button {
                sendMessage()
            } label: {
                Image(systemName: viewModel.isProcessing ? "arrow.circlepath" : "paperplane.circle.fill")
                    .font(.title2)
                    .foregroundColor(inputText.isEmpty ? .secondary : .accentColor)
            }
            .buttonStyle(.plain)
            .disabled(inputText.isEmpty || viewModel.isProcessing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            isInputFocused = true
        }
    }

    private func sendMessage() {
        guard !inputText.isEmpty else { return }

        let message = inputText
        inputText = ""

        Task {
            await viewModel.sendMessage(message)
        }
    }
}
