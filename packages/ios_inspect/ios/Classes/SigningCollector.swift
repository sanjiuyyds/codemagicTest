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
            codeSignatureSection(),
            entitlementsSection(),
            certificateSection(),
            executableSection(),
            trustSection(),
        ]
    }

    private static var info: [String: Any] { Bundle.main.infoDictionary ?? [:] }

    private static func identitySection() -> InfoSection {
        InfoSection("身份", subtitle: "Bundle 标识与版本，用来核对这次装的是哪一包", rows: [
            InfoRow("显示名", Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "—"),
            InfoRow("CFBundleName", string(info["CFBundleName"])),
            InfoRow("Bundle Identifier", Bundle.main.bundleIdentifier ?? "—"),
            InfoRow("CFBundleIdentifier", string(info["CFBundleIdentifier"])),
            InfoRow("短版本 CFBundleShortVersionString", string(info["CFBundleShortVersionString"])),
            InfoRow("Build CFBundleVersion", string(info["CFBundleVersion"])),
            InfoRow("包版本对象", Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"),
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
        var rows: [InfoRow] = [
            InfoRow("embedded.mobileprovision", url?.path ?? "不存在"),
        ]
        guard let url, let data = try? Data(contentsOf: url) else {
            rows.append(InfoRow("说明", "未签名 IPA 或被剥离描述文件时这里会空。全能签重签后通常会出现。"))
            return InfoSection("嵌入描述文件", rows: rows)
        }
        rows.append(InfoRow("文件大小", InfoFormat.bytes(Int64(data.count))))
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path), let date = attrs[.modificationDate] as? Date {
            rows.append(InfoRow("文件时间", InfoFormat.date(date)))
        }
        if let plist = decodeCMSPlist(data) {
            rows.append(contentsOf: profileRows(plist))
        } else if let text = String(data: data, encoding: .isoLatin1),
                  let start = text.range(of: "<?xml"),
                  let end = text.range(of: "</plist>") {
            let xml = String(text[start.lowerBound...end.upperBound])
            if let plistData = xml.data(using: .utf8),
               let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] {
                rows.append(contentsOf: profileRows(plist))
            } else {
                rows.append(InfoRow("解析", "找到 XML 但反序列化失败"))
            }
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
            InfoRow("keychain-access-groups", array(entitlements["keychain-access-groups"])),
            InfoRow("com.apple.security.application-groups", array(entitlements["com.apple.security.application-groups"])),
            InfoRow("完整 Entitlements JSON", InfoFormat.json(entitlements)),
        ]
        for (idx, certData) in certs.enumerated() {
            rows.append(contentsOf: certificateSummary("Profile 证书[\(idx)]", certData))
        }
        return rows
    }

    private static func codeSignatureSection() -> InfoSection {
        var rows: [InfoRow] = []
        let staticInfo = SecStaticCodeCreate()
        if let staticInfo {
            rows.append(contentsOf: copySigning(staticInfo, prefix: "静态"))
        } else {
            rows.append(InfoRow("SecStaticCode", "创建失败（未签名包常见）"))
        }
        if let dynamic = SecCodeCopySelf(), let staticCode = copyStaticCode(dynamic) {
            rows.append(contentsOf: copySigning(staticCode, prefix: "运行中"))
        }
        return InfoSection("代码签名对象", subtitle: "Security.framework", rows: rows)
    }

    private static func entitlementsSection() -> InfoSection {
        var rows: [InfoRow] = []
        if let code = staticCodeForSigning(),
           let info = SecCopySigningInfo(code) {
            for (key, value) in info.sorted(by: { $0.key < $1.key }) {
                let lower = key.lowercased()
                if lower.contains("entitlement") || lower.contains("identifier") || lower.contains("team") || lower.contains("flag") || lower.contains("format") || lower.contains("platform") {
                    rows.append(InfoRow(key, pretty(value)))
                }
            }
        }
        if rows.isEmpty {
            rows.append(InfoRow("状态", "没有可读的签名 Entitlements。未签名 IPA 会这样；重签后应出现 Team ID 等字段。"))
        }
        return InfoSection("签名 Entitlements", rows: rows)
    }

    private static func certificateSection() -> InfoSection {
        var rows: [InfoRow] = []
        if let code = staticCodeForSigning(), let info = SecCopySigningInfo(code) {
            var certs: [SecCertificate] = []
            for value in info.values {
                if let list = value as? [SecCertificate], !list.isEmpty {
                    certs = list
                    break
                }
            }
            if certs.isEmpty {
                rows.append(InfoRow("证书链", "签名信息里没有证书数组。键：\(info.keys.sorted().joined(separator: ", "))"))
            } else {
                rows.append(InfoRow("证书链长度", "\(certs.count)"))
                for (idx, cert) in certs.enumerated() {
                    let data = SecCertificateCopyData(cert) as Data
                    rows.append(contentsOf: certificateSummary("签名链[\(idx)]", data))
                    if let summary = SecCertificateCopySubjectSummary(cert) as String? {
                        rows.append(InfoRow("签名链[\(idx)] Summary", summary))
                    }
                }
            }
        } else {
            rows.append(InfoRow("证书链", "空。未签名或签名信息不可读。"))
        }
        return InfoSection("签名证书链", rows: rows)
    }

    private static func executableSection() -> InfoSection {
        let path = Bundle.main.executablePath ?? ""
        var rows: [InfoRow] = [
            InfoRow("可执行文件", path),
        ]
        if !path.isEmpty, let attrs = try? FileManager.default.attributesOfItem(atPath: path) {
            rows.append(InfoRow("文件大小", (attrs[.size] as? NSNumber).map { InfoFormat.bytes($0.int64Value) } ?? "—"))
            if let date = attrs[.modificationDate] as? Date {
                rows.append(InfoRow("修改时间", InfoFormat.date(date)))
            }
            rows.append(InfoRow("POSIX 权限", (attrs[.posixPermissions] as? NSNumber).map { String(format: "%o", $0.intValue) } ?? "—"))
        }
        if let data = try? Data(contentsOf: URL(fileURLWithPath: path), options: [.mappedIfSafe]) {
            rows.append(InfoRow("Mach-O 魔数", InfoFormat.hex(data.prefix(16), limit: 16)))
            rows.append(contentsOf: machoRows(data))
        }
        let codeDir = (Bundle.main.bundlePath as NSString).appendingPathComponent("_CodeSignature")
        var isDir: ObjCBool = false
        let hasCode = FileManager.default.fileExists(atPath: codeDir, isDirectory: &isDir)
        rows.append(InfoRow("_CodeSignature 目录", hasCode ? codeDir : "不存在"))
        if hasCode, let items = try? FileManager.default.contentsOfDirectory(atPath: codeDir) {
            rows.append(InfoRow("_CodeSignature 内容", items.joined(separator: ", ")))
            for item in items {
                let p = (codeDir as NSString).appendingPathComponent(item)
                if let attrs = try? FileManager.default.attributesOfItem(atPath: p), let size = attrs[.size] as? NSNumber {
                    rows.append(InfoRow(item, InfoFormat.bytes(size.int64Value)))
                }
            }
        }
        return InfoSection("可执行文件与 CodeSignature", rows: rows)
    }

    private static func trustSection() -> InfoSection {
        var rows: [InfoRow] = []
        if let code = SecStaticCodeCreate() {
            var requirement: SecRequirement?
            SecCodeCopyDesignatedRequirement(code, SecCSFlags(), &requirement)
            if let requirement {
                var text: CFString?
                SecRequirementCopyString(requirement, SecCSFlags(), &text)
                rows.append(InfoRow("Designated Requirement", (text as String?) ?? "—"))
            }
            let status = SecStaticCodeCheckValidity(code, SecCSFlags(rawValue: kSecCSCheckAllArchitectures), nil as SecRequirement?)
            rows.append(InfoRow("SecStaticCodeCheckValidity", secStatus(status)))
        }
        rows.append(InfoRow("get-task-allow 含义", "为 true 时更像开发证书；企业签 / 分发签通常为 false。"))
        rows.append(InfoRow("ProvisionsAllDevices 含义", "为 true 时更像企业 In-House；Ad Hoc 会列出 UDID。"))
        rows.append(InfoRow("重签提示", "全能签安装后，本页应出现 TeamName、证书主题、过期时间。若仍全空，说明系统仍把包视为未签名。"))
        return InfoSection("校验与判读", rows: rows)
    }

    // MARK: Security helpers

    private static func SecStaticCodeCreate() -> SecStaticCode? {
        guard let path = Bundle.main.bundleURL as CFURL? else { return nil }
        var code: SecStaticCode?
        let status = SecStaticCodeCreateWithPath(path, SecCSFlags(), &code)
        return status == errSecSuccess ? code : nil
    }

    private static func SecCodeCopySelf() -> SecCode? {
        var code: SecCode?
        let status = SecCodeCopySelf(SecCSFlags(), &code)
        return status == errSecSuccess ? code : nil
    }

    private static func copyStaticCode(_ code: SecCode) -> SecStaticCode? {
        var staticCode: SecStaticCode?
        let status = SecCodeCopyStaticCode(code, SecCSFlags(), &staticCode)
        return status == errSecSuccess ? staticCode : nil
    }

    private static func staticCodeForSigning() -> SecStaticCode? {
        SecStaticCodeCreate() ?? SecCodeCopySelf().flatMap(copyStaticCode)
    }

    private static func SecCopySigningInfo(_ code: SecStaticCode) -> [String: Any]? {
        var info: CFDictionary?
        let flags = SecCSFlags(rawValue: kSecCSSigningInformation | kSecCSRequirementInformation)
        let status = SecCodeCopySigningInformation(code, flags, &info)
        guard status == errSecSuccess, let info else { return nil }
        return info as? [String: Any]
    }

    private static func copySigning(_ code: SecStaticCode, prefix: String) -> [InfoRow] {
        guard let info = SecCopySigningInfo(code) else {
            return [InfoRow("\(prefix) 签名信息", "不可读")]
        }
        var rows: [InfoRow] = []
        let interesting = [
            "identifier",
            "teamid",
            "format",
            "flags",
            "source",
            "unique",
            "digest-algorithm",
            "digest-algorithms",
            "cdhashes",
            "time",
            "timestamp",
            "platform",
            "entitlements-dict",
        ]
        for (key, value) in info.sorted(by: { $0.key < $1.key }) {
            if interesting.contains(where: { key.lowercased().contains($0) }) || key.hasPrefix("com.apple") {
                rows.append(InfoRow("\(prefix) \(key)", pretty(value)))
            }
        }
        rows.append(InfoRow("\(prefix) 全部键", info.keys.sorted().joined(separator: ", ")))
        return rows
    }

    private static func certificateSummary(_ prefix: String, _ data: Data) -> [InfoRow] {
        guard let cert = SecCertificateCreateWithData(nil, data as CFData) else {
            return [InfoRow(prefix, "无法解析 \(data.count) bytes")]
        }
        var rows: [InfoRow] = [
            InfoRow("\(prefix) 长度", InfoFormat.bytes(Int64(data.count))),
            InfoRow("\(prefix) Summary", (SecCertificateCopySubjectSummary(cert) as String?) ?? "—"),
        ]
        var name: CFString?
        SecCertificateCopyCommonName(cert, &name)
        if let name = name as String? { rows.append(InfoRow("\(prefix) CN", name)) }
        var emails: CFArray?
        if SecCertificateCopyEmailAddresses(cert, &emails) == errSecSuccess, let emails = emails as? [String] {
            rows.append(InfoRow("\(prefix) 邮箱", emails.joined(separator: ", ")))
        }
        if let values = SecCertificateCopyValues(cert, nil, nil) as? [String: Any] {
            rows.append(InfoRow("\(prefix) OID 数", "\(values.count)"))
            let interesting = [
                "2.5.4.10": "组织 O",
                "2.5.4.11": "部门 OU",
                "2.5.4.3": "CN",
                "2.5.29.17": "SAN",
                "2.5.29.19": "Basic Constraints",
                "2.5.29.15": "Key Usage",
                "1.2.840.113635.100.6.1.2": "Apple Developer",
                "1.2.840.113635.100.6.1.4": "Apple iPhone OS",
            ]
            for (oid, label) in interesting {
                if let entry = values[oid] {
                    rows.append(InfoRow("\(prefix) \(label)", pretty(entry)))
                }
            }
        }
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
        let xml = data.subdata(in: start.lowerBound..<(end.upperBound))
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

    private static func secStatus(_ status: OSStatus) -> String {
        let msg = SecCopyErrorMessageString(status, nil) as String? ?? ""
        if status == errSecSuccess { return "通过 (\(status)) \(msg)" }
        return "失败 \(status) \(msg)"
    }
}
