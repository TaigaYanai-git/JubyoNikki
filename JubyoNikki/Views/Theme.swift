import SwiftUI
import UIKit

// Our Music（~/WatashiToOngaku の UIComponents.swift / ThemeStore.swift）と同じ色・部品。
// 薄いラベンダーの背景に水玉、白いカード、テーマカラーのグラデーションのボタン。

extension Color {
    static let dlBg = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.09, blue: 0.14, alpha: 1)   // #1C1724 dark plum
            : UIColor(red: 0.969, green: 0.957, blue: 0.988, alpha: 1) // #F7F4FC light lavender
    })
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

/// 背景テーマ（Our Music の BgPattern と同じ）
enum BgPattern: Int, CaseIterable {
    case none = 0, dots = 1, border = 2, borderV = 3, stars = 4, hearts = 5
    var label: String {
        switch self {
        case .none: return "なし"
        case .dots: return "水玉"
        case .border: return "ボーダー"
        case .borderV: return "ボーダー（縦）"
        case .stars: return "スター"
        case .hearts: return "ハート"
        }
    }
}

struct ThemeAccent: Identifiable {
    let id: Int
    let name: String
    let primary: Color
    let primaryEnd: Color
    let primaryBg: Color
    var needsBorder: Bool = false
}

final class ThemeStore: ObservableObject {
    static let shared = ThemeStore()

    @Published var accentIndex: Int {
        didSet { UserDefaults.standard.set(accentIndex, forKey: "accentID") }
    }
    @Published var isDark: Bool {
        didSet { UserDefaults.standard.set(isDark, forKey: "isDark") }
    }
    @Published var bgPatternIndex: Int {
        didSet { UserDefaults.standard.set(bgPatternIndex, forKey: "bgPattern") }
    }

    var accent: ThemeAccent {
        Self.accents.first { $0.id == accentIndex } ?? Self.accents[0]
    }

    /// 初期値のテーマカラー（Our Music との違いはここだけ）。日記は夜に一人で書くもので、
    /// 深い青（インディゴ）は落ち着き・内省・秘密を守る信頼を連想させる
    static let defaultAccent = 9

    // Our Music の ThemeStore.accents と同じ 9 色の前にインディゴ（id は保存する値なので変えない）
    static let accents: [ThemeAccent] = [
        ThemeAccent(id: 9, name: "インディゴ",
                    primary:    Color(red: 0.22, green: 0.28, blue: 0.62),
                    primaryEnd: Color(red: 0.40, green: 0.47, blue: 0.82),
                    primaryBg:  Color(red: 0.90, green: 0.92, blue: 0.98)),
        ThemeAccent(id: 0, name: "ブラック",
                    primary:    Color(red: 0.22, green: 0.22, blue: 0.25),
                    primaryEnd: Color(red: 0.40, green: 0.40, blue: 0.44),
                    primaryBg:  Color(red: 0.91, green: 0.91, blue: 0.93)),
        ThemeAccent(id: 1, name: "ホワイト",
                    primary:    Color(white: 0.72),
                    primaryEnd: Color(white: 0.86),
                    primaryBg:  Color(white: 0.96),
                    needsBorder: true),
        ThemeAccent(id: 2, name: "ローズ",
                    primary:    Color(red: 0.898, green: 0.451, blue: 0.600),
                    primaryEnd: Color(red: 0.957, green: 0.655, blue: 0.765),
                    primaryBg:  Color(red: 0.988, green: 0.894, blue: 0.925)),
        ThemeAccent(id: 3, name: "コーラル",
                    primary:    Color(red: 0.878, green: 0.482, blue: 0.482),
                    primaryEnd: Color(red: 0.949, green: 0.639, blue: 0.639),
                    primaryBg:  Color(red: 1.000, green: 0.922, blue: 0.933)),
        ThemeAccent(id: 4, name: "サンセット",
                    primary:    Color(red: 0.910, green: 0.537, blue: 0.353),
                    primaryEnd: Color(red: 0.957, green: 0.690, blue: 0.478),
                    primaryBg:  Color(red: 0.984, green: 0.914, blue: 0.906)),
        ThemeAccent(id: 5, name: "レモン",
                    primary:    Color(red: 0.871, green: 0.761, blue: 0.247),
                    primaryEnd: Color(red: 0.941, green: 0.867, blue: 0.529),
                    primaryBg:  Color(red: 0.996, green: 0.984, blue: 0.882)),
        ThemeAccent(id: 6, name: "ミント",
                    primary:    Color(red: 0.298, green: 0.686, blue: 0.510),
                    primaryEnd: Color(red: 0.502, green: 0.796, blue: 0.659),
                    primaryBg:  Color(red: 0.878, green: 0.949, blue: 0.933)),
        ThemeAccent(id: 7, name: "スカイ",
                    primary:    Color(red: 0.290, green: 0.565, blue: 0.812),
                    primaryEnd: Color(red: 0.510, green: 0.753, blue: 0.910),
                    primaryBg:  Color(red: 0.890, green: 0.949, blue: 0.992)),
        ThemeAccent(id: 8, name: "ラベンダー",
                    primary:    Color(red: 0.647, green: 0.482, blue: 0.878),
                    primaryEnd: Color(red: 0.800, green: 0.639, blue: 0.949),
                    primaryBg:  Color(red: 0.929, green: 0.882, blue: 0.984)),
    ]

    private init() {
        let ud = UserDefaults.standard
        // 保存の名前は Our Music に合わせて作り直したもの（前の "accent" / "background" とは番号の意味が違う）
        accentIndex = ud.object(forKey: "accentID") as? Int ?? Self.defaultAccent
        isDark = ud.bool(forKey: "isDark")
        // 初めては Our Music と同じく水玉
        bgPatternIndex = ud.object(forKey: "bgPattern") as? Int ?? BgPattern.dots.rawValue
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
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.dlCard)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
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

// Our Music の UIComponents.swift の DlBackground / AppBackgroundPattern をそのまま
/// Drop-in replacement for `Color.dlBg` that also renders the selected background pattern.
struct DlBackground: View {
    @ObservedObject private var theme = ThemeStore.shared
    var body: some View {
        ZStack {
            Color.dlBg
            if theme.bgPatternIndex > 0 {
                AppBackgroundPattern(patternIndex: theme.bgPatternIndex, primary: theme.accent.primary)
            }
        }
    }
}

struct AppBackgroundPattern: View {
    let patternIndex: Int
    let primary: Color

    var body: some View {
        Canvas { ctx, size in
            let c = primary.opacity(0.08)
            switch patternIndex {
            case 1:
                // 水玉 — offset every other row
                let spacing: CGFloat = 24
                let r: CGFloat = 2.8
                var row = 0
                var y = spacing * 0.5
                while y < size.height + spacing {
                    let xOff: CGFloat = row % 2 == 0 ? 0 : spacing * 0.5
                    var x = spacing * 0.5 + xOff
                    while x < size.width + spacing {
                        ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r,
                                                        width: r * 2, height: r * 2)),
                                 with: .color(c))
                        x += spacing
                    }
                    y += spacing * 0.866
                    row += 1
                }
            case 2:
                // ボーダー（横）
                let spacing: CGFloat = 22
                var y = spacing
                while y < size.height {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    ctx.stroke(path, with: .color(c), lineWidth: 1)
                    y += spacing
                }
            case 3:
                // ボーダー（縦）
                let spacing: CGFloat = 22
                var x = spacing
                while x < size.width {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    ctx.stroke(path, with: .color(c), lineWidth: 1)
                    x += spacing
                }
            case 4:
                // スター — same offset grid as 水玉
                let spacing: CGFloat = 24
                let outerR: CGFloat = 5.0
                let innerR: CGFloat = outerR * 0.4
                var row = 0
                var y = spacing * 0.5
                while y < size.height + spacing {
                    let xOff: CGFloat = row % 2 == 0 ? 0 : spacing * 0.5
                    var x = spacing * 0.5 + xOff
                    while x < size.width + spacing {
                        ctx.fill(Self.starPath(cx: x, cy: y, outerR: outerR, innerR: innerR),
                                 with: .color(c))
                        x += spacing
                    }
                    y += spacing * 0.866
                    row += 1
                }
            case 5:
                // ハート — same offset grid as 水玉
                let spacing: CGFloat = 26
                let s: CGFloat = 5.0
                var row = 0
                var y = spacing * 0.5
                while y < size.height + spacing {
                    let xOff: CGFloat = row % 2 == 0 ? 0 : spacing * 0.5
                    var x = spacing * 0.5 + xOff
                    while x < size.width + spacing {
                        ctx.fill(Self.heartPath(cx: x, cy: y, s: s), with: .color(c))
                        x += spacing
                    }
                    y += spacing * 0.866
                    row += 1
                }
            default: break
            }
        }
    }

    // 5-pointed star
    private static func starPath(cx: CGFloat, cy: CGFloat, outerR: CGFloat, innerR: CGFloat) -> Path {
        var p = Path()
        for i in 0..<10 {
            let angle = CGFloat(i) * .pi / 5 - .pi / 2
            let r = i % 2 == 0 ? outerR : innerR
            let pt = CGPoint(x: cx + r * cos(angle), y: cy + r * sin(angle))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }

    // Parametric heart: x=16sin³t, y=-(13cost-5cos2t-2cos3t-cos4t)
    // s controls half-width (total width = 2s); heart is visually centered at (cx, cy)
    private static func heartPath(cx: CGFloat, cy: CGFloat, s: CGFloat) -> Path {
        let scale = s / 16.0
        // Shift so visual center (midpoint of y-extent) sits at cy
        // y-extent: top ≈ -11.5*scale above math origin, bottom ≈ 17*scale below → center at +2.75*scale
        let oy = cy - scale * 2.75
        let steps = 64
        var p = Path()
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps) * 2 * .pi
            let x = cx + 16 * pow(sin(t), 3) * scale
            let y = oy - (13 * cos(t) - 5 * cos(2*t) - 2 * cos(3*t) - cos(4*t)) * scale
            if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
            else       { p.addLine(to: CGPoint(x: x, y: y)) }
        }
        p.closeSubpath()
        return p
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
