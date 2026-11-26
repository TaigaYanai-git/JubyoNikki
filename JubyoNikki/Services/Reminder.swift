import Foundation
import UserNotifications

/// 毎日決まった時刻の通知。書いた日は鳴らさないよう、くり返しの通知ではなく
/// 先 14 日ぶんを1つずつ予約し、アプリを開いたときと書いたときに入れ直す。
@MainActor
final class Reminder: ObservableObject {
    static let shared = Reminder()

    @Published var isOn: Bool { didSet { UserDefaults.standard.set(isOn, forKey: "reminderOn"); Task { await reschedule() } } }
    @Published var hour: Int { didSet { UserDefaults.standard.set(hour, forKey: "reminderHour") } }
    @Published var minute: Int { didSet { UserDefaults.standard.set(minute, forKey: "reminderMinute") } }
    @Published var denied = false
    /// まだ許可を聞いていない（今日の画面にお知らせのカードを出す）
    @Published var notAsked = false

    /// 最後に入れ直したときの「今日書いたか」
    private var writtenToday: () -> Bool = { false }

    private init() {
        let ud = UserDefaults.standard
        isOn = ud.object(forKey: "reminderOn") as? Bool ?? true
        hour = ud.object(forKey: "reminderHour") as? Int ?? 20
        minute = ud.object(forKey: "reminderMinute") as? Int ?? 0
    }

    var time: Date {
        get { Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date() }
        set {
            let c = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            hour = c.hour ?? 20
            minute = c.minute ?? 0
            Task { await reschedule() }
        }
    }

    var timeLabel: String { String(format: "%d:%02d", hour, minute) }

    func setWrittenToday(_ f: @escaping () -> Bool) { writtenToday = f }

    /// 許可の状態を読み直す（起動時・前面に戻ったとき）。ここでは許可を聞かない
    func refresh() async {
        let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        notAsked = status == .notDetermined
        denied = status == .denied
        await reschedule()
    }

    /// 今日の画面のカードから呼ぶ。断られたら denied を立てる
    func requestPermission() async {
        let ok = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
        notAsked = false
        denied = !ok
        if ok { isOn = true }
        await reschedule()
    }

    /// 次にお知らせする日時（オフ・未許可なら nil）
    func nextFire(writtenToday: Bool) -> Date? {
        guard isOn, !denied, !notAsked else { return nil }
        let cal = Calendar.current
        let now = Date()
        for offset in 0..<2 {
            guard let day = cal.date(byAdding: .day, value: offset, to: now),
                  let fire = cal.date(bySettingHour: hour, minute: minute, second: 0, of: day),
                  fire > now else { continue }
            if offset == 0 && writtenToday { continue }
            return fire
        }
        return nil
    }

    func reschedule() async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard isOn, !denied, !notAsked else { return }
        let cal = Calendar.current
        let now = Date()
        let lines = [
            "10秒だけ、今日のことを。",
            "書いている間は、時計が戻ります。",
            "今日いちばん覚えていることは？",
            "10秒で終わります。開くだけでも。",
            "今日の自分に、10秒だけ。",
        ]
        for offset in 0..<14 {
            guard let day = cal.date(byAdding: .day, value: offset, to: now),
                  let fire = cal.date(bySettingHour: hour, minute: minute, second: 0, of: day),
                  fire > now else { continue }
            if offset == 0 && writtenToday() { continue }
            let content = UNMutableNotificationContent()
            content.title = "10秒日記"
            content.body = lines[cal.ordinality(of: .day, in: .era, for: day)! % lines.count]
            content.sound = .default
            content.userInfo = ["open": "write"]
            let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
            let req = UNNotificationRequest(identifier: "diary-\(Day.key(day))",
                                            content: content,
                                            trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false))
            try? await center.add(req)
        }
    }
}

/// 通知を押したら書く画面を開く
final class NotificationRouter: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationRouter()
    @Published var openWrite = false

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        await MainActor.run { openWrite = true }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
