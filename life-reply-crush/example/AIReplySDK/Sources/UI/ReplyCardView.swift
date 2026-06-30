import SwiftUI

public struct ReplyCardView: View {
    let reply: ReplyOption
    let index: Int
    var onCopy: ((String) -> Void)?

    public init(reply: ReplyOption, index: Int, onCopy: ((String) -> Void)? = nil) {
        self.reply = reply
        self.index = index
        self.onCopy = onCopy
    }

    public var body: some View {
        let gradient = cardGradients[index % cardGradients.count]
        VStack(alignment: .leading, spacing: 12) {
            Text(reply.type)
                .font(.headline)
                .foregroundColor(.white)

            Text(reply.content)
                .font(.body)
                .foregroundColor(.white.opacity(0.95))
                .lineLimit(6)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [gradient.0, gradient.1], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(16)
        .shadow(color: gradient.0.opacity(0.3), radius: 8, y: 4)
        .onTapGesture {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            onCopy?(reply.content)
        }
    }
}

public struct ReplyGridView: View {
    let replies: [ReplyOption]
    var onCopy: ((String) -> Void)?

    public init(replies: [ReplyOption], onCopy: ((String) -> Void)? = nil) {
        self.replies = replies
        self.onCopy = onCopy
    }

    public var body: some View {
        LazyVGrid(columns: [GridItem(.flexible())], spacing: 12) {
            ForEach(Array(replies.enumerated()), id: \.element.id) { index, reply in
                ReplyCardView(reply: reply, index: index, onCopy: onCopy)
            }
        }
    }
}
