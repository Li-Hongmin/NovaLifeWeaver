import SwiftUI

/// 交易记录列表视图
struct TransactionListView: View {
    @ObservedObject var viewModel: FinancialViewModel
    let userId: String

    @State private var showingAddForm = false

    var body: some View {
        VStack(spacing: 0) {
            // 筛选栏
            FilterBar(
                selectedCategory: $viewModel.selectedCategory,
                dateRange: $viewModel.dateRange,
                categories: viewModel.availableCategories,
                totalSpending: viewModel.totalSpending
            )
            .padding()

            Divider()

            // 交易列表
            if viewModel.filteredTransactions.isEmpty {
                emptyStateView
            } else {
                transactionTable
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    showingAddForm = true
                } label: {
                    Label("添加交易", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddForm) {
            TransactionFormView(viewModel: viewModel, userId: userId)
        }
    }

    // MARK: - Transaction Table

    private var transactionTable: some View {
        Table(viewModel.filteredTransactions) {
            TableColumn("日期") { record in
                Text(record.transactionDate, style: .date)
                    .font(.callout)
            }
            .width(min: 100)

            TableColumn("金额") { record in
                Text("¥\(String(format: "%.0f", record.amount))")
                    .font(.callout.monospacedDigit())
                    .foregroundColor(.primary)
            }
            .width(min: 80)

            TableColumn("分类") { record in
                HStack {
                    Text(FinancialCategory(rawValue: record.category)?.emoji ?? "📦")
                    Text(record.category)
                        .font(.callout)
                }
            }
            .width(min: 100)

            TableColumn("心情") { record in
                if let mood = record.moodAtPurchase {
                    Text(Mood(score: mood).emoji)
                        .font(.title3)
                } else {
                    Text("-")
                        .foregroundColor(.secondary)
                }
            }
            .width(min: 60)

            TableColumn("备注") { record in
                Text(record.description ?? "")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .width(min: 150)

            TableColumn("操作") { record in
                Button {
                    Task {
                        await viewModel.deleteTransaction(record)
                    }
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            .width(min: 60)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "yensign.circle")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("还没有交易记录")
                .font(.title3)
                .foregroundColor(.secondary)

            Button("添加第一条记录") {
                showingAddForm = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Filter Bar

struct FilterBar: View {
    @Binding var selectedCategory: String?
    @Binding var dateRange: DateRange
    let categories: [String]
    let totalSpending: Double

    var body: some View {
        HStack {
            // 分类筛选
            Menu {
                Button("全部分类") {
                    selectedCategory = nil
                }

                Divider()

                ForEach(categories, id: \.self) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        HStack {
                            if let cat = FinancialCategory(rawValue: category) {
                                Text(cat.emoji)
                                Text(cat.displayName)
                            } else {
                                Text(category)
                            }

                            if selectedCategory == category {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text(selectedCategory ?? "全部分类")
                }
            }
            .frame(width: 150)

            // 日期范围
            Picker("", selection: $dateRange) {
                ForEach(DateRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 120)

            Spacer()

            // 统计信息
            if !categories.isEmpty {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("总计")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("¥\(String(format: "%.0f", totalSpending))")
                        .font(.headline.monospacedDigit())
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TransactionListView(viewModel: FinancialViewModel(), userId: "test-user")
        .frame(width: 800, height: 600)
}
