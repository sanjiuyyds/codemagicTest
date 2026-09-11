import Foundation
import UniformTypeIdentifiers

final class LicenseStore: ObservableObject {
    static let shared = LicenseStore()

    @Published private(set) var fileName: String?
    @Published private(set) var importedAt: Date?
    @Published private(set) var fileSize: Int64?
    @Published private(set) var hasDocument: Bool = false

    private let defaults = UserDefaults.standard
    private let nameKey = "xstools.license.filename"
    private let dateKey = "xstools.license.importedAt"
    private let sizeKey = "xstools.license.filesize"

    private var fileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return dir.appendingPathComponent("license.html")
    }

    init() {
        reload()
    }

    func reload() {
        let exists = FileManager.default.fileExists(atPath: fileURL.path)
        hasDocument = exists
        fileName = defaults.string(forKey: nameKey)
        if defaults.object(forKey: sizeKey) != nil {
            fileSize = Int64(defaults.integer(forKey: sizeKey))
        } else {
            fileSize = nil
        }
        if let ts = defaults.object(forKey: dateKey) as? TimeInterval {
            importedAt = Date(timeIntervalSince1970: ts)
        } else {
            importedAt = nil
        }
        if exists, fileSize == nil, let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path) {
            fileSize = (attrs[.size] as? NSNumber)?.int64Value
        }
    }

    func importFile(from url: URL) throws {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed { url.stopAccessingSecurityScopedResource() }
        }
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
        try FileManager.default.copyItem(at: url, to: fileURL)
        let attrs = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        defaults.set(url.lastPathComponent, forKey: nameKey)
        defaults.set(Date().timeIntervalSince1970, forKey: dateKey)
        defaults.set(Int((attrs[.size] as? NSNumber)?.int64Value ?? 0), forKey: sizeKey)
        reload()
    }

    func documentURL() -> URL? {
        FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
    }

    func clear() throws {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
        defaults.removeObject(forKey: nameKey)
        defaults.removeObject(forKey: dateKey)
        defaults.removeObject(forKey: sizeKey)
        reload()
    }
}
