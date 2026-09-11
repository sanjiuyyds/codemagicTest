import SwiftUI
import UIKit
import WebKit

struct RootView: View {
    @StateObject private var license = LicenseStore.shared
    @State private var systemSections = SystemCollector.sections()
    @State private var signingSections = SigningCollector.sections()

    var body: some View {
        TabView {
            NavigationStack {
                HomePage(license: license, onRefresh: refresh)
            }
            .tabItem { Label("主页", systemImage: "square.grid.2x2") }

            NavigationStack {
                MenuPage(
                    title: "系统",
                    subtitle: "设备、电源、网络与环境",
                    groups: systemGroups,
                    onRefresh: refresh
                )
            }
            .tabItem { Label("系统", systemImage: "iphone") }

            NavigationStack {
                MenuPage(
                    title: "签名",
                    subtitle: "描述文件、证书与包身份",
                    groups: signingGroups,
                    onRefresh: refresh
                )
            }
            .tabItem { Label("签名", systemImage: "checkmark.seal") }

            NavigationStack {
                LicensePage(store: license)
            }
            .tabItem { Label("授权", systemImage: "doc.richtext") }
        }
        .onAppear(perform: refresh)
    }

    private var systemGroups: [InfoSection] { systemSections }
    private var signingGroups: [InfoSection] { signingSections }

    private func refresh() {
        systemSections = SystemCollector.sections()
        signingSections = SigningCollector.sections()
        license.reload()
    }
}

struct HomePage: View {
    @ObservedObject var license: LicenseStore
    var onRefresh: () -> Void

    var body: some View {
        List {
            Section {
                NavigationLink {
                    AboutDetailPage()
                } label: {
                    menuLabel("关于 XsTools", "作者、版本与构建信息", "person.crop.square")
                }
                NavigationLink {
                    MenuPage(title: "系统", subtitle: nil, groups: SystemCollector.sections(), onRefresh: onRefresh)
                } label: {
                    menuLabel("系统信息", "\(SystemCollector.sections().count) 组", "iphone")
                }
                NavigationLink {
                    MenuPage(title: "签名", subtitle: nil, groups: SigningCollector.sections(), onRefresh: onRefresh)
                } label: {
                    menuLabel("签名信息", "\(SigningCollector.sections().count) 组", "checkmark.seal")
                }
                NavigationLink {
                    LicensePage(store: license)
                } label: {
                    menuLabel("授权系统", license.hasDocument ? (license.fileName ?? "已保存") : "未导入", "doc.richtext")
                }
            } header: {
                Text("功能")
            }

            Section {
                LabeledContent("软件", value: Brand.appName)
                LabeledContent("作者", value: Brand.author)
                LabeledContent("版本", value: Brand.version)
                LabeledContent("Build", value: BuildStamp.buildNumber)
            } header: {
                Text("制作")
            } footer: {
                Text("\(Brand.appName) by \(Brand.author)")
            }
        }
        .navigationTitle(Brand.appName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }

    private func menuLabel(_ title: String, _ subtitle: String, _ icon: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: icon)
        }
    }
}

struct AboutDetailPage: View {
    var body: some View {
        List {
            Section("软件") {
                LabeledContent("名称", value: Brand.appName)
                LabeledContent("作者", value: Brand.author)
                LabeledContent("版本", value: Brand.version)
                LabeledContent("Build", value: BuildStamp.buildNumber)
                LabeledContent("显示名", value: displayName)
                LabeledContent("Bundle ID", value: Bundle.main.bundleIdentifier ?? "—")
            }
            Section("构建") {
                LabeledContent("Commit", value: BuildStamp.gitCommit)
                LabeledContent("短哈希", value: BuildStamp.gitCommitShort)
                LabeledContent("分支", value: BuildStamp.branch)
                LabeledContent("时间", value: BuildStamp.builtAt)
                LabeledContent("工作流", value: BuildStamp.workflow)
                LabeledContent("实例", value: BuildStamp.instance)
                LabeledContent("仓库", value: BuildStamp.repo)
            }
            Section("本机") {
                LabeledContent("系统", value: UIDevice.current.systemName + " " + UIDevice.current.systemVersion)
                LabeledContent("机型", value: UIDevice.current.model)
            }
            Section {
                Text("本软件由 \(Brand.author) 制作。")
            }
        }
        .navigationTitle("关于")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var displayName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? Brand.appName
    }
}

struct MenuPage: View {
    let title: String
    let subtitle: String?
    let groups: [InfoSection]
    var onRefresh: () -> Void

    var body: some View {
        List {
            if let subtitle, !subtitle.isEmpty {
                Section { Text(subtitle).foregroundStyle(.secondary) }
            }
            Section("分组") {
                ForEach(groups) { group in
                    NavigationLink {
                        SectionDetailPage(section: group)
                    } label: {
                        LabeledContent(group.title, value: "\(group.rows.count) 项")
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }
}

struct SectionDetailPage: View {
    let section: InfoSection
    @State private var query = ""

    var body: some View {
        List {
            if filtered.isEmpty {
                Text("没有匹配项")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(filtered) { row in
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
            }
        }
        .navigationTitle(section.title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "搜索")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("拷贝全部") {
                    UIPasteboard.general.string = dumpText()
                }
            }
        }
    }

    private var filtered: [InfoRow] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return section.rows }
        return section.rows.filter {
            $0.title.lowercased().contains(q) || $0.value.lowercased().contains(q)
        }
    }

    private func dumpText() -> String {
        var lines = ["# \(section.title)", ""]
        for row in section.rows {
            lines.append("- \(row.title): \(row.value)")
        }
        return lines.joined(separator: "\n")
    }
}

struct LicensePage: View {
    @ObservedObject var store: LicenseStore
    @State private var picking = false
    @State private var errorText: String?

    var body: some View {
        List {
            Section {
                LabeledContent("状态", value: store.hasDocument ? "已保存" : "未导入")
                if let name = store.fileName {
                    LabeledContent("文件", value: name)
                }
                if let size = store.fileSize {
                    LabeledContent("大小", value: InfoFormat.bytes(size))
                }
                if let date = store.importedAt {
                    LabeledContent("导入时间", value: InfoFormat.date(date))
                }
            } footer: {
                Text("导入一次后保存在本机，重装 App 前都可打开。可随时替换。请选择 .html 或 .htm。")
            }

            Section {
                Button(store.hasDocument ? "替换 HTML" : "导入 HTML") {
                    picking = true
                }
                if store.hasDocument {
                    NavigationLink("打开授权页") {
                        LicenseWebPage(url: store.documentURL())
                    }
                    Button("清除本地文件", role: .destructive) {
                        do {
                            try store.clear()
                            errorText = nil
                        } catch {
                            errorText = error.localizedDescription
                        }
                    }
                }
            }

            if let errorText {
                Section { Text(errorText).foregroundStyle(.red) }
            }
        }
        .navigationTitle("授权系统")
        .navigationBarTitleDisplayMode(.large)
        .fileImporter(
            isPresented: $picking,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let url):
                do {
                    try store.importFile(from: url)
                    errorText = nil
                } catch {
                    errorText = error.localizedDescription
                }
            case .failure(let error):
                errorText = error.localizedDescription
            }
        }
    }
}

struct LicenseWebPage: View {
    let url: URL?

    var body: some View {
        Group {
            if let url {
                LicenseWebView(url: url)
                    .ignoresSafeArea(edges: .bottom)
            } else {
                Text("还没有保存的 HTML")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("授权页")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LicenseWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        let view = WKWebView(frame: .zero, configuration: config)
        view.allowsBackForwardNavigationGestures = true
        view.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
