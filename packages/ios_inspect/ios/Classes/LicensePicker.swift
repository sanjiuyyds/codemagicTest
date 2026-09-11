import UIKit
import UniformTypeIdentifiers

final class LicensePicker: NSObject, UIDocumentPickerDelegate {
    static let shared = LicensePicker()

    private var onPicked: ((Result<URL, Error>) -> Void)?
    private var picker: UIDocumentPickerViewController?

    func present(from view: UIView? = nil, completion: @escaping (Result<URL, Error>) -> Void) {
        onPicked = completion
        let types: [UTType] = [
            .item,
            .data,
            .content,
            .html,
            .plainText,
            .text,
            UTType(filenameExtension: "html") ?? .html,
            UTType(filenameExtension: "htm") ?? .html,
        ]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        picker.delegate = self
        self.picker = picker
        guard let host = topController(from: view) else {
            completion(.failure(LicensePickerError.noPresenter))
            return
        }
        host.present(picker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        controller.dismiss(animated: true)
        picker = nil
        guard let url = urls.first else {
            onPicked?(.failure(LicensePickerError.empty))
            onPicked = nil
            return
        }
        onPicked?(.success(url))
        onPicked = nil
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
        picker = nil
        onPicked = nil
    }

    private func topController(from view: UIView?) -> UIViewController? {
        if let from = view?.window?.rootViewController {
            return topMost(from)
        }
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
            ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first
        guard let root = window?.rootViewController else { return nil }
        return topMost(root)
    }

    private func topMost(_ controller: UIViewController) -> UIViewController {
        if let presented = controller.presentedViewController {
            return topMost(presented)
        }
        if let nav = controller as? UINavigationController, let visible = nav.visibleViewController {
            return topMost(visible)
        }
        if let tab = controller as? UITabBarController, let selected = tab.selectedViewController {
            return topMost(selected)
        }
        return controller
    }
}

enum LicensePickerError: LocalizedError {
    case noPresenter
    case empty
    case notHtml

    var errorDescription: String? {
        switch self {
        case .noPresenter: return "找不到可用于打开文件选择器的窗口"
        case .empty: return "没有选中文件"
        case .notHtml: return "请选择 .html 或 .htm 文件"
        }
    }
}
