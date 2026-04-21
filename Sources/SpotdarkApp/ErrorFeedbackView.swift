import SwiftUI

struct ErrorFeedbackView: View {
    let content: ErrorFeedbackContent

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(content.style.tint.opacity(0.16))

                Image(systemName: content.style.symbolName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(content.style.tint)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 6) {
                Text(content.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(content.message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)

                if let footnote = content.footnote {
                    Text(footnote)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(width: 520, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.16), radius: 24, y: 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessibilityLabel))
    }

    private var accessibilityLabel: String {
        var parts = [content.title, content.message]
        if let footnote = content.footnote {
            parts.append(footnote)
        }
        return parts.joined(separator: ". ")
    }
}

#Preview("Shortcut Fallback") {
    ZStack {
        LinearGradient(
            colors: [Color.black.opacity(0.18), Color.black.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        ErrorFeedbackView(content: .accessibilityPermissionError)
            .padding(32)
    }
    .frame(width: 640, height: 220)
}

#Preview("Shortcut Failure") {
    ZStack {
        Color.black.opacity(0.16)

        ErrorFeedbackView(content: .shortcutMonitorError)
            .padding(32)
    }
    .frame(width: 640, height: 220)
}
