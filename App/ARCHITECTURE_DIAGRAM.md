# AppState 架构图

## 系统架构总览

```
┌─────────────────────────────────────────────────────────────────────┐
│                         SwiftUI Views Layer                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │  MenuBarView │  │  ContentView │  │  GoalListView│  ...        │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘             │
│         │                  │                  │                      │
│         └──────────────────┼──────────────────┘                      │
│                            │ @EnvironmentObject / @ObservedObject   │
└────────────────────────────┼────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          AppState (Singleton)                       │
│  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓   │
│  ┃              @Published State Variables                     ┃   │
│  ┃  • currentUser: User?                                       ┃   │
│  ┃  • context: UserContext?                                    ┃   │
│  ┃  • insights: [Insight]                                      ┃   │
│  ┃  • isLoading: Bool                                          ┃   │
│  ┃  • errorMessage: String?                                    ┃   │
│  ┃  • appStatus: AppStatus                                     ┃   │
│  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛   │
│                                                                       │
│  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓   │
│  ┃                    Core Methods                             ┃   │
│  ┃  • loadUserState() async                                    ┃   │
│  ┃  • refreshContext() async                                   ┃   │
│  ┃  • handleError(error, context)                              ┃   │
│  ┃  • invalidateCacheAndRefresh() async                        ┃   │
│  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛   │
│                                                                       │
│  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓   │
│  ┃              Convenience Accessors                          ┃   │
│  ┃  • activeGoals / activeHabits / todaySchedule               ┃   │
│  ┃  • urgentInsights / budgetAlerts                            ┃   │
│  ┃  • hasUrgentMatters / isStressed / briefSummary             ┃   │
│  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛   │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │           Auto-Refresh Timer (5 minutes)                   │    │
│  └────────────────────────────────────────────────────────────┘    │
└───────────────────────────┬───────────────────────────────────────┘
                            │
                ┌───────────┴───────────┐
                ▼                       ▼
┌─────────────────────────┐   ┌──────────────────────┐
│   ContextEngine         │   │  DatabaseService     │
│  ┌──────────────────┐   │   │  ┌────────────────┐ │
│  │ loadContext()    │   │   │  │ fetchUser()    │ │
│  │ <100ms target    │   │   │  │ fetchGoals()   │ │
│  │ parallel loading │   │   │  │ fetchHabits()  │ │
│  │ 5min cache       │   │   │  │ fetchEmotions()│ │
│  └──────────────────┘   │   │  └────────────────┘ │
└─────────────────────────┘   └──────────────────────┘
```

## 数据流向图

### 1. 应用启动流程

```
App Launch
    │
    ├─→ NovaLifeWeaverApp.init()
    │       │
    │       └─→ @StateObject appState = AppState.shared
    │
    ├─→ .task { await appState.loadUserState() }
    │       │
    │       ├─→ getOrCreateDefaultUser()
    │       │       └─→ return "default-user"
    │       │
    │       ├─→ loadUser(userId)
    │       │       └─→ currentUser = User(...)
    │       │
    │       ├─→ refreshContext()
    │       │       │
    │       │       ├─→ ContextEngine.loadContext(userId)
    │       │       │       │
    │       │       │       ├─→ Parallel Load:
    │       │       │       │   • loadGoalData()
    │       │       │       │   • loadHabitData()
    │       │       │       │   • loadFinancialData()
    │       │       │       │   • loadEmotionData()
    │       │       │       │   • loadEventData()
    │       │       │       │   • loadInsightData()
    │       │       │       │   • loadCorrelations()
    │       │       │       │
    │       │       │       └─→ context = UserContext(...)
    │       │       │
    │       │       ├─→ insights = context.recentInsights
    │       │       │
    │       │       └─→ updateAppStatus()
    │       │
    │       └─→ startAutoRefresh()
    │               └─→ Timer (every 5 minutes)
    │                       └─→ refreshContext()
    │
    └─→ ContentView (SwiftUI)
            └─→ .environmentObject(appState)
```

### 2. 上下文刷新流程

```
User Action / Timer Trigger
    │
    └─→ refreshContext() async
            │
            ├─→ guard currentUser != nil
            │       │
            │       └─→ else: handleError(.noUser)
            │
            ├─→ isLoading = true
            │       └─→ SwiftUI Views update (show loading)
            │
            ├─→ try await contextEngine.loadContext(userId)
            │       │
            │       ├─→ Check Cache (5min expiry)
            │       │   ├─→ Hit: return cached context (<1ms)
            │       │   └─→ Miss: parallel load from DB
            │       │
            │       └─→ context = UserContext(...)
            │
            ├─→ insights = context.recentInsights
            │
            ├─→ updateAppStatus()
            │   ├─→ Has urgent? → .hasAlert
            │   ├─→ Loading? → .syncing
            │   └─→ else → .normal
            │
            ├─→ isLoading = false
            │       └─→ SwiftUI Views update (hide loading)
            │
            └─→ SwiftUI Views re-render with new data
```

### 3. 错误处理流程

```
Error Occurs
    │
    └─→ handleError(error, context: "操作描述")
            │
            ├─→ errorMessage = "\(context): \(error.localizedDescription)"
            │       └─→ SwiftUI Alert triggered
            │
            ├─→ appStatus = .offline
            │       └─→ Menu Bar icon updates
            │
            └─→ logError(error, context)
                    └─→ Console output / File logging
```

### 4. SwiftUI 集成流程

```
┌────────────────────────────────────────────────────────────┐
│                      App Entry Point                       │
│  @main                                                     │
│  struct NovaLifeWeaverApp: App {                          │
│      @StateObject private var appState = AppState.shared  │
│                                                             │
│      var body: some Scene {                                │
│          WindowGroup {                                     │
│              ContentView()                                 │
│                  .environmentObject(appState)              │
│                  .task {                                   │
│                      await appState.loadUserState()        │
│                  }                                         │
│          }                                                  │
│      }                                                      │
│  }                                                          │
└────────────────────────────────────────────────────────────┘
                         │
                         ├─→ Inject into Environment
                         │
         ┌───────────────┴───────────────┐
         ▼                               ▼
┌─────────────────┐            ┌──────────────────┐
│  ContentView    │            │  MenuBarView     │
│                 │            │                  │
│  @Environment   │            │  @ObservedObject │
│  Object var     │            │  var appState =  │
│  appState       │            │  AppState.shared │
└─────────────────┘            └──────────────────┘
         │                               │
         └───────────┬───────────────────┘
                     │
                     ├─→ Access State
                     │   • appState.currentUser
                     │   • appState.context
                     │   • appState.isLoading
                     │
                     ├─→ Call Methods
                     │   • await appState.refreshContext()
                     │   • appState.handleError(...)
                     │
                     └─→ Observe Changes
                         • Auto-update on @Published changes
```

## 性能优化架构

```
┌─────────────────────────────────────────────────────────────┐
│                    Performance Strategy                     │
└─────────────────────────────────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   Caching    │  │   Parallel   │  │    Thread    │
│   Strategy   │  │   Loading    │  │    Safety    │
└──────────────┘  └──────────────┘  └──────────────┘
        │                 │                 │
        │                 │                 │
        ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Context      │  │ async/await  │  │ @MainActor   │
│ Engine       │  │ for all DB   │  │ for AppState │
│ 5min cache   │  │ operations   │  │              │
└──────────────┘  └──────────────┘  └──────────────┘
        │                 │                 │
        └─────────────────┴─────────────────┘
                          │
                          ▼
                ┌──────────────────┐
                │  <100ms Target   │
                │  Context Loading │
                └──────────────────┘
```

## 错误处理架构

```
┌─────────────────────────────────────────────────────────────┐
│                     Error Handling                          │
└─────────────────────────────────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   Capture    │  │    Process   │  │   Display    │
└──────────────┘  └──────────────┘  └──────────────┘
        │                 │                 │
        ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Any error in │  │ handleError  │  │ errorMessage │
│ AppState     │  │ ├─ Set msg   │  │ @Published   │
│ operations   │  │ ├─ Update    │  │              │
│              │  │ │  status    │  │ SwiftUI Alert│
│              │  │ └─ Log error │  │              │
└──────────────┘  └──────────────┘  └──────────────┘
        │                 │                 │
        └─────────────────┴─────────────────┘
                          │
                          ▼
                ┌──────────────────┐
                │  User-Friendly   │
                │  Error Display   │
                └──────────────────┘
```

## 状态同步架构

```
┌─────────────────────────────────────────────────────────────┐
│                  State Synchronization                      │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
            ┌─────────────────────────┐
            │  AppState (@Published)   │
            └─────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  All SwiftUI │  │  Menu Bar    │  │   Widgets    │
│   Views      │  │  Indicator   │  │   (Future)   │
└──────────────┘  └──────────────┘  └──────────────┘
        │                 │                 │
        ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Auto-update  │  │ Icon changes │  │ Live updates │
│ on state     │  │ based on     │  │ based on     │
│ change       │  │ appStatus    │  │ context      │
└──────────────┘  └──────────────┘  └──────────────┘
```

## 依赖关系图

```
┌─────────────────────────────────────────────────────────────┐
│                      Dependencies                           │
└─────────────────────────────────────────────────────────────┘

AppState
    │
    ├─→ Foundation (Timer, Date, etc.)
    │
    ├─→ SwiftUI (ObservableObject, Published)
    │
    ├─→ Combine (for future reactive extensions)
    │
    ├─→ Models/
    │   ├─→ User.swift
    │   ├─→ UserContext.swift
    │   ├─→ Insight.swift
    │   ├─→ Goal.swift
    │   ├─→ Habit.swift
    │   ├─→ FinancialRecord.swift
    │   ├─→ EmotionRecord.swift
    │   └─→ Event.swift
    │
    ├─→ Engines/
    │   └─→ ContextEngine.swift
    │       └─→ DatabaseService.swift
    │
    └─→ Protocols/
        └─→ UIProtocols.swift (AppStateProtocol)
```

## 反向依赖图（谁使用 AppState）

```
┌─────────────────────────────────────────────────────────────┐
│                   Reverse Dependencies                      │
└─────────────────────────────────────────────────────────────┘

SwiftUI Views Layer
    │
    ├─→ NovaLifeWeaverApp.swift (App Entry)
    │
    ├─→ Views/
    │   ├─→ ContentView.swift
    │   ├─→ MenuBarView.swift (via MenuBarManager)
    │   ├─→ GoalListView.swift
    │   ├─→ HabitTrackingView.swift
    │   ├─→ FinanceDashboardView.swift
    │   ├─→ EmotionTrackerView.swift
    │   └─→ ScheduleView.swift
    │
    ├─→ ViewModels/
    │   ├─→ GoalListViewModel.swift
    │   ├─→ HabitTrackingViewModel.swift
    │   └─→ ... (other ViewModels)
    │
    └─→ App/
        └─→ MenuBarManager.swift
```

## 总结

AppState 是整个应用的**中央状态管理器**，具有以下特点：

1. **集中式管理** - 所有全局状态集中在一处
2. **响应式更新** - 通过 @Published 自动触发 UI 更新
3. **高性能** - ContextEngine 保证 <100ms 加载时间
4. **线程安全** - @MainActor 确保所有操作在主线程
5. **自动同步** - 5 分钟定时器保持数据新鲜度
6. **统一错误处理** - 所有错误经过 handleError() 统一处理
7. **便捷访问** - 提供多个计算属性快速访问常用数据

这个架构确保了数据的一致性、性能和可维护性。
