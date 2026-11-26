import SwiftData
import SwiftUI
import UIKit

/// 10 秒だけ書ける画面。書いている間（最後に打ってから freeze 秒）は時計が反転して
/// 持ち時間が増え（最大 10 秒、ゲージは緑）、手が止まっている間だけ減る。
/// 文字数を数えないので、変換・予測変換・削除のどれでも同じように増える。
struct WriteView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var entries: [DiaryEntry]

    static let baseSeconds: Double = 10
    /// 最後に打ってから「書いている」とみなす時間
    static let freeze: Double = 1.2

    /// 書く日（ふだんは今日。広告を見て昨日を取り戻すときは昨日）
    var dayKey: String = Day.key()
    var recovering = false
    /// しおりを使って昨日を書く（保存できたら 1 枚減らす）
    var usesShiori = false
    /// 今日の分を書いて、7 日続いたのでしおりをもらえた
    @State private var gotShiori = false

    @State private var text = ""
    @State private var start = Date()
    @State private var now = Date()
    /// 残りの持ち時間（書いている間は増え、手が止まっているときは減る。最大 baseSeconds）
    @State private var remaining = WriteView.baseSeconds
    @State private var lastTick = Date()
    /// 最後に打った時刻
    @State private var lastType = Date.distantPast
    /// 書いて取り戻した秒数の合計
    @State private var gainedTotal: Double = 0
    @State private var finished = false
    /// 書き終わったときの、書いていた秒数（書き終わりの画面に出す）
    @State private var usedSeconds: Double = 0
    /// 開いた時点の今日の文（10秒追加のとき。入力欄に入れて、前の文も直せる）
    @State private var original: String?
    @State private var focused = false

    /// 書いている間のゲージの色
    static let green = Color(red: 0.22, green: 0.68, blue: 0.45)
    static let greenEnd = Color(red: 0.45, green: 0.80, blue: 0.52)

    private let ticker = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()
    private let haptic = UIImpactFeedbackGenerator(style: .soft)

    private var todayKey: String { dayKey }
    private var existing: DiaryEntry? { entries.first { $0.dayKey == todayKey } }
    private var charCount: Int { Self.count(text) }
    /// いま書いている最中か（時計が反転して増える）
    private var frozen: Bool { !finished && now.timeIntervalSince(lastType) < Self.freeze }

    /// 数える文字（空白と改行は数えない）
    static func count(_ s: String) -> Int { s.filter { !$0.isWhitespace && !$0.isNewline }.count }

    var body: some View {
        ZStack {
            DlBackground().ignoresSafeArea()
            VStack(spacing: 18) {
                header
                timerRing
                editor
                if finished { finishedButtons } else { hint }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .onAppear(perform: begin)
        .onReceive(ticker) { t in
            guard !finished else { return }
            let dt = t.timeIntervalSince(lastTick)
            lastTick = t
            now = t
            if t.timeIntervalSince(lastType) < Self.freeze {
                let gain = min(dt, Self.baseSeconds - remaining)
                remaining += gain
                gainedTotal += gain
            } else {
                remaining = max(0, remaining - dt)
                if remaining <= 0 { finish() }
            }
        }
    }

    /// 打つたびに呼ぶ（DiaryTextView から。変換中の文字の変化・削除キーも含む）
    private func typed() {
        guard !finished else { return }
        if !frozen { haptic.impactOccurred(intensity: 0.5) }
        lastType = Date()
    }

    // MARK: 部品

    private var header: some View {
        HStack {
            Button {
                if !finished { save() }
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.dlText)
                    .frame(width: 44, height: 44)
                    .background(Color.dlCard)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
            }
            Spacer()
            VStack(spacing: 2) {
                Text(Day.label(Day.date(from: dayKey) ?? Date()))
                    .font(.headline)
                    .foregroundColor(.dlText)
                if recovering {
                    Text("昨日の日記")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.dlPrimary)
                }
            }
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
    }

    private var timerRing: some View {
        let progress = finished ? 0 : remaining / Self.baseSeconds
        let urgent = remaining < 3 && !finished
        return ZStack {
            Circle().stroke(Color.dlCardTint, lineWidth: 12)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(LinearGradient(colors: frozen ? [Self.green, Self.greenEnd] : [.dlPrimary, .dlPrimaryEnd],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.2), value: frozen)
            VStack(spacing: 0) {
                Text(finished ? "0" : "\(Int(ceil(remaining)))")
                    .font(.system(size: 58, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(frozen ? Self.green : urgent ? Color(red: 0.88, green: 0.36, blue: 0.40) : .dlText)
                    .contentTransition(.numericText(countsDown: !frozen))
                    .animation(.snappy, value: Int(ceil(remaining)))
                // 書いている間は「戻っています」、手が止まっている間は「秒」
                HStack(spacing: 3) {
                    if frozen { Image(systemName: "arrow.counterclockwise").font(.system(size: 9, weight: .bold)) }
                    Text(frozen ? (remaining >= Self.baseSeconds ? "満タン" : "戻っています") : "秒")
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(frozen ? Self.green : .dlTextSub)
            }
        }
        .frame(width: 150, height: 150)
        .padding(.top, 4)
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("今日あったこと、ひとことで。")
                        .foregroundColor(.dlTextLight)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }
                DiaryTextView(text: $text, isEditable: !finished, focus: focused, onType: typed)
            }
            .padding(10)
            .frame(minHeight: 120, maxHeight: finished ? 220 : .infinity)
            .background(Color.dlCardTint)
            .cornerRadius(14)
            HStack {
                Text("\(charCount)文字")
                Spacer()
                Text("書いて戻した \(Int(gainedTotal))秒")
            }
            .font(.caption.weight(.semibold))
            .foregroundColor(.dlTextSub)
            .monospacedDigit()
        }
        .dlCard()
    }

    private var hint: some View {
        Text("書いている間は、時計が戻ります（最大10秒）")
            .font(.footnote)
            .foregroundColor(.dlTextSub)
            .padding(.bottom, 8)
    }

    private var finishedButtons: some View {
        VStack(spacing: 10) {
            if text.isEmpty {
                Text(original == nil ? "今日は書けませんでした。また明日。" : "今日の日記を消しました。")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.dlText)
            } else {
                VStack(spacing: 6) {
                    Text(recovering ? "昨日の分も書けました" : "今日もお疲れさまでした")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.dlText)
                    Text(recovering ? "ゆっくり休んでくださいね。" : "また明日、10秒だけ。")
                        .font(.subheadline)
                        .foregroundColor(.dlTextSub)
                    HStack(spacing: 8) {
                        Label("\(Day.streak(keys: Set(entries.map(\.dayKey))))日連続", systemImage: "flame.fill")
                        Text("・").foregroundColor(.dlTextLight)
                        Label("\(Int(usedSeconds.rounded()))秒", systemImage: "timer")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.dlPrimary)
                    .padding(.top, 6)
                    if gotShiori {
                        Label("\(Shiori.streakPerShiori)日続いたので、しおりを1枚もらいました", systemImage: "bookmark.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.dlPrimary)
                            .padding(.top, 6)
                    }
                }
                .padding(.bottom, 6)
            }
            if text.isEmpty {
                Button("もう一度 10 秒") { begin() }.buttonStyle(PrimaryButtonStyle())
            }
            Button("とじる") { dismiss() }
                .buttonStyle(text.isEmpty ? AnyButtonStyle(SecondaryButtonStyle()) : AnyButtonStyle(PrimaryButtonStyle()))
        }
        .padding(.bottom, 8)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: 動き

    private func begin() {
        original = existing?.text
        text = original ?? ""
        finished = false
        start = Date()
        now = start
        lastTick = start
        lastType = .distantPast
        remaining = Self.baseSeconds
        gainedTotal = 0
        haptic.prepare()
        focused = true
        // -typeDemo：撮影用に1文字ずつ自動で書く（+1 秒の動きを確かめる）
        if ProcessInfo.processInfo.arguments.contains("-typeDemo") {
            let demo = Array("帰りに見た夕焼けがきれいだった。")
            for (i, ch) in demo.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 + Double(i) * 0.35) {
                    if !finished { text.append(ch); typed() }
                }
            }
        }
    }

    /// この回に書いていた時間（開いてから今まで）
    private var baseSecondsUsed: Double { Date().timeIntervalSince(start) }

    private func finish() {
        usedSeconds = baseSecondsUsed
        withAnimation(.spring(duration: 0.35)) { finished = true }
        focused = false
        save()
        UINotificationFeedbackGenerator().notificationOccurred(text.isEmpty ? .warning : .success)
    }

    /// 入力欄の文で今日の日記を置き換える（10秒追加では前の文も直せるため）。
    /// 何も変えていなければ保存しない。全部消したら今日の日記を消す
    private func save() {
        let body = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let original, body == original.trimmingCharacters(in: .whitespacesAndNewlines) { return }
        let used = baseSecondsUsed
        if let existing {
            if body.isEmpty {
                context.delete(existing)
            } else {
                existing.text = body
                existing.seconds += used
                existing.updatedAt = Date()
            }
        } else if !body.isEmpty {
            let entry = DiaryEntry(dayKey: todayKey, text: body, seconds: used)
            entry.recovered = recovering
            context.insert(entry)
            if recovering && usesShiori { Shiori.shared.use() }
            if !recovering {
                let keys = Set(entries.map(\.dayKey)).union([todayKey])
                gotShiori = Shiori.shared.awardIfNeeded(streak: Day.streak(keys: keys), todayKey: todayKey)
            }
        }
        try? context.save()
        Task { await Reminder.shared.reschedule() }
    }
}

struct AnyButtonStyle: ButtonStyle {
    private let make: (Configuration) -> AnyView
    init<S: ButtonStyle>(_ style: S) { make = { AnyView(style.makeBody(configuration: $0)) } }
    func makeBody(configuration: Configuration) -> some View { make(configuration) }
}
