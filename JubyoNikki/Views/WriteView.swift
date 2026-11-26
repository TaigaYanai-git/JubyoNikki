import SwiftData
import SwiftUI
import UIKit

/// 10 秒だけ書ける画面。空白以外の文字が1つ増えるたびに 1 秒のびる。
/// 消して書き直しても秒は増えない（いちばん多かった文字数から数える）。
struct WriteView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var entries: [DiaryEntry]

    static let baseSeconds: Double = 10

    /// 書く日（ふだんは今日。広告を見て昨日を取り戻すときは昨日）
    var dayKey: String = Day.key()
    var recovering = false
    /// しおりを使って昨日を書く（保存できたら 1 枚減らす）
    var usesShiori = false
    /// 今日の分を書いて、7 日続いたのでしおりをもらえた
    @State private var gotShiori = false

    @State private var text = ""
    @State private var start = Date()
    @State private var deadline = Date().addingTimeInterval(WriteView.baseSeconds)
    @State private var now = Date()
    /// この回でのびた秒数（＝数えた文字数）
    @State private var credited = 0
    /// 確定した文字数の、これまでの最大（消して書き直しても秒が増えないようにする）
    @State private var committedHigh = 0
    /// 変換中の文字で、すでにのばした秒数（変換して文字数が減っても返さない）
    @State private var composingCredit = 0
    @State private var composing = false
    @State private var finished = false
    @State private var bonusTick = 0
    /// 開いた時点の今日の文（10秒追加のとき。入力欄に入れて、前の文も直せる）
    @State private var original: String?
    @State private var focused = false

    private let ticker = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()
    private let haptic = UIImpactFeedbackGenerator(style: .soft)

    private var todayKey: String { dayKey }
    private var existing: DiaryEntry? { entries.first { $0.dayKey == todayKey } }
    private var remaining: Double { max(0, deadline.timeIntervalSince(now)) }
    private var gained: Int { credited }
    private var charCount: Int { Self.count(text) }

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
            now = t
            if remaining <= 0 { finish() }
        }
    }

    /// 文字が変わるたびに呼ぶ。1 文字ふえるごとに 1 秒のばす。
    /// - 変換中のかなは、ふえた分だけその場でのばす（変換を待たずに秒が増える）
    /// - 変換・予測変換で確定したとき、確定した文字の方が多ければ差の分を足す。少なくなっても返さない
    /// - 確定した文字は「これまでの最大」を超えた分だけ数える（消して書き直しても増えない）
    private func handleEdit(committed: String, marked: String) {
        guard !finished else { return }
        let c = Self.count(committed)
        let m = Self.count(marked)
        if m > 0 {
            composing = true
            let provisional = max(0, c + m - committedHigh)
            if provisional > composingCredit {
                grant(provisional - composingCredit)
                composingCredit = provisional
            }
        } else if composing {
            let growth = max(0, c - committedHigh)
            if growth > composingCredit { grant(growth - composingCredit) }
            committedHigh = max(committedHigh, c)
            composingCredit = 0
            composing = false
        } else if c > committedHigh {
            grant(c - committedHigh)
            committedHigh = c
        }
    }

    private func grant(_ n: Int) {
        guard n > 0 else { return }
        deadline += Double(n)
        credited += n
        bonusTick += 1
        haptic.impactOccurred(intensity: 0.6)
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
        let progress = finished ? 0 : remaining / max(Self.baseSeconds, deadline.timeIntervalSince(start))
        let urgent = remaining < 3 && !finished
        return ZStack {
            Circle().stroke(Color.dlCardTint, lineWidth: 12)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(LinearGradient(colors: [.dlPrimary, .dlPrimaryEnd], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.3), value: credited)
            VStack(spacing: 0) {
                Text(finished ? "0" : "\(Int(ceil(remaining)))")
                    .font(.system(size: 58, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(urgent ? Color(red: 0.88, green: 0.36, blue: 0.40) : .dlText)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.snappy, value: Int(ceil(remaining)))
                Text("秒")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.dlTextSub)
            }
            BonusPop(trigger: bonusTick)
                .offset(x: 62, y: -52)
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
                DiaryTextView(text: $text, isEditable: !finished, focus: focused) { committed, marked in
                    handleEdit(committed: committed, marked: marked)
                }
            }
            .padding(10)
            .frame(minHeight: 120, maxHeight: finished ? 220 : .infinity)
            .background(Color.dlCardTint)
            .cornerRadius(14)
            HStack {
                Text("\(charCount)文字")
                Spacer()
                Text("+\(gained)秒")
            }
            .font(.caption.weight(.semibold))
            .foregroundColor(.dlTextSub)
            .monospacedDigit()
        }
        .dlCard()
    }

    private var hint: some View {
        Text("1文字書くと、1秒のびます")
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
                VStack(spacing: 4) {
                    Text("\(Day.streak(keys: Set(entries.map(\.dayKey))))日連続")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.dlText)
                    Text("\(Int(deadline.timeIntervalSince(start).rounded()))秒の日記を書きました")
                        .font(.subheadline)
                        .foregroundColor(.dlTextSub)
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
        committedHigh = charCount
        credited = 0
        composingCredit = 0
        composing = false
        finished = false
        start = Date()
        now = start
        deadline = start.addingTimeInterval(Self.baseSeconds)
        haptic.prepare()
        focused = true
        // -typeDemo：撮影用に1文字ずつ自動で書く（+1 秒の動きを確かめる）
        if ProcessInfo.processInfo.arguments.contains("-typeDemo") {
            let demo = Array("帰りに見た夕焼けがきれいだった。")
            for (i, ch) in demo.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 + Double(i) * 0.35) {
                    if !finished { text.append(ch); handleEdit(committed: text, marked: "") }
                }
            }
        }
    }

    private func finish() {
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
        let used = min(Date(), deadline).timeIntervalSince(start)
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

/// 文字を書いたときに出る「+1」
private struct BonusPop: View {
    let trigger: Int
    @State private var shown = false
    var body: some View {
        Text("+1")
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundColor(.dlPrimary)
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? -10 : 6)
            .onChange(of: trigger) { _, _ in
                shown = false
                withAnimation(.easeOut(duration: 0.12)) { shown = true }
                withAnimation(.easeIn(duration: 0.35).delay(0.35)) { shown = false }
            }
    }
}

struct AnyButtonStyle: ButtonStyle {
    private let make: (Configuration) -> AnyView
    init<S: ButtonStyle>(_ style: S) { make = { AnyView(style.makeBody(configuration: $0)) } }
    func makeBody(configuration: Configuration) -> some View { make(configuration) }
}
