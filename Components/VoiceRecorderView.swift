import SwiftUI
import AVFoundation
import Combine

/// 语音录制组件
struct VoiceRecorderView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var recorder = AudioRecorder()

    let onComplete: (Data) -> Void
    let onCancel: (() -> Void)?

    init(onComplete: @escaping (Data) -> Void, onCancel: (() -> Void)? = nil) {
        self.onComplete = onComplete
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: 24) {
            // 标题
            Text(recorder.isRecording ? "录音中..." : "按下开始录音")
                .font(.headline)
                .foregroundColor(recorder.isRecording ? .red : .primary)

            // 录音图标
            ZStack {
                Circle()
                    .stroke(recorder.isRecording ? Color.red : Color.gray, lineWidth: 3)
                    .frame(width: 100, height: 100)
                    .scaleEffect(recorder.isRecording ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: recorder.isRecording)

                Image(systemName: recorder.isRecording ? "waveform" : "mic.fill")
                    .font(.system(size: 40))
                    .foregroundColor(recorder.isRecording ? .red : .blue)
            }

            // 录音时长
            Text(formatDuration(recorder.recordingDuration))
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .foregroundColor(.secondary)

            // 错误提示
            if let error = recorder.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            // 控制按钮
            HStack(spacing: 32) {
                // 取消
                Button {
                    onCancel?()
                    dismiss()
                } label: {
                    Label("取消", systemImage: "xmark.circle.fill")
                        .font(.title2)
                }

                // 录音/停止
                Button {
                    toggleRecording()
                } label: {
                    Image(systemName: recorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(recorder.isRecording ? .red : .blue)
                }
                .buttonStyle(.plain)

                // 完成
                Button {
                    handleComplete()
                } label: {
                    Label("完成", systemImage: "checkmark.circle.fill")
                        .font(.title2)
                }
                .disabled(!recorder.hasRecording)
            }
        }
        .padding(32)
        .frame(width: 400, height: 350)
        .onAppear {
            recorder.requestPermission()
        }
    }

    private func toggleRecording() {
        if recorder.isRecording {
            recorder.stopRecording()
        } else {
            recorder.startRecording()
        }
    }

    private func handleComplete() {
        if let audioData = recorder.audioData {
            onComplete(audioData)
            dismiss()
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - Audio Recorder

class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var hasRecording = false
    @Published var error: String?

    var audioData: Data?
    private var audioRecorder: AVAudioRecorder?
    private var durationTimer: Timer?

    private var recordingURL: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("recording_\(UUID().uuidString).m4a")
    }

    func requestPermission() {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            DispatchQueue.main.async {
                if !granted {
                    self?.error = "需要麦克风权限才能录音"
                }
            }
        }
    }

    func startRecording() {
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.record()
            isRecording = true
            error = nil
            recordingDuration = 0

            durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.recordingDuration += 0.1
                if (self?.recordingDuration ?? 0) >= 60 {
                    self?.stopRecording()
                }
            }
        } catch {
            self.error = "录音失败：\(error.localizedDescription)"
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        durationTimer?.invalidate()

        do {
            audioData = try Data(contentsOf: recordingURL)
            hasRecording = true
        } catch {
            self.error = "读取录音失败"
        }
    }
}

// MARK: - Preview
// Removed due to init ambiguity
