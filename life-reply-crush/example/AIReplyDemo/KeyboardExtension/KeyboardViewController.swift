import UIKit
import SwiftUI
import AIReplySDK

@objc(KeyboardViewController)
class KeyboardViewController: UIInputViewController {

    private var hostingController: UIHostingController<ExtensionKeyboardView>?
    private var heightConstraint: NSLayoutConstraint?
    private let defaultHeight = KeyboardHeight.default
    private let expandedHeight = KeyboardHeight.expanded
    private let maxHeight = KeyboardHeight.overlay

    override func viewDidLoad() {
        super.viewDidLoad()

        let keyboardView = ExtensionKeyboardView(
            insertText: { [weak self] text in
                self?.textDocumentProxy.insertText(text)
            },
            dismissKeyboard: { [weak self] in
                self?.dismissKeyboard()
            },
            setKeyboardHeight: { [weak self] height in
                self?.setHeight(height)
            },
            isInputEditable: false,
            onAddPreset: { [weak self] in
                guard let self = self else { return }
                let url = URL(string: "aireply://presets")!

                if let app = UIApplication.value(forKey: "sharedApplication") as? UIApplication {
                    app.open(url, options: [:], completionHandler: nil)
                } else if self.hasFullAccess {
                    self.extensionContext?.open(url)
                } else {
                    let sel = sel_registerName("openURL:")
                    var resp: UIResponder? = self
                    while let r = resp {
                        if r.responds(to: sel) {
                            r.perform(sel, with: url)
                            return
                        }
                        resp = r.next
                    }
                }
            },
            onOpenSettings: { [weak self] in
                guard let self = self else { return }
                let url = URL(string: UIApplication.openSettingsURLString)!
                if let app = UIApplication.value(forKey: "sharedApplication") as? UIApplication {
                    app.open(url, options: [:], completionHandler: nil)
                }
            },
            onOpenAppSettings: { [weak self] in
                guard let self = self else { return }
                let url = URL(string: "aireply://settings")!

                if let app = UIApplication.value(forKey: "sharedApplication") as? UIApplication {
                    app.open(url, options: [:], completionHandler: nil)
                } else if self.hasFullAccess {
                    self.extensionContext?.open(url)
                } else {
                    let sel = sel_registerName("openURL:")
                    var resp: UIResponder? = self
                    while let r = resp {
                        if r.responds(to: sel) {
                            r.perform(sel, with: url)
                            return
                        }
                        resp = r.next
                    }
                }
            },
            hasFullAccess: hasFullAccess,
            bottomBarRightExtra: AnyView(
                Button { [weak self] in
                    self?.textDocumentProxy.deleteBackward()
                } label: {
                    Image(systemName: "delete.left.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(8)
                }
            )
        )

        let hosting = UIHostingController(rootView: keyboardView)
        hostingController = hosting
        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(hosting.view)

        NSLayoutConstraint.activate([
            hosting.view.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            hosting.view.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            hosting.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
        ])

        hosting.didMove(toParent: self)

        let constraint = self.view.heightAnchor.constraint(equalToConstant: defaultHeight)
        constraint.isActive = true
        heightConstraint = constraint
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        hostingController?.view.frame = view.bounds
    }

    private func setHeight(_ height: CGFloat) {
        heightConstraint?.constant = height
        view.superview?.setNeedsLayout()
    }
}
