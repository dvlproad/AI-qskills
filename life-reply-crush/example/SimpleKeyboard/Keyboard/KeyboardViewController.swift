import UIKit

@objc(KeyboardViewController)
class KeyboardViewController: UIInputViewController {

    private enum KeyboardState { case letters, numbers, symbols }
    private var keyboardState: KeyboardState = .letters
    private var isShifted = false
    private var mainStack: UIStackView?

    override func viewDidLoad() {
        super.viewDidLoad()
        buildKeyboard()
    }

    private func buildKeyboard() {
        mainStack?.removeFromSuperview()

        view.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(white: 0.15, alpha: 1) : UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1)
        }

        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        mainStack = stack

        NSLayoutConstraint.activate([
            stack.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 3),
            stack.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -3),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
        ])

        for (i, row) in currentRows().enumerated() {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 5

            for title in row {
                let btn = makeKey(title: title)
                rowStack.addArrangedSubview(btn)
            }

            if i == 2 {
                let bs = makeKey(title: "⌫")
                bs.addTarget(self, action: #selector(deletePressed), for: .touchUpInside)
                rowStack.addArrangedSubview(bs)
            }

            stack.addArrangedSubview(rowStack)
        }

        // Bottom row
        let bottom = UIStackView()
        bottom.axis = .horizontal
        bottom.distribution = .fillEqually
        bottom.spacing = 5

        let switchBtn = makeKey(title: "123")
        switchBtn.addTarget(self, action: #selector(switchPressed), for: .touchUpInside)
        bottom.addArrangedSubview(switchBtn)

        let globe = makeKey(title: "🌐")
        globe.addTarget(self, action: #selector(globeTap), for: .touchUpInside)
        bottom.addArrangedSubview(globe)

        let space = makeKey(title: "空格")
        space.addTarget(self, action: #selector(spacePressed), for: .touchUpInside)
        bottom.addArrangedSubview(space)

        let hide = makeKey(title: "⌨️")
        hide.addTarget(self, action: #selector(hidePressed), for: .touchUpInside)
        bottom.addArrangedSubview(hide)

        let done = makeKey(title: "确认")
        done.addTarget(self, action: #selector(returnPressed), for: .touchUpInside)
        bottom.addArrangedSubview(done)

        stack.addArrangedSubview(bottom)
    }

    private func makeKey(title: String) -> UIButton {
        let isAction = title == "⌫" || title == "123" || title == "🌐" || title == "空格" || title == "⌨️" || title == "确认"
        let isLetter = !isAction
        let b = UIButton(type: .system)
        let display = isLetter && !isShifted ? title.lowercased() : title
        b.setTitle(display, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: isAction ? 16 : 20)
        b.tintColor = .black
        b.backgroundColor = isAction ? UIColor(white: 0.75, alpha: 1) : .white
        b.layer.cornerRadius = 5
        b.clipsToBounds = true
        if isLetter {
            b.addTarget(self, action: #selector(keyPressed(_:)), for: .touchUpInside)
        }
        return b
    }

    private func currentRows() -> [[String]] {
        switch keyboardState {
        case .letters:
            return [
                ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
                ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
                ["Z", "X", "C", "V", "B", "N", "M"],
            ]
        case .numbers:
            return [
                ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
                ["-", "/", ":", ";", "(", ")", "¥", "&", "@", "\""],
                [".", ",", "?", "!", "’"],
            ]
        case .symbols:
            return [
                ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="],
                ["_", "\\", "|", "~", "<", ">", "€", "£", "•", "·"],
                [".", ",", "?", "!", "’"],
            ]
        }
    }

    @objc private func keyPressed(_ sender: UIButton) {
        guard let t = sender.currentTitle else { return }
        textDocumentProxy.insertText(t)
        if isShifted { isShifted = false; buildKeyboard() }
    }

    @objc private func deletePressed() { textDocumentProxy.deleteBackward() }
    @objc private func spacePressed() { textDocumentProxy.insertText(" ") }
    @objc private func returnPressed() { textDocumentProxy.insertText("\n") }
    @objc private func globeTap() { advanceToNextInputMode() }
    @objc private func hidePressed() { dismissKeyboard() }

    @objc private func switchPressed() {
        switch keyboardState {
        case .letters: keyboardState = .numbers
        case .numbers: keyboardState = .symbols
        case .symbols: keyboardState = .letters
        }
        isShifted = false
        buildKeyboard()
    }

    @objc private func shiftPressed() {
        isShifted.toggle()
        buildKeyboard()
    }
}
