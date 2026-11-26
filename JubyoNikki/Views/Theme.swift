import SwiftUI
import UIKit

// Our Music（~/WatashiToOngaku の UIComponents.swift / ThemeStore.swift）と同じ色・部品。
// 薄いラベンダーの背景に水玉、白いカード、テーマカラーのグラデーションのボタン。

extension Color {
    /// 画面の背景。ライトでは「白」（初期値）か、Our Music と同じ薄いラベンダー
    static var dlBg: Color {
        let lavender = ThemeStore.shared.background != .white
        return Color(UIColor { t in
            t.userInterfaceStyle == .dark
                ? UIColor(red: 0.11, green: 0.09, blue: 0.14, alpha: 1)
                : (lavender ? UIColor(red: 0.969, green: 0.957, blue: 0.988, alpha: 1) : .white)
        })
    }
    static let dlCard = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.15, green: 0.13, blue: 0.22, alpha: 1)
            : UIColor.white
    })
    static let dlCardTint = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.19, green: 0.16, blue: 0.28, alpha: 1)
            : UIColor(red: 0.933, green: 0.910, blue: 0.984, alpha: 1)
    })
    static let dlDivider = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.24, green: 0.21, blue: 0.32, alpha: 1)
            : UIColor(red: 0.910, green: 0.890, blue: 0.941, alpha: 1)
    })
    static let dlText = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.93, green: 0.90, blue: 0.97, alpha: 1)
            : UIColor(red: 0.180, green: 0.145, blue: 0.251, alpha: 1)
    })
    static let dlTextSub = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.62, green: 0.60, blue: 0.70, alpha: 1)
            : UIColor(red: 0.557, green: 0.541, blue: 0.600, alpha: 1)
    })
    static let dlTextLight = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.42, green: 0.40, blue: 0.50, alpha: 1)
            : UIColor(red: 0.784, green: 0.769, blue: 0.831, alpha: 1)
    })

    static var dlPrimary: Color { ThemeStore.shared.accent.primary }
    static var dlPrimaryEnd: Color { ThemeStore.shared.accent.primaryEnd }
    static var dlPrimaryBg: Color { ThemeStore.shared.accent.primaryBg }
}

enum AppBackground: Int, CaseIterable, Identifiable {
    case white = 0, lavender = 1, dots = 2
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .white: return "白"
        case .lavender: return "ラベンダー"
        case .dots: return "水玉"
        }
    }
}

struct ThemeAccent: Identifiable {
    let id: Int
    let name: String
    let primary: Color
    let primaryEnd: Color
    let primaryBg: Color
}

final class ThemeStore: ObservableObject {
    static let shared = ThemeStore()

    @Published var accentIndex: Int {
        didSet { UserDefaults.standard.set(accentIndex, forKey: "accent") }
    }
    @Published var isDark: Bool {
        didSet { UserDefaults.standard.set(isDark, forKey: "isDark") }
    }
    @Published var background: AppBackground {
        didSet { UserDefaults.standard.set(background.rawValue, forKey: "background") }
    }
    var showsDots: Bool { background == .dots }

    var accent: ThemeAccent {
        Self.accents[Self.accents.indices.contains(accentIndex) ? accentIndex : 0]
    }

    static let accents: [ThemeAccent] = [
        ThemeAccent(id: 0, name: "ブラック",
                    primary: Color(red: 0.22, green: 0.22, blue: 0.25),
                    primaryEnd: Color(red: 0.40, green: 0.40, blue: 0.44),
                    primaryBg: Color(red: 0.91, green: 0.91, blue: 0.93)),
        ThemeAccent(id: 1, name: "ローズ",
                    primary: Color(red: 0.898, green: 0.451, blue: 0.600),
                    primaryEnd: Color(red: 0.957, green: 0.655, blue: 0.765),
                    primaryBg: Color(red: 0.988, green: 0.894, blue: 0.925)),
        ThemeAccent(id: 2, name: "サンセット",
                    primary: Color(red: 0.910, green: 0.537, blue: 0.353),
                    primaryEnd: Color(red: 0.957, green: 0.690, blue: 0.478),
                    primaryBg: Color(red: 0.984, green: 0.914, blue: 0.906)),
        ThemeAccent(id: 3, name: "レモン",
                    primary: Color(red: 0.871, green: 0.761, blue: 0.247),
                    primaryEnd: Color(red: 0.941, green: 0.867, blue: 0.529),
                    primaryBg: Color(red: 0.996, green: 0.984, blue: 0.882)),
        ThemeAccent(id: 4, name: "ミント",
                    primary: Color(red: 0.298, green: 0.686, blue: 0.510),
                    primaryEnd: Color(red: 0.502, green: 0.796, blue: 0.659),
                    primaryBg: Color(red: 0.878, green: 0.949, blue: 0.933)),
        ThemeAccent(id: 5, name: "スカイ",
                    primary: Color(red: 0.290, green: 0.565, blue: 0.812),
                    primaryEnd: Color(red: 0.510, green: 0.753, blue: 0.910),
                    primaryBg: Color(red: 0.890, green: 0.949, blue: 0.992)),
        ThemeAccent(id: 6, name: "ラベンダー",
                    primary: Color(red: 0.647, green: 0.482, blue: 0.878),
                    primaryEnd: Color(red: 0.800, green: 0.639, blue: 0.949),
                    primaryBg: Color(red: 0.929, green: 0.882, blue: 0.984)),
    ]

    private init() {
        let ud = UserDefaults.standard
        accentIndex = ud.integer(forKey: "accent")
        isDark = ud.bool(forKey: "isDark")
        background = AppBackground(rawValue: ud.integer(forKey: "background")) ?? .white
    }
}

// MARK: - 部品

private struct ThemedBody<Content: View>: View {
    @ObservedObject private var theme = ThemeStore.shared
    @ViewBuilder let content: () -> Content
    var body: some View { content() }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        ThemedBody {
            configuration.label
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    isEnabled
                        ? LinearGradient(colors: [.dlPrimary, .dlPrimaryEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color(.systemGray3), Color(.systemGray3)], startPoint: .top, endPoint: .bottom)
                )
                .cornerRadius(18)
                .shadow(color: isEnabled ? Color.dlPrimary.opacity(0.28) : .clear, radius: 12, x: 0, y: 6)
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
        }
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ThemedBody {
            configuration.label
                .font(.headline)
                .foregroundColor(.dlPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.dlPrimaryBg)
                .cornerRadius(18)
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
        }
    }
}

struct CardModifier: ViewModifier {
    var padding: CGFloat = 16
    @ObservedObject private var theme = ThemeStore.shared
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.dlCard)
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.dlDivider, lineWidth: theme.background == .white ? 1 : 0))
            .shadow(color: .black.opacity(theme.background == .white ? 0.04 : 0.05), radius: 12, x: 0, y: 4)
    }
}

extension View {
    func dlCard(padding: CGFloat = 16) -> some View { modifier(CardModifier(padding: padding)) }

    /// 画面の題（Our Music と同じく中央の小さめの太字）と水玉の背景
    func dlScreen(_ title: String) -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(DlBackground().ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
    }
}

/// 薄い背景＋テーマカラーの水玉
struct DlBackground: View {
    @ObservedObject private var theme = ThemeStore.shared
    var body: some View {
        ZStack {
            Color.dlBg
            if theme.showsDots {
                Canvas { ctx, size in
                    let c = Color.dlPrimary.opacity(0.08)
                    let spacing: CGFloat = 24, r: CGFloat = 2.8
                    var row = 0
                    var y = spacing * 0.5
                    while y < size.height + spacing {
                        var x = spacing * 0.5 + (row % 2 == 0 ? 0 : spacing * 0.5)
                        while x < size.width + spacing {
                            ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(c))
                            x += spacing
                        }
                        y += spacing * 0.866
                        row += 1
                    }
                }
            }
        }
    }
}

/// 設定などの1行（左に角丸の四角のアイコン）
struct SettingRow<Trailing: View>: View {
    let icon: String
    let title: String
    @ViewBuilder var trailing: () -> Trailing
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.dlTextSub)
                .frame(width: 40, height: 40)
                .background(Color.dlCardTint.opacity(0.7))
                .cornerRadius(11)
            Text(title).foregroundColor(.dlText)
            Spacer(minLength: 8)
            trailing()
        }
    }
}
