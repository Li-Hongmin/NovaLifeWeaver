import SwiftUI

/// 交易记录表单 - 添加/编辑交易
struct TransactionFormView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: FinancialViewModel

    // 表单字段
    @State private var amount: String = ""
    @State private var category: String = "食品"
    @State private var description: String = ""
    @State private var moodAtPurchase: Mood?
    @State private var date: Date = Date()

    let userId: String
    let editingRecord: FinancialRecord?

    init(viewModel: FinancialViewModel, userId: String, editingRecord: FinancialRecord? = nil) {
        self.viewModel = viewModel
        self.userId = userId
        self.editingRecord = editingRecord

        // 如果是编辑模式，填充现有数据
        if let record = editingRecord {
            _amount = State(initialValue: String(format: "%.0f", record.amount))
            _category = State(initialValue: record.category)
            _description = State(initialValue: record.description ?? "")
            _moodAtPurchase = State(initialValue: Mood(score: record.moodAtPurchase ?? 0))
            _date = State(initialValue: record.transactionDate)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text(editingRecord == nil ? "添加交易" : "编辑交易")
                    .font(.headline)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // 表单内容
            Form {
                // 金额
                Section("金额") {
                    HStack {
                        Text("¥")
                            .foregroundColor(.secondary)
                        TextField("0", text: $amount)
                            .textFieldStyle(.plain)
                            .font(.system(size: 24, weight: .medium))
                    }
                }

                // 分类
                Section("分类") {
                    Picker("", selection: $category) {
                        ForEach(FinancialCategory.allCases, id: \.rawValue) { cat in
                            HStack {
                                Text(cat.emoji)
                                Text(cat.displayName)
                            }
                            .tag(cat.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // 描述（可选）
                Section("备注") {
                    TextField("例如：午餐", text: $description)
                }

                // 购买时的心情
                Section("购买时的心情（可选）") {
                    EmotionPickerView(selectedMood: $moodAtPurchase, showLabel: false, compact: true)
                }

                // 日期
                Section("日期") {
                    DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                }
            }
            .formStyle(.grouped)

            Divider()

            // 底部按钮
            HStack {
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(editingRecord == nil ? "添加" : "保存") {
                    Task {
                        await handleSubmit()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
            .padding()
        }
        .frame(width: 500, height: 600)
    }

    // MARK: - Validation

    private var isValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else {
            return false
        }
        return !category.isEmpty
    }

    // MARK: - Actions

    private func handleSubmit() async {
        guard let amountValue = Double(amount) else { return }

        let record = FinancialRecord(
            id: editingRecord?.id ?? UUID().uuidString,
            userId: userId,
            amount: amountValue,
            currency: "JPY",
            category: category,
            subcategory: nil,
            title: nil,
            description: description.isEmpty ? nil : description,
            merchant: nil,
            location: nil,
            relatedGoalId: nil,
            relatedEventId: nil,
            moodAtPurchase: moodAtPurchase?.score,
            purchaseType: nil,
            satisfaction: nil,
            receiptPhotoPath: nil,
            ocrData: nil,
            transactionDate: date,
            createdAt: editingRecord?.createdAt ?? Date(),
            updatedAt: Date()
        )

        await viewModel.addTransaction(record)
        dismiss()
    }
}

// MARK: - Financial Categories

/// 财务分类
enum FinancialCategory: String, CaseIterable {
    case food           = "食品"
    case transportation = "交通"
    case shopping       = "购物"
    case entertainment  = "娱乐"
    case healthcare     = "医疗"
    case education      = "教育"
    case housing        = "住房"
    case utilities      = "水电"
    case other          = "其他"

    var emoji: String {
        switch self {
        case .food:           return "🍜"
        case .transportation: return "🚃"
        case .shopping:       return "🛍️"
        case .entertainment:  return "🎮"
        case .healthcare:     return "💊"
        case .education:      return "📚"
        case .housing:        return "🏠"
        case .utilities:      return "💡"
        case .other:          return "📦"
        }
    }

    var displayName: String {
        rawValue
    }
}

// MARK: - Mood Extension

extension Mood {
    /// 从分数创建 Mood
    init(score: Double) {
        if score >= 0.75 {
            self = .veryHappy
        } else if score >= 0.25 {
            self = .happy
        } else if score >= -0.25 {
            self = .neutral
        } else if score >= -0.75 {
            self = .sad
        } else {
            self = .verySad
        }
    }
}

// MARK: - Preview

#Preview {
    TransactionFormView(
        viewModel: FinancialViewModel(),
        userId: "test-user"
    )
}
