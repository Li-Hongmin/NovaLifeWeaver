import SwiftUI

/// 对话输入视图 - 统一的用户输入入口
struct ConversationView: View {
    @State private var userInput: String = ""
    @State private var isProcessing: Bool = false
    @State private var showingVoiceRecorder: Bool = false
    @State private var showingImagePicker: Bool = false

    let onSubmit: (String) async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            Text("和 Nova 对话")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            // 输入框
            HStack(spacing: 8) {
                // 文本输入
                TextField("说说你的想法...", text: $userInput, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(3)
                    .padding(8)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .disabled(isProcessing)
                    .onSubmit {
                        Task {
                            await handleSubmit()
                        }
                    }

                // 发送按钮
                Button(action: {
                    Task {
                        await handleSubmit()
                    }
                }) {
                    Image(systemName: isProcessing ? "hourglass" : "paperplane.fill")
                        .foregroundColor(userInput.isEmpty ? .secondary : .accentColor)
                }
                .buttonStyle(.plain)
                .disabled(userInput.isEmpty || isProcessing)
            }

            // 多模态输入按钮
            HStack(spacing: 16) {
                // 语音输入
                Button(action: { showingVoiceRecorder.toggle() }) {
                    Label("语音", systemImage: "mic.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)

                // 图片输入
                Button(action: { showingImagePicker.toggle() }) {
                    Label("图片", systemImage: "photo.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                // 快捷示例
                Menu {
                    Button("我想学日语 N2") {
                        userInput = "我想学日语 N2"
                    }
                    Button("今天感觉有点累") {
                        userInput = "今天感觉有点累"
                    }
                    Button("最近花钱有点多") {
                        userInput = "最近花钱有点多"
                    }
                    Button("下周健身 3 次") {
                        userInput = "下周健身 3 次"
                    }
                } label: {
                    Label("示例", systemImage: "text.bubble")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color.accentColor.opacity(0.05))
        .cornerRadius(10)
        .sheet(isPresented: $showingVoiceRecorder) {
            VoiceRecorderView(onComplete: { audioData in
                // TODO: 处理语音数据
                showingVoiceRecorder = false
            })
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerView(onComplete: { imageData in
                // TODO: 处理图片数据
                showingImagePicker = false
            })
        }
    }

    // MARK: - Actions

    private func handleSubmit() async {
        guard !userInput.isEmpty, !isProcessing else { return }

        let input = userInput
        userInput = ""
        isProcessing = true

        await onSubmit(input)

        isProcessing = false
    }
}

// MARK: - Multimodal Components
// VoiceRecorderView and ImagePickerView are now in Components/ folder

// MARK: - Preview

#Preview {
    ConversationView(onSubmit: { input in
        print("User input: \(input)")
    })
    .padding()
}
