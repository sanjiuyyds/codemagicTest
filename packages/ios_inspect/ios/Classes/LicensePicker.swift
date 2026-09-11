import SwiftUI
import UniformTypeIdentifiers

struct LicenseDocumentPicker: UIViewControllerRepresentable {
    var onPick: (Result<URL, Error>) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        picker.directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (Result<URL, Error>) -> Void

        init(onPick: @escaping (Result<URL, Error>) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                onPick(.failure(LicensePickerError.empty))
                return
            }
            onPick(.success(url))
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {}
    }
}

enum LicensePickerError: LocalizedError {
    case empty
    case notHtml
    case unreadable

    var errorDescription: String? {
        switch self {
        case .empty: return "没有选中文件"
        case .notHtml: return "请选择 .html 或 .htm 文件"
        case .unreadable: return "无法读取该文件，请再试一次或换一个位置的 html"
        }
    }
}
