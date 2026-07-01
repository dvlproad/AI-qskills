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
    let onShowClipboardHistory: (() -> Void)?
    let hasFullAccess: Bool
    let bottomBarRightExtra: AnyView?

    public init(
        insertText: @escaping (String) -> Void,
        dismissKeyboard: @escaping () -> Void,
        setKeyboardHeight: @escaping (CGFloat) -> Void,
        onTokenUsage: ((Int, String) -> Void)? = nil,
        showBottomBar: Bool = true,
        transparentBackground: Bool = false,
        showResultsInline: Bool = false,
        onResults: (([ReplyOption], String) -> Void)? = nil,
        isInputEditable: Bool,
        onAddPreset: (() -> Void)? = nil,
        onOpenSettings: (() -> Void)? = nil,
        onOpenAppSettings: (() -> Void)? = nil,
        onShowClipboardHistory: (() -> Void)? = nil,
        hasFullAccess: Bool,
        bottomBarRightExtra: AnyView? = nil
    ) {
        self.insertText = insertText
        self.dismissKeyboard = dismissKeyboard
        self.setKeyboardHeight = setKeyboardHeight
        self.onTokenUsage = onTokenUsage
        self.showBottomBar = showBottomBar
        self.bottomBarRightExtra = bottomBarRightExtra
        self.transparentBackground = transparentBackground
        self.showResultsInline = showResultsInline
        self.onResults = onResults
        self.isInputEditable = isInputEditable
        self.onAddPreset = onAddPreset
        self.onOpenSettings = onOpenSettings
        self.onOpenAppSettings = onOpenAppSettings
        self.onShowClipboardHistory = onShowClipboardHistory
        self.hasFullAccess = hasFullAccess
    }

    @State private var inputText = ""
    @State private var replies: [ReplyOption] = []
    @State private var rawResult = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showReplyPopup = false
    @State private var showClipboardPopup = false
    @State private var showHistoryList = false
    @State private var selectedPreset: PromptPreset = .default
    @State private var clipboardSuggestions: [String] = []
    @State private var clipboardTimer: Timer?
    @State private var countdown = 2
    @State private var resultHistory: [UUID: ResultHistoryEntry] = [:]
    @State private var cachedPresetId: UUID?
    @Environment(\.scenePhase) private var scenePhase

    private var historyItems: [(UUID, ResultHistoryEntry)] {
        resultHistory.sorted { $0.value.timestamp > $1.value.timestamp }
    }

    private static let fullAccessError = "需要先在 设置→通用→键盘→AI键盘 中开启「允许完全访问」，否则粘贴、复制、AI 生成等功能均不可用"

    private var isExtension: Bool {
        Bundle.main.bundleURL.pathExtension == "appex"
    }

    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                inputArea
                presetBar
                if showBottomBar {
                    defaultBottomBar
                }
            }
            .background(transparentBackground ? Color.clear : Color(.systemGray6))

            if showReplyPopup {
                replyPopup
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
            }

            if showClipboardPopup {
                clipboardPopup
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
            }

            if showHistoryList {
                historyListPopup
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
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: showClipboardPopup)
        .animation(.easeInOut(duration: 0.2), value: errorMessage != nil)
        .onChange(of: showReplyPopup) { show in
            setKeyboardHeight(show ? KeyboardHeight.expanded : KeyboardHeight.default)
        }
        .onChange(of: showClipboardPopup) { show in
            setKeyboardHeight(show ? KeyboardHeight.expanded : KeyboardHeight.default)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                checkClipboard()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIPasteboard.changedNotification)) { _ in
            checkClipboard()
        }
        .onAppear {
            loadPreset()
            loadHistory()
            if !hasFullAccess {
                errorMessage = Self.fullAccessError
            }
            clipboardSuggestions = loadClipboardHistory()
            checkClipboard()
            if isExtension {
                countdown = 2
                clipboardTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    if countdown <= 0 {
                        checkClipboard()
                        countdown = 2
                    } else {
                        countdown -= 1
                    }
                }
            }
        }
        .onDisappear {
            clipboardTimer?.invalidate()
            clipboardTimer = nil
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
                    Image(systemName: "pencil")
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

            resultContent
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

    private var resultContent: some View {
        ScrollView {
            ResultContentView(
                replies: replies,
                rawText: rawResult,
                rawTextMode: selectedPreset.rawTextMode,
                onCopy: { text in
                    insertText(text)
                    showReplyPopup = false
                }
            )
            .padding()
        }
    }

    // MARK: - Clipboard Popup (Extension)

    private var clipboardPopup: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(.systemGray3))
                .frame(width: 36, height: 5)
                .padding(.top, 10)

            HStack {
                Text("剪贴板历史")
                    .font(.headline)
                Spacer()
                Button {
                    showClipboardPopup = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            ClipboardHistoryListView(
                items: loadClipboardHistory(),
                actionTitle: "粘贴",
                onAction: { text in
                    insertText(text)
                    showClipboardPopup = false
                }
            )

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

    // MARK: - Input Area

    private var inputArea: some View {
        VStack(spacing: 6) {
            if !clipboardSuggestions.isEmpty {
                ClipboardSuggestionView(
                    items: clipboardSuggestions,
                    isPolling: isExtension,
                    countdown: countdown,
                    onTap: { text in
                        inputText = text
                    },
                    onMore: isExtension
                        ? { showClipboardPopup = true }
                        : onShowClipboardHistory
                )
                .padding(.top, 2)
            }

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
                },
                trailingContent: { historyMenuButton }
            )
        }
        .padding(8)
        .background(Color(.systemGray5).overlay(.regularMaterial))
    }

    // MARK: - Default Bottom Bar

    private var defaultBottomBar: some View {
        HStack {
            if onOpenAppSettings != nil {
                Button {
                    onOpenAppSettings?()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(8)
                }
            }

            if onOpenSettings != nil {
                Button {
                    onOpenSettings?()
                } label: {
                Image(systemName: "keyboard.fill")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .padding(8)
                }
            }

            Spacer()
            if let bottomBarRightExtra {
                bottomBarRightExtra
            }
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

    // MARK: - Clipboard

    private func checkClipboard() {
        guard hasFullAccess else { return }
        let currentChangeCount = UIPasteboard.general.changeCount
        let saved = UserDefaults.shared.integer(forKey: "last_clipboard_change_count")
        guard currentChangeCount != saved else { return }
        UserDefaults.shared.set(currentChangeCount, forKey: "last_clipboard_change_count")
        guard let string = UIPasteboard.general.string, !string.isEmpty else { return }
        var history = loadClipboardHistory()
        history = history.filter { $0 != string }
        history.insert(string, at: 0)
        if history.count > 3 { history = Array(history.prefix(3)) }
        saveClipboardHistory(history)
        DispatchQueue.main.async {
            self.clipboardSuggestions = history
        }
    }

    private func loadClipboardHistory() -> [String] {
        guard let data = UserDefaults.shared.data(forKey: "clipboard_history"),
              let history = try? JSONDecoder().decode([String].self, from: data) else { return [] }
        return history
    }

    private func saveClipboardHistory(_ history: [String]) {
        guard let data = try? JSONEncoder().encode(history) else { return }
        UserDefaults.shared.set(data, forKey: "clipboard_history")
        DispatchQueue.main.async {
            self.clipboardSuggestions = history
        }
    }

    private func removeClipboardItem(_ text: String) {
        var history = loadClipboardHistory()
        history.removeAll { $0 == text }
        saveClipboardHistory(history)
    }

    // MARK: - History Persistence

    private func loadHistory() {
        resultHistory = loadResultHistory()
    }

    private func saveHistory() {
        saveResultHistory(resultHistory)
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
        cachedPresetId = nil

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
                cachedPresetId = selectedPreset.id
                resultHistory[selectedPreset.id] = ResultHistoryEntry(
                    input: text,
                    presetName: selectedPreset.name,
                    replies: replies,
                    rawText: rawResult,
                    timestamp: Date()
                )
                saveHistory()

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

    private var historyMenuButton: some View {
        Button {
            showHistoryList = true
        } label: {
            Image(systemName: "clock.arrow.circlepath")
                .font(.body)
                .foregroundColor(historyItems.isEmpty ? .secondary.opacity(0.4) : .purple)
        }
        .disabled(historyItems.isEmpty)
    }

    private var historyListPopup: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(.systemGray3))
                .frame(width: 36, height: 5)
                .padding(.top, 10)

            HStack {
                Text("历史结果")
                    .font(.headline)
                Spacer()
                Button {
                    showHistoryList = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            if historyItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.largeTitle)
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("暂无历史记录")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(historyItems, id: \.0) { id, entry in
                            historyRow(id: id, entry: entry)
                        }
                    }
                    .padding()
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGray6))
    }

    private func historyRow(id: UUID, entry: ResultHistoryEntry) -> some View {
        Button {
            loadHistoryResult(id: id, entry: entry)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.input)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(entry.presetName)
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                    Text(entry.preview)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Text(entry.relativeTime)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private func loadHistoryResult(id: UUID, entry: ResultHistoryEntry) {
        replies = entry.replies
        rawResult = entry.rawText
        selectedPreset = PromptPreset.allPresets.first(where: { $0.id == id }) ?? selectedPreset
        cachedPresetId = id
        showHistoryList = false
        showReplyPopup = true
    }
}


