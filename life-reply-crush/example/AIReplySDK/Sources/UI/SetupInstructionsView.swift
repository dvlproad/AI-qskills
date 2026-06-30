import SwiftUI

public struct SetupInstructionsView: View {
    private let keyboardName: String

    public init(keyboardName: String) {
        self.keyboardName = keyboardName
    }

    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Label("添加键盘步骤", systemImage: "keyboard")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 12) {
                    instructionRow(number: "1", text: "打开 设置 → 通用 → 键盘")
                    instructionRow(number: "2", text: "点击「键盘」→「添加新键盘」")
                    instructionRow(number: "3", text: "选择 \(keyboardName)")
                    instructionRow(number: "4", text: "点击 \(keyboardName) → 开启「允许完全访问」（可选，用于联网功能）")
                }

                Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                    HStack {
                        Image(systemName: "gearshape.fill")
                        Text("打开设置")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.purple)
                    .cornerRadius(10)
                }
            }
        } label: {
            Text("设置")
        }
        .groupBoxStyle(.automatic)
    }

    private func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption)
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(Color.purple)
                .clipShape(Circle())
            Text(text)
                .font(.body)
            Spacer()
        }
    }
}
