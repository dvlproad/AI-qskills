import SwiftUI
import AIReplySDK

struct ContentView: View {
    @State private var replies: [ReplyOption] = []
    @State private var rawResult = ""
    @State private var tokenInfo: (count: Int, cost: String)?
    @State private var showSettings = false
    @State private var settingsPlatform: Platform = {
        let id = UserDefaults.shared.string(forKey: "selected_platform") ?? "deepseek"
        return Platform.all.first { $0.id == id } ?? .deepseek
    }()
    @State private var settingsModel: String = {
        let id = UserDefaults.shared.string(forKey: "selected_platform") ?? "deepseek"
        return UserDefaults.shared.string(forKey: "selected_model_\(id)") ?? "deepseek-chat"
    }()
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    setupInstructionsView

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
                        }
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

                    if !rawResult.isEmpty {
                        emojiResultView
                    } else if !replies.isEmpty {
                        repliesGrid
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

    private var emojiResultView: some View {
        RawResultView(text: rawResult, onCopy: { UIPasteboard.general.string = rawResult })
    }

    private var repliesGrid: some View {
        ReplyGridView(replies: replies) { content in
            UIPasteboard.general.string = content
        }
    }

    // MARK: - Setup Instructions

    private var setupInstructionsView: some View {
        SetupInstructionsView(keyboardName: "AI键盘")
    }
}
