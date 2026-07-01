import SwiftUI
import AIReplySDK

struct ContentView: View {
    @State private var replies: [ReplyOption] = []
    @State private var rawResult = ""
    @State private var tokenInfo: (count: Int, cost: String)?
    @State private var showSettings = false
    @State private var showPresets = false
    @State private var settingsPlatform: Platform = {
        let id = UserDefaults.shared.string(forKey: "selected_platform") ?? "deepseek"
        return Platform.all.first { $0.id == id } ?? .deepseek
    }()
    @State private var settingsModel: String = {
        let id = UserDefaults.shared.string(forKey: "selected_platform") ?? "deepseek"
        return UserDefaults.shared.string(forKey: "selected_model_\(id)") ?? "deepseek-chat"
    }()
    @State private var testCopyText = ""
    @State private var copiedFeedback: String?
    @State private var showClipboardHistory = false
    @State private var resultHistory: [UUID: ResultHistoryEntry] = loadResultHistory()
    @State private var showHistoryList = false
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    setupInstructionsView

                    NavigationLink {
                        TextSelectionTestView()
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                            Text("长按选字测试")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    clipboardTestSection

                    ExtensionKeyboardView(
                        insertText: { text in
                            UIPasteboard.general.string = text
                        },
                        dismissKeyboard: {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        },
                        setKeyboardHeight: { _ in },
                        onTokenUsage: { count, cost in
                            tokenInfo = (count, cost)
                        },
                        showBottomBar: false,
                        transparentBackground: true,
                        showResultsInline: true,
                        onResults: { r, raw in
                            replies = r
                            rawResult = raw
                            resultHistory = loadResultHistory()
                        },
                        isInputEditable: true,
                        onAddPreset: { showPresets = true },
                        onShowClipboardHistory: { showClipboardHistory = true },
                        hasFullAccess: true
                    )
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 4)

                    if !replies.isEmpty || !rawResult.isEmpty {
                        modelInfoBar
                    }

                    if let info = tokenInfo {
                        tokenBar(count: info.count, cost: info.cost)
                    }

                    if !replies.isEmpty || !rawResult.isEmpty {
                        ResultContentView(
                            replies: replies,
                            rawText: rawResult,
                            rawTextMode: !rawResult.isEmpty,
                            onCopy: { UIPasteboard.general.string = $0 }
                        )
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.immediately)
            .simultaneousGesture(
                TapGesture().onEnded {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            )
            .background(
                LinearGradient(
                    colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("AI 回复生成器")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        resultHistory = loadResultHistory()
                        showHistoryList = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(selectedPlatform: $settingsPlatform, selectedModel: $settingsModel)
            }
            .sheet(isPresented: $showPresets) {
                PresetsView()
            }
            .sheet(isPresented: $showClipboardHistory) {
                clipboardHistoryView
            }
            .sheet(isPresented: $showHistoryList) {
                historyListView
            }
            .onOpenURL { url in
                if url.scheme == "aireply" {
                    switch url.host {
                    case "presets": showPresets = true
                    case "settings": showSettings = true
                    default: break
                    }
                }
            }
            .onAppear {
                resultHistory = loadResultHistory()
            }
            .onChange(of: scenePhase) { phase in
                if phase == .active {
                    resultHistory = loadResultHistory()
                }
            }
            .onChange(of: settingsPlatform) { platform in
                UserDefaults.shared.set(platform.id, forKey: "selected_platform")
            }
            .onChange(of: settingsModel) { model in
                let key = settingsPlatform.id == "siliconflow" ? "selected_model_siliconflow" : "selected_model_deepseek"
                UserDefaults.shared.set(model, forKey: key)
            }
        }
    }

    // MARK: - Info Bar

    private var modelInfoBar: some View {
        Text("使用平台：\(settingsPlatform.name) | 模型：\(modelDisplayName)")
            .font(.caption)
            .foregroundColor(.white.opacity(0.7))
            .frame(maxWidth: .infinity)
    }

    private var modelDisplayName: String {
        if let models = settingsPlatform.models,
           let model = models.first(where: { $0.id == settingsModel }) {
            return model.name
        }
        return settingsModel
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

    // MARK: - Results

    // MARK: - Clipboard History Sheet

    private var clipboardHistoryView: some View {
        NavigationStack {
            ClipboardHistoryListView(
                items: loadClipboardHistory(),
                actionTitle: "复制",
                onAction: { UIPasteboard.general.string = $0 },
                onDelete: { indexSet in
                    var h = loadClipboardHistory()
                    h.remove(atOffsets: indexSet)
                    saveClipboardHistory(h)
                }
            )
            .navigationTitle("剪贴板历史")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { showClipboardHistory = false }
                }
            }
        }
    }

    // MARK: - Clipboard Test

    private var clipboardTestSection: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "hammer.fill")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Text("剪贴板测试")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                Spacer()
                if let feedback = copiedFeedback {
                    Text(feedback)
                        .font(.caption.weight(.medium))
                        .foregroundColor(Color.green)
                        .transition(.opacity)
                }
            }

            HStack(spacing: 8) {
                TextField("输入要复制的文字...", text: $testCopyText)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
                    .foregroundColor(.white)

                Button {
                    let text = testCopyText.trimmingCharacters(in: .whitespaces)
                    guard !text.isEmpty else { return }
                    UIPasteboard.general.string = text
                    showCopied(text)
                } label: {
                    Text("复制")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.purple)
                        .cornerRadius(8)
                }
                .disabled(testCopyText.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(testPresets, id: \.self) { text in
                        Button {
                            UIPasteboard.general.string = text
                            showCopied(text)
                        } label: {
                            Text(text)
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(10)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    private let testPresets = [
        "我要去洗澡了",
        "在干嘛呢",
        "想你了",
        "刚刚在忙",
        "今天天气不错",
        "晚安",
        "哈哈",
        "？",
    ]

    private func showCopied(_ text: String) {
        let preview = text.count > 15 ? String(text.prefix(15)) + "..." : text
        copiedFeedback = "已复制「\(preview)」"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { copiedFeedback = nil }
        }
    }

    // MARK: - History

    private var historyListView: some View {
        NavigationStack {
            historyListContent
                .navigationTitle("历史结果")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("关闭") { showHistoryList = false }
                    }
                }
        }
    }

    private var historyListContent: some View {
        Group {
            if resultHistory.isEmpty {
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
                List {
                    ForEach(resultHistory.sorted(by: { $0.value.timestamp > $1.value.timestamp }), id: \.key) { id, entry in
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
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private func loadHistoryResult(id: UUID, entry: ResultHistoryEntry) {
        replies = entry.replies
        rawResult = entry.rawText
        showHistoryList = false
    }

    private var setupInstructionsView: some View {
        SetupInstructionsView(keyboardName: "AI键盘")
    }
}
