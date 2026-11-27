import Foundation

/// アプリとウィジェットで共有するもの（App Group の UserDefaults と、日替わりのお題）
enum AppGroup {
    static let id = "group.com.taigayanai.jubyonikki"
    static var defaults: UserDefaults { UserDefaults(suiteName: id) ?? .standard }
}

/// ウィジェットに渡す今の状態。アプリが書いて、ウィジェットが読む
struct WidgetSnapshot: Codable {
    /// 最後に書いた日（yyyy-MM-dd）
    var lastKey: String?
    /// lastKey の日までの連続日数
    var streakAtLast: Int = 0
    /// 最後に書いた日の文
    var lastText: String = ""
    /// これまでの文字数
    var totalChars: Int = 0
    /// テーマカラー（RGB）
    var primary: [Double] = [0.22, 0.28, 0.62]
    var primaryEnd: [Double] = [0.40, 0.47, 0.82]

    private static let key = "widgetSnapshot"

    static func load() -> WidgetSnapshot {
        guard let data = AppGroup.defaults.data(forKey: key),
              let s = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else { return WidgetSnapshot() }
        return s
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) { AppGroup.defaults.set(data, forKey: Self.key) }
    }

    /// その日に書いてあるか
    func written(on dayKey: String) -> Bool { lastKey == dayKey }

    /// その日の時点の連続日数（今日まだなら昨日までで数える。途切れていれば 0）
    func streak(on day: Date) -> Int {
        guard let lastKey else { return 0 }
        let cal = Calendar.current
        let today = SharedDay.key(day)
        let yesterday = SharedDay.key(cal.date(byAdding: .day, value: -1, to: day)!)
        return lastKey == today || lastKey == yesterday ? streakAtLast : 0
    }
}

enum SharedDay {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    static func key(_ date: Date = Date()) -> String { formatter.string(from: date) }
}

/// 書くことがない時のヒント（書く画面の入力欄に薄く出す）。日替わり
enum Prompt {
    static let all = [
        "今日いちばん笑ったこと",
        "今日食べたもので、いちばんおいしかったもの",
        "今日だれと話した？",
        "今日の空はどんな色だった？",
        "今日がんばったこと、ひとつ",
        "今日ちょっとだけ嬉しかったこと",
        "今日のもやもや、ひとこと",
        "今日の自分に点数をつけるなら",
        "明日やりたいこと",
        "今日聴いた音楽",
        "今日見つけた小さな発見",
        "今日いちばん長くいた場所",
        "今日ありがとうと言いたい人",
        "今日の失敗、ひとつ",
        "今日の天気と気分",
        "今日買ったもの",
        "今日いちばん疲れたこと",
        "今日の自分をほめるなら",
        "今日ふと思い出したこと",
        "今日の一枚の写真を言葉にするなら",
        "今日の晩ごはん",
        "今日いちばん集中できた時間",
        "今日読んだ・見たもの",
        "最近ハマっていること",
        "今日の朝いちばんに考えたこと",
        "今日のいい匂い",
        "今週の楽しみ",
        "今日のちょっとした贅沢",
        "今日がもう一回あるなら、何を変える？",
        "今日の自分にひとこと",
    ]

    static func of(_ date: Date = Date()) -> String {
        let days = Int(Calendar.current.startOfDay(for: date).timeIntervalSince1970 / 86400)
        return all[((days % all.count) + all.count) % all.count]
    }
}
