import SwiftUI
import UIKit

/// 日記の入力欄（UITextView）。秒をのばすための文字の増減を知らせる。
///
/// 数え方（WriteView.handleGrow / handleRemove）：
/// - 文字数（空白・改行は除く）が増えたら、増えた分を onGrow で知らせる。変換中・確定・予測変換・貼り付けの区別はしない
/// - 減ったときは知らせない。変換で「きょうは」→「今日は」と減っても、もらった秒はそのまま
/// - 削除キー・切り取り・選択した文字の上書きで消えた分だけ onRemove で知らせる（WriteView が「借り」にして、
///   次に増えた分からまず返す。消して書き直しても秒は増えない）
/// iOS は変換を確定しただけでは textViewDidChange を呼ばないことがあるので、確定の知らせには頼らない。
struct DiaryTextView: UIViewRepresentable {
    @Binding var text: String
    var isEditable: Bool
    var focus: Bool
    var onGrow: (Int) -> Void
    var onRemove: (Int) -> Void

    static func count(_ s: String) -> Int { s.filter { !$0.isWhitespace && !$0.isNewline }.count }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> CountingTextView {
        let view = CountingTextView()
        view.delegate = context.coordinator
        view.coordinator = context.coordinator
        view.font = .preferredFont(forTextStyle: .body)
        view.adjustsFontForContentSizeCategory = true
        view.backgroundColor = .clear
        view.text = text
        context.coordinator.last = Self.count(text)
        return view
    }

    func updateUIView(_ view: CountingTextView, context: Context) {
        context.coordinator.parent = self
        // 外から書き換えたとき（撮影用の自動入力など）。変換中は触らない
        if view.markedTextRange == nil && view.text != text {
            view.text = text
            context.coordinator.last = Self.count(text)
        }
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
        /// 前に知らせたときの文字数
        var last = 0
        init(_ parent: DiaryTextView) { self.parent = parent }

        func textViewDidChange(_ view: UITextView) {
            parent.text = view.text ?? ""
            let n = DiaryTextView.count(view.text ?? "")
            if n > last { parent.onGrow(n - last) }
            last = n
        }

        /// 選択した文字を打った文字で上書きしたとき、上書きで消えた分を借りにする（変換中の置きかえは除く）
        func textView(_ view: UITextView, shouldChangeTextIn range: NSRange, replacementText: String) -> Bool {
            if range.length > 0, !replacementText.isEmpty, view.markedTextRange == nil,
               let old = Range(range, in: view.text ?? "") {
                let removed = DiaryTextView.count(String((view.text ?? "")[old]))
                if removed > 0 { parent.onRemove(removed) }
            }
            return true
        }

        /// 削除キー・切り取りで消えた分（CountingTextView から）
        func removed(before: Int, after: Int) {
            if before > after { parent.onRemove(before - after) }
            last = after
        }
    }
}

/// 削除キーと切り取りで消えた文字数を測る UITextView
final class CountingTextView: UITextView {
    weak var coordinator: DiaryTextView.Coordinator?

    override func deleteBackward() {
        let before = DiaryTextView.count(text ?? "")
        super.deleteBackward()
        coordinator?.removed(before: before, after: DiaryTextView.count(text ?? ""))
    }

    override func cut(_ sender: Any?) {
        let before = DiaryTextView.count(text ?? "")
        super.cut(sender)
        coordinator?.removed(before: before, after: DiaryTextView.count(text ?? ""))
    }
}
