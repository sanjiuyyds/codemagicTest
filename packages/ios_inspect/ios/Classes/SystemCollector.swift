import Darwin
import Foundation
import MachO
import Metal
import UIKit

enum SystemCollector {
    static func sections() -> [InfoSection] {
        [
            deviceSection(),
            osSection(),
            screenSection(),
            processSection(),
            memorySection(),
            storageSection(),
            cpuSection(),
            thermalPowerSection(),
            localeTimeSection(),
            networkSection(),
            accessibilitySection(),
            environmentSection(),
        ]
    }

    private static func deviceSection() -> InfoSection {
        let d = UIDevice.current
        let idiom: String
        switch d.userInterfaceIdiom {
        case .phone: idiom = "iPhone"
        case .pad: idiom = "iPad"
        case .mac: idiom = "Mac"
        case .tv: idiom = "TV"
        case .carPlay: idiom = "CarPlay"
        case .vision: idiom = "Vision"
        @unknown default: idiom = "\(d.userInterfaceIdiom.rawValue)"
        }
        return InfoSection("设备", subtitle: "UIDevice / utsname / IORegistry", rows: [
            InfoRow("名称", d.name),
            InfoRow("系统名", d.systemName),
            InfoRow("系统版本", d.systemVersion),
            InfoRow("机型标识", d.model),
            InfoRow("本地化机型", d.localizedModel),
            InfoRow("界面类型", idiom),
            InfoRow("模拟器", InfoFormat.bool(isSimulator)),
            InfoRow("uts.sysname", uts.sysname),
            InfoRow("uts.nodename", uts.nodename),
            InfoRow("uts.release", uts.release),
            InfoRow("uts.version", uts.version),
            InfoRow("uts.machine", uts.machine),
            InfoRow("hw.machine", sysctlString("hw.machine")),
            InfoRow("hw.model", sysctlString("hw.model")),
            InfoRow("hw.targettype", sysctlString("hw.targettype")),
            InfoRow("硬件机型名", marketingName(for: uts.machine)),
            InfoRow("标识符供参考", identifierNote()),
        ])
    }

    private static func osSection() -> InfoSection {
        let p = ProcessInfo.processInfo
        let os = p.operatingSystemVersion
        let info = Bundle.main.infoDictionary ?? [:]
        return InfoSection("系统与运行时", rows: [
            InfoRow("操作系统", p.operatingSystemVersionString),
            InfoRow("主.次.补丁", "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"),
            InfoRow("iOS 26+", InfoFormat.bool(p.isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 26, minorVersion: 0, patchVersion: 0)))),
            InfoRow("Liquid Glass API", liquidGlassStatus()),
            InfoRow("kern.osproductversion", sysctlString("kern.osproductversion")),
            InfoRow("kern.osversion", sysctlString("kern.osversion")),
            InfoRow("kern.version", sysctlString("kern.version")),
            InfoRow("kern.ostype", sysctlString("kern.ostype")),
            InfoRow("kern.osrelease", sysctlString("kern.osrelease")),
            InfoRow("darwin 启动", bootTime()),
            InfoRow("开机时长", uptime()),
            InfoRow("内核启动参数", sysctlString("kern.bootargs")),
            InfoRow("安全启动", sysctlInt("kern.secure_kernel").map { InfoFormat.bool($0 != 0) } ?? "—"),
            InfoRow("开发者模式 sysctl", sysctlInt("security.mac.amfi.developer_mode_status").map { "\($0)" } ?? "不可读"),
            InfoRow("MinimumOSVersion (Info)", string(info["MinimumOSVersion"])),
            InfoRow("DTPlatformName", string(info["DTPlatformName"])),
            InfoRow("DTPlatformVersion", string(info["DTPlatformVersion"])),
            InfoRow("DTSDKName", string(info["DTSDKName"])),
            InfoRow("DTSDKBuild", string(info["DTSDKBuild"])),
            InfoRow("DTXcode", string(info["DTXcode"])),
            InfoRow("DTXcodeBuild", string(info["DTXcodeBuild"])),
            InfoRow("DTCompiler", string(info["DTCompiler"])),
            InfoRow("BuildMachineOSBuild", string(info["BuildMachineOSBuild"])),
            InfoRow("LSRequiresIPhoneOS", string(info["LSRequiresIPhoneOS"])),
        ])
    }

    private static func screenSection() -> InfoSection {
        let s = UIScreen.main
        let b = s.bounds
        let n = s.nativeBounds
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        let scene = window?.windowScene
        return InfoSection("显示", rows: [
            InfoRow("逻辑分辨率", "\(Int(b.width)) × \(Int(b.height)) pt"),
            InfoRow("物理分辨率", "\(Int(n.width)) × \(Int(n.height)) px"),
            InfoRow("scale", String(format: "%.3f", s.scale)),
            InfoRow("nativeScale", String(format: "%.3f", s.nativeScale)),
            InfoRow("最大 FPS", "\(s.maximumFramesPerSecond)"),
            InfoRow("当前模式", s.currentMode.map { "\($0.pixelAspectRatio) \($0.size.width)x\($0.size.height)" } ?? "—"),
            InfoRow("亮度", String(format: "%.3f", s.brightness)),
            InfoRow("深色模式", UITraitCollection.current.userInterfaceStyle == .dark ? "深色" : "浅色"),
            InfoRow("显示色域", colorGamut()),
            InfoRow("对比度", contrastStatus()),
            InfoRow("窗口场景", scene.map { "\($0.session.persistentIdentifier)" } ?? "—"),
            InfoRow("屏幕坐标", window.map { "origin \($0.frame.origin) size \($0.frame.size)" } ?? "—"),
            InfoRow("安全区", window.map { inset($0.safeAreaInsets) } ?? "—"),
            InfoRow("布局边距", window.map { inset($0.layoutMargins) } ?? "—"),
        ])
    }

    private static func processSection() -> InfoSection {
        let p = ProcessInfo.processInfo
        return InfoSection("进程", rows: [
            InfoRow("进程名", p.processName),
            InfoRow("PID", "\(p.processIdentifier)"),
            InfoRow("宿主名", p.hostName),
            InfoRow("GloballyUniqueString", p.globallyUniqueString),
            InfoRow("活动处理器", "\(p.activeProcessorCount)"),
            InfoRow("处理器数", "\(p.processorCount)"),
            InfoRow("物理内存", InfoFormat.bytes(Int64(p.physicalMemory))),
            InfoRow("低电量模式", InfoFormat.bool(p.isLowPowerModeEnabled)),
            InfoRow("Mac Catalyst", InfoFormat.bool(p.isiOSAppOnMac)),
            InfoRow("参数", p.arguments.joined(separator: " ")),
            InfoRow("环境变量数", "\(p.environment.count)"),
            InfoRow("PATH", p.environment["PATH"] ?? "—"),
            InfoRow("HOME", p.environment["HOME"] ?? "—"),
            InfoRow("TMPDIR", p.environment["TMPDIR"] ?? "—"),
            InfoRow("CFFIXED_USER_HOME", p.environment["CFFIXED_USER_HOME"] ?? "—"),
        ])
    }

    private static func memorySection() -> InfoSection {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        var rows: [InfoRow] = [
            InfoRow("物理内存", InfoFormat.bytes(Int64(ProcessInfo.processInfo.physicalMemory))),
            InfoRow("hw.memsize", sysctlU64("hw.memsize").map(Int64.init).map(InfoFormat.bytes) ?? "—"),
            InfoRow("hw.pagesize", sysctlU64("hw.pagesize").map { "\($0)" } ?? "—"),
        ]
        if kr == KERN_SUCCESS {
            rows.append(contentsOf: [
                InfoRow("本进程驻留", InfoFormat.bytes(Int64(info.resident_size))),
                InfoRow("本进程虚拟", InfoFormat.bytes(Int64(info.virtual_size))),
                InfoRow("挂起时间", "\(info.suspend_count)"),
            ])
        }
        return InfoSection("内存", rows: rows)
    }

    private static func storageSection() -> InfoSection {
        let home = URL(fileURLWithPath: NSHomeDirectory())
        let values = try? home.resourceValues(forKeys: [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityForOpportunisticUsageKey,
            .volumeNameKey,
            .volumeIsReadOnlyKey,
            .volumeSupportsPersistentIDsKey,
        ])
        let fm = FileManager.default
        return InfoSection("存储", rows: [
            InfoRow("卷名", values?.volumeName ?? "—"),
            InfoRow("总容量", values?.volumeTotalCapacity.map { InfoFormat.bytes(Int64($0)) } ?? "—"),
            InfoRow("可用", values?.volumeAvailableCapacity.map { InfoFormat.bytes(Int64($0)) } ?? "—"),
            InfoRow("重要用途可用", (values?.volumeAvailableCapacityForImportantUsage).map(InfoFormat.bytes) ?? "—"),
            InfoRow("机会性可用", (values?.volumeAvailableCapacityForOpportunisticUsage).map(InfoFormat.bytes) ?? "—"),
            InfoRow("只读", values?.volumeIsReadOnly.map(InfoFormat.bool) ?? "—"),
            InfoRow("沙盒 Home", NSHomeDirectory()),
            InfoRow("Documents", fm.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? "—"),
            InfoRow("Library", fm.urls(for: .libraryDirectory, in: .userDomainMask).first?.path ?? "—"),
            InfoRow("Caches", fm.urls(for: .cachesDirectory, in: .userDomainMask).first?.path ?? "—"),
            InfoRow("tmp", NSTemporaryDirectory()),
            InfoRow("Bundle 路径", Bundle.main.bundlePath),
            InfoRow("可执行路径", Bundle.main.executablePath ?? "—"),
        ])
    }

    private static func cpuSection() -> InfoSection {
        var rows: [InfoRow] = [
            InfoRow("hw.ncpu", sysctlInt("hw.ncpu").map(String.init) ?? "—"),
            InfoRow("hw.physicalcpu", sysctlInt("hw.physicalcpu").map(String.init) ?? "—"),
            InfoRow("hw.logicalcpu", sysctlInt("hw.logicalcpu").map(String.init) ?? "—"),
            InfoRow("hw.physicalcpu_max", sysctlInt("hw.physicalcpu_max").map(String.init) ?? "—"),
            InfoRow("hw.logicalcpu_max", sysctlInt("hw.logicalcpu_max").map(String.init) ?? "—"),
            InfoRow("hw.cputype", sysctlInt("hw.cputype").map { cpuTypeName($0) } ?? "—"),
            InfoRow("hw.cpusubtype", sysctlInt("hw.cpusubtype").map(String.init) ?? "—"),
            InfoRow("hw.cpufamily", sysctlU32("hw.cpufamily").map { String(format: "0x%08X", $0) } ?? "—"),
            InfoRow("hw.optional.arm.FEAT_LSE", sysctlInt("hw.optional.arm.FEAT_LSE").map(String.init) ?? "—"),
            InfoRow("编译架构", compiledArch()),
        ]
        if let device = MTLCreateSystemDefaultDevice() {
            rows.append(contentsOf: [
                InfoRow("GPU 名称", device.name),
                InfoRow("GPU 统一内存", InfoFormat.bool(device.hasUnifiedMemory)),
                InfoRow("GPU 推荐工作集", InfoFormat.bytes(Int64(device.recommendedMaxWorkingSetSize))),
                InfoRow("GPU 最大 buffer", InfoFormat.bytes(Int64(device.maxBufferLength))),
                InfoRow("GPU family", metalFamily(device)),
            ])
        }
        return InfoSection("CPU / GPU", rows: rows)
    }

    private static func thermalPowerSection() -> InfoSection {
        let p = ProcessInfo.processInfo
        UIDevice.current.isBatteryMonitoringEnabled = true
        defer { UIDevice.current.isBatteryMonitoringEnabled = false }
        let battery: String
        switch UIDevice.current.batteryState {
        case .unknown: battery = "未知"
        case .unplugged: battery = "未充电"
        case .charging: battery = "充电中"
        case .full: battery = "已满"
        @unknown default: battery = "\(UIDevice.current.batteryState.rawValue)"
        }
        let thermal: String
        switch p.thermalState {
        case .nominal: thermal = "正常"
        case .fair: thermal = "轻微"
        case .serious: thermal = "严重"
        case .critical: thermal = "危急"
        @unknown default: thermal = "\(p.thermalState.rawValue)"
        }
        return InfoSection("电源与散热", rows: [
            InfoRow("热状态", thermal),
            InfoRow("低电量模式", InfoFormat.bool(p.isLowPowerModeEnabled)),
            InfoRow("电池状态", battery),
            InfoRow("电量", String(format: "%.0f%%", UIDevice.current.batteryLevel * 100)),
            InfoRow("接近监听（本进程）", InfoFormat.bool(UIDevice.current.isProximityMonitoringEnabled)),
        ])
    }

    private static func localeTimeSection() -> InfoSection {
        let loc = Locale.current
        let tz = TimeZone.current
        let now = Date()
        return InfoSection("区域与时间", rows: [
            InfoRow("现在", InfoFormat.date(now)),
            InfoRow("时区", tz.identifier),
            InfoRow("秒偏移", "\(tz.secondsFromGMT())"),
            InfoRow("夏令时", InfoFormat.bool(tz.isDaylightSavingTime())),
            InfoRow("区域", loc.identifier),
            InfoRow("语言", Locale.preferredLanguages.joined(separator: ", ")),
            InfoRow("日历", String(describing: loc.calendar.identifier)),
            InfoRow("度量", String(describing: loc.measurementSystem)),
            InfoRow("24 小时", InfoFormat.bool(DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: loc)?.contains("a") == false)),
        ])
    }

    private static func networkSection() -> InfoSection {
        var rows: [InfoRow] = [
            InfoRow("hostname", sysctlString("kern.hostname")),
        ]
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddr) == 0, let first = ifaddr {
            defer { freeifaddrs(first) }
            var seen = Set<String>()
            var ptr: UnsafeMutablePointer<ifaddrs>? = first
            while let p = ptr {
                let name = String(cString: p.pointee.ifa_name)
                if let addr = p.pointee.ifa_addr {
                    var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    let family = Int32(addr.pointee.sa_family)
                    if family == AF_INET || family == AF_INET6 {
                        getnameinfo(addr, socklen_t(addr.pointee.sa_len), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST)
                        let ip = String(cString: host)
                        let key = "\(name) \(family == AF_INET ? "IPv4" : "IPv6")"
                        if seen.insert(key + ip).inserted {
                            rows.append(InfoRow(key, ip))
                        }
                    }
                }
                ptr = p.pointee.ifa_next
            }
        }
        return InfoSection("网络接口", subtitle: "本机接口，不含公网 IP", rows: rows)
    }

    private static func accessibilitySection() -> InfoSection {
        InfoSection("辅助功能", rows: [
            InfoRow("VoiceOver", InfoFormat.bool(UIAccessibility.isVoiceOverRunning)),
            InfoRow("切换控制", InfoFormat.bool(UIAccessibility.isSwitchControlRunning)),
            InfoRow("引导式访问", InfoFormat.bool(UIAccessibility.isGuidedAccessEnabled)),
            InfoRow("降低透明度", InfoFormat.bool(UIAccessibility.isReduceTransparencyEnabled)),
            InfoRow("减弱动态效果", InfoFormat.bool(UIAccessibility.isReduceMotionEnabled)),
            InfoRow("加粗文本", InfoFormat.bool(UIAccessibility.isBoldTextEnabled)),
            InfoRow("按钮形状", InfoFormat.bool(UIAccessibility.buttonShapesEnabled)),
            InfoRow("开合字幕", InfoFormat.bool(UIAccessibility.isClosedCaptioningEnabled)),
            InfoRow("反转颜色", InfoFormat.bool(UIAccessibility.isInvertColorsEnabled)),
            InfoRow("灰度", InfoFormat.bool(UIAccessibility.isGrayscaleEnabled)),
            InfoRow("屏幕朗读", InfoFormat.bool(UIAccessibility.isSpeakScreenEnabled)),
        ])
    }

    private static func environmentSection() -> InfoSection {
        InfoSection("编译戳记", subtitle: "由 Codemagic 写入，用于核对本次 IPA", rows: [
            InfoRow("仓库", BuildStamp.repo),
            InfoRow("分支", BuildStamp.branch),
            InfoRow("Commit", BuildStamp.gitCommit),
            InfoRow("短哈希", BuildStamp.gitCommitShort),
            InfoRow("Build 号", BuildStamp.buildNumber),
            InfoRow("Codemagic Build ID", BuildStamp.buildId),
            InfoRow("构建时间", BuildStamp.builtAt),
            InfoRow("工作流", BuildStamp.workflow),
            InfoRow("实例", BuildStamp.instance),
            InfoRow("Xcode", BuildStamp.xcode),
            InfoRow("Flutter", BuildStamp.flutter),
        ])
    }

    // MARK: helpers

    private static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }

    private static let uts: (sysname: String, nodename: String, release: String, version: String, machine: String) = {
        var n = utsname()
        uname(&n)
        func s(_ v: Any) -> String {
            withUnsafePointer(to: v) {
                $0.withMemoryRebound(to: CChar.self, capacity: 256) { String(cString: $0) }
            }
        }
        return (s(n.sysname), s(n.nodename), s(n.release), s(n.version), s(n.machine))
    }()

    private static func liquidGlassStatus() -> String {
        if #available(iOS 26.0, *) { return "可用 (iOS 26 glassEffect)" }
        return "当前系统低于 26，界面回退到 ultraThinMaterial"
    }

    private static func sysctlString(_ name: String) -> String {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return "—" }
        var buf = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &buf, &size, nil, 0) == 0 else { return "—" }
        return String(cString: buf)
    }

    private static func sysctlInt(_ name: String) -> Int? {
        var v: Int32 = 0
        var size = MemoryLayout<Int32>.size
        guard sysctlbyname(name, &v, &size, nil, 0) == 0 else { return nil }
        return Int(v)
    }

    private static func sysctlU32(_ name: String) -> UInt32? {
        var v: UInt32 = 0
        var size = MemoryLayout<UInt32>.size
        guard sysctlbyname(name, &v, &size, nil, 0) == 0 else { return nil }
        return v
    }

    private static func sysctlU64(_ name: String) -> UInt64? {
        var v: UInt64 = 0
        var size = MemoryLayout<UInt64>.size
        guard sysctlbyname(name, &v, &size, nil, 0) == 0 else { return nil }
        return v
    }

    private static func sysctlTimeval(_ name: String) -> timeval? {
        var v = timeval()
        var size = MemoryLayout<timeval>.size
        guard sysctlbyname(name, &v, &size, nil, 0) == 0 else { return nil }
        return v
    }

    private static func bootTime() -> String {
        guard let tv = sysctlTimeval("kern.boottime") else { return "—" }
        let date = Date(timeIntervalSince1970: TimeInterval(tv.tv_sec) + TimeInterval(tv.tv_usec) / 1_000_000)
        return InfoFormat.date(date)
    }

    private static func uptime() -> String {
        let s = ProcessInfo.processInfo.systemUptime
        let h = Int(s) / 3600
        let m = (Int(s) % 3600) / 60
        let sec = Int(s) % 60
        return String(format: "%dh %dm %ds (%.3f s)", h, m, sec, s)
    }

    private static func string(_ value: Any?) -> String {
        guard let value else { return "—" }
        return String(describing: value)
    }

    private static func inset(_ i: UIEdgeInsets) -> String {
        String(format: "t %.1f l %.1f b %.1f r %.1f", i.top, i.left, i.bottom, i.right)
    }

    private static func colorGamut() -> String {
        switch UITraitCollection.current.displayGamut {
        case .P3: return "P3"
        case .SRGB: return "sRGB"
        default: return "unspecified"
        }
    }

    private static func contrastStatus() -> String {
        UITraitCollection.current.accessibilityContrast == .high ? "高对比" : "标准"
    }

    private static func cpuTypeName(_ v: Int) -> String {
        switch v {
        case Int(CPU_TYPE_ARM64): return "ARM64 (\(v))"
        case Int(CPU_TYPE_ARM): return "ARM (\(v))"
        case Int(CPU_TYPE_X86_64): return "x86_64 (\(v))"
        default: return "\(v)"
        }
    }

    private static func compiledArch() -> String {
        #if arch(arm64)
        return "arm64"
        #elseif arch(x86_64)
        return "x86_64"
        #else
        return "unknown"
        #endif
    }

    private static func metalFamily(_ device: MTLDevice) -> String {
        var families: [String] = []
        if device.supportsFamily(.apple7) { families.append("Apple7") }
        if device.supportsFamily(.apple8) { families.append("Apple8") }
        if #available(iOS 18.0, *) {
            if device.supportsFamily(.apple9) { families.append("Apple9") }
        }
        return families.isEmpty ? "未知" : families.joined(separator: ", ")
    }

    private static func identifierNote() -> String {
        "IDFV / 广告标识未采集。本页仅展示本机系统与硬件探测结果。"
    }

    private static func marketingName(for machine: String) -> String {
        let map: [String: String] = [
            "iPhone17,1": "iPhone 16 Pro",
            "iPhone17,2": "iPhone 16 Pro Max",
            "iPhone18,1": "iPhone 17 Pro",
            "iPhone18,2": "iPhone 17 Pro Max",
            "iPhone18,3": "iPhone 17",
            "iPhone18,4": "iPhone 17 Air",
        ]
        return map[machine] ?? "查表未覆盖，显示 uts.machine 即可"
    }
}
