import SwiftUI
import Charts

/// 关联分析图表视图
struct CorrelationChartView: View {
    let correlation: Correlation

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundColor(.accentColor)

                Text(correlation.description ?? "\(correlation.dimensionA) ↔ \(correlation.dimensionB)")
                    .font(.headline)
            }

            // 统计信息卡片
            HStack(spacing: 20) {
                StatBox(
                    label: "相关系数",
                    value: String(format: "%.2f", correlation.correlationCoefficient ?? 0),
                    color: correlationColor(correlation.correlationCoefficient ?? 0)
                )

                StatBox(
                    label: "显著性",
                    value: significance(correlation.significance),
                    color: significanceColor(correlation.significance)
                )

                StatBox(
                    label: "发现时间",
                    value: formatDate(correlation.discoveredAt),
                    color: .blue
                )
            }

            // 说明
            if let coefficient = correlation.correlationCoefficient {
                Text(interpretCorrelation(coefficient))
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    // MARK: - Helpers

    private func correlationColor(_ r: Double) -> Color {
        let abs_r = abs(r)
        if abs_r >= 0.7 { return .green }
        if abs_r >= 0.4 { return .orange }
        return .gray
    }

    private func significance(_ p: Double?) -> String {
        guard let p = p else { return "N/A" }
        if p < 0.01 { return "***" }
        if p < 0.05 { return "**" }
        if p < 0.10 { return "*" }
        return "n.s."
    }

    private func significanceColor(_ p: Double?) -> Color {
        guard let p = p else { return .gray }
        if p < 0.05 { return .green }
        return .gray
    }

    private func interpretCorrelation(_ r: Double) -> String {
        let abs_r = abs(r)
        let strength = abs_r >= 0.7 ? "强" : (abs_r >= 0.4 ? "中等" : "弱")
        let direction = r > 0 ? "正相关" : "负相关"

        return "\(strength)\(direction)：\(correlation.dimensionA) 和 \(correlation.dimensionB) 之间存在关联"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

// MARK: - Stat Box

struct StatBox: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}
