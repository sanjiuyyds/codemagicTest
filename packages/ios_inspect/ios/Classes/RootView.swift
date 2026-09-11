import SwiftUI
import UIKit

struct RootView: View {
    @State private var tab = 0
    @State private var systemSections = SystemCollector.sections()
    @State private var signingSections = SigningCollector.sections()
    @State private var taps = 0

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                TabView(selection: $tab) {
                    AboutPage(taps: $taps).tag(0)
                    DetailPage(title: "系统", empty: "没有系统信息", sections: systemSections).tag(1)
                    DetailPage(title: "签名", empty: "没有签名信息", sections: signingSections).tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                tabBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            refresh()
        }
    }

    private var background: some View {
        ZStack {
            LinearGradient(colors: [IpaTheme.bgTop, IpaTheme.bgBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle()
                .fill(IpaTheme.accent.opacity(0.28))
                .frame(width: 340, height: 340)
                .blur(radius: 70)
                .offset(x: 120, y: -220)
            Circle()
                .fill(IpaTheme.mint.opacity(0.22))
                .frame(width: 280, height: 280)
                .blur(radius: 80)
                .offset(x: -140, y: 80)
            Circle()
                .fill(Color.purple.opacity(0.18))
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(x: 40, y: 320)
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(tabTitle)
                    .font(.largeTitle.weight(.bold))
                Text(tabSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.body.weight(.semibold))
                    .padding(12)
            }
            .ipaGlassClear(cornerRadius: 16)
        }
        .padding(.top, 6)
    }

    private var tabTitle: String {
        switch tab {
        case 1: return "系统"
        case 2: return "签名"
        default: return displayName
        }
    }

    private var tabSubtitle: String {
        switch tab {
        case 1: return "当前 iPhone 与 iOS 探测结果"
        case 2: return "描述文件、证书链与 CodeSignature"
        default: return "构建 \(BuildStamp.buildNumber) · \(BuildStamp.gitCommitShort)"
        }
    }

    private var displayName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "液态工坊"
    }

    private var tabBar: some View {
        HStack(spacing: 8) {
            tabButton(0, "关于", "sparkles")
            tabButton(1, "系统", "iphone")
            tabButton(2, "签名", "checkmark.seal")
        }
        .padding(8)
        .ipaGlass(cornerRadius: 28)
    }

    private func tabButton(_ id: Int, _ title: String, _ icon: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.28)) { tab = id }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                Text(title).font(.caption.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundStyle(tab == id ? Color.white : Color.white.opacity(0.6))
            .background {
                if tab == id {
                    Capsule().fill(.white.opacity(0.16))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func refresh() {
        systemSections = SystemCollector.sections()
        signingSections = SigningCollector.sections()
    }
}

struct AboutPage: View {
    @Binding var taps: Int

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hero
                infoCard("这次构建", rows: [
                    ("显示名", displayName),
                    ("版本", version),
                    ("Build", BuildStamp.buildNumber),
                    ("Bundle ID", Bundle.main.bundleIdentifier ?? "—"),
                    ("Commit", BuildStamp.gitCommit),
                    ("构建时间", BuildStamp.builtAt),
                    ("工作流", BuildStamp.workflow),
                    ("实例", BuildStamp.instance),
                ])
                infoCard("设备快览", rows: [
                    ("系统", UIDevice.current.systemName + " " + UIDevice.current.systemVersion),
                    ("机型", UIDevice.current.model),
                    ("uts.machine", machine()),
                    ("液态玻璃", glassLine()),
                ])
                tapCard
                Text("签名证书不要放进云端。本页只读本机与包内信息。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
            .padding(20)
            .padding(.bottom, 24)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("iOS 26 Liquid Glass")
                .font(.caption.weight(.semibold))
                .foregroundStyle(IpaTheme.mint)
            Text(displayName)
                .font(.system(size: 34, weight: .bold))
            Text("云编译测试壳 · 关于 / 系统 / 签名")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .ipaGlass(cornerRadius: 28)
    }

    private var tapCard: some View {
        VStack(spacing: 12) {
            Text("\(taps)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(IpaTheme.mint)
            Button {
                taps += 1
            } label: {
                Text("点一下确认可交互")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .ipaGlassClear(cornerRadius: 18)
        }
        .padding(22)
        .ipaGlass(cornerRadius: 28)
    }

    private func infoCard(_ title: String, rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                VStack(alignment: .leading, spacing: 4) {
                    Text(row.0)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(row.1)
                        .font(.body.monospaced())
                        .textSelection(.enabled)
                }
                if row.0 != rows.last?.0 {
                    Divider().opacity(0.25)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .ipaGlass(cornerRadius: 24)
    }

    private var displayName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "液态工坊"
    }

    private var version: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "\(short) (\(build))"
    }

    private func machine() -> String {
        var n = utsname()
        uname(&n)
        return withUnsafePointer(to: &n.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 256) { String(cString: $0) }
        }
    }

    private func glassLine() -> String {
        if #available(iOS 26.0, *) { return "glassEffect 已启用" }
        return "回退到 ultraThinMaterial"
    }
}

struct DetailPage: View {
    let title: String
    let empty: String
    let sections: [InfoSection]
    @State private var query = ""
    @State private var copied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    TextField("搜索 \(title) 字段", text: $query)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .padding(12)
                        .ipaGlassClear(cornerRadius: 16)
                    Button(copied ? "已复制" : "复制全部") {
                        UIPasteboard.general.string = dumpText()
                        copied = true
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .ipaGlassClear(cornerRadius: 16)
                }
                if filtered.isEmpty {
                    Text(empty)
                        .foregroundStyle(.secondary)
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .ipaGlass(cornerRadius: 24)
                } else {
                    ForEach(filtered) { section in
                        sectionCard(section)
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 24)
        }
    }

    private var filtered: [InfoSection] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return sections }
        return sections.compactMap { section in
            let rows = section.rows.filter {
                $0.title.lowercased().contains(q) || $0.value.lowercased().contains(q)
            }
            if section.title.lowercased().contains(q) { return section }
            guard !rows.isEmpty else { return nil }
            return InfoSection(section.title, subtitle: section.subtitle, rows: rows)
        }
    }

    private func sectionCard(_ section: InfoSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.title).font(.headline)
            if let subtitle = section.subtitle {
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            ForEach(section.rows) { row in
                VStack(alignment: .leading, spacing: 4) {
                    Text(row.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(row.value)
                        .font(.footnote.monospaced())
                        .textSelection(.enabled)
                    if let footnote = row.footnote {
                        Text(footnote).font(.caption2).foregroundStyle(.secondary.opacity(0.7))
                    }
                }
                Divider().opacity(0.2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .ipaGlass(cornerRadius: 24)
    }

    private func dumpText() -> String {
        var lines: [String] = ["# \(title)", ""]
        for section in sections {
            lines.append("## \(section.title)")
            for row in section.rows {
                lines.append("- \(row.title): \(row.value)")
            }
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }
}
