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

    @State private var text = ""
    @State private var start = Date()
    @State private var deadline = Date().addingTimeInterval(WriteView.baseSeconds)
    @State private var now = Date()
    @State private var maxCount = 0
    @State private var finished = false
    @State private var bonusTick = 0
    /// 書きはじめた時点で、今日すでに書いてあった文（書き足すときに上へ小さく出す）
    @State private var earlier: String?
    @FocusState private var focused: Bool

    private let ticker = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()
    private let haptic = UIImpactFeedbackGenerator(style: .soft)

    private var todayKey: String { Day.key() }
    private var existing: DiaryEntry? { entries.first { $0.dayKey == todayKey } }
    private var remaining: Double { max(0, deadline.timeIntervalSince(now)) }
    private var gained: Int { maxCount }

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
        .onChange(of: text) { _, newValue in
            guard !finished else { return }
            let n = newValue.filter { !$0.isWhitespace && !$0.isNewline }.count
            if n > maxCount {
                deadline += Double(n - maxCount)
                maxCount = n
                bonusTick += 1
                haptic.impactOccurred(intensity: 0.6)
            }
        }
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
            Text(Day.label(Date()))
                .font(.headline)
                .foregroundColor(.dlText)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
    }

    private var timerRing: some View {
        let progress = min(1, remaining / Self.baseSeconds)
        let urgent = remaining < 3 && !finished
        return ZStack {
            Circle().stroke(Color.dlCardTint, lineWidth: 12)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(LinearGradient(colors: [.dlPrimary, .dlPrimaryEnd], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
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
            if let earlier, !earlier.isEmpty {
                Text(earlier)
                    .font(.subheadline)
                    .foregroundColor(.dlTextSub)
                    .lineLimit(3)
            }
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(earlier == nil ? "今日あったこと、ひとことで。" : "書き足す")
                        .foregroundColor(.dlTextLight)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }
                TextEditor(text: $text)
                    .focused($focused)
                    .disabled(finished)
                    .scrollContentBackground(.hidden)
                    .foregroundColor(.dlText)
                    .font(.body)
            }
            .padding(10)
            .frame(maxHeight: .infinity)
            .background(Color.dlCardTint)
            .cornerRadius(14)
            HStack {
                Text("\(gained)文字")
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
            Text(text.isEmpty ? "今日は書けませんでした。また明日。" : "書けました。\(Int((deadline.timeIntervalSince(start)).rounded()))秒の日記です。")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.dlText)
            if text.isEmpty {
                Button("もう一度 10 秒") { begin() }.buttonStyle(PrimaryButtonStyle())
            }
            Button("とじる") { dismiss() }
                .buttonStyle(text.isEmpty ? AnyButtonStyle(SecondaryButtonStyle()) : AnyButtonStyle(PrimaryButtonStyle()))
        }
        .padding(.bottom, 8)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: 動き

    private func begin() {
        earlier = existing?.text
        text = ""
        maxCount = 0
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 + Double(i) * 0.35) { if !finished { text.append(ch) } }
            }
        }
    }

    private func finish() {
        withAnimation(.spring(duration: 0.35)) { finished = true }
        focused = false
        save()
        UINotificationFeedbackGenerator().notificationOccurred(text.isEmpty ? .warning : .success)
    }

    private func save() {
        let body = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        let used = min(Date(), deadline).timeIntervalSince(start)
        if let existing {
            existing.text += (existing.text.isEmpty ? "" : "\n") + body
            existing.seconds += used
            existing.updatedAt = Date()
        } else {
            context.insert(DiaryEntry(dayKey: todayKey, text: body, seconds: used))
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
