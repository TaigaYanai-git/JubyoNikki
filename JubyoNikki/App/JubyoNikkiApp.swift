import SwiftData
import SwiftUI
import UserNotifications

@main
struct JubyoNikkiApp: App {
    let container: ModelContainer

    init() {
        UNUserNotificationCenter.current().delegate = NotificationRouter.shared
        // -demo：スクリーンショット用にメモリ上の見本の日記を入れる（本物の日記には触れない）
        let demo = ProcessInfo.processInfo.arguments.contains("-demo")
        let config = ModelConfiguration(isStoredInMemoryOnly: demo)
        container = try! ModelContainer(for: DiaryEntry.self, configurations: config)
        if demo { Demo.fill(container.mainContext) }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var phase
    @ObservedObject private var theme = ThemeStore.shared
    @ObservedObject private var router = NotificationRouter.shared
    @State private var tab = UserDefaults.standard.integer(forKey: "tab")  // -tab N で撮影用に選べる
    @State private var showWrite = ProcessInfo.processInfo.arguments.contains("-write")

    private var writtenToday: Bool {
        let key = Day.key()
        let d = FetchDescriptor<DiaryEntry>(predicate: #Predicate { $0.dayKey == key })
        return ((try? context.fetchCount(d)) ?? 0) > 0
    }

    var body: some View {
        TabView(selection: $tab) {
            TodayView(showWrite: $showWrite)
                .tabItem { Label("今日", systemImage: "pencil.line") }
                .tag(0)
            CalendarView()
                .tabItem { Label("カレンダー", systemImage: "calendar") }
                .tag(1)
            SettingsView()
                .tabItem { Label("設定", systemImage: "gearshape") }
                .tag(2)
        }
        .tint(.dlPrimary)
        .preferredColorScheme(theme.isDark ? .dark : .light)
        .fullScreenCover(isPresented: $showWrite) { WriteView() }
        // ウィジェットから：まだなら 10 秒をすぐ始める、書いた日は今日の画面へ
        .onOpenURL { url in
            tab = 0
            if url.host == "write" && !writtenToday { showWrite = true }
        }
        .onChange(of: theme.accentIndex) { _, _ in WidgetSync.update(context) }
        .onChange(of: router.openWrite) { _, open in
            guard open else { return }
            router.openWrite = false
            tab = 0
            showWrite = true
        }
        .task {
            Reminder.shared.setWrittenToday { [context] in
                let key = Day.key()
                let d = FetchDescriptor<DiaryEntry>(predicate: #Predicate { $0.dayKey == key })
                return ((try? context.fetchCount(d)) ?? 0) > 0
            }
            await Reminder.shared.refresh()
            WidgetSync.update(context)
        }
        .onChange(of: phase) { _, p in
            if p == .active {
                Task { await Reminder.shared.refresh() }
                WidgetSync.update(context)
            }
        }
    }
}

enum Demo {
    static func fill(_ context: ModelContext) {
        let lines = [
            "朝から雨。傘を忘れてコンビニで買った。",
            "会議が3つ。疲れた。",
            "久しぶりに自炊。カレー。",
            "ねむい",
            "友達から電話。来月会うことに。",
            "散歩していたら猫がいた。",
            "仕事が早く終わった。映画を観た。",
            "何もしなかった。それもよし。",
            "新しいノートを買った。",
            "",
            "母に電話した。元気そうでよかった。",
            "コーヒーをこぼした",
        ]
        let cal = Calendar.current
        // -demoMiss：昨日を空けて「昨日を取り戻す」カードを出す
        let miss = ProcessInfo.processInfo.arguments.contains("-demoMiss")
        for (i, line) in lines.enumerated() where !line.isEmpty && !(miss && i == 0) {
            let d = cal.date(byAdding: .day, value: -(i + 1), to: Date())!
            context.insert(DiaryEntry(dayKey: Day.key(d), text: line, seconds: 10 + Double(line.count)))
        }
        if ProcessInfo.processInfo.arguments.contains("-demoToday") {
            context.insert(DiaryEntry(dayKey: Day.key(), text: "10秒日記をはじめた。思ったより書ける。", seconds: 27))
        }
    }
}
