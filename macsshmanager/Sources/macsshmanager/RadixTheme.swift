import SwiftUI
import AppKit

enum RadixTheme {
    static let pageBackground = Color(nsColor: .windowBackgroundColor)
    static let surface = Color(nsColor: .windowBackgroundColor)
    static let surfaceElevated = Color(nsColor: .controlBackgroundColor)
    static let surfaceSubtle = Color(nsColor: .underPageBackgroundColor)
    static let border = Color(nsColor: .separatorColor)
    static let borderStrong = Color(nsColor: .gridColor)
    static let textMuted = Color(nsColor: .secondaryLabelColor)
    static let accent = Color.accentColor
    static let accentSoft = Color(nsColor: .selectedContentBackgroundColor).opacity(0.22)
}

struct RadixPageBackground: View {
    var body: some View {
        RadixTheme.pageBackground
            .ignoresSafeArea()
    }
}

struct RadixCardModifier: ViewModifier {
    let elevated: Bool
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(elevated ? RadixTheme.surfaceElevated : RadixTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(RadixTheme.border.opacity(elevated ? 1 : 0.9), lineWidth: 1)
            )
    }
}

extension View {
    func radixCard(elevated: Bool = false, radius: CGFloat = 12) -> some View {
        modifier(RadixCardModifier(elevated: elevated, radius: radius))
    }
}

struct RadixPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(configuration.isPressed ? Color.accentColor.opacity(0.78) : Color.accentColor)
            )
            .foregroundStyle(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.5)
            )
    }
}

struct RadixSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(configuration.isPressed ? Color(nsColor: .controlBackgroundColor) : Color(nsColor: .windowBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(RadixTheme.border, lineWidth: 1)
            )
            .foregroundStyle(.primary)
    }
}

struct RadixIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(4)
            .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}
