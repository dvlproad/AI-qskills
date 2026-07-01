import SwiftUI
import AIReplySDK

/// 测试 ExtensionKeyboardView 的包装视图（在真机/模拟器主 App 中运行）
struct CustomKeyboardView: View {
    @State private var insertedText = ""

    var body: some View {
        VStack(spacing: 0) {
            ExtensionKeyboardView(
                insertText: { insertedText = $0 },
                dismissKeyboard: { /* 在主 App 中无操作 */ },
                setKeyboardHeight: { _ in /* 在主 App 中忽略键盘高度变化 */ },
                transparentBackground: true,
                showResultsInline: true,
                onResults: { r, raw in
                    if !raw.isEmpty { insertedText = raw }
                },
                isInputEditable: true,
                hasFullAccess: true
            )

            if !insertedText.isEmpty {
                Divider()
                HStack {
                    Text("已选择回复:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(insertedText)
                        .font(.body)
                    Spacer()
                    Button {
                        UIPasteboard.general.string = insertedText
                    } label: {
                        Label("复制", systemImage: "doc.on.doc")
                            .font(.caption)
                    }
                }
                .padding()
                .background(Color(.systemGroupedBackground))
            }
        }
        .navigationTitle("键盘预览")
        .navigationBarTitleDisplayMode(.inline)
    }
}
