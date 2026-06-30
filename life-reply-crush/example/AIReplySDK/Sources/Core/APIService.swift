import Foundation

public enum APIError: LocalizedError {
    case noAPIKey
    case invalidResponse
    case requestFailed(statusCode: Int, message: String)
    case decodingFailed

    public var errorDescription: String? {
        switch self {
        case .noAPIKey: return "请先配置 API Key"
        case .invalidResponse: return "服务器返回无效响应"
        case .requestFailed(let code, let message): return "请求失败 (\(code)): \(message)"
        case .decodingFailed: return "数据解析失败"
        }
    }
}

public actor APIService {
    public static let shared = APIService()
    private init() {}

    public func generateReplies(input: String, platformID: String, model: String, apiKey: String, systemPrompt: String? = nil, userPromptTemplate: String? = nil) async throws -> ChatResponse {
        guard let platform = Platform.all.first(where: { $0.id == platformID }) else {
            throw APIError.requestFailed(statusCode: 0, message: "未知平台")
        }

        let prompt = systemPrompt ?? PromptPreset.default.systemPrompt
        let userMessage = userPromptTemplate?.replacingOccurrences(of: "{input}", with: input)
            ?? PromptPreset.default.userPromptTemplate.replacingOccurrences(of: "{input}", with: input)

        let url = URL(string: platform.endpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60

        let chatRequest = ChatRequest(
            model: model,
            messages: [
                ChatMessage(role: "system", content: prompt),
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
