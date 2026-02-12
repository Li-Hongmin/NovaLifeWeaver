# AppState - 全局状态管理

## 概述

AppState 是 NovaLifeWeaver 的全局状态管理器，负责管理用户状态、上下文、洞察和错误处理。它是应用的核心状态容器，所有 SwiftUI 视图都应通过 AppState 访问应用数据。

## 架构设计

### 核心职责

1. **用户状态管理** - 管理当前用户信息和认证状态
2. **上下文加载** - 通过 ContextEngine 加载完整用户上下文
3. **状态同步** - 自动刷新上下文（每 5 分钟）
4. **错误处理** - 统一的错误处理和展示机制
5. **状态观察** - 支持 SwiftUI 的响应式更新

### 技术特性

- **Singleton 模式** - 全局单例访问
- **ObservableObject** - 支持 SwiftUI 响应式更新
- **@MainActor** - 确保线程安全的 UI 更新
- **缓存失效** - 数据更新后自动失效缓存
- **性能监控** - 加载时间跟踪和优化

## 核心 API

### 初始化和加载

```swift
// 应用启动时加载用户状态
await AppState.shared.loadUserState()

// 手动刷新上下文
await AppState.shared.refreshContext()

// 使缓存失效并刷新
await AppState.shared.invalidateCacheAndRefresh()
```

### 状态访问

```swift
let appState = AppState.shared

// Published 状态变量
appState.currentUser      // 当前用户
appState.context          // 用户上下文
appState.insights         // 洞察列表
appState.isLoading        // 加载状态
appState.errorMessage     // 错误消息
appState.appStatus        // 应用状态

// 便捷访问方法
appState.activeGoals      // 活跃目标
appState.activeHabits     // 活跃习惯
appState.todaySchedule    // 今日待办
appState.urgentInsights   // 紧急洞察
appState.budgetAlerts     // 预算预警
appState.hasUrgentMatters // 是否有紧急事项
appState.isStressed       // 是否压力状态
appState.briefSummary     // 简短摘要
```

### 错误处理

```swift
// 统一错误处理
appState.handleError(error, context: "操作描述")

// 清除错误
appState.clearError()

// SwiftUI 绑定
.alert(isPresented: appState.errorBinding) {
    Alert(title: Text("错误"), message: Text(appState.errorDisplayText))
}
```

## SwiftUI 集成

### 方式 1: EnvironmentObject

```swift
// App 入口注入
@main
struct NovaLifeWeaverApp: App {
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

// 视图中使用
struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if let user = appState.currentUser {
            Text("欢迎，\(user.name)")
        }
    }
}
```

### 方式 2: ObservedObject

```swift
struct ContentView: View {
    @ObservedObject var appState = AppState.shared

    var body: some View {
        if appState.isLoading {
            ProgressView()
        } else {
            MainContentView()
        }
    }
}
```

### 方式 3: StateObject (推荐用于生命周期管理)

```swift
struct RootView: View {
    @StateObject private var appState = AppState.shared

    var body: some View {
        ContentView()
            .environmentObject(appState)
            .task {
                await appState.loadUserState()
            }
    }
}
```

## 状态流转

### 应用启动流程

```
App Launch
    ↓
AppState.loadUserState()
    ↓
1. 获取/创建默认用户
    ↓
2. 加载用户信息 (currentUser)
    ↓
3. 刷新上下文 (context)
    ↓
4. 启动自动刷新定时器
    ↓
Ready for Use
```

### 上下文刷新流程

```
refreshContext()
    ↓
1. 验证用户 ID
    ↓
2. ContextEngine.loadContext()
    ↓
3. 更新 insights
    ↓
4. 更新 appStatus
    ↓
5. 触发 SwiftUI 更新
```

### 错误处理流程

```
Error Occurs
    ↓
handleError(error, context)
    ↓
1. 设置 errorMessage
    ↓
2. 更新 appStatus = .offline
    ↓
3. 记录错误日志
    ↓
4. 触发 UI 展示
    ↓
User Action: clearError()
```

## 性能优化

### 缓存策略

- **ContextEngine 缓存**: 5 分钟有效期
- **自动失效**: 数据更新后调用 `invalidateCache()`
- **手动刷新**: 用户可触发强制刷新

### 加载性能

- **目标**: <100ms 加载完整上下文
- **并行加载**: ContextEngine 使用 async/await 并行查询
- **性能监控**: 内置加载时间跟踪

### 内存管理

- **Singleton 生命周期**: 与应用生命周期一致
- **定时器管理**: deinit 时自动清理
- **弱引用**: Timer 使用 weak self 防止循环引用

## 测试

### 运行测试

```swift
// 在 App 启动时运行测试
@main
struct NovaLifeWeaverApp: App {
    init() {
        Task { @MainActor in
            await runAppStateTests()
        }
    }
}
```

### 测试覆盖

- ✅ 用户状态加载
- ✅ 上下文刷新
- ✅ 错误处理
- ✅ 便捷访问方法
- ✅ 自动刷新配置
- ✅ ObservableObject 协议
- ✅ 性能基准测试

## 扩展开发

### 添加新状态

```swift
// 1. 添加 @Published 属性
@Published var newFeatureData: [NewFeature] = []

// 2. 在 refreshContext() 中更新
func refreshContext() async {
    // ... 现有代码 ...

    // 更新新功能数据
    newFeatureData = context?.someNewData ?? []
}

// 3. 提供便捷访问
var filteredNewFeatures: [NewFeature] {
    newFeatureData.filter { $0.isActive }
}
```

### 添加新操作

```swift
// 添加业务操作方法
func createNewGoal(_ title: String) async {
    isLoading = true

    do {
        // 执行操作
        try await db.createGoal(...)

        // 刷新上下文
        await refreshContext()
    } catch {
        handleError(error, context: "创建目标失败")
    }

    isLoading = false
}
```

## 依赖关系

```
AppState
    ├── Models/User.swift
    ├── Models/UserContext.swift
    ├── Models/Insight.swift
    ├── Engines/ContextEngine.swift
    ├── Services/DatabaseService.swift
    └── Protocols/UIProtocols.swift (AppStateProtocol)
```

## 注意事项

### 线程安全

- ⚠️ 所有 UI 更新必须在主线程
- ✅ AppState 使用 @MainActor 确保线程安全
- ✅ 所有 async 方法自动在主线程执行

### 内存泄漏防护

- ✅ Timer 使用 weak self
- ✅ Combine 订阅自动管理
- ✅ ContextEngine 缓存定期清理

### 性能考虑

- ⚠️ 避免在 UI 线程执行重操作
- ✅ 所有数据库操作使用 async/await
- ✅ 大数据集使用分页加载（未来实现）

### 错误处理最佳实践

```swift
// ✅ 推荐: 提供上下文信息
appState.handleError(error, context: "加载用户数据失败")

// ❌ 不推荐: 没有上下文
appState.handleError(error)

// ✅ 推荐: 在 UI 中展示友好错误
.alert(isPresented: appState.errorBinding) {
    Alert(
        title: Text("操作失败"),
        message: Text(appState.errorDisplayText),
        dismissButton: .default(Text("确定"))
    )
}
```

## 未来优化

### Phase 2 改进

- [ ] 持久化用户 ID（UserDefaults）
- [ ] 多用户支持
- [ ] 离线模式优化
- [ ] 更细粒度的缓存控制

### Phase 3 改进

- [ ] 状态变更历史记录
- [ ] Undo/Redo 支持
- [ ] 乐观更新策略
- [ ] 增量数据同步

### Phase 4 改进

- [ ] CloudKit 同步
- [ ] 性能分析面板
- [ ] A/B 测试框架
- [ ] 崩溃报告集成

## 相关文档

- **架构**: `/ARCHITECTURE.md`
- **数据库设计**: `/DATABASE_DESIGN.md`
- **UI 协议**: `/Protocols/UIProtocols.swift`
- **上下文引擎**: `/Engines/ContextEngine.swift`
- **测试**: `/Tests/TestAppState.swift`
