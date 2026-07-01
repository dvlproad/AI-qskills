import SwiftUI
import AIReplySDK

struct TextSelectionTestView: View {
    let sampleTexts = [
        ("暧昧撩人", "我刚洗完澡出来，看到手机亮了，点开一看是你。突然觉得今晚的月色特别好看。"),
        ("暧昧撩人", "今天工作好累，但看到你的消息又觉得满血复活了。你是不是偷偷给我打了鸡血？"),
        ("猜谜语", "🌙👀👤 — 有月亮有眼睛有人，打一个成语。谜底：月下老人（月+下=下有目，老=老人？还是月..."),
        ("暧昧撩人", "你是不是偷了我的东西？因为每次看到你，我的心就被偷走了。🌟"),
    ]

    var body: some View {
        List {
            Section {
                Text("长按文字 → 滑动选择 → 系统工具栏复制选中内容")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ForEach(Array(sampleTexts.enumerated()), id: \.offset) { index, pair in
                VStack(alignment: .leading, spacing: 8) {
                    Text(pair.0)
                        .font(.caption)
                        .foregroundColor(.purple)

                    CJSelectableText(
                        text: pair.1,
                        font: .preferredFont(forTextStyle: .body),
                        textColor: .label
                    )
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(index % 2 == 0 ? Color(.systemGray6) : Color(.systemBackground))
                .cornerRadius(12)
            }
        }
        .listStyle(.plain)
        .navigationTitle("长按选字测试")
    }
}

#Preview {
    NavigationStack {
        TextSelectionTestView()
    }
}
