import SwiftData
import SwiftUI

struct TodayView: View {
    @Query(sort: \DiaryEntry.dayKey, order: .reverse) private var entries: [DiaryEntry]
    @ObservedObject private var theme = ThemeStore.shared
    @ObservedObject private var reminder = Reminder.shared
    @ObservedObject private var ads = RewardedAds.shared
    @State private var showRecover = false
    @Binding var showWrite: Bool

    private var today: DiaryEntry? { entries.first { $0.dayKey == Day.key() } }
    private var streak: Int { Day.streak(keys: Set(entries.map(\.dayKey))) }
    private var totalChars: Int { entries.reduce(0) { $0 + $1.text.filter { !$0.isWhitespace }.count } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text(Day.label(Date()))
                        .font(.diary(24, bold: true))
                        .foregroundColor(.dlText)
                        .padding(.top, 4)
                    if let today { writtenCard(today) } else { startCard }
                    if canRecover { recoverCard }
                    if reminder.notAsked { askCard }
                    statsCard
                    if !entries.filter({ $0.dayKey != Day.key() }).isEmpty { recent }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .dlScreen("今日")
            .fullScreenCover(isPresented: $showRecover) {
                WriteView(dayKey: yesterdayKey, recovering: true)
            }
        }
    }

    private var yesterdayKey: String {
        Day.key(Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
    }

    /// 昨日が空いていて、それより前に1日でも書いている人だけ（始めたばかりの人には出さない）
    private var canRecover: Bool {
        ads.isAvailable
            && !entries.contains { $0.dayKey == yesterdayKey }
            && entries.contains { $0.dayKey < yesterdayKey }
    }

    /// 前の日まで続いていれば、昨日を書くと連続がつながる
    private var wouldReconnect: Bool {
        let before = Day.key(Calendar.current.date(byAdding: .day, value: -2, to: Date())!)
        return entries.contains { $0.dayKey == before }
    }

    /// 広告を見て昨日を取り戻す
    private var recoverCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.dlPrimary)
                    .frame(width: 44, height: 44)
                    .background(Color.dlPrimaryBg)
                    .cornerRadius(12)
                VStack(alignment: .leading, spacing: 2) {
                    Text("昨日の日記がありません").font(.headline).foregroundColor(.dlText)
                    Text(wouldReconnect ? "広告を見ると、昨日の分を10秒で書けます。連続記録がつながります。"
                                        : "広告を見ると、昨日の分を10秒で書けます。")
                        .font(.caption).foregroundColor(.dlTextSub)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Button {
                Task {
                    await ads.show { ok in if ok { showRecover = true } }
                }
            } label: {
                HStack(spacing: 8) {
                    if ads.isLoading { ProgressView().tint(.dlPrimary) }
                    else { Image(systemName: "play.rectangle") }
                    Text("広告を見て昨日を書く")
                }
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(ads.isLoading)
            if let message = ads.errorMessage {
                Text(message).font(.caption).foregroundColor(.dlTextSub)
            }
        }
        .dlCard(padding: 18)
        .task {
            await ads.preload()
            #if DEBUG
            // -autoRecover：確認用。カードのボタンを押したのと同じ流れを自動で通す
            if ProcessInfo.processInfo.arguments.contains("-autoRecover") {
                await ads.show { ok in if ok { showRecover = true } }
            }
            #endif
        }
    }

    private var startCard: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle().stroke(Color.dlCardTint, lineWidth: 12)
                Circle()
                    .stroke(LinearGradient(colors: [.dlPrimary, .dlPrimaryEnd], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round))
                VStack(spacing: 0) {
                    Text("10")
                        .font(.system(size: 58, weight: .bold, design: .rounded))
                        .foregroundColor(.dlText)
                    Text("秒").font(.caption.weight(.semibold)).foregroundColor(.dlTextSub)
                }
            }
            .frame(width: 150, height: 150)
            .padding(.top, 8)
            VStack(spacing: 6) {
                Text("10秒だけ、今日のことを。")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.dlText)
                Text("1文字書くごとに、1秒のびます。")
                    .font(.subheadline)
                    .foregroundColor(.dlTextSub)
            }
            Button {
                showWrite = true
            } label: {
                Label("書きはじめる", systemImage: "pencil")
            }
            .buttonStyle(PrimaryButtonStyle())
            if let next = reminder.nextFire(writtenToday: false) {
                Label("\(Calendar.current.isDateInToday(next) ? "今日" : "明日") \(reminder.timeLabel) にお知らせします", systemImage: "bell")
                    .font(.caption)
                    .foregroundColor(.dlTextSub)
            }
        }
        .dlCard(padding: 22)
    }

    /// 通知の許可は起動直後ではなく、ここで理由を見せてから聞く
    private var askCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "bell.badge")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.dlPrimary)
                    .frame(width: 44, height: 44)
                    .background(Color.dlPrimaryBg)
                    .cornerRadius(12)
                VStack(alignment: .leading, spacing: 2) {
                    Text("毎日 \(reminder.timeLabel) にお知らせ").font(.headline).foregroundColor(.dlText)
                    Text("書き忘れた日だけ届きます。時刻は設定で変えられます。")
                        .font(.caption).foregroundColor(.dlTextSub)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Button("お知らせを受け取る") { Task { await reminder.requestPermission() } }
                .buttonStyle(SecondaryButtonStyle())
        }
        .dlCard(padding: 18)
    }

    private func writtenCard(_ e: DiaryEntry) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.dlPrimary)
                Text("今日の日記").font(.subheadline.weight(.semibold)).foregroundColor(.dlTextSub)
                Spacer()
                Text("\(Int(e.seconds.rounded()))秒")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.dlPrimary)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color.dlPrimaryBg)
                    .clipShape(Capsule())
            }
            RuledText(text: e.text, minLines: 2)
                .padding(.horizontal, 4)
            Button {
                showWrite = true
            } label: {
                Label("10秒追加", systemImage: "plus")
            }
            .buttonStyle(SecondaryButtonStyle())
            if let next = reminder.nextFire(writtenToday: true) {
                Label("次のお知らせは明日 \(reminder.timeLabel)", systemImage: "bell")
                    .font(.caption)
                    .foregroundColor(.dlTextSub)
                    .frame(maxWidth: .infinity)
                    .opacity(Calendar.current.isDateInToday(next) ? 0 : 1)
            }
        }
        .dlCard(padding: 20)
    }

    private var statsCard: some View {
        HStack(spacing: 0) {
            stat("\(streak)日", "連続")
            Divider().frame(height: 40).overlay(Color.dlDivider)
            stat("\(entries.count)日", "書いた日")
            Divider().frame(height: 40).overlay(Color.dlDivider)
            stat("\(totalChars)", "これまでの文字")
        }
        .dlCard(padding: 18)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.weight(.bold)).foregroundColor(.dlText).monospacedDigit()
            Text(label).font(.caption).foregroundColor(.dlTextSub)
        }
        .frame(maxWidth: .infinity)
    }

    private var recent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("これまでの日記")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.dlTextSub)
                .padding(.leading, 4)
            ForEach(entries.filter { $0.dayKey != Day.key() }.prefix(5)) { e in
                EntryRow(entry: e)
            }
        }
    }
}

struct EntryRow: View {
    let entry: DiaryEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(Day.label(entry.date)).font(.diary(14, bold: true)).foregroundColor(.dlTextSub)
                Spacer()
                Text("\(Int(entry.seconds.rounded()))秒").font(.caption).foregroundColor(.dlTextLight)
            }
            RuledText(text: entry.text)
        }
        .dlCard()
    }
}
