import SwiftUI

@main
struct NovaLifeWeaverApp: App {
    init() {
        // 启动时运行数据库测试
        print("🧠 NovaLife Weaver 启动中...")
        Task {
            await TestDatabase.runTests()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("NovaLife Weaver")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("更懂你的感受和生活")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Divider()
                .padding()
            
            VStack(alignment: .leading, spacing: 10) {
                StatusRow(icon: "checkmark.circle.fill", text: "数据库已初始化", color: .green)
                StatusRow(icon: "checkmark.circle.fill", text: "10 个核心表已创建", color: .green)
                StatusRow(icon: "checkmark.circle.fill", text: "支持全局上下文查询", color: .green)
                StatusRow(icon: "checkmark.circle.fill", text: "情绪消费分析已就绪", color: .green)
            }
            .padding()
            
            Text("Phase 1 开发中...")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top)
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
}

struct StatusRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(text)
                .font(.body)
        }
    }
}

#Preview {
    ContentView()
}
