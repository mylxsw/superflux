import AppKit
import SwiftUI

struct AppIconView: View {
    private let size: CGSize

    @StateObject private var viewModel: AppIconViewModel

    init(bundleURL: URL, size: CGSize = CGSize(width: 28, height: 28)) {
        self.size = size
        _viewModel = StateObject(wrappedValue: AppIconViewModel(bundleURL: bundleURL, size: size))
    }

    var body: some View {
        Group {
            if let image = viewModel.image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                placeholder
                    .transition(.opacity)
            }
        }
        .frame(width: size.width, height: size.height)
        .animation(.easeOut(duration: 0.14), value: viewModel.image != nil)
        .task {
            viewModel.loadIfNeeded()
        }
        .onDisappear {
            viewModel.cancelLoading()
        }
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(.thinMaterial)

            Image(systemName: "app.dashed")
                .font(.system(size: min(size.width, size.height) * 0.45, weight: .medium))
                .foregroundStyle(.secondary.opacity(0.75))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
    }
}

#Preview("App Icon Placeholder") {
    AppIconView(bundleURL: URL(fileURLWithPath: "/Applications/TextEdit.app"))
        .padding()
        .background(.ultraThinMaterial)
}
