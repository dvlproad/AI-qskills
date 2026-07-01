import SwiftUI

public struct ClipboardSuggestionView: View {
    let items: [String]
    let isPolling: Bool
    let countdown: Int
    let onTap: (String) -> Void
    let onMore: (() -> Void)?

    public init(items: [String], isPolling: Bool = false, countdown: Int = 2, onTap: @escaping (String) -> Void, onMore: (() -> Void)? = nil) {
        self.items = items
        self.isPolling = isPolling
        self.countdown = countdown
        self.onTap = onTap
        self.onMore = onMore
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                HStack(spacing: 3) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.caption)
                        .foregroundColor(Color(hex: "9333ea"))
                    if isPolling {
                        Text("\(countdown)s")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                }

                ForEach(Array(items.enumerated()), id: \.offset) { _, text in
                    Text(truncated(text))
                        .font(.caption2)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.purple.opacity(0.2), lineWidth: 0.5)
                        )
                        .onTapGesture { onTap(text) }
                }

                if let onMore = onMore {
                    Button(action: onMore) {
                        Text("更多")
                            .font(.caption2.weight(.medium))
                            .foregroundColor(.purple)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.purple.opacity(0.08))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.purple.opacity(0.2), lineWidth: 0.5)
                            )
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func truncated(_ text: String) -> String {
        text.count > 12 ? String(text.prefix(12)) + "…" : text
    }
}
