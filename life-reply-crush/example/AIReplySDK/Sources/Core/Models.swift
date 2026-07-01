import Foundation

// MARK: - API Models

public struct ChatMessage: Codable {
    public let role: String
    public let content: String

    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

public struct ChatRequest: Codable {
    public let model: String
    public let messages: [ChatMessage]
    public let temperature: Double

    public init(model: String, messages: [ChatMessage], temperature: Double) {
        self.model = model
        self.messages = messages
        self.temperature = temperature
    }
}

public struct ChatResponse: Codable {
    public let choices: [Choice]
    public let usage: Usage?
}

public struct Choice: Codable {
    public let message: ChatMessage
}

public struct Usage: Codable {
    public let promptTokens: Int
    public let completionTokens: Int
    public let totalTokens: Int

    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

struct ErrorResponse: Codable {
    let error: ErrorDetail?
}

struct ErrorDetail: Codable {
    let message: String?
}

// MARK: - Reply

public struct ReplyOption: Identifiable, Codable {
    public let id: UUID
    public let type: String
    public let content: String

    public init(id: UUID = UUID(), type: String, content: String) {
        self.id = id
        self.type = type
        self.content = content
    }
}

// MARK: - Platform

public struct ModelOption: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let inputPerM: Double
    public let outputPerM: Double
    public let isFree: Bool

    public init(id: String, name: String, inputPerM: Double, outputPerM: Double, isFree: Bool) {
        self.id = id
        self.name = name
        self.inputPerM = inputPerM
        self.outputPerM = outputPerM
        self.isFree = isFree
    }
}

public struct Platform: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let endpoint: String
    public let apiKeyHelpURL: String
    public let pricingURL: String
    public let inputPerM: Double
    public let outputPerM: Double
    public let currency: String
    public var models: [ModelOption]?

    public init(id: String, name: String, endpoint: String, apiKeyHelpURL: String, pricingURL: String, inputPerM: Double, outputPerM: Double, currency: String, models: [ModelOption]? = nil) {
        self.id = id
        self.name = name
        self.endpoint = endpoint
        self.apiKeyHelpURL = apiKeyHelpURL
        self.pricingURL = pricingURL
        self.inputPerM = inputPerM
        self.outputPerM = outputPerM
        self.currency = currency
        self.models = models
    }

    public static let deepseek = Platform(
        id: "deepseek",
        name: "DeepSeek",
        endpoint: "https://api.deepseek.com/v1/chat/completions",
        apiKeyHelpURL: "https://platform.deepseek.com/",
        pricingURL: "https://api-docs.deepseek.com/quick_start/pricing",
        inputPerM: 0.28,
        outputPerM: 0.42,
        currency: "$"
    )

    public static let siliconflow = Platform(
        id: "siliconflow",
        name: "硅基流动",
        endpoint: "https://api.siliconflow.cn/v1/chat/completions",
        apiKeyHelpURL: "https://cloud.siliconflow.cn/me/account/ak",
        pricingURL: "https://siliconflow.cn/pricing",
        inputPerM: 2,
        outputPerM: 3,
        currency: "¥",
        models: [
            ModelOption(id: "deepseek-ai/DeepSeek-V3.2", name: "DeepSeek-V3.2", inputPerM: 2, outputPerM: 3, isFree: false),
            ModelOption(id: "Qwen/Qwen2.5-7B-Instruct", name: "Qwen2.5-7B", inputPerM: 0, outputPerM: 0, isFree: true),
            ModelOption(id: "THUDM/glm-4-9b-chat", name: "GLM-4-9B", inputPerM: 0, outputPerM: 0, isFree: true),
            ModelOption(id: "deepseek-ai/DeepSeek-R1-Distill-Qwen-7B", name: "R1-7B", inputPerM: 0, outputPerM: 0, isFree: true),
            ModelOption(id: "Qwen/Qwen3-8B", name: "Qwen3-8B", inputPerM: 0, outputPerM: 0, isFree: true),
        ]
    )

    public static let all: [Platform] = [.deepseek, .siliconflow]
}

// MARK: - Prompt Preset

public struct PromptPreset: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var systemPrompt: String
    public var userPromptTemplate: String
    public var placeholder: String
    public var generateTitle: String
    public var rawTextMode: Bool

    public init(id: UUID = UUID(), name: String, systemPrompt: String, userPromptTemplate: String = "对方说：{input}\n\n请生成6-8个不同的回复选项，每个回复一行，格式为：类型: 回复内容", placeholder: String = "我要去洗澡了", generateTitle: String = "对方说了什么？", rawTextMode: Bool = false) {
        self.id = id
        self.name = name
        self.systemPrompt = systemPrompt
        self.userPromptTemplate = userPromptTemplate
        self.placeholder = placeholder
        self.generateTitle = generateTitle
        self.rawTextMode = rawTextMode
    }

    public func formatUserPrompt(input: String) -> String {
        userPromptTemplate.replacingOccurrences(of: "{input}", with: input)
    }

    public static let `default` = PromptPreset(
        name: "暧昧撩人",
        systemPrompt: """
        你是一个情商大师，专门帮用户用幽默撩人、有情绪张力的方式回复 crush 的消息。

        核心目标：回复要有情绪价值——能让对方笑、让对方脸红、让对方想继续聊。偶尔可以加点拉扯，让对话停不下来。

        ## 核心方向（底线和方向，不是限制。好回复可以同时满足多条）

        1. 上位者姿态：回复要体现出"我是主动方，我是在引导这段互动"，而不是"我在等你回应"。语气轻松调侃，但位置要稳。
        2. 轻占有感：用确定、自然的方式表达，比如"从小就没老婆的"暗示对方愿意做你老婆
        3. 避免备胎感：不说"我等你好久""你不在我很无聊"这类话
        4. 拒绝土味和刻意撩：不用"小傻瓜""坏蛋"这类词，保持自然、轻巧、有个人风格
        5. 有钩子但不说破：创造一个对方回来后可以自然接住的小情境，且钩子的落点是你已经准备好的、有画面感的回应

        ## 思考方式

        拿到 crush 的话，从以下方向想回复：
        - 想撩的方向、想引起好奇的方向、想让她笑的方向
        - 想让她脸红的方向、想让她想反驳你的方向
        - 想让她有画面感——幻想和你在一起的场景
        - 想让她觉得你好玩、有趣、聊天停不下来

        ## 具体技巧

        1. 打破预期：她以为你会正常回，偏不按套路出牌
        2. 留钩子：让她想追问、想反驳，而不是简单回"哈哈"或"哦"
        3. 制造画面感：让她产生和你在一起的想象，产生甜蜜或好笑的场景
        4. 反向拉扯：她撩你，你要更撩；她冷淡，你要更热情

        ## 坚决避免的回复

        - 平淡回应：哦、嗯、好、可以
        - 逻辑正确但无情绪：分析她为什么这么说、给建议
        - 让她只能回"哈哈"：过于正常或无聊的回复
        - 查户口式：不停问问题让她回答

        ## 风格类型参考（选择性使用，不强求）

        - 曲解型：脑回路清奇，把正常对话拐向奇怪方向
        - 造谣型/反转型/反客为主型：无中生有，越离谱越好
        - 画饼型：暗示对方是自己老婆/女朋友
        - 反向画饼型：画比你还大的饼（她说"请你吃饭"→"那我要吃你"）
        - 学霸型/学渣型/装傻型
        - 油腻型：直球撩，不要脸但有分寸
        - 霸总型/主人型：我说了算的气势
        - 嫁祸型：拒不认错，反向甩锅
        - 阴阳怪气型：话里有话，嘴贱但可爱

        ## 规则

        1. 每次生成 5-8 个回复
        2. 回复要短，1-2句话
        3. 不要泛泛的"早点休息"这类无聊回答
        4. 可以有点撩、有点油、有点不要脸，但不能冒犯
        5. 造谣型、反转型、装傻型往往最出彩，可以优先想
        6. 有趣的画面感 > 风格标签——能让对方产生想象空间的回复优先
        7. 必须让她想接话——避免她只能回"哈哈"、"哦"
        8. 优先打破预期、留钩子、制造画面感的回复
        9. 碰到简单消息（如"？""...""哈哈"）时，更需要脑回路清奇、出其不意
        """,
        userPromptTemplate: "对方说：{input}\n\n请生成5-8个回复选项，每个一行，格式为：风格型：回复内容。风格可以不写，但回复必须有趣、有钩子、有情绪价值。",
        placeholder: "我要去洗澡了",
        generateTitle: "对方说了什么？",
        rawTextMode: false
    )

    public static let emojiIdiom = PromptPreset(
        name: "Emoji 猜成语",
        systemPrompt: """
        你是一个看图猜成语的高手，擅长根据表情符号（emoji）的本义、谐音、象形/引申来推断成语。

        ## 核心规律

        每个 emoji 通常对应成语中的一个字，通过以下三种方式匹配：

        1. 本义法：利用 emoji 本身代表的含义，如 🐯 → 虎、🐴 → 马
        2. 谐音法：利用 emoji 名称或含义的读音
           - 同音字：🐟(鱼 yú) → 渔(yú)、💰(钱 qián) → 前(qián)
           - 近音字：🐱(猫 māo) → 貌(mào)、👋(拜拜 bái) → 白(bái)
           - 多字 emoji 取主要音节：🍍(菠萝) → 博、🐝(蜜蜂) → 靡
        3. 象形/引申法：利用 emoji 的形状、动作或联想
           - 象形：🙅‍♀️(双手交叉) → 交、⭕(圆圈) → 空
           - 引申：😭(哭) → 悲、🎥(摄像机) → 影

        ## 响应流程（必须严格按以下三步输出）

        第一步：逐一拆解。对每个 emoji，从本义/谐音/象形三种角度分析。

        第二步：组合尝试。将每个 emoji 的多种含义排列组合，列出所有合理的成语选项（至少2种，如果只有1个合理则只输出1个）。

        第三步：筛选排序。对选项进行匹配度排序（高/中/低），说明排序理由。

        ## 匹配原则

        1. 解读应合理：该 emoji 与对应字的关联应当能被理解
        2. 一字一符优先：尽量保证每个 emoji 对应成语中的一个字
        3. 优先选择解读更直接的组合

        常见示例：👦💰👩🐱 → 男才女貌、❤️❌🍅✋ → 爱不释手、🔪⚡🚀🎥 → 刀光剑影
        """,
        userPromptTemplate: "猜成语：{input}",
        placeholder: "😭😄🙅‍♀️🏠",
        generateTitle: "输入 Emoji？",
        rawTextMode: true
    )

    public static let builtinPresets: [PromptPreset] = [.default, .emojiIdiom]

    public static var customPresets: [PromptPreset] {
        get {
            guard let data = UserDefaults.shared.data(forKey: "custom_presets"),
                  let presets = try? JSONDecoder().decode([PromptPreset].self, from: data) else { return [] }
            return presets
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            UserDefaults.shared.set(data, forKey: "custom_presets")
        }
    }

    public static var allPresets: [PromptPreset] {
        builtinPresets + customPresets
    }

    public static func == (lhs: PromptPreset, rhs: PromptPreset) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Shared UserDefaults

public extension UserDefaults {
    static let shared = UserDefaults(suiteName: "group.com.dvlproad.AIReply")!
}

// MARK: - Parsing

public func parseReplies(from text: String) -> [ReplyOption] {
    let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    var replies: [ReplyOption] = []

    for line in lines {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        if let range = trimmed.range(of: "：") ?? trimmed.range(of: ":") ?? trimmed.range(of: " - ") {
            let type = trimmed[..<range.lowerBound].trimmingCharacters(in: .whitespaces)
            let content = trimmed[range.upperBound...].trimmingCharacters(in: .whitespaces)
            if !type.isEmpty, content.count > 2, !type.contains("【") {
                replies.append(ReplyOption(type: type, content: content))
                continue
            }
        }

        if trimmed.hasPrefix("【"), let closeRange = trimmed.range(of: "】") {
            let start = trimmed.index(after: trimmed.startIndex)
            let type = String(trimmed[start..<closeRange.lowerBound])
            let content = trimmed[closeRange.upperBound...].trimmingCharacters(in: .whitespaces)
            if content.count > 2 {
                replies.append(ReplyOption(type: type, content: content))
                continue
            }
        }

        if trimmed.count >= 4 && trimmed.count <= 50
            && !trimmed.contains("回复") && !trimmed.contains("以下") && !trimmed.contains("生成") {
            replies.append(ReplyOption(type: "选项", content: trimmed))
        }
    }

    if replies.isEmpty {
        for text in lines where text.trimmingCharacters(in: .whitespaces).count > 5
            && text.trimmingCharacters(in: .whitespaces).count < 100 {
            replies.append(ReplyOption(type: "选项\(replies.count + 1)", content: text.trimmingCharacters(in: .whitespaces)))
        }
    }

    return replies
}

// MARK: - Result History

public struct ResultHistoryEntry: Codable {
    public let input: String
    public let presetName: String
    public let replies: [ReplyOption]
    public let rawText: String
    public let timestamp: Date

    public init(input: String, presetName: String, replies: [ReplyOption], rawText: String, timestamp: Date) {
        self.input = input
        self.presetName = presetName
        self.replies = replies
        self.rawText = rawText
        self.timestamp = timestamp
    }

    public var preview: String {
        if !rawText.isEmpty { return rawText }
        return replies.first?.content ?? ""
    }

    public var relativeTime: String {
        let interval = -timestamp.timeIntervalSinceNow
        if interval < 60 { return "刚刚" }
        if interval < 3600 { return "\(Int(interval / 60))分钟前" }
        if interval < 86400 { return "\(Int(interval / 3600))小时前" }
        return "\(Int(interval / 86400))天前"
    }
}

public func loadResultHistory() -> [UUID: ResultHistoryEntry] {
    guard let data = UserDefaults.shared.data(forKey: "result_history"),
          let dict = try? JSONDecoder().decode([String: ResultHistoryEntry].self, from: data)
    else { return [:] }
    var result: [UUID: ResultHistoryEntry] = [:]
    for (key, value) in dict {
        if let uuid = UUID(uuidString: key) {
            result[uuid] = value
        }
    }
    return result
}

public func saveResultHistory(_ history: [UUID: ResultHistoryEntry]) {
    var dict: [String: ResultHistoryEntry] = [:]
    for (key, value) in history {
        dict[key.uuidString] = value
    }
    if let data = try? JSONEncoder().encode(dict) {
        UserDefaults.shared.set(data, forKey: "result_history")
    }
}
