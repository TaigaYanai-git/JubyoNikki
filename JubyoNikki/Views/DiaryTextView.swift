import SwiftUI
import UIKit

/// 日記の入力欄。SwiftUI の TextEditor では変換中（未確定）の文字が分からないので UITextView で作る。
/// 文字が変わるたびに onEdit(確定した文, 変換中の文) を呼ぶ。
struct DiaryTextView: UIViewRepresentable {
    @Binding var text: String
    var isEditable: Bool
    var focus: Bool
    var onEdit: (_ committed: String, _ marked: String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.delegate = context.coordinator
        view.font = .preferredFont(forTextStyle: .body)
        view.adjustsFontForContentSizeCategory = true
        view.backgroundColor = .clear
        view.text = text
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        context.coordinator.parent = self
        // 変換中に外から書き換えると変換が切れるので、確定しているときだけ合わせる
        if view.markedTextRange == nil && view.text != text { view.text = text }
        view.isEditable = isEditable
        view.textColor = UIColor(Color.dlText)
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
            let full = view.text ?? ""
            var marked = ""
            var committed = full
            if let range = view.markedTextRange {
                marked = view.text(in: range) ?? ""
                let start = view.offset(from: view.beginningOfDocument, to: range.start)
                let length = view.offset(from: range.start, to: range.end)
                committed = (full as NSString).replacingCharacters(in: NSRange(location: start, length: length), with: "")
            }
            parent.text = full
            parent.onEdit(committed, marked)
        }
    }
}
