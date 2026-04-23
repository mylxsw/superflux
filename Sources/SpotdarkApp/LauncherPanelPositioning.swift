import CoreGraphics
import Foundation

enum LauncherPanelPositioning {
    static func compactOrigin(
        panelSize: CGSize,
        screenFrame: CGRect,
        visibleFrame: CGRect,
        verticalOffsetRatio: CGFloat,
        maximumVerticalOffset: CGFloat
    ) -> CGPoint {
        let verticalOffset = min(visibleFrame.height * verticalOffsetRatio, maximumVerticalOffset)
        let center = CGPoint(
            x: screenFrame.midX,
            y: visibleFrame.midY + verticalOffset
        )
        return CGPoint(
            x: round(center.x - panelSize.width / 2),
            y: round(center.y - panelSize.height / 2)
        )
    }

    static func originKeepingTopEdge(currentFrame: CGRect, newHeight: CGFloat) -> CGPoint {
        CGPoint(
            x: round(currentFrame.origin.x),
            y: round(currentFrame.maxY - newHeight)
        )
    }

    static func restoredOrigin(
        from persistedFrame: [String: Any],
        panelSize: CGSize,
        visibleFrames: [CGRect]
    ) -> CGPoint? {
        guard let x = persistedFrame["x"] as? Double else {
            return nil
        }

        let y: CGFloat
        if let top = persistedFrame["top"] as? Double {
            y = CGFloat(top) - panelSize.height
        } else if let storedY = persistedFrame["y"] as? Double {
            y = CGFloat(storedY)
        } else {
            return nil
        }

        let origin = CGPoint(x: CGFloat(x), y: y)
        let frame = CGRect(origin: origin, size: panelSize).integral
        guard visibleFrames.contains(where: { contains(frame, in: $0) }) else {
            return nil
        }

        return origin
    }

    private static func contains(_ frame: CGRect, in visibleFrame: CGRect) -> Bool {
        frame.minX >= visibleFrame.minX &&
        frame.maxX <= visibleFrame.maxX &&
        frame.minY >= visibleFrame.minY &&
        frame.maxY <= visibleFrame.maxY
    }
}
