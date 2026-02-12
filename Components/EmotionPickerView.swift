import SwiftUI

/// 情绪选择器 - 可复用组件
struct EmotionPickerView: View {
    @Binding var selectedMood: Mood?
    var showLabel: Bool = true
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 12) {
            if showLabel {
                Text("当前心情")
                    .font(compact ? .subheadline : .headline)
                    .foregroundColor(.primary)
            }

            HStack(spacing: compact ? 12 : 20) {
                ForEach(Mood.allCases, id: \.self) { mood in
                    Button {
                        selectedMood = mood
                    } label: {
                        VStack(spacing: compact ? 4 : 8) {
                            Text(mood.emoji)
                                .font(.system(size: compact ? 32 : 40))

                            if !compact {
                                Text(mood.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(width: compact ? 60 : 80, height: compact ? 60 : 80)
                        .background(
                            selectedMood == mood
                                ? mood.color.opacity(0.3)
                                : Color.clear
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    selectedMood == mood
                                        ? mood.color
                                        : Color.gray.opacity(0.3),
                                    lineWidth: selectedMood == mood ? 2 : 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(mood.displayName)心情")
                    .accessibilityAddTraits(selectedMood == mood ? [.isSelected] : [])
                }
            }
        }
    }
}

// MARK: - Mood Model

/// 情绪/心情枚举
enum Mood: String, Codable, CaseIterable {
    case veryHappy  = "very_happy"
    case happy      = "happy"
    case neutral    = "neutral"
    case sad        = "sad"
    case verySad    = "very_sad"

    /// Emoji 表情
    var emoji: String {
        switch self {
        case .veryHappy: return "😄"
        case .happy:     return "😊"
        case .neutral:   return "😐"
        case .sad:       return "😔"
        case .verySad:   return "😢"
        }
    }

    /// 显示名称
    var displayName: String {
        switch self {
        case .veryHappy: return "很开心"
        case .happy:     return "开心"
        case .neutral:   return "一般"
        case .sad:       return "难过"
        case .verySad:   return "很难过"
        }
    }

    /// 主题颜色
    var color: Color {
        switch self {
        case .veryHappy: return .green
        case .happy:     return .mint
        case .neutral:   return .gray
        case .sad:       return .orange
        case .verySad:   return .red
        }
    }

    /// 数值分数（用于计算）
    var score: Double {
        switch self {
        case .veryHappy: return 1.0
        case .happy:     return 0.5
        case .neutral:   return 0.0
        case .sad:       return -0.5
        case .verySad:   return -1.0
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        EmotionPickerView(selectedMood: .constant(.happy))

        EmotionPickerView(selectedMood: .constant(nil), showLabel: false)

        EmotionPickerView(selectedMood: .constant(.neutral), compact: true)
    }
    .padding()
}
