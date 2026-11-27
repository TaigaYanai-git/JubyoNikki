import SwiftUI
import WidgetKit

/// ホーム画面のウィジェット。連続日数と「今日まだ／書けた」を出し、タップするとすぐ 10 秒が始まる
@main
struct JubyoWidgetBundle: WidgetBundle {
    var body: some Widget { JubyoWidget() }
}

struct JubyoWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "JubyoWidget", provider: Provider()) { entry in
            JubyoWidgetView(entry: entry)
        }
        .configurationDisplayName("10秒日記")
        .description("連続日数と今日書いたか。タップするとすぐ書きはじめます。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct DayEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> DayEntry {
        DayEntry(date: Date(), snapshot: WidgetSnapshot(lastKey: SharedDay.key(), streakAtLast: 12, lastText: "", totalChars: 340))
    }

    func getSnapshot(in context: Context, completion: @escaping (DayEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : DayEntry(date: Date(), snapshot: .load()))
    }

    /// 今と、この先 3 日の 0 時（日付が変わると「今日まだ」に戻る）
    func getTimeline(in context: Context, completion: @escaping (Timeline<DayEntry>) -> Void) {
        let snap = WidgetSnapshot.load()
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        var entries = [DayEntry(date: Date(), snapshot: snap)]
        for i in 1...3 { entries.append(DayEntry(date: cal.date(byAdding: .day, value: i, to: start)!, snapshot: snap)) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct JubyoWidgetView: View {
    let entry: DayEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var scheme

    private var snap: WidgetSnapshot { entry.snapshot }
    private var done: Bool { snap.written(on: SharedDay.key(entry.date)) }
    private var streak: Int { snap.streak(on: entry.date) }
    private var primary: Color { color(snap.primary) }
    private var primaryEnd: Color { color(snap.primaryEnd) }
    private var text: Color { scheme == .dark ? Color(red: 0.93, green: 0.90, blue: 0.97) : Color(red: 0.180, green: 0.145, blue: 0.251) }
    private var sub: Color { scheme == .dark ? Color(red: 0.62, green: 0.60, blue: 0.70) : Color(red: 0.557, green: 0.541, blue: 0.600) }
    private var bg: Color { scheme == .dark ? Color(red: 0.15, green: 0.13, blue: 0.22) : .white }

    private func color(_ c: [Double]) -> Color {
        c.count == 3 ? Color(red: c[0], green: c[1], blue: c[2]) : .indigo
    }

    var body: some View {
        Group {
            if family == .systemMedium {
                HStack(spacing: 16) {
                    ring
                    VStack(alignment: .leading, spacing: 6) {
                        Text(done ? "今日の日記" : "今日はまだ")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(sub)
                        Text(done ? snap.lastText : "10秒だけ、今日のことを。")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(text)
                            .lineLimit(3)
                        Spacer(minLength: 0)
                        status
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        ring.frame(width: 54, height: 54)
                        Spacer()
                    }
                    Spacer(minLength: 0)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(streak)")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(text)
                            .monospacedDigit()
                        Text("日連続").font(.caption.weight(.semibold)).foregroundColor(sub)
                    }
                    status
                }
            }
        }
        .containerBackground(bg, for: .widget)
        .widgetURL(URL(string: done ? "jubyonikki://today" : "jubyonikki://write"))
    }

    /// 書いた日は輪がいっぱい、まだの日は「10」
    private var ring: some View {
        ZStack {
            Circle().stroke(primary.opacity(0.15), lineWidth: 7)
            Circle()
                .stroke(LinearGradient(colors: [primary, primaryEnd], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 7, lineCap: .round))
            if done {
                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(primary)
            } else {
                Text("10")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(text)
            }
        }
        .frame(width: family == .systemMedium ? 92 : 54, height: family == .systemMedium ? 92 : 54)
    }

    private var status: some View {
        Text(done ? "今日は書けました" : "タップして10秒")
            .font(.caption2.weight(.semibold))
            .foregroundColor(done ? sub : primary)
    }
}
