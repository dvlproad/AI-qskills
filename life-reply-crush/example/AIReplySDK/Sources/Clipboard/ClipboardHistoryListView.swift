import SwiftUI

// MARK: - Persistence

public func loadClipboardHistory() -> [String] {
    guard let data = UserDefaults.shared.data(forKey: "clipboard_history"),
          let history = try? JSONDecoder().decode([String].self, from: data) else { return [] }
    return history
}

public func saveClipboardHistory(_ history: [String]) {
    guard let data = try? JSONEncoder().encode(history) else { return }
    UserDefaults.shared.set(data, forKey: "clipboard_history")
}

// MARK: - Shared View

public struct ClipboardHistoryListView: View {
    let actionTitle: String
    let onAction: (String) -> Void
    let onDelete: ((IndexSet) -> Void)?

    @State private var localItems: [String]

    public init(items: [String], actionTitle: String, onAction: @escaping (String) -> Void, onDelete: ((IndexSet) -> Void)? = nil) {
        self.actionTitle = actionTitle
        self.onAction = onAction
        self.onDelete = onDelete
        _localItems = State(initialValue: items)
    }

    public var body: some View {
        Group {
            if localItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("暂无剪贴板记录")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(localItems.enumerated()), id: \.offset) { index, text in
                            row(text: text, index: index)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private func row(text: String, index: Int) -> some View {
        HStack(spacing: 12) {
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(actionTitle) {
                onAction(text)
            }
            .font(.caption.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                LinearGradient(
                    colors: [Color(hex: "9333ea"), Color(hex: "ec4899")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)

            if let onDelete {
                Button {
                    localItems.remove(at: index)
                    onDelete(IndexSet(integer: index))
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.7))
                        .padding(6)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.purple.opacity(0.08))
        .cornerRadius(10)
        .padding(.horizontal, 8)
    }
}
