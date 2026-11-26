import Foundation

/// 書き忘れた日の救済の 1 段目「しおり」。
/// 7 日続けて書くと 1 枚もらえて（最大 3 枚、始めたときに 1 枚）、昨日を書き忘れたときに 1 枚使うと広告なしで昨日を書ける。
/// しおりがないときだけ、2 段目の広告（RewardedAds）になる。
@MainActor
final class Shiori: ObservableObject {
    static let shared = Shiori()

    static let maxCount = 3
    static let streakPerShiori = 7

    @Published private(set) var count: Int {
        didSet { UserDefaults.standard.set(count, forKey: "shiori") }
    }
    /// 最後にしおりを渡した日（同じ日に 2 枚渡さない）
    private var lastAwardKey: String? {
        get { UserDefaults.standard.string(forKey: "shioriAwardDay") }
        set { UserDefaults.standard.set(newValue, forKey: "shioriAwardDay") }
    }

    private init() {
        // 始めたときに 1 枚（起動引数 -shiori N でも決められるよう integer で読む）
        let ud = UserDefaults.standard
        count = ud.object(forKey: "shiori") == nil ? 1 : ud.integer(forKey: "shiori")
    }

    /// 今日の日記を書いたあとに呼ぶ。連続が 7 の倍数になったら 1 枚渡して true
    func awardIfNeeded(streak: Int, todayKey: String) -> Bool {
        guard streak > 0, streak % Self.streakPerShiori == 0,
              lastAwardKey != todayKey, count < Self.maxCount else { return false }
        count += 1
        lastAwardKey = todayKey
        return true
    }

    /// しおりで昨日を書いて保存できたときに 1 枚減らす（書かずに閉じたら減らさない）
    func use() {
        if count > 0 { count -= 1 }
    }
}
