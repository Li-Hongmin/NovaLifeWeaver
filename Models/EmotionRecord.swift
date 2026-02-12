import Foundation

/// 情绪记录模型 - 支持多模态输入和关联分析
struct EmotionRecord: Codable, Identifiable {
    // MARK: - 基础信息
    let id: String
    let userId: String
    var score: Double              // -1.0 (消极) to 1.0 (积极)
    var intensity: Double?         // 情绪强度 0.0-1.0

    // MARK: - 情绪详情
    var emotions: [String]?        // ["happy", "excited", "anxious"]
    var trigger: String?           // 触发因素类型
    var triggerDescription: String?
    var activity: String?          // 当时的活动
    var location: String?          // 地点
    var weather: String?           // 天气

    // MARK: - 多模态记录
    var voiceRecordingPath: String?
    var transcription: String?     // 语音转文本
    var photoPath: String?
    var note: String?              // 文字日记

    // MARK: - AI 分析
    var sentimentAnalysis: SentimentAnalysis?
    var recommendedActions: String?

    // MARK: - 时间戳
    var recordedAt: Date
    let createdAt: Date

    // MARK: - 初始化
    init(
        id: String = UUID().uuidString,
        userId: String,
        score: Double,
        intensity: Double? = nil,
        emotions: [String]? = nil,
        trigger: String? = nil,
        triggerDescription: String? = nil,
        activity: String? = nil,
        location: String? = nil,
        weather: String? = nil,
        voiceRecordingPath: String? = nil,
        transcription: String? = nil,
        photoPath: String? = nil,
        note: String? = nil,
        sentimentAnalysis: SentimentAnalysis? = nil,
        recommendedActions: String? = nil,
        recordedAt: Date = Date(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.score = score
        self.intensity = intensity
        self.emotions = emotions
        self.trigger = trigger
        self.triggerDescription = triggerDescription
        self.activity = activity
        self.location = location
        self.weather = weather
        self.voiceRecordingPath = voiceRecordingPath
        self.transcription = transcription
        self.photoPath = photoPath
        self.note = note
        self.sentimentAnalysis = sentimentAnalysis
        self.recommendedActions = recommendedActions
        self.recordedAt = recordedAt
        self.createdAt = createdAt
    }

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case score
        case intensity
        case emotions
        case trigger
        case triggerDescription = "trigger_description"
        case activity
        case location
        case weather
        case voiceRecordingPath = "voice_recording_path"
        case transcription
        case photoPath = "photo_path"
        case note
        case sentimentAnalysis = "sentiment_analysis"
        case recommendedActions = "recommended_actions"
        case recordedAt = "recorded_at"
        case createdAt = "created_at"
    }
}

// MARK: - 业务逻辑扩展
extension EmotionRecord {
    /// 情绪分类
    var emotionCategory: EmotionCategory {
        if score >= 0.6 {
            return .positive
        } else if score >= 0.2 {
            return .neutral
        } else if score >= -0.3 {
            return .mild_negative
        } else {
            return .negative
        }
    }

    /// 是否为压力状态
    var isStressed: Bool {
        guard let emotions = emotions else { return false }
        let stressEmotions = ["anxious", "stressed", "overwhelmed", "worried"]
        return emotions.contains(where: { stressEmotions.contains($0) })
    }

    /// 是否需要关注
    var needsAttention: Bool {
        score < -0.5 || (intensity ?? 0) > 0.8
    }

    /// 格式化情绪描述
    var emotionDescription: String {
        if let emotions = emotions, !emotions.isEmpty {
            return emotions.joined(separator: ", ")
        }
        return emotionCategory.rawValue
    }
}

// MARK: - 枚举定义

/// 情绪分类
enum EmotionCategory: String, Codable {
    case positive       // 积极
    case neutral        // 中性
    case mild_negative  // 轻度消极
    case negative       // 消极
}

/// AI 情绪分析结果
struct SentimentAnalysis: Codable {
    var primaryEmotion: String?
    var emotionLabels: [String: Double]?  // {"joy": 0.8, "sadness": 0.1}
    var topics: [String]?                  // 讨论的主题
    var keywords: [String]?                // 关键词
    var stressLevel: Double?               // 压力水平 0.0-1.0
}
