import SwiftUI

extension View {
    @ViewBuilder
    func ipaGlass(cornerRadius: CGFloat = 24) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(
                .regular,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
        } else {
            self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }

    @ViewBuilder
    func ipaGlassClear(cornerRadius: CGFloat = 20) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(
                .clear,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
        } else {
            self.background(.thinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}

enum IpaTheme {
    static let bgTop = Color(red: 0.05, green: 0.08, blue: 0.18)
    static let bgBottom = Color(red: 0.02, green: 0.03, blue: 0.07)
    static let accent = Color(red: 0.45, green: 0.85, blue: 0.95)
    static let mint = Color(red: 0.36, green: 0.92, blue: 0.75)
}
