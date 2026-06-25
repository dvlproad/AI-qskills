import Foundation

// MARK: - API Models

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ChatRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
}

struct ChatResponse: Codable {
    let choices: [Choice]
    let usage: Usage?
}

struct Choice: Codable {
    let message: ChatMessage
}

struct Usage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int

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

struct ReplyOption: Identifiable {
    let id = UUID()
    let type: String
    let content: String
}

// MARK: - Platform

struct ModelOption: Identifiable, Hashable {
    let id: String
    let name: String
    let inputPerM: Double
    let outputPerM: Double
    let isFree: Bool
}

struct Platform: Identifiable, Hashable {
    let id: String
    let name: String
    let endpoint: String
    let apiKeyHelpURL: String
    let pricingURL: String
    let inputPerM: Double
    let outputPerM: Double
    let currency: String
    var models: [ModelOption]?

    static let deepseek = Platform(
        id: "deepseek",
        name: "DeepSeek",
        endpoint: "https://api.deepseek.com/v1/chat/completions",
        apiKeyHelpURL: "https://platform.deepseek.com/",
        pricingURL: "https://api-docs.deepseek.com/quick_start/pricing",
        inputPerM: 0.28,
        outputPerM: 0.42,
        currency: "$"
    )

    static let siliconflow = Platform(
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

    static let all: [Platform] = [.deepseek, .siliconflow]
}

// MARK: - Parsing

func parseReplies(from text: String) -> [ReplyOption] {
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
