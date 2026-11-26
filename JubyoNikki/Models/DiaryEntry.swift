import Foundation
import SwiftData

/// 1日1つの日記。書き足すと text の後ろに続き、seconds（使った秒数）が増える
@Model
final class DiaryEntry {
    var dayKey: String = ""
    var text: String = ""
    var seconds: Double = 0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(dayKey: String, text: String, seconds: Double) {
        self.dayKey = dayKey
        self.text = text
        self.seconds = seconds
    }

    var date: Date { Day.date(from: dayKey) ?? createdAt }
}

enum Day {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func key(_ date: Date = Date()) -> String { formatter.string(from: date) }
    static func date(from key: String) -> Date? { formatter.date(from: key) }

    static func label(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "M月d日 (E)"
        return f.string(from: date)
    }

    /// 今日から遡って続いている日数（今日まだ書いていなければ昨日から数える）
    static func streak(keys: Set<String>) -> Int {
        let cal = Calendar.current
        var day = Date()
        if !keys.contains(key(day)) { day = cal.date(byAdding: .day, value: -1, to: day)! }
        var n = 0
        while keys.contains(key(day)) {
            n += 1
            day = cal.date(byAdding: .day, value: -1, to: day)!
        }
        return n
    }
}
