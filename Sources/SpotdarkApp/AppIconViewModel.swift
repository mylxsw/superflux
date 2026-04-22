import AppKit
import Foundation

@MainActor
final class AppIconViewModel: ObservableObject {
    @Published private(set) var image: NSImage?

    private let bundleURL: URL
    private let size: CGSize
    private var loadTask: Task<Void, Never>?

    init(bundleURL: URL, size: CGSize) {
        self.bundleURL = bundleURL
        self.size = size
        self.image = AppPresentationCache.shared.cachedIcon(for: bundleURL, size: size)
    }

    deinit {
        loadTask?.cancel()
    }

    func loadIfNeeded() {
        guard image == nil, loadTask == nil else { return }

        let bundleURL = bundleURL
        let size = size

        loadTask = Task { [weak self] in
            let icon = await AppPresentationCache.shared.loadIcon(for: bundleURL, size: size)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard let self else { return }
                self.image = icon
                self.loadTask = nil
            }
        }
    }

    func cancelLoading() {
        loadTask?.cancel()
        loadTask = nil
    }
}
