import Foundation

struct InfoRow: Identifiable, Hashable {
    let id: String
    let title: String
    let value: String
    let footnote: String?

    init(_ title: String, _ value: String, footnote: String? = nil) {
        self.id = UUID().uuidString
        self.title = title
        self.value = value.isEmpty ? "—" : value
        self.footnote = footnote
    }
}

struct InfoSection: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let rows: [InfoRow]

    init(_ title: String, subtitle: String? = nil, rows: [InfoRow]) {
        self.id = title
        self.title = title
        self.subtitle = subtitle
        self.rows = rows
    }
}

enum InfoFormat {
    static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    static let local: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
        return f
    }()

    static func bytes(_ value: Int64) -> String {
        let f = ByteCountFormatter()
        f.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        f.countStyle = .file
        return "\(f.string(fromByteCount: value)) (\(value) B)"
    }

    static func bool(_ value: Bool) -> String { value ? "是" : "否" }

    static func json(_ object: Any) -> String {
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
              let text = String(data: data, encoding: .utf8)
        else {
            return String(describing: object)
        }
        return text
    }

    static func hex(_ data: Data, limit: Int = 64) -> String {
        let slice = data.prefix(limit)
        let text = slice.map { String(format: "%02X", $0) }.joined(separator: " ")
        if data.count > limit {
            return text + " … (\(data.count) bytes)"
        }
        return text.isEmpty ? "—" : text
    }

    static func date(_ date: Date) -> String {
        "\(local.string(from: date)) | \(iso.string(from: date))"
    }
}
