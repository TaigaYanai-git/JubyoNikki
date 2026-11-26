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

                    section("テーマカラー").padding(.top, 10)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(ThemeStore.accents) { a in
                                Button { theme.accentIndex = a.id } label: {
                                    VStack(spacing: 6) {
                                        ZStack {
                                            Circle().fill(a.primary).frame(width: 52, height: 52)
                                            if theme.accentIndex == a.id {
                                                Image(systemName: "checkmark").font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                                            }
                                        }
                                        Text(a.name).font(.caption2)
                                            .foregroundColor(theme.accentIndex == a.id ? .dlText : .dlTextSub)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 4)
                    }
                    .padding(.horizontal, -20)

                    section("背景").padding(.top, 10)
                    HStack(spacing: 12) {
                        ForEach(AppBackground.allCases) { bg in
                            Button { theme.background = bg } label: {
                                VStack(spacing: 6) {
                                    BackgroundSwatch(kind: bg)
                                        .frame(height: 64)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                        .overlay(RoundedRectangle(cornerRadius: 14)
                                            .strokeBorder(theme.background == bg ? Color.dlText : Color.dlDivider,
                                                          lineWidth: theme.background == bg ? 2.5 : 1))
                                    Text(bg.label).font(.caption)
                                        .foregroundColor(theme.background == bg ? .dlText : .dlTextSub)
                                }
                            }
                            .buttonStyle(.plain)
                        }
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
                        Text("忙しい日も、やる気のない日も。\n10秒だけなら続けられる日記です。1文字書くごとに1秒のびます。日記はこの iPhone の中にだけ保存されます。")
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

    private func section(_ title: String) -> some View {
        Text(title).font(.headline).foregroundColor(.dlTextSub).padding(.leading, 4)
    }
}

/// 背景の見本（設定の選択肢）
private struct BackgroundSwatch: View {
    let kind: AppBackground
    var body: some View {
        ZStack {
            Color.dlCard
            if kind == .lavender || kind == .dots { Color(red: 0.969, green: 0.957, blue: 0.988) }
            if kind == .ruled { RuledLines(spacing: 12, top: 12) }
            if kind == .dots {
                Canvas { ctx, size in
                    var y: CGFloat = 8, row = 0
                    while y < size.height {
                        var x: CGFloat = row % 2 == 0 ? 8 : 16
                        while x < size.width {
                            ctx.fill(Path(ellipseIn: CGRect(x: x - 2.5, y: y - 2.5, width: 5, height: 5)),
                                     with: .color(Color.dlPrimary.opacity(0.12)))
                            x += 16
                        }
                        y += 14; row += 1
                    }
                }
            }
        }
    }
}
