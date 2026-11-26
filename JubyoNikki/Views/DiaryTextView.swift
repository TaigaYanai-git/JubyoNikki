import SwiftUI
import UIKit

/// 日記の入力欄（UITextView）。打つたびに onType を呼ぶ（書いている間は時計を戻すため）。
/// textViewDidChange は変換中の文字が変わるたびにも呼ばれるので、かな入力・変換・予測変換・削除のどれでも戻る。
struct DiaryTextView: UIViewRepresentable {
    @Binding var text: String
    var isEditable: Bool
    var focus: Bool
    var onType: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> TypingTextView {
        let view = TypingTextView()
        view.delegate = context.coordinator
        view.onKey = { [weak coordinator = context.coordinator] in coordinator?.parent.onType() }
        view.font = .preferredFont(forTextStyle: .body)
        view.adjustsFontForContentSizeCategory = true
        view.backgroundColor = .clear
        view.text = text
        return view
    }

    func updateUIView(_ view: TypingTextView, context: Context) {
        context.coordinator.parent = self
        // 外から書き換えたとき（撮影用の自動入力など）。変換中は触らない
        if view.markedTextRange == nil && view.text != text { view.text = text }
        view.isEditable = isEditable
        if view.textColor != UIColor(Color.dlText) { view.textColor = UIColor(Color.dlText) }
        view.tintColor = UIColor(Color.dlPrimary)
        if focus && !view.isFirstResponder {
            DispatchQueue.main.async { if view.window != nil { view.becomeFirstResponder() } }
        } else if !focus && view.isFirstResponder {
            DispatchQueue.main.async { view.resignFirstResponder() }
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: DiaryTextView
        init(_ parent: DiaryTextView) { self.parent = parent }

        func textViewDidChange(_ view: UITextView) {
            parent.text = view.text ?? ""
            parent.onType()
        }
    }
}

/// キーを押したこと自体も知らせる UITextView（文字が変わらないキー操作でも時計を戻す）
final class TypingTextView: UITextView {
    var onKey: (() -> Void)?

    override func insertText(_ text: String) {
        super.insertText(text)
        onKey?()
    }

    override func deleteBackward() {
        super.deleteBackward()
        onKey?()
    }

    override func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
        super.setMarkedText(markedText, selectedRange: selectedRange)
        onKey?()
    }

    override func unmarkText() {
        super.unmarkText()
        onKey?()
    }
}
