import SwiftUI

struct SettingsView: View {
    @Binding var selectedPlatform: Platform
    @Binding var selectedModel: String

    @AppStorage("api_key_deepseek") private var deepseekKey = ""
    @AppStorage("api_key_siliconflow") private var siliconflowKey = ""

    @Environment(\.dismiss) private var dismiss

    private var currentKey: String {
        switch selectedPlatform.id {
        case "deepseek": return deepseekKey
        case "siliconflow": return siliconflowKey
        default: return ""
        }
    }

    private var platformKeyBinding: Binding<String> {
        Binding(
            get: { currentKey },
            set: { newValue in
                switch selectedPlatform.id {
                case "deepseek": deepseekKey = newValue
                case "siliconflow": siliconflowKey = newValue
                default: break
                }
            }
        )
    }

    private var modelOptions: [ModelOption] {
        selectedPlatform.models ?? []
    }

    var body: some View {
        NavigationStack {
            Form {
                platformSection
                if !modelOptions.isEmpty {
                    modelSection
                }
                apiKeySection
                pricingSection
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private var platformSection: some View {
        Section("平台选择") {
            Picker("平台", selection: $selectedPlatform) {
                ForEach(Platform.all) { platform in
                    Text(platform.name).tag(platform)
                }
            }
            .onChange(of: selectedPlatform) { newPlatform in
                selectedModel = newPlatform.models?.first?.id ?? newPlatform.id
            }
            Link(destination: URL(string: selectedPlatform.apiKeyHelpURL)!) {
                HStack {
                    Text("获取 API Key")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var modelSection: some View {
        Section("模型选择") {
            if let models = selectedPlatform.models {
                ForEach(models) { model in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(model.name)
                                .font(.body)
                            if model.isFree {
                                Text("免费")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        Spacer()
                        if selectedModel == model.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedModel = model.id
                    }
                }
            }
        }
    }

    private var apiKeySection: some View {
        Section("API Key") {
            SecureField("输入 API Key", text: platformKeyBinding)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Text("仅保存在本地设备，不上传服务器")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var pricingSection: some View {
        Section("定价信息") {
            if let selectedModelObj = modelOptions.first(where: { $0.id == selectedModel }) {
                if selectedModelObj.isFree {
                    Text("免费")
                } else {
                    pricingRow(selectedModelObj)
                }
            } else {
                pricingRow(nil)
            }
            if selectedPlatform.currency == "$" {
                Text("预计每次：约 ¥\((0.001 * selectedPlatform.inputPerM + 0.0005 * selectedPlatform.outputPerM) * 7.2, specifier: "%.2f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("预计每次：约 ¥\((0.001 * selectedPlatform.inputPerM + 0.0005 * selectedPlatform.outputPerM), specifier: "%.2f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Link("定价来源", destination: URL(string: selectedPlatform.pricingURL)!)
                .font(.caption)
        }
    }

    private func pricingRow(_ model: ModelOption?) -> some View {
        let input = model?.inputPerM ?? selectedPlatform.inputPerM
        let output = model?.outputPerM ?? selectedPlatform.outputPerM
        let symbol = selectedPlatform.currency == "$" ? "$" : "¥"
        return VStack(alignment: .leading, spacing: 2) {
            Text("输入：\(symbol)\(input, specifier: "%.2f")/M tokens")
            Text("输出：\(symbol)\(output, specifier: "%.2f")/M tokens")
        }
        .font(.subheadline)
    }
}
