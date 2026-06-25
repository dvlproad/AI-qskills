import SwiftUI

struct ContentView: View {
    @State private var inputText = ""
    @State private var replies: [ReplyOption] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var tokenCount: Int?
    @State private var tokenCost: String?

    @State private var selectedPlatform: Platform = .deepseek
    @State private var selectedModel = "deepseek-chat"

    @AppStorage("api_key_deepseek") private var deepseekKey = ""
    @AppStorage("api_key_siliconflow") private var siliconflowKey = ""

    @State private var showSettings = false
    @FocusState private var isInputFocused: Bool

    private let apiService = APIService.shared

    private var currentAPIKey: String {
        switch selectedPlatform.id {
        case "deepseek": return deepseekKey
        case "siliconflow": return siliconflowKey
        default: return ""
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    inputSection
                    if isLoading || !replies.isEmpty || errorMessage != nil {
                        modelInfoBar
                    }
                    if let count = tokenCount, let cost = tokenCost {
                        tokenBar(count: count, cost: cost)
                    }
                    if isLoading {
                        loadingView
                    } else if let error = errorMessage {
                        errorCard(error)
                    } else if !replies.isEmpty {
                        repliesGrid
                    } else {
                        emptyState
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { isInputFocused = false }
            }
            .scrollDismissesKeyboard(.immediately)
            .background(
                LinearGradient(
                    colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("聊天回复生成器")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(
                    selectedPlatform: $selectedPlatform,
                    selectedModel: $selectedModel
                )
            }
            .onAppear {
                let savedID = UserDefaults.standard.string(forKey: "selected_platform") ?? "deepseek"
                selectedPlatform = Platform.all.first(where: { $0.id == savedID }) ?? .deepseek
                switch savedID {
                case "siliconflow":
                    selectedModel = UserDefaults.standard.string(forKey: "selected_model_siliconflow") ?? "deepseek-ai/DeepSeek-V3.2"
                default:
                    selectedModel = UserDefaults.standard.string(forKey: "selected_model_deepseek") ?? "deepseek-chat"
                }
            }
            .onChange(of: selectedPlatform) { platform in
                UserDefaults.standard.set(platform.id, forKey: "selected_platform")
            }
            .onChange(of: selectedModel) { model in
                let key = selectedPlatform.id == "siliconflow" ? "selected_model_siliconflow" : "selected_model_deepseek"
                UserDefaults.standard.set(model, forKey: key)
            }
        }
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(spacing: 12) {
            Text("对方说了什么？")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField("我要去洗澡了", text: $inputText)
                .font(.body)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
                .focused($isInputFocused)
                .onSubmit { generate() }

            Button(action: generate) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("思考中...")
                    } else {
                        Text(replies.isEmpty ? "✨ AI 生成回复" : "✨ 重新生成")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "9333ea"), Color(hex: "ec4899")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
            }
            .disabled(isLoading)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
    }

    // MARK: - Info Bar

    private var modelInfoBar: some View {
        Text("使用平台：\(selectedPlatform.name) | 模型：\(modelDisplayName)")
            .font(.caption)
            .foregroundColor(.white.opacity(0.7))
            .frame(maxWidth: .infinity)
    }

    private var modelDisplayName: String {
        if let models = selectedPlatform.models,
           let model = models.first(where: { $0.id == selectedModel }) {
            return model.name
        }
        return selectedModel
    }

    // MARK: - Token Usage

    private func tokenBar(count: Int, cost: String) -> some View {
        Text("本次消耗：\(count) tokens (\(cost))")
            .font(.caption)
            .foregroundColor(.white.opacity(0.6))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(.ultraThinMaterial)
            .cornerRadius(8)
    }

    // MARK: - Loading

    private var loadingView: some View {
        ForEach(0..<4, id: \.self) { _ in
            skeletonCard
        }
    }

    private var skeletonCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.3))
                .frame(width: 80, height: 20)
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.2))
                .frame(height: 16)
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.2))
                .frame(width: 200, height: 16)
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    // MARK: - Error

    private func errorCard(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text("😢")
                .font(.system(size: 40))
            Text("生成失败")
                .font(.headline)
                .foregroundColor(.red)
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("💭")
                .font(.system(size: 60))
            Text("输入对方说的话，开启你的社交自由")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.top, 40)
    }

    // MARK: - Replies Grid

    private var repliesGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(Array(replies.enumerated()), id: \.element.id) { index, reply in
                replyCard(reply, index: index)
            }
        }
    }

    private func replyCard(_ reply: ReplyOption, index: Int) -> some View {
        let gradient = cardGradients[index % cardGradients.count]
        return VStack(alignment: .leading, spacing: 12) {
            Text(reply.type)
                .font(.headline)
                .foregroundColor(.white)

            Text(reply.content)
                .font(.body)
                .foregroundColor(.white.opacity(0.95))
                .lineLimit(4)

            Button {
                UIPasteboard.general.string = reply.content
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            } label: {
                HStack {
                    Image(systemName: "doc.on.doc")
                    Text("复制回复")
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.2))
                .cornerRadius(8)
            }
        }
        .padding(20)
        .background(
            LinearGradient(colors: [gradient.0, gradient.1], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(16)
        .shadow(color: gradient.0.opacity(0.3), radius: 8, y: 4)
    }

    // MARK: - Generate

    private func generate() {
        isInputFocused = false
        errorMessage = nil

        let text = inputText.trimmingCharacters(in: .whitespaces).isEmpty
            ? "我要去洗澡了"
            : inputText.trimmingCharacters(in: .whitespaces)

        guard !currentAPIKey.isEmpty else {
            errorMessage = "请先在设置中配置 \(selectedPlatform.name) API Key"
            showSettings = true
            return
        }

        isLoading = true
        replies = []
        tokenCount = nil
        tokenCost = nil

        Task {
            do {
                let response = try await apiService.generateReplies(
                    input: text,
                    platformID: selectedPlatform.id,
                    model: selectedModel,
                    apiKey: currentAPIKey
                )

                let content = response.choices.first?.message.content ?? ""
                replies = parseReplies(from: content)

                if let usage = response.usage {
                    tokenCount = usage.totalTokens
                    let promptCost = Double(usage.promptTokens) / 1_000_000 * selectedPlatform.inputPerM
                    let completionCost = Double(usage.completionTokens) / 1_000_000 * selectedPlatform.outputPerM
                    let totalCost = promptCost + completionCost
                    let converted = selectedPlatform.currency == "$" ? totalCost * 7.2 : totalCost
                    tokenCost = "约 ¥\(String(format: "%.4f", converted))"
                }

                if replies.isEmpty {
                    errorMessage = "AI 返回的内容格式异常，请重试"
                }
            } catch {
                errorMessage = error.localizedDescription
            }

            isLoading = false
        }
    }
}
