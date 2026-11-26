import SwiftUI

struct SettingsView: View {
    @ObservedObject private var theme = ThemeStore.shared
    @ObservedObject private var reminder = Reminder.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    section("お知らせ")
                    VStack(spacing: 14) {
                        SettingRow(icon: "bell", title: "毎日のお知らせ") {
                            Toggle("", isOn: $reminder.isOn).labelsHidden().tint(.dlPrimary)
                        }
                        if reminder.isOn {
                            Divider().overlay(Color.dlDivider)
                            SettingRow(icon: "clock", title: "時刻") {
                                DatePicker("", selection: Binding(get: { reminder.time }, set: { reminder.time = $0 }),
                                           displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }
                        }
                    }
                    .dlCard()
                    if reminder.denied {
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                        } label: {
                            Text("通知が許可されていません。iPhone の設定で許可してください。")
                                .font(.footnote).foregroundColor(.dlTextSub).multilineTextAlignment(.leading)
                        }
                        .padding(.horizontal, 4)
                    } else {
                        Text("書いた日はお知らせしません。")
                            .font(.footnote).foregroundColor(.dlTextSub).padding(.horizontal, 4)
                    }

                    // テーマカラーと背景テーマは Our Music の設定画面と同じ形
                    section("テーマカラー").padding(.top, 10)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(ThemeStore.accents) { accent in
                                accentButton(accent)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 4)
                    }
                    .padding(.horizontal, -20)

                    section("背景テーマ").padding(.top, 10)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                        ForEach(BgPattern.allCases, id: \.rawValue) { bgPatternButton($0) }
                    }

                    VStack(spacing: 14) {
                        SettingRow(icon: "moon", title: "ダークモード") {
                            Toggle("", isOn: $theme.isDark).labelsHidden().tint(.dlPrimary)
                        }
                    }
                    .dlCard()
                    .padding(.top, 6)

                    section("このアプリについて").padding(.top, 10)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("忙しい日も、やる気のない日も。\n10秒だけなら続けられる日記です。書いている間は時計が止まります。日記はこの iPhone の中にだけ保存されます。")
                            .font(.subheadline).foregroundColor(.dlText)
                        Text("バージョン \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")")
                            .font(.caption).foregroundColor(.dlTextSub)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .dlCard()

                    VStack(spacing: 14) {
                        linkRow("questionmark.circle", "サポート", "https://taigayanai-git.github.io/JubyoNikki/")
                        Divider().overlay(Color.dlDivider)
                        linkRow("hand.raised", "プライバシーポリシー", "https://taigayanai-git.github.io/JubyoNikki/privacy.html")
                    }
                    .dlCard()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .dlScreen("設定")
        }
    }

    private func linkRow(_ icon: String, _ title: String, _ url: String) -> some View {
        Link(destination: URL(string: url)!) {
            SettingRow(icon: icon, title: title) {
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundColor(.dlTextLight)
            }
        }
    }

    private func accentButton(_ accent: ThemeAccent) -> some View {
        let selected = theme.accentIndex == accent.id
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { theme.accentIndex = accent.id }
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(accent.primary)
                        .frame(width: 36, height: 36)
                        .overlay(Circle().strokeBorder(Color.dlDivider, lineWidth: accent.needsBorder ? 1.5 : 0))
                        .shadow(color: accent.primary.opacity(selected ? 0.5 : 0.18), radius: selected ? 8 : 3, y: 2)
                    if selected {
                        Image(systemName: "checkmark")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(accent.needsBorder ? Color.dlText : .white)
                    }
                }
                .scaleEffect(selected ? 1.12 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: theme.accentIndex)
                Text(accent.name)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(selected ? .dlPrimary : .dlTextSub)
            }
        }
        .buttonStyle(.plain)
    }

    private func bgPatternButton(_ pattern: BgPattern) -> some View {
        let selected = theme.bgPatternIndex == pattern.rawValue
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { theme.bgPatternIndex = pattern.rawValue }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(Color.dlCard).frame(width: 72, height: 48)
                    if pattern != .none {
                        AppBackgroundPattern(patternIndex: pattern.rawValue, primary: theme.accent.primary)
                            .frame(width: 72, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(selected ? Color.dlPrimary : Color.dlDivider, lineWidth: selected ? 2 : 1)
                        .frame(width: 72, height: 48)
                }
                Text(pattern.label)
                    .font(.caption.weight(selected ? .semibold : .regular))
                    .foregroundColor(selected ? .dlPrimary : .dlTextSub)
            }
        }
        .buttonStyle(.plain)
    }

    private func section(_ title: String) -> some View {
        Text(title).font(.headline).foregroundColor(.dlTextSub).padding(.leading, 4)
    }
}
