import AppKit
import SwiftUI

enum LauncherGlassStyle {
    static let accent = Color(red: 0.10, green: 0.48, blue: 0.98)
    static let panelTintTop = Color.black.opacity(0.34)
    static let panelTintBottom = Color.black.opacity(0.48)
    static let panelHighlight = Color.white.opacity(0.07)
    static let panelStroke = Color.white.opacity(0.12)
    static let divider = Color.white.opacity(0.08)
    static let title = Color.white.opacity(0.94)
    static let secondary = Color.white.opacity(0.70)
    static let tertiary = Color.white.opacity(0.48)
    static let hoverFill = Color.white.opacity(0.05)
    static let selectionFill = accent
    static let selectedHighlight = Color(red: 1.0, green: 0.86, blue: 0.30)
    static let selectionStroke = Color.white.opacity(0.12)
    static let capsuleFill = Color.white.opacity(0.06)
    static let capsuleStroke = Color.white.opacity(0.08)
    static let shadow = Color.black.opacity(0.32)
    static let glow = Color.white.opacity(0.04)
    static let searchText = Color.white.opacity(0.96)
    static let searchPlaceholder = Color.white.opacity(0.42)
}

struct LauncherGlassBackground: View {
    let cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.clear)
            .background(
                GlassMaterialView(material: .hudWindow, blendingMode: .behindWindow)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [LauncherGlassStyle.panelTintTop, LauncherGlassStyle.panelTintBottom],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(LauncherGlassStyle.panelStroke, lineWidth: 1)
            )
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(LauncherGlassStyle.panelHighlight, lineWidth: 1)
                    .blur(radius: 0.3)
                    .mask(
                        LinearGradient(
                            colors: [.white, .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .shadow(color: LauncherGlassStyle.shadow, radius: 30, x: 0, y: 18)
    }
}

struct GlassMaterialView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.state = .active
        view.material = material
        view.blendingMode = blendingMode
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.state = .active
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.isEmphasized = true
    }
}
