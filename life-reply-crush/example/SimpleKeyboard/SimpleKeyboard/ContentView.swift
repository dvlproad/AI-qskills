import SwiftUI
import UIKit

struct ContentView: View {
    @State private var testText = ""
    @FocusState private var isTextFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 50))
                            .foregroundColor(.accentColor)

                        Text("SimpleKeyboard")
                            .font(.title)
                            .bold()

                        VStack(alignment: .leading, spacing: 12) {
                            Label("添加键盘步骤", systemImage: "list.number")
                                .font(.headline)
                                .foregroundColor(.primary)

                            VStack(alignment: .leading, spacing: 12) {
                                instructionRow(number: "1", text: "打开 设置 → 通用 → 键盘")
                                instructionRow(number: "2", text: "点击「键盘」→「添加新键盘」")
                                instructionRow(number: "3", text: "选择 A-键盘")
                                instructionRow(number: "4", text: "点击 A-键盘 → 开启「允许完全访问」（可选，用于联网功能）")
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)

                        Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                            HStack {
                                Image(systemName: "gearshape.fill")
                                Text("打开设置")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.accentColor)
                            .cornerRadius(12)
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Label("测试键盘切换", systemImage: "rectangle.and.pencil.and.ellipsis")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            TextEditor(text: $testText)
                                .font(.title2)
                                .frame(height: 120)
                                .padding(8)
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(.separator), lineWidth: 1)
                                )
                                .overlay(alignment: .topLeading) {
                                    if testText.isEmpty {
                                        Text("点击此处切换键盘测试...")
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 16)
                                            .allowsHitTesting(false)
                                    }
                                }
                                .focused($isTextFocused)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture { isTextFocused = false }
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationTitle("A-键盘")
        }
    }

    private func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption)
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(Color.accentColor)
                .clipShape(Circle())
            Text(text)
                .font(.body)
            Spacer()
        }
    }
}
