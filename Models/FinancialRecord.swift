import Foundation

/// 财务记录模型 - 支持情绪消费关联分析
struct FinancialRecord: Codable, Identifiable {
    // MARK: - 基础信息
    let id: String
    let userId: String
    var amount: Double
    var currency: String
    var category: String
    var subcategory: String?
    var title: String?
    var description: String?

    // MARK: - 商家和地点
    var merchant: String?
    var location: String?

    // MARK: - 关联信息
    var relatedGoalId: String?
    var relatedEventId: String?

    // MARK: - 关键：情绪消费分析字段
    var moodAtPurchase: Double?    // 购买时情绪 (-1.0 to 1.0)
    var purchaseType: PurchaseType?
    var satisfaction: Double?       // 购买后满意度 (0.0 to 1.0)

    // MARK: - 多模态输入
    var receiptPhotoPath: String?
    var ocrData: OCRData?

    // MARK: - 时间戳
    var transactionDate: Date
    let createdAt: Date
    var updatedAt: Date

    // MARK: - 初始化
    init(
        id: String = UUID().uuidString,
        userId: String,
        amount: Double,
        currency: String = "JPY",
        category: String,
        subcategory: String? = nil,
        title: String? = nil,
        description: String? = nil,
        merchant: String? = nil,
        location: String? = nil,
        relatedGoalId: String? = nil,
        relatedEventId: String? = nil,
        moodAtPurchase: Double? = nil,
        purchaseType: PurchaseType? = nil,
        satisfaction: Double? = nil,
        receiptPhotoPath: String? = nil,
        ocrData: OCRData? = nil,
        transactionDate: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.amount = amount
        self.currency = currency
        self.category = category
        self.subcategory = subcategory
        self.title = title
        self.description = description
        self.merchant = merchant
        self.location = location
        self.relatedGoalId = relatedGoalId
        self.relatedEventId = relatedEventId
        self.moodAtPurchase = moodAtPurchase
        self.purchaseType = purchaseType
        self.satisfaction = satisfaction
        self.receiptPhotoPath = receiptPhotoPath
        self.ocrData = ocrData
        self.transactionDate = transactionDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case amount
        case currency
        case category
        case subcategory
        case title
        case description
        case merchant
        case location
        case relatedGoalId = "related_goal_id"
        case relatedEventId = "related_event_id"
        case moodAtPurchase = "mood_at_purchase"
        case purchaseType = "purchase_type"
        case satisfaction
        case receiptPhotoPath = "receipt_photo_path"
        case ocrData = "ocr_data"
        case transactionDate = "transaction_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - 业务逻辑扩展
extension FinancialRecord {
    /// 是否为情绪消费
    var isEmotionalPurchase: Bool {
        guard let mood = moodAtPurchase else { return false }
        return mood < -0.3 // 情绪低落时的消费
    }

    /// 是否为大额消费
    var isLargeExpense: Bool {
        amount > 10000 // JPY
    }

    /// 格式化金额
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}

// MARK: - 枚举定义

/// 购买类型
enum PurchaseType: String, Codable {
    case planned        // 计划内
    case impulse        // 冲动消费
    case necessary      // 必需品
    case entertainment  // 娱乐
    case investment     // 投资
}

/// OCR 提取的数据
struct OCRData: Codable {
    var merchant: String?
    var amount: Double?
    var date: String?
    var items: [String]?
    var rawText: String?
}

// MARK: - 预算模型

/// 预算模型
struct Budget: Codable, Identifiable {
    let id: String
    let userId: String
    var periodStart: Date
    var periodEnd: Date
    var totalBudget: Double
    var categoryBudgets: [String: Double]?  // 分类预算
    var totalSpent: Double
    var categorySpent: [String: Double]?    // 分类支出
    var alertThreshold: Double              // 预警阈值 (0.0-1.0)
    let createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String,
        periodStart: Date,
        periodEnd: Date,
        totalBudget: Double,
        categoryBudgets: [String: Double]? = nil,
        totalSpent: Double = 0.0,
        categorySpent: [String: Double]? = nil,
        alertThreshold: Double = 0.8,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.totalBudget = totalBudget
        self.categoryBudgets = categoryBudgets
        self.totalSpent = totalSpent
        self.categorySpent = categorySpent
        self.alertThreshold = alertThreshold
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case periodStart = "period_start"
        case periodEnd = "period_end"
        case totalBudget = "total_budget"
        case categoryBudgets = "category_budgets"
        case totalSpent = "total_spent"
        case categorySpent = "category_spent"
        case alertThreshold = "alert_threshold"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - 预算业务逻辑
extension Budget {
    /// 使用率
    var usageRate: Double {
        guard totalBudget > 0 else { return 0 }
        return totalSpent / totalBudget
    }

    /// 使用百分比
    var usagePercentage: Int {
        Int(usageRate * 100)
    }

    /// 是否超预算
    var isOverBudget: Bool {
        totalSpent > totalBudget
    }

    /// 是否达到预警阈值
    var shouldAlert: Bool {
        usageRate >= alertThreshold
    }

    /// 剩余预算
    var remaining: Double {
        max(totalBudget - totalSpent, 0)
    }

    /// 剩余天数
    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: periodEnd).day ?? 0
    }

    /// 每日可用预算
    var dailyBudget: Double {
        guard daysRemaining > 0 else { return 0 }
        return remaining / Double(daysRemaining)
    }

    /// 获取分类预算使用率
    func categoryUsageRate(for category: String) -> Double {
        guard let budget = categoryBudgets?[category], budget > 0,
              let spent = categorySpent?[category] else {
            return 0
        }
        return spent / budget
    }
}
