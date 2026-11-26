import GoogleMobileAds
import SwiftUI
import UIKit

/// 「昨日を取り戻す」ためのリワード広告（AdMob）。
/// 広告ユニット ID が空（本番の ID をまだ入れていない Release）のときは使えない扱いにして、カードごと出さない。
@MainActor
final class RewardedAds: NSObject, ObservableObject {
    static let shared = RewardedAds()

    static let unitID = (Bundle.main.object(forInfoDictionaryKey: "AdMobRewardedUnitID") as? String ?? "")
        .trimmingCharacters(in: .whitespaces)
    var isAvailable: Bool { !Self.unitID.isEmpty }

    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private var ad: RewardedAd?
    private var started = false
    private var earned = false
    private var onFinish: ((Bool) -> Void)?

    /// 先に読み込んでおく（カードが見えたとき）
    func preload() async {
        guard isAvailable, ad == nil, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        if !started {
            _ = await MobileAds.shared.start()
            started = true
        }
        do {
            let loaded = try await RewardedAd.load(with: Self.unitID, request: Request())
            loaded.fullScreenContentDelegate = self
            ad = loaded
        } catch {
            ad = nil
        }
    }

    /// 広告を見せる。最後まで見たら finish(true)、途中で閉じたり読み込めなかったら finish(false)
    func show(finish: @escaping (Bool) -> Void) async {
        errorMessage = nil
        if ad == nil { await preload() }
        guard let ad, let root = Self.topViewController() else {
            errorMessage = "広告を読み込めませんでした。通信の状態を確かめて、もう一度お試しください。"
            finish(false)
            return
        }
        earned = false
        onFinish = finish
        ad.present(from: root) { [weak self] in
            Task { @MainActor in self?.earned = true }
        }
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var vc = scene?.keyWindow?.rootViewController
        while let next = vc?.presentedViewController { vc = next }
        return vc
    }
}

extension RewardedAds: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            self.ad = nil
            let ok = self.earned
            self.onFinish?(ok)
            self.onFinish = nil
            if !ok { self.errorMessage = "最後まで見ると昨日の日記を書けます。" }
            await self.preload()
        }
    }

    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            self.ad = nil
            self.errorMessage = "広告を表示できませんでした。もう一度お試しください。"
            self.onFinish?(false)
            self.onFinish = nil
        }
    }
}
