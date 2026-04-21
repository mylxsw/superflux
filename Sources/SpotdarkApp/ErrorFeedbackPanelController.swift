import AppKit
import SwiftUI

final class ErrorFeedbackPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class ErrorFeedbackPanelController {
    private let panel: ErrorFeedbackPanel
    private let hostingController: NSHostingController<ErrorFeedbackView>

    private var dismissTask: Task<Void, Never>?

    init() {
        hostingController = NSHostingController(rootView: ErrorFeedbackView(content: .accessibilityPermissionError))

        panel = ErrorFeedbackPanel(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 140),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true
        panel.contentViewController = hostingController

        hostingController.view.wantsLayer = true
        hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor

        updateLayout(for: .accessibilityPermissionError)
    }

    func present(_ content: ErrorFeedbackContent) {
        dismissTask?.cancel()

        hostingController.rootView = ErrorFeedbackView(content: content)
        updateLayout(for: content)

        if !panel.isVisible {
            panel.alphaValue = 0
            panel.orderFrontRegardless()
        } else {
            panel.orderFrontRegardless()
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }

        dismissTask = Task { [weak self, duration = content.duration] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.dismiss()
            }
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        dismissTask = nil

        guard panel.isVisible else { return }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.16
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        }, completionHandler: {
            self.panel.orderOut(nil)
        })
    }

    private func updateLayout(for content: ErrorFeedbackContent) {
        let height: CGFloat = content.footnote == nil ? 108 : 132
        panel.setContentSize(NSSize(width: 520, height: height))
        centerOnScreen()
    }

    private func centerOnScreen() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let visibleFrame = screen.visibleFrame
        let origin = NSPoint(
            x: visibleFrame.midX - panel.frame.width / 2,
            y: visibleFrame.maxY - panel.frame.height - 56
        )
        panel.setFrameOrigin(origin)
    }
}
