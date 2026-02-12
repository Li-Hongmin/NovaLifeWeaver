import SwiftUI

/// 情绪记录视图 - 快速记录情绪
struct EmotionRecorderView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: EmotionViewModel

    @State private var selectedMood: Mood?
    @State private var note: String = ""
    @State private var triggers: String = ""

    let userId: String

    var body: some View {
        VStack(spacing: 0) {
            // 标题
            HStack {
                Text("记录情绪")
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // 表单
            Form {
                Section("当前心情") {
                    EmotionPickerView(selectedMood: $selectedMood, showLabel: false)
                }

                Section("触发因素（可选）") {
                    TextField("例如：工作压力", text: $triggers)
                }

                Section("备注（可选）") {
                    TextEditor(text: $note)
                        .frame(height: 100)
                }
            }
            .formStyle(.grouped)

            Divider()

            // 按钮
            HStack {
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button("保存") {
                    Task { await handleSubmit() }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedMood == nil)
            }
            .padding()
        }
        .frame(width: 450, height: 500)
    }

    private func handleSubmit() async {
        guard let mood = selectedMood else { return }

        let record = EmotionRecord(
            id: UUID().uuidString,
            userId: userId,
            score: mood.score,
            intensity: 0.7,
            emotions: [mood.rawValue],
            trigger: triggers.isEmpty ? nil : triggers,
            triggerDescription: nil,
            activity: nil,
            location: nil,
            weather: nil,
            voiceRecordingPath: nil,
            transcription: nil,
            photoPath: nil,
            note: note.isEmpty ? nil : note,
            sentimentAnalysis: nil,
            recommendedActions: nil,
            recordedAt: Date(),
            createdAt: Date()
        )

        await viewModel.addEmotion(record)
        dismiss()
    }
}
