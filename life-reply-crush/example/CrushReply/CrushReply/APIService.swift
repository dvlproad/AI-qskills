import Foundation

enum APIError: LocalizedError {
    case noAPIKey
    case invalidResponse
    case requestFailed(statusCode: Int, message: String)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .noAPIKey: return "请先配置 API Key"
        case .invalidResponse: return "服务器返回无效响应"
        case .requestFailed(let code, let message): return "请求失败 (\(code)): \(message)"
        case .decodingFailed: return "数据解析失败"
        }
    }
}

actor APIService {
    static let shared = APIService()
    private init() {}

    func generateReplies(input: String, platformID: String, model: String, apiKey: String) async throws -> ChatResponse {
        guard let platform = Platform.all.first(where: { $0.id == platformID }) else {
            throw APIError.requestFailed(statusCode: 0, message: "未知平台")
        }

        let systemPrompt = """
        你是一个情商大师，专门帮用户用幽默撩人、有情绪张力的方式回复 crush 的消息。

        核心目标：回复要有情绪价值——能让对方笑、让对方脸红、让对方想继续聊。

        核心方向（这些是底线和方向，不是限制）：
        1. 上位者姿态：回复要体现出"我是主动方，我是在引导这段互动"
        2. 轻占有感：用暗示的方式，比如"从小就没老婆的"暗示对方愿意做你老婆
        3. 避免备胎感：不暴露过度等待或情绪依赖
        4. 拒绝土味和刻意撩：不用"小傻瓜""坏蛋"这类词
        5. 有钩子但不说破：创造一个对方回来后可以自然接住的小情境

        规则：每次生成 6-8 个回复，1-2句话，必须让她想接话
        """

        let userMessage = "crush：\(input)\n\n请生成6-8个不同的回复选项，每个回复一行，格式为：类型: 回复内容"

        let url = URL(string: platform.endpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60

        let chatRequest = ChatRequest(
            model: model,
            messages: [
                ChatMessage(role: "system", content: systemPrompt),
                ChatMessage(role: "user", content: userMessage)
            ],
            temperature: 0.9
        )

        request.httpBody = try JSONEncoder().encode(chatRequest)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data),
               let message = errorResponse.error?.message {
                throw APIError.requestFailed(statusCode: httpResponse.statusCode, message: message)
            }
            let body = String(data: data, encoding: .utf8) ?? "未知错误"
            throw APIError.requestFailed(statusCode: httpResponse.statusCode, message: body)
        }

        do {
            return try JSONDecoder().decode(ChatResponse.self, from: data)
        } catch {
            throw APIError.decodingFailed
        }
    }
}
