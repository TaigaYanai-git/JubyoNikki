import SwiftData
import SwiftUI
import UIKit
import WidgetKit

/// 日記の状態をウィジェットへ渡す（書いたとき・起動したとき・テーマを変えたとき）
enum WidgetSync {
    @MainActor
    static func update(_ context: ModelContext) {
        // 撮影用の見本データはウィジェットに出さない
        if ProcessInfo.processInfo.arguments.contains("-demo") { return }
        let all = (try? context.fetch(FetchDescriptor<DiaryEntry>(sortBy: [SortDescriptor(\.dayKey, order: .reverse)]))) ?? []
        var snap = WidgetSnapshot()
        if let last = all.first {
            snap.lastKey = last.dayKey
            snap.lastText = last.text
            let keys = Set(all.map(\.dayKey))
            var day = last.date
            var n = 0
            while keys.contains(Day.key(day)) {
                n += 1
                day = Calendar.current.date(byAdding: .day, value: -1, to: day)!
            }
            snap.streakAtLast = n
        }
        snap.totalChars = all.reduce(0) { $0 + WriteView.count($1.text) }
        snap.primary = rgb(.dlPrimary)
        snap.primaryEnd = rgb(.dlPrimaryEnd)
        snap.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    private static func rgb(_ c: Color) -> [Double] {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(c).getRed(&r, green: &g, blue: &b, alpha: &a)
        return [r, g, b].map(Double.init)
    }
}
