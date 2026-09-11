import UIKit
import UniformTypeIdentifiers

final class LicensePicker: NSObject, UIDocumentPickerDelegate {
    static let shared = LicensePicker()

    private var onPicked: ((Result<URL, Error>) -> Void)?
    private var picker: UIDocumentPickerViewController?

    func present(completion: @escaping (Result<URL, Error>) -> Void) {
        onPicked = completion
        let types: [UTType] = [.item]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        picker.delegate = self
        picker.modalPresentationStyle = .formSheet
        self.picker = picker

        DispatchQueue.main.async {
            guard let host = self.rootPresenter() else {
                completion(.failure(LicensePickerError.noPresenter))
                self.onPicked = nil
                self.picker = nil
                return
            }
            host.present(picker, animated: true)
        }
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        finish(urls.first)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
        picker = nil
        onPicked = nil
    }

    private func finish(_ url: URL?) {
        picker?.dismiss(animated: true)
        picker = nil
        guard let url else {
            onPicked?(.failure(LicensePickerError.empty))
            onPicked = nil
            return
        }
        onPicked?(.success(url))
        onPicked = nil
    }

    private func rootPresenter() -> UIViewController? {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow && !$0.isHidden })
            ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first(where: { !$0.isHidden })
        var controller = window?.rootViewController
        while let presented = controller?.presentedViewController {
            controller = presented
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
