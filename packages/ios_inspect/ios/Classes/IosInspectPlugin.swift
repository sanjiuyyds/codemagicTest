import Flutter
import SwiftUI
import UIKit

public class IosInspectPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        registrar.register(InspectViewFactory(), withId: "ipa_min/root")
        NativeHost.schedule()
    }
}

enum NativeHost {
    static func schedule() {
        let delays: [Double] = [0.0, 0.2, 0.8, 1.6]
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                installIfNeeded()
            }
        }
    }

    static func installIfNeeded() {
        guard let window = keyWindow() else { return }
        if window.rootViewController is XsToolsHostController { return }
        let host = XsToolsHostController(rootView: RootView())
        host.view.backgroundColor = .systemBackground
        host.view.frame = window.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        window.rootViewController = host
        window.makeKeyAndVisible()
    }

    static func keyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
            ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first
    }
}

final class XsToolsHostController: UIHostingController<RootView> {}

final class InspectViewFactory: NSObject, FlutterPlatformViewFactory {
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }

    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        InspectPlatformView(frame: frame)
    }
}

final class InspectPlatformView: NSObject, FlutterPlatformView {
    private let controller: UIHostingController<RootView>

    init(frame: CGRect) {
        let controller = UIHostingController(rootView: RootView())
        controller.view.backgroundColor = .systemBackground
        controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        if #available(iOS 16.4, *) {
            controller.safeAreaRegions = []
        }
        self.controller = controller
        super.init()
        attach(in: frame)
    }

    private func attach(in frame: CGRect) {
        controller.view.frame = frame
        DispatchQueue.main.async { [weak controller] in
            guard let view = controller?.view else { return }
            var parent: UIView? = view.superview
            while let current = parent {
                current.clipsToBounds = false
                parent = current.superview
            }
            view.superview?.backgroundColor = .systemBackground
        }
    }

    func view() -> UIView { controller.view }
}
