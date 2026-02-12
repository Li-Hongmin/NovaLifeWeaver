import Foundation
import SwiftUI
import Combine

/// 财务视图模型 - 管理财务记录和预算
@MainActor
class FinancialViewModel: ObservableObject {
    // MARK: - Published State

    /// 交易记录列表
    @Published var transactions: [FinancialRecord] = []

    /// 预算列表
    @Published var budgets: [Budget] = []

    /// 分类总计
    @Published var categoryTotals: [String: Double] = [:]

    /// 加载状态
    @Published var isLoading = false

    /// 错误消息
    @Published var errorMessage: String?

    // MARK: - Filters

    /// 选中的分类（用于筛选）
    @Published var selectedCategory: String?

    /// 日期范围
    @Published var dateRange: DateRange = .thisMonth

    // MARK: - Dependencies

    private let db = DatabaseService.shared

    // MARK: - Computed Properties

    /// 筛选后的交易记录
    var filteredTransactions: [FinancialRecord] {
        var filtered = transactions

        // 按分类筛选
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }

        // 按日期筛选
        let range = dateRange.dateInterval
        filtered = filtered.filter {
            $0.transactionDate >= range.start && $0.transactionDate <= range.end
        }

        return filtered.sorted { $0.transactionDate > $1.transactionDate }
    }

    /// 总支出
    var totalSpending: Double {
        filteredTransactions.reduce(0) { $0 + $1.amount }
    }

    /// 可用分类列表
    var availableCategories: [String] {
        Array(Set(transactions.map { $0.category })).sorted()
    }

    // MARK: - Public Methods

    /// 加载交易记录
    func loadTransactions(userId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // 从数据库加载（根据当前日期范围）
            let interval = dateRange.dateInterval
            transactions = try await db.fetchFinancialRecords(
                userId: userId,
                from: interval.start,
                to: interval.end
            )

            // 计算分类总计
            calculateCategoryTotals()

            print("✅ 已加载 \(transactions.count) 条交易记录")

        } catch {
            errorMessage = "加载交易记录失败：\(error.localizedDescription)"
            print("❌ 加载交易失败：\(error)")
        }

        isLoading = false
    }

    /// 加载预算
    func loadBudgets(userId: String) async {
        do {
            if let budget = try await db.fetchCurrentBudget(userId: userId) {
                budgets = [budget]
            }
            print("✅ 已加载预算")
        } catch {
            print("❌ 加载预算失败：\(error)")
        }
    }

    /// 添加交易记录
    func addTransaction(_ record: FinancialRecord) async {
        isLoading = true
        errorMessage = nil

        do {
            _ = try await db.createFinancialRecord(record)

            // 更新列表
            transactions.insert(record, at: 0)

            // 重新计算总计
            calculateCategoryTotals()

            print("✅ 交易记录已添加：\(record.category) ¥\(record.amount)")

        } catch {
            errorMessage = "添加交易失败：\(error.localizedDescription)"
            print("❌ 添加交易失败：\(error)")
        }

        isLoading = false
    }

    /// 删除交易记录
    func deleteTransaction(_ record: FinancialRecord) async {
        do {
            try await db.deleteFinancialRecord(record.id)

            // 从列表移除
            transactions.removeAll { $0.id == record.id }

            // 重新计算总计
            calculateCategoryTotals()

            print("✅ 交易记录已删除")

        } catch {
            errorMessage = "删除交易失败：\(error.localizedDescription)"
            print("❌ 删除交易失败：\(error)")
        }
    }

    /// 更新预算
    func updateBudget(_ budget: Budget) async {
        do {
            _ = try await db.createBudget(budget)

            // 更新列表
            if let index = budgets.firstIndex(where: { $0.id == budget.id }) {
                budgets[index] = budget
            } else {
                budgets.append(budget)
            }

            print("✅ 预算已更新：\(budget.totalBudget) 元")

        } catch {
            errorMessage = "更新预算失败：\(error.localizedDescription)"
            print("❌ 更新预算失败：\(error)")
        }
    }

    // MARK: - Helper Methods

    /// 计算分类总计
    func calculateCategoryTotals() {
        categoryTotals = Dictionary(grouping: filteredTransactions, by: { $0.category })
            .mapValues { records in
                records.reduce(0) { $0 + $1.amount }
            }
    }

    /// 获取预算状态
    func getBudgetStatus() -> BudgetStatus? {
        guard let budget = budgets.first else {
            return nil
        }

        let spent = totalSpending
        let percentage = spent / budget.totalBudget

        return BudgetStatus(
            budget: budget,
            spent: spent,
            remaining: budget.totalBudget - spent,
            percentage: percentage,
            status: getBudgetAlertLevel(percentage: percentage)
        )
    }

    /// 获取预算警告级别
    private func getBudgetAlertLevel(percentage: Double) -> AlertLevel {
        if percentage >= 1.0 {
            return .critical  // 超支
        } else if percentage >= 0.9 {
            return .high      // 90% 以上
        } else if percentage >= 0.7 {
            return .medium    // 70% 以上
        } else {
            return .normal    // 正常
        }
    }
}

// MARK: - Supporting Types

/// 日期范围枚举
enum DateRange: String, CaseIterable {
    case today      = "今天"
    case thisWeek   = "本周"
    case thisMonth  = "本月"
    case lastMonth  = "上月"
    case thisYear   = "今年"
    case all        = "全部"

    var dateInterval: DateInterval {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .today:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return DateInterval(start: start, end: end)

        case .thisWeek:
            let start = calendar.dateInterval(of: .weekOfYear, for: now)!.start
            let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start)!
            return DateInterval(start: start, end: end)

        case .thisMonth:
            let start = calendar.dateInterval(of: .month, for: now)!.start
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return DateInterval(start: start, end: end)

        case .lastMonth:
            let thisMonthStart = calendar.dateInterval(of: .month, for: now)!.start
            let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: thisMonthStart)!
            return DateInterval(start: lastMonthStart, end: thisMonthStart)

        case .thisYear:
            let start = calendar.dateInterval(of: .year, for: now)!.start
            let end = calendar.date(byAdding: .year, value: 1, to: start)!
            return DateInterval(start: start, end: end)

        case .all:
            let distantPast = Date(timeIntervalSince1970: 0)
            let distantFuture = Date(timeIntervalSinceNow: 365 * 24 * 3600)
            return DateInterval(start: distantPast, end: distantFuture)
        }
    }
}

/// 预算状态
struct BudgetStatus {
    let budget: Budget
    let spent: Double
    let remaining: Double
    let percentage: Double
    let status: AlertLevel
}

/// 警告级别
enum AlertLevel {
    case normal   // 正常
    case medium   // 70% 以上
    case high     // 90% 以上
    case critical // 超支

    var color: Color {
        switch self {
        case .normal:   return .green
        case .medium:   return .yellow
        case .high:     return .orange
        case .critical: return .red
        }
    }

    var displayName: String {
        switch self {
        case .normal:   return "正常"
        case .medium:   return "注意"
        case .high:     return "警告"
        case .critical: return "超支"
        }
    }
}
