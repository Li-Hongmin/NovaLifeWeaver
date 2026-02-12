import SwiftUI

/// 设置视图 - 应用配置
struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var userName = "李鴻敏"
    @State private var language = "zh-CN"
    @State private var timezone = "Asia/Tokyo"
    @State private var enableNotifications = true
    @State private var enableNotionSync = false

    var body: some View {
        VStack(spacing: 0) {
            // 头部
            HStack {
                Text("设置")
                    .font(.headline)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // 设置内容
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 个人信息
                    SettingSection(title: "个人信息") {
                        TextField("姓名", text: $userName)
                            .textFieldStyle(.roundedBorder)

                        Picker("语言", selection: $language) {
                            Text("简体中文").tag("zh-CN")
                            Text("日本语").tag("ja")
                            Text("English").tag("en")
                        }

                        Picker("时区", selection: $timezone) {
                            Text("东京 (Asia/Tokyo)").tag("Asia/Tokyo")
                            Text("北京 (Asia/Shanghai)").tag("Asia/Shanghai")
                            Text("纽约 (America/New_York)").tag("America/New_York")
                        }
                    }

                    // 通知设置
                    SettingSection(title: "通知") {
                        Toggle("启用通知", isOn: $enableNotifications)
                    }

                    // 同步设置
                    SettingSection(title: "数据同步") {
                        Toggle("Notion 同步", isOn: $enableNotionSync)

                        if enableNotionSync {
                            Button("配置 Notion") {
                                // TODO: 打开 Notion 配置
                            }
                            .buttonStyle(.borderless)
                        }
                    }

                    // 关于
                    SettingSection(title: "关于") {
                        HStack {
                            Text("版本")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.secondary)
                        }

                        Link("GitHub 仓库", destination: URL(string: "https://github.com")!)
                            .foregroundColor(.accentColor)

                        Link("提交反馈", destination: URL(string: "https://github.com")!)
                            .foregroundColor(.accentColor)
                    }

                    // 危险操作
                    SettingSection(title: "数据管理") {
                        Button("导出数据", role: .none) {
                            // TODO: 导出数据
                        }

                        Button("重置所有数据", role: .destructive) {
                            // TODO: 重置数据
                        }
                    }
                }
                .padding()
            }

            Divider()

            // 底部按钮
            HStack {
                Spacer()

                Button("保存") {
                    // TODO: 保存设置
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 500, height: 600)
    }
}

// MARK: - Setting Section

struct SettingSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
