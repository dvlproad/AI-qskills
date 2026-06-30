import SwiftUI
import UIKit

/// Adds a UITapGestureRecognizer to the window so taps on blank areas
/// dismiss the keyboard without consuming touches from Form controls.
private struct DismissingTapHelper: UIViewRepresentable {
    let onTap: () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        context.coordinator.install(on: view)
        return view
    }

    func updateUIView(_: UIView, context _: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onTap: onTap) }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        static let gestureName = "com.aireply.dismissKeyboard"
        let onTap: () -> Void
        weak var window: UIWindow?

        init(onTap: @escaping () -> Void) { self.onTap = onTap }

        func install(on view: UIView) {
            guard let window = view.window else {
                DispatchQueue.main.async { [weak self, weak view] in
                    guard let self = self, let view = view else { return }
                    self.install(on: view)
                }
                return
            }
            self.window = window
            let existing = window.gestureRecognizers?.contains(where: { $0.name == Self.gestureName }) == true
            if existing { return }
            let tap = UITapGestureRecognizer(target: self, action: #selector(dismiss))
            tap.cancelsTouchesInView = false
            tap.name = Self.gestureName
            tap.delegate = self
            window.addGestureRecognizer(tap)
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            // Don't intercept touches on text fields so they can be focused normally
            !(touch.view is UITextField)
        }

        @objc func dismiss() { onTap() }

        deinit {
            window?.gestureRecognizers?
                .filter { $0.name == Self.gestureName }
                .forEach { window?.removeGestureRecognizer($0) }
        }
    }
}

public struct SettingsView: View {
    @Binding var selectedPlatform: Platform
    @Binding var selectedModel: String
    let onDismiss: (() -> Void)?

    @AppStorage("api_key_deepseek", store: .shared) private var deepseekKey = ""
    @AppStorage("api_key_siliconflow", store: .shared) private var siliconflowKey = ""
    @FocusState private var focusedField: Bool

    public init(selectedPlatform: Binding<Platform>, selectedModel: Binding<String>, onDismiss: (() -> Void)? = nil) {
        self._selectedPlatform = selectedPlatform
        self._selectedModel = selectedModel
        self.onDismiss = onDismiss
    }

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

    public var body: some View {
        NavigationStack {
            Form {
                platformSection
                if !modelOptions.isEmpty {
                    modelSection
                }
                apiKeySection
                pricingSection
            }
            .scrollDismissesKeyboard(.immediately)
            .background(DismissingTapHelper(onTap: { focusedField = false }))
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { focusedField = false; if let onDismiss { onDismiss() } else { dismiss() } }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") { focusedField = false }
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
                .focused($focusedField)
                .onSubmit { focusedField = false }
            Text("仅保存在本地设备，不上传服务器")
                .font(.caption)
                .foregroundColor(.secondary)
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
