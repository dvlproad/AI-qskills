import SwiftUI

public struct ResultContentView: View {
    let replies: [ReplyOption]
    let rawText: String
    let rawTextMode: Bool
    let onCopy: ((String) -> Void)?

    public init(replies: [ReplyOption], rawText: String, rawTextMode: Bool, onCopy: ((String) -> Void)? = nil) {
        self.replies = replies
        self.rawText = rawText
        self.rawTextMode = rawTextMode
        self.onCopy = onCopy
    }

    public var body: some View {
        if rawTextMode {
            rawContentView
        } else {
            cardsView
        }
    }

    private var rawContentView: some View {
        let gradient = cardGradients[0]
        return VStack(alignment: .leading, spacing: 8) {
            Text("结果")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))

            CJSelectableText(
                text: rawText,
                font: .preferredFont(forTextStyle: .body),
                textColor: .white
            )
        }
        .padding(20)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [gradient.0, gradient.1], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(16)
        .shadow(color: gradient.0.opacity(0.3), radius: 8, y: 4)
        .overlay(alignment: .bottomTrailing) {
            Button {
                onCopy?(rawText)
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(6)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .padding(8)
        }
    }

    private var cardsView: some View {
        LazyVGrid(columns: [GridItem(.flexible())], spacing: 12) {
            ForEach(Array(replies.enumerated()), id: \.element.id) { index, reply in
                cardView(index: index, reply: reply)
            }
        }
    }

    private func cardView(index: Int, reply: ReplyOption) -> some View {
        let gradient = cardGradients[index % cardGradients.count]
        return VStack(alignment: .leading, spacing: 8) {
            Text(reply.type)
                .font(.headline)
                .foregroundColor(.white)

            CJSelectableText(
                text: reply.content,
                font: .preferredFont(forTextStyle: .body),
                textColor: .white
            )
        }
        .padding(20)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [gradient.0, gradient.1], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(16)
        .shadow(color: gradient.0.opacity(0.3), radius: 8, y: 4)
        .overlay(alignment: .bottomTrailing) {
            Button {
                onCopy?(reply.content)
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(6)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .padding(8)
        }
    }
}
