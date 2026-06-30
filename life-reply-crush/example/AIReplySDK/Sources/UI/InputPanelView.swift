import SwiftUI

public struct InputPanelView: View {
    @Binding var inputText: String
    let isLoading: Bool
    let hasGeneratedReplies: Bool
    let onGenerate: () -> Void
    var title: String = "对方说了什么？"
    var placeholder: String = "我要去洗澡了"
    var isInputEditable: Bool
    var onPasteFailure: (() -> Void)?
    @FocusState private var isFocused: Bool

    public init(inputText: Binding<String>, isLoading: Bool, hasGeneratedReplies: Bool, onGenerate: @escaping () -> Void, title: String = "对方说了什么？", placeholder: String = "我要去洗澡了", isInputEditable: Bool = true, onPasteFailure: (() -> Void)? = nil) {
        self._inputText = inputText
        self.isLoading = isLoading
        self.hasGeneratedReplies = hasGeneratedReplies
        self.onGenerate = onGenerate
        self.title = title
        self.placeholder = placeholder
        self.isInputEditable = isInputEditable
        self.onPasteFailure = onPasteFailure
    }

    public var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                TextField(isInputEditable ? placeholder : "点击右侧按钮粘贴", text: $inputText)
                    .font(.body)
                    .padding()
                    .padding(.trailing, isInputEditable && !inputText.isEmpty ? 32 : 0)
                    .background(isInputEditable ? Color(.systemBackground) : Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isInputEditable ? Color.purple.opacity(0.3) : Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                    .overlay(alignment: .trailing) {
                        if isInputEditable && !inputText.isEmpty {
                            Button {
                                inputText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.body)
                                    .foregroundColor(.secondary.opacity(0.5))
                            }
                            .padding(.trailing, 8)
                        }
                    }
                    .focused($isFocused)
                    .onSubmit { onGenerate() }
                    .disabled(!isInputEditable)
                    .foregroundColor(isInputEditable ? .primary : .secondary.opacity(0.6))

                Button {
                    if let string = UIPasteboard.general.string {
                        inputText = string
                    } else {
                        onPasteFailure?()
                    }
                } label: {
                    Image(systemName: "doc.on.clipboard")
                        .font(.title3)
                        .foregroundColor(.purple)
                        .frame(width: 44, height: 44)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                        )
                }
            }

            Button(action: onGenerate) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("思考中...")
                    } else {
                        Text(hasGeneratedReplies ? "✨ 重新生成" : "✨ AI 生成")
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
    }
}
