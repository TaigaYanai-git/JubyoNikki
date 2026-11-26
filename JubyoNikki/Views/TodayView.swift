import SwiftData
import SwiftUI

struct TodayView: View {
    @Query(sort: \DiaryEntry.dayKey, order: .reverse) private var entries: [DiaryEntry]
    @ObservedObject private var theme = ThemeStore.shared
    @ObservedObject private var reminder = Reminder.shared
    @Binding var showWrite: Bool

    private var today: DiaryEntry? { entries.first { $0.dayKey == Day.key() } }
    private var streak: Int { Day.streak(keys: Set(entries.map(\.dayKey))) }
    private var totalChars: Int { entries.reduce(0) { $0 + $1.text.filter { !$0.isWhitespace }.count } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text(Day.label(Date()))
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.dlText)
                        .padding(.top, 4)
                    if let today { writtenCard(today) } else { startCard }
                    statsCard
                    if !entries.filter({ $0.dayKey != Day.key() }).isEmpty { recent }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .dlScreen("今日")
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
        }
        .dlCard(padding: 22)
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
            Text(e.text)
                .font(.body)
                .foregroundColor(.dlText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.dlCardTint)
                .cornerRadius(14)
            Button {
                showWrite = true
            } label: {
                Label("10秒 書き足す", systemImage: "plus")
            }
            .buttonStyle(SecondaryButtonStyle())
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
