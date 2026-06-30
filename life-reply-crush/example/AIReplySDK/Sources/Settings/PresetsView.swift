import SwiftUI

public struct PresetsView: View {
    @Environment(\.dismiss) private var dismiss
    let onDismiss: (() -> Void)?

    public init(onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
    }

    @State private var builtinPresets = PromptPreset.builtinPresets
    @State private var customPresets: [PromptPreset] = []
    @State private var editingPreset: PromptPreset?
    @State private var creatingPreset = false

    public var body: some View {
        NavigationStack {
            List {
                Section("内置预设") {
                    ForEach(builtinPresets) { preset in
                        Button {
                            editingPreset = preset
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(preset.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(preset.systemPrompt.replacingOccurrences(of: "\n", with: " ").prefix(80))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                if !customPresets.isEmpty {
                    Section("自定义预设") {
                        ForEach(customPresets) { preset in
                            Button {
                                editingPreset = preset
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(preset.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(preset.systemPrompt.replacingOccurrences(of: "\n", with: " ").prefix(80))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete(perform: deleteCustomPresets)
                    }
                }
            }
            .navigationTitle("提示词管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { saveAndDismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editingPreset = PromptPreset(name: "", systemPrompt: "", userPromptTemplate: "对方说：{input}\n\n请生成6-8个不同的回复选项，每个回复一行，格式为：类型: 回复内容")
                        creatingPreset = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $editingPreset) { preset in
                PresetEditorView(preset: preset, isNew: creatingPreset, onSave: { updated in
                    if creatingPreset {
                        customPresets.append(updated)
                    } else if let idx = builtinPresets.firstIndex(where: { $0.id == preset.id }) {
                        builtinPresets[idx] = updated
                    } else if let idx = customPresets.firstIndex(where: { $0.id == preset.id }) {
                        customPresets[idx] = updated
                    }
                })
            }
            .onAppear {
                customPresets = PromptPreset.customPresets
            }
        }
    }

    private func deleteCustomPresets(at offsets: IndexSet) {
        customPresets.remove(atOffsets: offsets)
    }

    private func saveAndDismiss() {
        PromptPreset.customPresets = customPresets
        if let onDismiss { onDismiss() } else { dismiss() }
    }
}

public struct PresetEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let preset: PromptPreset
    let isNew: Bool
    let onSave: (PromptPreset) -> Void

    @State private var name: String = ""
    @State private var systemPrompt: String = ""
    @State private var userPromptTemplate: String = ""

    public init(preset: PromptPreset, isNew: Bool = false, onSave: @escaping (PromptPreset) -> Void) {
        self.preset = preset
        self.isNew = isNew
        self.onSave = onSave
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("名称") {
                    TextField("预设名称", text: $name)
                }
                Section("系统提示词（给 AI 的角色设定）") {
                    TextEditor(text: $systemPrompt)
                        .font(.subheadline)
                        .frame(minHeight: 150)
                }
                Section("用户提示词模板（{input} 会被替换为对方说的话）") {
                    TextEditor(text: $userPromptTemplate)
                        .font(.subheadline)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle(isNew ? "新建预设" : "编辑预设")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let updated = PromptPreset(
                            id: isNew ? UUID() : preset.id,
                            name: name,
                            systemPrompt: systemPrompt,
                            userPromptTemplate: userPromptTemplate
                        )
                        onSave(updated)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                name = preset.name
                systemPrompt = preset.systemPrompt
                userPromptTemplate = preset.userPromptTemplate
            }
        }
    }
}
