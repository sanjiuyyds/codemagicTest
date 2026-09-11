import SwiftUI
import UIKit

struct RootView: View {
    @State private var systemSections = SystemCollector.sections()
    @State private var signingSections = SigningCollector.sections()
    @State private var taps = 0

    var body: some View {
        TabView {
            NavigationStack {
                AboutPage(taps: $taps, onRefresh: refresh)
            }
            .tabItem {
                Label("关于", systemImage: "info.circle")
            }

            NavigationStack {
                DetailPage(
                    title: "系统",
                    empty: "没有系统信息",
                    sections: systemSections,
                    onRefresh: refresh
                )
            }
            .tabItem {
                Label("系统", systemImage: "iphone")
            }

            NavigationStack {
                DetailPage(
                    title: "签名",
                    empty: "没有签名信息",
                    sections: signingSections,
                    onRefresh: refresh
                )
            }
            .tabItem {
                Label("签名", systemImage: "checkmark.seal")
            }
        }
        .onAppear(perform: refresh)
    }

    private func refresh() {
        systemSections = SystemCollector.sections()
        signingSections = SigningCollector.sections()
    }
}

struct AboutPage: View {
    @Binding var taps: Int
    var onRefresh: () -> Void

    var body: some View {
        List {
            Section {
                LabeledContent("显示名", value: displayName)
                LabeledContent("版本", value: version)
                LabeledContent("Build", value: BuildStamp.buildNumber)
                LabeledContent("Bundle ID", value: Bundle.main.bundleIdentifier ?? "—")
            } header: {
                Text("这次构建")
            }

            Section {
                LabeledContent("Commit", value: BuildStamp.gitCommit)
                LabeledContent("分支", value: BuildStamp.branch)
                LabeledContent("构建时间", value: BuildStamp.builtAt)
                LabeledContent("工作流", value: BuildStamp.workflow)
                LabeledContent("实例", value: BuildStamp.instance)
                LabeledContent("Xcode", value: BuildStamp.xcode)
            } header: {
                Text("云编译")
            }

            Section {
                LabeledContent("系统", value: UIDevice.current.systemName + " " + UIDevice.current.systemVersion)
                LabeledContent("机型", value: UIDevice.current.model)
                LabeledContent("uts.machine", value: machine())
                LabeledContent("系统外观", value: "使用 iOS 标准导航栏、标签栏和列表")
            } header: {
                Text("设备")
            }

            Section {
                Stepper(value: $taps, in: 0...9_999) {
                    LabeledContent("点击计数", value: "\(taps)")
                }
            } footer: {
                Text("签名证书不要放进云端。本页只读本机与包内信息。")
            }
        }
        .navigationTitle(displayName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
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
}

struct DetailPage: View {
    let title: String
    let empty: String
    let sections: [InfoSection]
    var onRefresh: () -> Void

    @State private var query = ""
    @State private var copied = false

    var body: some View {
        List {
            if filtered.isEmpty {
                Text(empty)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(filtered) { section in
                    Section {
                        ForEach(section.rows) { row in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(row.title)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(row.value)
                                    .font(.body)
                                    .textSelection(.enabled)
                                if let footnote = row.footnote {
                                    Text(footnote)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                            .contextMenu {
                                Button("拷贝") {
                                    UIPasteboard.general.string = "\(row.title): \(row.value)"
                                }
                            }
                        }
                    } header: {
                        Text(section.title)
                    } footer: {
                        if let subtitle = section.subtitle {
                            Text(subtitle)
                        }
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $query, prompt: "搜索\(title)字段")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(copied ? "已拷贝" : "拷贝全部") {
                    UIPasteboard.general.string = dumpText()
                    copied = true
                }
            }
        }
    }

    private var filtered: [InfoSection] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return sections }
        return sections.compactMap { section in
            if section.title.lowercased().contains(q) { return section }
            let rows = section.rows.filter {
                $0.title.lowercased().contains(q) || $0.value.lowercased().contains(q)
            }
            guard !rows.isEmpty else { return nil }
            return InfoSection(section.title, subtitle: section.subtitle, rows: rows)
        }
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
