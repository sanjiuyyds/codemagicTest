import Foundation
import Security
import UIKit

enum SigningCollector {
    static func sections() -> [InfoSection] {
        [
            identitySection(),
            infoPlistSection(),
            receiptSection(),
            embeddedProfileSection(),
            entitlementsFileSection(),
            codeDirectorySection(),
            executableSection(),
            trustSection(),
        ]
    }

    private static var info: [String: Any] { Bundle.main.infoDictionary ?? [:] }
    private static var bundleURL: URL { Bundle.main.bundleURL }

    private static func identitySection() -> InfoSection {
        InfoSection("身份", subtitle: "Bundle 标识与版本，用来核对这次装的是哪一包", rows: [
            InfoRow("软件名", Brand.appName),
            InfoRow("作者", Brand.author),
            InfoRow("版本", Brand.version),
            InfoRow("显示名", Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "—"),
            InfoRow("CFBundleName", string(info["CFBundleName"])),
            InfoRow("Bundle Identifier", Bundle.main.bundleIdentifier ?? "—"),
            InfoRow("CFBundleIdentifier", string(info["CFBundleIdentifier"])),
            InfoRow("短版本 CFBundleShortVersionString", string(info["CFBundleShortVersionString"])),
            InfoRow("Build CFBundleVersion", string(info["CFBundleVersion"])),
            InfoRow("可执行文件", string(info["CFBundleExecutable"])),
            InfoRow("包类型", string(info["CFBundlePackageType"])),
            InfoRow("签名标识 CFBundleSignature", string(info["CFBundleSignature"])),
            InfoRow("开发区域", string(info["CFBundleDevelopmentRegion"])),
            InfoRow("支持的平台", array(info["CFBundleSupportedPlatforms"])),
            InfoRow("UIDeviceFamily", array(info["UIDeviceFamily"])),
            InfoRow("所需设备能力", array(info["UIRequiredDeviceCapabilities"])),
            InfoRow("ATS", InfoFormat.json(info["NSAppTransportSecurity"] ?? [:])),
        ])
    }

    private static func infoPlistSection() -> InfoSection {
        let keys = info.keys.sorted()
        var rows: [InfoRow] = [
            InfoRow("Info.plist 键数量", "\(keys.count)"),
            InfoRow("全部键", keys.joined(separator: ", ")),
        ]
        for key in ["DTPlatformBuild", "DTPlatformName", "DTPlatformVersion", "DTSDKBuild", "DTSDKName", "DTXcode", "DTXcodeBuild", "DTCompiler", "BuildMachineOSBuild", "MinimumOSVersion", "UILaunchStoryboardName", "UIBackgroundModes", "ITSAppUsesNonExemptEncryption"] {
            rows.append(InfoRow(key, pretty(info[key])))
        }
        return InfoSection("Info.plist 编译信息", rows: rows)
    }

    private static func receiptSection() -> InfoSection {
        let url = Bundle.main.appStoreReceiptURL
        var rows: [InfoRow] = [
            InfoRow("收据路径", url?.path ?? "无"),
        ]
        if let url {
            let exists = FileManager.default.fileExists(atPath: url.path)
            rows.append(InfoRow("收据存在", InfoFormat.bool(exists)))
            if exists, let attrs = try? FileManager.default.attributesOfItem(atPath: url.path) {
                rows.append(InfoRow("收据大小", (attrs[.size] as? NSNumber).map { InfoFormat.bytes($0.int64Value) } ?? "—"))
                if let date = attrs[.modificationDate] as? Date {
                    rows.append(InfoRow("收据修改时间", InfoFormat.date(date)))
                }
            }
            rows.append(InfoRow("说明", exists
                ? "存在收据通常表示 App Store / TestFlight 分发；全能签安装常见为无收据。"
                : "无 App Store 收据。当前更像开发签、Ad Hoc、企业签或重签包。"))
        }
        return InfoSection("App Store 收据", rows: rows)
    }

    private static func embeddedProfileSection() -> InfoSection {
        let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision")
            ?? bundleURL.appendingPathComponent("embedded.mobileprovision")
        var rows: [InfoRow] = [
            InfoRow("embedded.mobileprovision", url.path),
        ]
        let exists = FileManager.default.fileExists(atPath: url.path)
        rows.append(InfoRow("文件存在", InfoFormat.bool(exists)))
        guard exists, let data = try? Data(contentsOf: url) else {
            rows.append(InfoRow("说明", "未签名 IPA 或被剥离描述文件时这里会空。全能签重签后通常会出现。"))
            return InfoSection("嵌入描述文件", subtitle: "Provisioning Profile", rows: rows)
        }
        rows.append(InfoRow("文件大小", InfoFormat.bytes(Int64(data.count))))
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path), let date = attrs[.modificationDate] as? Date {
            rows.append(InfoRow("文件时间", InfoFormat.date(date)))
        }
        if let plist = decodeCMSPlist(data) {
            rows.append(contentsOf: profileRows(plist))
        } else {
            rows.append(InfoRow("解析", "无法从 CMS / XML 中取出 plist"))
        }
        return InfoSection("嵌入描述文件", subtitle: "Provisioning Profile", rows: rows)
    }

    private static func profileRows(_ plist: [String: Any]) -> [InfoRow] {
        let entitlements = plist["Entitlements"] as? [String: Any] ?? [:]
        let devices = plist["ProvisionedDevices"] as? [String] ?? []
        let certs = plist["DeveloperCertificates"] as? [Data] ?? []
        var rows: [InfoRow] = [
            InfoRow("Name", string(plist["Name"])),
            InfoRow("AppIDName", string(plist["AppIDName"])),
            InfoRow("TeamName", string(plist["TeamName"])),
            InfoRow("TeamIdentifier", array(plist["TeamIdentifier"])),
            InfoRow("UUID", string(plist["UUID"])),
            InfoRow("ApplicationIdentifierPrefix", array(plist["ApplicationIdentifierPrefix"])),
            InfoRow("Platform", array(plist["Platform"])),
            InfoRow("IsXcodeManaged", pretty(plist["IsXcodeManaged"])),
            InfoRow("ProvisionsAllDevices", pretty(plist["ProvisionsAllDevices"])),
            InfoRow("ProvisionedDevices 数量", "\(devices.count)"),
            InfoRow("设备 UDID 列表", devices.isEmpty ? "无（企业签/App Store 常见）" : devices.joined(separator: "\n")),
            InfoRow("创建时间", dateValue(plist["CreationDate"])),
            InfoRow("过期时间", dateValue(plist["ExpirationDate"])),
            InfoRow("TimeToLive", pretty(plist["TimeToLive"])),
            InfoRow("Version", pretty(plist["Version"])),
            InfoRow("DER-Encoded-Profile 长度", (plist["DER-Encoded-Profile"] as? Data).map { "\($0.count) bytes" } ?? "—"),
            InfoRow("DeveloperCertificates", "\(certs.count) 张"),
            InfoRow("Entitlements 键", entitlements.keys.sorted().joined(separator: ", ")),
            InfoRow("application-identifier", string(entitlements["application-identifier"])),
            InfoRow("com.apple.developer.team-identifier", string(entitlements["com.apple.developer.team-identifier"])),
            InfoRow("get-task-allow", pretty(entitlements["get-task-allow"])),
            InfoRow("aps-environment", string(entitlements["aps-environment"])),
            InfoRow("beta-reports-active", pretty(entitlements["beta-reports-active"])),
            InfoRow("keychain-access-groups", array(entitlements["keychain-access-groups"])),
            InfoRow("com.apple.security.application-groups", array(entitlements["com.apple.security.application-groups"])),
            InfoRow("完整 Entitlements JSON", InfoFormat.json(entitlements)),
        ]
        for (idx, certData) in certs.enumerated() {
            rows.append(contentsOf: certificateSummary("Profile 证书[\(idx)]", certData))
        }
        return rows
    }

    private static func entitlementsFileSection() -> InfoSection {
        let names = [
            "archived-expanded-entitlements.xcent",
            "embedded.entitlements",
            "Runner.entitlements",
        ]
        var rows: [InfoRow] = []
        for name in names {
            let url = bundleURL.appendingPathComponent(name)
            let exists = FileManager.default.fileExists(atPath: url.path)
            rows.append(InfoRow(name, exists ? url.path : "不存在"))
            if exists, let data = try? Data(contentsOf: url) {
                rows.append(InfoRow("\(name) 大小", InfoFormat.bytes(Int64(data.count))))
                if let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) {
                    rows.append(InfoRow("\(name) 内容", pretty(plist)))
                } else if let text = String(data: data, encoding: .utf8) {
                    rows.append(InfoRow("\(name) 文本", text))
                }
            }
        }
        return InfoSection("包内 Entitlements 文件", rows: rows)
    }

    private static func codeDirectorySection() -> InfoSection {
        let codeDir = bundleURL.appendingPathComponent("_CodeSignature")
        var isDir: ObjCBool = false
        let hasCode = FileManager.default.fileExists(atPath: codeDir.path, isDirectory: &isDir)
        var rows: [InfoRow] = [
            InfoRow("_CodeSignature 目录", hasCode ? codeDir.path : "不存在"),
        ]
        if hasCode, let items = try? FileManager.default.contentsOfDirectory(atPath: codeDir.path) {
            rows.append(InfoRow("内容", items.sorted().joined(separator: ", ")))
            for item in items.sorted() {
                let url = codeDir.appendingPathComponent(item)
                if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path), let size = attrs[.size] as? NSNumber {
                    rows.append(InfoRow(item, InfoFormat.bytes(size.int64Value)))
                }
                if item == "CodeResources", let data = try? Data(contentsOf: url) {
                    if let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) {
                        rows.append(InfoRow("CodeResources 摘要", pretty(plist)))
                    }
                }
            }
        } else {
            rows.append(InfoRow("说明", "未签名 IPA 常见为不存在。全能签重签后应出现 CodeResources。"))
        }
        return InfoSection("CodeSignature 目录", rows: rows)
    }

    private static func executableSection() -> InfoSection {
        let path = Bundle.main.executablePath ?? ""
        var rows: [InfoRow] = [
            InfoRow("可执行文件", path.isEmpty ? "—" : path),
        ]
        guard !path.isEmpty else {
            return InfoSection("可执行文件", rows: rows)
        }
        if let attrs = try? FileManager.default.attributesOfItem(atPath: path) {
            rows.append(InfoRow("文件大小", (attrs[.size] as? NSNumber).map { InfoFormat.bytes($0.int64Value) } ?? "—"))
            if let date = attrs[.modificationDate] as? Date {
                rows.append(InfoRow("修改时间", InfoFormat.date(date)))
            }
            rows.append(InfoRow("POSIX 权限", (attrs[.posixPermissions] as? NSNumber).map { String(format: "%o", $0.intValue) } ?? "—"))
        }
        if let handle = try? FileHandle(forReadingFrom: URL(fileURLWithPath: path)) {
            let header = handle.readData(ofLength: 32)
            try? handle.close()
            rows.append(InfoRow("Mach-O 头", InfoFormat.hex(header, limit: 32)))
            rows.append(contentsOf: machoRows(header))
        }
        return InfoSection("可执行文件", rows: rows)
    }

    private static func trustSection() -> InfoSection {
        InfoSection("校验与判读", rows: [
            InfoRow("iOS 限制", "应用内不能调用 macOS 的 SecStaticCode / codesign API。本页只读包内文件。"),
            InfoRow("get-task-allow 含义", "为 true 时更像开发证书；企业签 / 分发签通常为 false。"),
            InfoRow("ProvisionsAllDevices 含义", "为 true 时更像企业 In-House；Ad Hoc 会列出 UDID。"),
            InfoRow("重签提示", "全能签安装后，应在「嵌入描述文件」看到 TeamName、证书主题和过期时间。"),
        ])
    }

    private static func certificateSummary(_ prefix: String, _ data: Data) -> [InfoRow] {
        guard let cert = SecCertificateCreateWithData(nil, data as CFData) else {
            return [InfoRow(prefix, "无法解析 \(data.count) bytes")]
        }
        var rows: [InfoRow] = [
            InfoRow("\(prefix) 长度", InfoFormat.bytes(Int64(data.count))),
        ]
        if let summary = SecCertificateCopySubjectSummary(cert) as String? {
            rows.append(InfoRow("\(prefix) Summary", summary))
        }
        var name: CFString?
        if SecCertificateCopyCommonName(cert, &name) == errSecSuccess, let name = name as String? {
            rows.append(InfoRow("\(prefix) CN", name))
        }
        var emails: CFArray?
        if SecCertificateCopyEmailAddresses(cert, &emails) == errSecSuccess, let emails = emails as? [String], !emails.isEmpty {
            rows.append(InfoRow("\(prefix) 邮箱", emails.joined(separator: ", ")))
        }
        rows.append(InfoRow("\(prefix) DER 开头", InfoFormat.hex(data, limit: 24)))
        return rows
    }

    private static func machoRows(_ data: Data) -> [InfoRow] {
        guard data.count >= 8 else { return [] }
        let magic = data.prefix(4).withUnsafeBytes { $0.load(as: UInt32.self) }
        let swapped: Bool
        let is64: Bool
        switch magic {
        case 0xfeedface: swapped = false; is64 = false
        case 0xcefaedfe: swapped = true; is64 = false
        case 0xfeedfacf: swapped = false; is64 = true
        case 0xcffaedfe: swapped = true; is64 = true
        case 0xcafebabe, 0xbebafeca: return [InfoRow("Mach-O", "Fat / Universal")]
        default: return [InfoRow("Mach-O", String(format: "未知 magic 0x%08x", magic))]
        }
        func u32(_ offset: Int) -> UInt32 {
            guard data.count >= offset + 4 else { return 0 }
            let v = data.dropFirst(offset).prefix(4).withUnsafeBytes { $0.load(as: UInt32.self) }
            return swapped ? v.byteSwapped : v
        }
        let cputype = Int32(bitPattern: u32(4))
        let ncmds = u32(is64 ? 16 : 12)
        return [
            InfoRow("Mach-O 64 位", InfoFormat.bool(is64)),
            InfoRow("字节序交换", InfoFormat.bool(swapped)),
            InfoRow("cputype", "\(cputype)"),
            InfoRow("ncmds", "\(ncmds)"),
        ]
    }

    private static func decodeCMSPlist(_ data: Data) -> [String: Any]? {
        guard let start = data.range(of: Data("<?xml".utf8)),
              let end = data.range(of: Data("</plist>".utf8))
        else { return nil }
        let xml = data.subdata(in: start.lowerBound..<end.upperBound)
        return (try? PropertyListSerialization.propertyList(from: xml, options: [], format: nil)) as? [String: Any]
    }

    private static func pretty(_ value: Any?) -> String {
        guard let value else { return "—" }
        if let date = value as? Date { return InfoFormat.date(date) }
        if let data = value as? Data { return InfoFormat.hex(data) }
        if JSONSerialization.isValidJSONObject(value) { return InfoFormat.json(value) }
        if let dict = value as? [String: Any] { return InfoFormat.json(dict) }
        if let arr = value as? [Any] { return arr.map { pretty($0) }.joined(separator: "\n") }
        return String(describing: value)
    }

    private static func array(_ value: Any?) -> String {
        if let arr = value as? [Any] { return arr.map { String(describing: $0) }.joined(separator: ", ") }
        return pretty(value)
    }

    private static func string(_ value: Any?) -> String {
        guard let value else { return "—" }
        return String(describing: value)
    }

    private static func dateValue(_ value: Any?) -> String {
        if let date = value as? Date { return InfoFormat.date(date) }
        return pretty(value)
    }
}
