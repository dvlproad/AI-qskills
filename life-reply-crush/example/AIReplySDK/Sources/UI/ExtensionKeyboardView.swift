import SwiftUI

public enum KeyboardHeight {
    public static let `default`: CGFloat = 260
    public static let expanded: CGFloat = 480
    public static let overlay: CGFloat = 650
}

public struct ExtensionKeyboardView: View {
    let insertText: (String) -> Void
    let dismissKeyboard: () -> Void
    let setKeyboardHeight: (CGFloat) -> Void
    let onTokenUsage: ((Int, String) -> Void)?
    let showBottomBar: Bool
    let transparentBackground: Bool
    let showResultsInline: Bool
    let onResults: (([ReplyOption], String) -> Void)?
    let isInputEditable: Bool
    let onAddPreset: (() -> Void)?
    let onOpenSettings: (() -> Void)?
    let onOpenAppSettings: (() -> Void)?
    let hasFullAccess: Bool

    public init(insertText: @escaping (String) -> Void, dismissKeyboard: @escaping () -> Void, setKeyboardHeight: @escaping (CGFloat) -> Void, onTokenUsage: ((Int, String) -> Void)? = nil, showBottomBar: Bool = true, transparentBackground: Bool = false, showResultsInline: Bool = false, onResults: (([ReplyOption], String) -> Void)? = nil, isInputEditable: Bool = true, onAddPreset: (() -> Void)? = nil, onOpenSettings: (() -> Void)? = nil, onOpenAppSettings: (() -> Void)? = nil, hasFullAccess: Bool = true) {
        self.insertText = insertText
        self.dismissKeyboard = dismissKeyboard
        self.setKeyboardHeight = setKeyboardHeight
        self.onTokenUsage = onTokenUsage
        self.showBottomBar = showBottomBar
        self.transparentBackground = transparentBackground
        self.showResultsInline = showResultsInline
        self.onResults = onResults
        self.isInputEditable = isInputEditable
        self.onAddPreset = onAddPreset
        self.onOpenSettings = onOpenSettings
        self.onOpenAppSettings = onOpenAppSettings
        self.hasFullAccess = hasFullAccess
    }

    @State private var inputText = ""
    @State private var replies: [ReplyOption] = []
    @State private var rawResult = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showReplyPopup = false
    @State private var selectedPreset: PromptPreset = .default

    private static let fullAccessError = "需要先在 设置→通用→键盘→AI键盘 中开启「允许完全访问」，否则粘贴、复制、AI 生成等功能均不可用"

    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                inputArea
                presetBar
                if showBottomBar {
                    bottomBar
                }
            }
            .background(transparentBackground ? Color.clear : Color(.systemGray6))

            if showReplyPopup {
                replyPopup
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
            }

            if let error = errorMessage {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.white)
                        Text(error)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    HStack(spacing: 12) {
                        Button {
                            errorMessage = nil
                        } label: {
                            Text("取消")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(8)
                        }

                        Button {
                            dismissKeyboard()
                            if let error = errorMessage, error.contains("允许完全访问") {
                                errorMessage = nil
                                onOpenSettings?()
                            } else {
                                errorMessage = nil
                                onOpenAppSettings?()
                            }
                        } label: {
                            Text("去设置")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(Color(hex: "e74c3c"))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.bottom, 12)
                }
                .background(Color.red.opacity(0.9))
                .cornerRadius(10)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(2)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: showReplyPopup)
        .animation(.easeInOut(duration: 0.2), value: errorMessage != nil)
        .onChange(of: showReplyPopup) { show in
            setKeyboardHeight(show ? KeyboardHeight.expanded : KeyboardHeight.default)
        }
        .onAppear {
            loadPreset()
            if !hasFullAccess {
                errorMessage = Self.fullAccessError
            }
        }
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    if !showReplyPopup {
                        dismissKeyboard()
                    }
                }
        )
    }

    // MARK: - Preset Selector

    private var presetBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(PromptPreset.allPresets) { preset in
                    Button {
                        selectedPreset = preset
                        savePreset(preset)
                        inputText = preset.rawTextMode ? preset.placeholder : ""
                    } label: {
                        Text(preset.name)
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedPreset.id == preset.id ? Color.purple : Color(.systemGray4))
                            .foregroundColor(selectedPreset.id == preset.id ? .white : .secondary)
                            .cornerRadius(14)
                    }
                }
                Button {
                    if !hasFullAccess {
                        errorMessage = Self.fullAccessError
                    } else {
                        onAddPreset?()
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.caption2.weight(.medium))
                        .foregroundColor(.secondary)
                        .padding(6)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
    }

    // MARK: - Reply Popup

    private var replyPopup: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(.systemGray3))
                .frame(width: 36, height: 5)
                .padding(.top, 10)

            HStack {
                Text("结果")
                    .font(.headline)
                Spacer()
                Button {
                    showReplyPopup = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            if selectedPreset.rawTextMode {
                rawTextPopupContent
            } else {
                crushPopupContent
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                Color(.systemGray6)
                LinearGradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .opacity(0.06)
            }
        )
    }

    private var crushPopupContent: some View {
        ScrollView {
            ReplyGridView(replies: replies) { content in
                insertText(content)
                showReplyPopup = false
            }
            .padding()
        }
    }

    private var rawTextPopupContent: some View {
        ScrollView {
            RawResultView(text: rawResult, onCopy: { UIPasteboard.general.string = rawResult })
                .padding()
        }
    }

    // MARK: - Input Area

    private var inputArea: some View {
        InputPanelView(
            inputText: $inputText, isLoading: isLoading,
            hasGeneratedReplies: false, onGenerate: generate,
            title: selectedPreset.generateTitle,
            placeholder: selectedPreset.placeholder,
            isInputEditable: isInputEditable,
            onPasteFailure: {
                if !self.hasFullAccess {
                    self.errorMessage = Self.fullAccessError
                }
            }
        )
        .padding(8)
        .background(Color(.systemGray5).overlay(.regularMaterial))
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            Button {
                onOpenAppSettings?()
            } label: {
                Image(systemName: "gearshape")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .padding(8)
            }
            Spacer()
            Button {
                dismissKeyboard()
            } label: {
                Image(systemName: "keyboard.chevron.compact.down")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .padding(8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemGray5).overlay(.regularMaterial))
    }

    // MARK: - Preset Persistence

    private func loadPreset() {
        guard let data = UserDefaults.shared.data(forKey: "selected_preset"),
              let preset = try? JSONDecoder().decode(PromptPreset.self, from: data) else {
            selectedPreset = PromptPreset.allPresets.first ?? .default
            return
        }
        selectedPreset = PromptPreset.allPresets.first(where: { $0.id == preset.id }) ?? (PromptPreset.allPresets.first ?? .default)
    }

    private func savePreset(_ preset: PromptPreset) {
        guard let data = try? JSONEncoder().encode(preset) else { return }
        UserDefaults.shared.set(data, forKey: "selected_preset")
    }

    // MARK: - Generate

    private func generate() {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            inputText = selectedPreset.placeholder
        }
        errorMessage = nil
        let text = trimmed.isEmpty ? inputText : trimmed

        let savedID = UserDefaults.shared.string(forKey: "selected_platform") ?? "deepseek"
        guard Platform.all.first(where: { $0.id == savedID }) != nil else { return }
        let apiKey = savedID == "deepseek"
            ? (UserDefaults.shared.string(forKey: "api_key_deepseek") ?? "")
            : (UserDefaults.shared.string(forKey: "api_key_siliconflow") ?? "")
        guard !apiKey.isEmpty else { errorMessage = "请先在设置中配置 API Key"; return }

        let model: String = {
            switch savedID {
            case "siliconflow":
                return UserDefaults.shared.string(forKey: "selected_model_siliconflow") ?? "deepseek-ai/DeepSeek-V3.2"
            default:
                return UserDefaults.shared.string(forKey: "selected_model_deepseek") ?? "deepseek-chat"
            }
        }()

        isLoading = true
        replies = []
        rawResult = ""

        let preset = selectedPreset

        Task {
            do {
                let response = try await APIService.shared.generateReplies(
                    input: text, platformID: savedID, model: model, apiKey: apiKey,
                    systemPrompt: preset.systemPrompt,
                    userPromptTemplate: preset.userPromptTemplate
                )
                let content = response.choices.first?.message.content ?? ""
                if let usage = response.usage {
                    let platform = Platform.all.first(where: { $0.id == savedID }) ?? .deepseek
                    let promptCost = Double(usage.promptTokens) / 1_000_000 * platform.inputPerM
                    let completionCost = Double(usage.completionTokens) / 1_000_000 * platform.outputPerM
                    let totalCost = promptCost + completionCost
                    let converted = platform.currency == "$" ? totalCost * 7.2 : totalCost
                    let cost = "约 ¥\(String(format: "%.4f", converted))"
                    onTokenUsage?(usage.totalTokens, cost)
                }
                let rawText = selectedPreset.rawTextMode
                if rawText {
                    rawResult = content
                } else {
                    replies = parseReplies(from: content)
                }

                if showResultsInline {
                    onResults?(replies, rawResult)
                } else {
                    if rawText {
                        if content.isEmpty {
                            errorMessage = "AI 返回的内容格式异常，请重试"
                        } else {
                            showReplyPopup = true
                        }
                    } else if replies.isEmpty {
                        errorMessage = "AI 返回的内容格式异常，请重试"
                    } else {
                        showReplyPopup = true
                    }
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}


