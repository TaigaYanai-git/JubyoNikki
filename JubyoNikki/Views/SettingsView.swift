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

                    VStack(spacing: 14) {
                        SettingRow(icon: "circle.grid.3x3", title: "水玉の背景") {
                            Toggle("", isOn: $theme.showsDots).labelsHidden().tint(.dlPrimary)
                        }
                        Divider().overlay(Color.dlDivider)
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
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .dlScreen("設定")
        }
    }

    private func section(_ title: String) -> some View {
        Text(title).font(.headline).foregroundColor(.dlTextSub).padding(.leading, 4)
    }
}
