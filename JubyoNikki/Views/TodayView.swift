import SwiftData
import SwiftUI

struct TodayView: View {
    @Query(sort: \DiaryEntry.dayKey, order: .reverse) private var entries: [DiaryEntry]
    @ObservedObject private var theme = ThemeStore.shared
    @ObservedObject private var reminder = Reminder.shared
    @ObservedObject private var ads = RewardedAds.shared
    @State private var showRecover = false
    @Binding var showWrite: Bool
    /// 表示している日（左右のボタンか横スワイプで前後の日へ。未来には進めない）
    @State private var day = Calendar.current.date(
        byAdding: .day, value: -UserDefaults.standard.integer(forKey: "dayOffset"),  // -dayOffset N：撮影用に N 日前を開く
        to: Calendar.current.startOfDay(for: Date()))!
    /// 日を移るときに新しい日が入ってくる向き
    @State private var slideFrom: Edge = .trailing

    private var isToday: Bool { Calendar.current.isDateInToday(day) }
    private var dayKey: String { Day.key(day) }
    private var shown: DiaryEntry? { entries.first { $0.dayKey == dayKey } }

    private var today: DiaryEntry? { entries.first { $0.dayKey == Day.key() } }
    private var streak: Int { Day.streak(keys: Set(entries.map(\.dayKey))) }
    private var totalChars: Int { entries.reduce(0) { $0 + $1.text.filter { !$0.isWhitespace }.count } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    dateHeader
                    VStack(spacing: 20) {
                        if isToday {
                            if let today { writtenCard(today) } else { startCard }
                            if canRecover { recoverCard }
                            if reminder.notAsked { askCard }
                        } else if let shown {
                            writtenCard(shown)
                        } else if dayKey == yesterdayKey && canRecover {
                            recoverCard
                        } else {
                            emptyDayCard
                        }
                    }
                    .id(dayKey)
                    .transition(.asymmetric(insertion: .move(edge: slideFrom).combined(with: .opacity),
                                            removal: .opacity))
                    statsCard
                    if isToday && !entries.filter({ $0.dayKey != Day.key() }).isEmpty { recent }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            // 横にスワイプして前後の日へ（縦のスクロールとは向きで見分ける）
            .simultaneousGesture(
                DragGesture(minimumDistance: 30).onEnded { v in
                    let w = v.translation.width, h = v.translation.height
                    guard abs(w) > 60, abs(w) > abs(h) * 1.5 else { return }
                    shiftDay(w < 0 ? 1 : -1)
                }
            )
            .dlScreen(isToday ? "今日" : "この日の日記")
            // 開いたまま日付が変わったら、昨日（だった今日）を見ていた人は新しい今日へ
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
                let cal = Calendar.current
                if let y = cal.date(byAdding: .day, value: -1, to: cal.startOfDay(for: Date())), day == y { goToday() }
            }
            .fullScreenCover(isPresented: $showRecover) {
                WriteView(dayKey: yesterdayKey, recovering: true)
            }
        }
    }

    // MARK: 日付（Our Music の今日の画面と同じ「‹ 日付 ›」）

    private var dateHeader: some View {
        HStack {
            circleButton("chevron.left") { shiftDay(-1) }
            Spacer()
            VStack(spacing: 2) {
                Text(Day.label(day))
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.dlText)
                if !isToday {
                    Button("今日に戻る") { goToday() }
                        .font(.caption)
                        .foregroundColor(.dlPrimary)
                }
            }
            Spacer()
            circleButton("chevron.right") { shiftDay(1) }
                .opacity(isToday ? 0.3 : 1)
                .disabled(isToday)
        }
        .padding(.top, 4)
    }

    private func circleButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .foregroundColor(.dlPrimary)
                .frame(width: 36, height: 36)
                .background(Color.dlPrimaryBg)
                .clipShape(Circle())
        }
    }

    private func shiftDay(_ delta: Int) {
        let cal = Calendar.current
        guard let next = cal.date(byAdding: .day, value: delta, to: day),
              next <= cal.startOfDay(for: Date()) else { return }
        slideFrom = delta > 0 ? .trailing : .leading
        withAnimation(.easeOut(duration: 0.25)) { day = next }
    }

    private func goToday() {
        slideFrom = .trailing
        withAnimation(.easeOut(duration: 0.25)) { day = Calendar.current.startOfDay(for: Date()) }
    }

    /// 書いていない過去の日（昨日は広告のカード、それより前はこれ）
    private var emptyDayCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "book.closed")
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.dlTextLight)
            Text("この日の日記はありません")
                .font(.headline)
                .foregroundColor(.dlTextSub)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .dlCard()
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
                Text(isToday ? "今日の日記" : (e.recovered ? "あとから書いた日記" : "この日の日記"))
                    .font(.subheadline.weight(.semibold)).foregroundColor(.dlTextSub)
                Spacer()
                Text("\(Int(e.seconds.rounded()))秒")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.dlPrimary)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color.dlPrimaryBg)
                    .clipShape(Capsule())
            }
            Text(e.text)
                .font(.body)
                .foregroundColor(.dlText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.dlCardTint)
                .cornerRadius(14)
            // 前の日は直せない（10秒追加は今日だけ）
            if isToday {
                Button {
                    showWrite = true
                } label: {
                    Label("10秒追加", systemImage: "plus")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            if isToday, let next = reminder.nextFire(writtenToday: true) {
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
                Text(Day.label(entry.date)).font(.caption.weight(.semibold)).foregroundColor(.dlTextSub)
                Spacer()
                Text("\(Int(entry.seconds.rounded()))秒").font(.caption).foregroundColor(.dlTextLight)
            }
            Text(entry.text)
                .font(.body)
                .foregroundColor(.dlText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .dlCard()
    }
}
