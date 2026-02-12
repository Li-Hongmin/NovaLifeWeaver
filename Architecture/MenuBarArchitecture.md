# Menu Bar 应用架构设计

## 组件拆分（并行开发）

### Agent 1: Menu Bar 基础架构
**文件**: `App/MenuBarManager.swift`
**职责**:
- NSStatusBar 管理
- NSPopover 创建和显示
- 图标状态更新
- 快捷键支持

**接口**: `MenuBarManagerProtocol`

**关键实现**:
```swift
class MenuBarManager: MenuBarManagerProtocol {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.image = NSImage(systemSymbolName: "brain.head.profile", accessibilityDescription: "NovaLife")
    }

    func togglePopover() {
        // 显示/隐藏 popover
    }
}
```

---

### Agent 2: MenuBarView 完善
**文件**: `Views/MenuBarView.swift`（已存在，需完善）
**职责**:
- 集成真实数据（ContextEngine）
- 替换模拟数据为数据库查询
- 实现用户交互逻辑

**依赖**:
- MenuBarViewModel
- ContextEngine
- DatabaseService

**改进点**:
- 连接真实用户数据
- 实现下拉刷新
- 添加加载动画

---

### Agent 3: Intent Router + 对话处理
**文件**: `Services/IntentRouter.swift`
**职责**:
- 分析用户输入意图
- 使用 Nova AI 理解自然语言
- 路由到对应的 Agent

**接口**: `IntentRouterProtocol`

**处理流程**:
```
用户输入 → IntentRouter.analyze()
    ↓
识别意图类型（goal/habit/emotion/expense/query）
    ↓
调用对应的 Agent (PlannerAgent/MemoryAgent)
    ↓
返回结果 + 建议行动
```

---

### Agent 4: ContextEngine 数据加载实现
**文件**: `Engines/ContextEngine.swift`（已存在，需完善）
**职责**:
- 实现所有 TODO 的数据加载方法
- 连接 DatabaseService
- 确保 <100ms 加载性能

**需要实现的方法**:
```swift
private func loadUser(_ userId: String) async throws -> User
private func loadGoalData(_ userId: String) async throws -> GoalData
private func loadHabitData(_ userId: String) async throws -> HabitData
private func loadFinancialData(_ userId: String) async throws -> FinancialData
private func loadEmotionData(_ userId: String) async throws -> EmotionData
private func loadEventData(_ userId: String) async throws -> EventData
private func loadInsightData(_ userId: String) async throws -> InsightData
private func loadCorrelations(_ userId: String) async throws -> [Correlation]
```

---

### Agent 5: AppState 全局状态管理
**文件**: `App/AppState.swift`
**职责**:
- 全局状态管理（ObservableObject）
- 用户会话管理
- 上下文缓存
- 错误处理

**接口**: `AppStateProtocol`

**状态包含**:
```swift
@Published var currentUser: User?
@Published var context: UserContext?
@Published var isLoading: Bool
@Published var errorMessage: String?
@Published var insights: [Insight]
```

---

## 数据流设计

```
User Input (MenuBarView)
    ↓
IntentRouter.analyze()
    ↓
PlannerAgent / MemoryAgent
    ↓
DatabaseService (CRUD)
    ↓
ContextEngine.invalidateCache()
    ↓
AppState.refreshContext()
    ↓
@Published → SwiftUI Auto-Refresh
    ↓
UI Update
```

---

## 并行开发依赖关系

```
Agent 1 (MenuBar) - 无依赖，独立开发 ✅
Agent 2 (MenuBarView) - 依赖 Agent 5 (AppState)
Agent 3 (IntentRouter) - 无依赖，独立开发 ✅
Agent 4 (ContextEngine) - 无依赖，独立开发 ✅
Agent 5 (AppState) - 无依赖，独立开发 ✅
```

**可并行**: 所有 5 个 Agent 可以同时开发！

---

## 接口契约

### MenuBarManager ↔ MenuBarView
```swift
// MenuBarManager 创建 Popover，内容为 MenuBarView
popover.contentViewController = NSHostingController(rootView: MenuBarView())
```

### MenuBarView ↔ AppState
```swift
// MenuBarView 通过 @EnvironmentObject 访问 AppState
@EnvironmentObject var appState: AppState
```

### IntentRouter ↔ Agents
```swift
// IntentRouter 调用各个 Agent
switch intent {
case .createGoal(let goal):
    return try await PlannerAgent.shared.plan(goal: goal, userId: userId)
case .recordEmotion(let text):
    return try await MemoryAgent.shared.processText(text, userId: userId)
}
```

### ContextEngine ↔ DatabaseService
```swift
// ContextEngine 使用 DatabaseService 查询数据
let user = try await db.fetchUser(userId)
let goals = try await db.fetchActiveGoals(userId: userId)
```

---

## 开发顺序建议

1. **Agent 5 (AppState)** - 先实现全局状态，其他组件依赖它
2. **Agent 1 (MenuBar)** - 同时进行，建立应用框架
3. **Agent 4 (ContextEngine)** - 同时进行，实现数据加载
4. **Agent 3 (IntentRouter)** - 实现意图识别
5. **Agent 2 (MenuBarView)** - 最后集成所有组件

---

**准备好了吗？开始并行开发！** 🚀
