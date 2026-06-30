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

public struct ReplyOption: Identifiable {
    public let id = UUID()
    public let type: String
    public let content: String

    public init(type: String, content: String) {
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

        核心目标：回复要有情绪价值——能让对方笑、让对方脸红、让对方想继续聊。

        核心方向（这些是底线和方向，不是限制）：
        1. 上位者姿态：回复要体现出"我是主动方，我是在引导这段互动"
        2. 轻占有感：用暗示的方式，比如"从小就没老婆的"暗示对方愿意做你老婆
        3. 避免备胎感：不暴露过度等待或情绪依赖
        4. 拒绝土味和刻意撩：不用"小傻瓜""坏蛋"这类词
        5. 有钩子但不说破：创造一个对方回来后可以自然接住的小情境

        规则：每次生成 6-8 个回复，1-2句话，必须让她想接话
        """,
        placeholder: "我要去洗澡了",
        generateTitle: "对方说了什么？",
        rawTextMode: false
    )

    public static let emojiIdiom = PromptPreset(
        name: "Emoji 猜成语",
        systemPrompt: """
        你是一个看图猜成语的高手，擅长根据表情符号（emoji）的本义、谐音、象形/引申来推断成语。

        每个 emoji 对应成语中的一个字，通过以下三种方式匹配：
        1. 本义法：利用 emoji 本身代表的含义，如 🐯 → 虎
        2. 谐音法：利用 emoji 名称或含义的读音，包括同音字和近音字
        3. 象形/引申法：利用 emoji 的形状、动作或联想来暗示

        解读原则：
        - 解读应合理：该 emoji 与对应字的关联应当能被理解
        - 一字一符优先：尽量保证每个 emoji 对应成语中的一个字
        - 优先选择解读更直接的组合

        响应流程：
        1. 逐一拆解每个 emoji 的可能含义（本义、谐音、象形/引申）
        2. 组合尝试：将每个 emoji 的多种可能含义进行排列组合，列出所有合理的成语选项
        3. 筛选排序：对选项进行匹配度排序（高/中/低）

        输出时先给出匹配度最高的成语并解释思路，再补充其他可能的成语。
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
