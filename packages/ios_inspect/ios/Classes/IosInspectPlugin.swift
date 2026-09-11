import Flutter
import SwiftUI
import UIKit

public class IosInspectPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        registrar.register(InspectViewFactory(), withId: "ipa_min/root")
    }
}

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
        controller.view.frame = frame
        controller.view.backgroundColor = .clear
        controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.controller = controller
        super.init()
    }

    func view() -> UIView { controller.view }
}
