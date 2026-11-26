import SwiftData
import SwiftUI

struct CalendarView: View {
    @Query(sort: \DiaryEntry.dayKey) private var entries: [DiaryEntry]
    @ObservedObject private var theme = ThemeStore.shared
    @State private var month = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!
    @State private var selected: DiaryEntry?

    private let cal = Calendar.current
    private var byKey: [String: DiaryEntry] { Dictionary(entries.map { ($0.dayKey, $0) }, uniquingKeysWith: { a, _ in a }) }

    private var days: [Date?] {
        let range = cal.range(of: .day, in: .month, for: month)!
        let lead = cal.component(.weekday, from: month) - 1
        return Array(repeating: nil, count: lead) + range.map { cal.date(byAdding: .day, value: $0 - 1, to: month) }
    }

    private var monthEntries: [DiaryEntry] {
        days.compactMap { $0 }.compactMap { byKey[Day.key($0)] }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    monthHeader
                    grid
                    summary
                    ForEach(monthEntries.reversed()) { EntryRow(entry: $0) }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .dlScreen("カレンダー")
            .sheet(item: $selected) { e in
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(Day.label(e.date)).font(.headline).foregroundColor(.dlText)
                        Text(e.text).font(.body).foregroundColor(.dlText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16).background(Color.dlCardTint).cornerRadius(14)
                        Text("\(Int(e.seconds.rounded()))秒で書きました").font(.caption).foregroundColor(.dlTextSub)
                    }
                    .padding(24)
                }
                .background(Color.dlBg.ignoresSafeArea())
                .presentationDetents([.medium, .large])
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            circleButton("chevron.left") { shift(-1) }
            Spacer()
            Text(month.formatted(.dateTime.year().month(.wide).locale(Locale(identifier: "ja_JP"))))
                .font(.title3.weight(.semibold)).foregroundColor(.dlText)
            Spacer()
            circleButton("chevron.right") { shift(1) }
                .opacity(isCurrentMonth ? 0.3 : 1)
                .disabled(isCurrentMonth)
        }
        .padding(.horizontal, 4)
    }

    private var isCurrentMonth: Bool { cal.isDate(month, equalTo: Date(), toGranularity: .month) }

    private func shift(_ n: Int) {
        withAnimation(.easeOut(duration: 0.2)) { month = cal.date(byAdding: .month, value: n, to: month)! }
    }

    private func circleButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.dlText)
                .frame(width: 44, height: 44)
                .background(Color.dlCardTint.opacity(0.8))
                .clipShape(Circle())
        }
    }

    private var grid: some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 7), count: 7)
        return VStack(spacing: 10) {
            HStack {
                ForEach(["日", "月", "火", "水", "木", "金", "土"], id: \.self) {
                    Text($0).font(.caption.weight(.semibold)).foregroundColor(.dlTextLight).frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: cols, spacing: 7) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, d in
                    if let d { cell(d) } else { Color.clear.aspectRatio(1, contentMode: .fit) }
                }
            }
        }
    }

    private func cell(_ d: Date) -> some View {
        let key = Day.key(d)
        let e = byKey[key]
        let future = d > Date() && !cal.isDateInToday(d)
        let isToday = cal.isDateInToday(d)
        return Button { selected = e } label: {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(e != nil
                          ? AnyShapeStyle(LinearGradient(colors: [.dlPrimary, .dlPrimaryEnd], startPoint: .topLeading, endPoint: .bottomTrailing))
                          : AnyShapeStyle(Color.dlCard.opacity(future ? 0.4 : 1)))
                Text("\(cal.component(.day, from: d))")
                    .font(.caption.weight(.bold))
                    .foregroundColor(e != nil ? .white : (future ? .dlTextLight.opacity(0.6) : .dlTextLight))
                    .padding(6)
                if let e, e.recovered {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(7)
                }
                if let e {
                    Text("\(Int(e.seconds.rounded()))秒")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(6)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.dlText, lineWidth: isToday ? 2.5 : 0))
            .shadow(color: .black.opacity(e != nil ? 0.08 : 0), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(e == nil)
    }

    private var summary: some View {
        let keys = Set(entries.map(\.dayKey))
        var longest = 0, run = 0
        var prev: Date?
        for e in entries {
            if let p = prev, cal.dateComponents([.day], from: p, to: e.date).day == 1 { run += 1 } else { run = 1 }
            longest = max(longest, run)
            prev = e.date
        }
        return HStack(spacing: 0) {
            stat("\(monthEntries.count)日", "この月の日記")
            Divider().frame(height: 40).overlay(Color.dlDivider)
            stat("\(Day.streak(keys: keys))日", "現在の連続")
            Divider().frame(height: 40).overlay(Color.dlDivider)
            stat("\(longest)日", "最長記録")
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
}
