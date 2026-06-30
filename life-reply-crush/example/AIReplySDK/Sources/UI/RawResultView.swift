import SwiftUI

public struct RawResultView: View {
    let text: String
    let onCopy: (() -> Void)?

    public init(text: String, onCopy: (() -> Void)? = nil) {
        self.text = text
        self.onCopy = onCopy
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("结果")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                if let onCopy {
                    Button {
                        UIPasteboard.general.string = text
                        onCopy()
                    } label: {
                        Label("复制", systemImage: "doc.on.doc")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
            }
            Text(text)
                .font(.body)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
        }
    }
}
