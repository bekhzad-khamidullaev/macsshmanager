import SwiftUI
import AppKit

enum RadixTheme {
    private static func dynamic(light: NSColor, dark: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                return dark
            }
            return light
        })
    }

    static let pageBackground = dynamic(
        light: NSColor(srgbRed: 0.988, green: 0.989, blue: 0.991, alpha: 1),
        dark: NSColor(srgbRed: 0.085, green: 0.091, blue: 0.100, alpha: 1)
    )
    static let surface = dynamic(
        light: NSColor(srgbRed: 0.978, green: 0.980, blue: 0.984, alpha: 1),
        dark: NSColor(srgbRed: 0.122, green: 0.132, blue: 0.145, alpha: 1)
    )
    static let surfaceElevated = dynamic(
        light: NSColor(srgbRed: 0.996, green: 0.997, blue: 0.999, alpha: 1),
        dark: NSColor(srgbRed: 0.155, green: 0.169, blue: 0.186, alpha: 1)
    )
    static let surfaceSubtle = dynamic(
        light: NSColor(srgbRed: 0.945, green: 0.952, blue: 0.960, alpha: 1),
        dark: NSColor(srgbRed: 0.188, green: 0.206, blue: 0.227, alpha: 1)
    )
    static let border = dynamic(
        light: NSColor(srgbRed: 0.808, green: 0.831, blue: 0.858, alpha: 1),
        dark: NSColor(srgbRed: 0.294, green: 0.333, blue: 0.372, alpha: 1)
    )
    static let borderStrong = dynamic(
        light: NSColor(srgbRed: 0.688, green: 0.729, blue: 0.770, alpha: 1),
        dark: NSColor(srgbRed: 0.404, green: 0.451, blue: 0.498, alpha: 1)
    )
    static let textMuted = dynamic(
        light: NSColor(srgbRed: 0.360, green: 0.406, blue: 0.454, alpha: 1),
        dark: NSColor(srgbRed: 0.690, green: 0.735, blue: 0.782, alpha: 1)
    )
    static let accent = dynamic(
        light: NSColor(srgbRed: 0.000, green: 0.447, blue: 0.831, alpha: 1),
        dark: NSColor(srgbRed: 0.335, green: 0.665, blue: 0.972, alpha: 1)
    )
    static let accentSoft = dynamic(
        light: NSColor(srgbRed: 0.898, green: 0.949, blue: 0.996, alpha: 1),
        dark: NSColor(srgbRed: 0.167, green: 0.270, blue: 0.380, alpha: 1)
    )
}

struct RadixPageBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    RadixTheme.pageBackground,
                    Color(nsColor: NSColor(srgbRed: 0.969, green: 0.974, blue: 0.982, alpha: 1))
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(RadixTheme.accent.opacity(0.08))
                .frame(width: 620, height: 620)
                .offset(x: 360, y: -260)
                .blur(radius: 40)

            Circle()
                .fill(RadixTheme.surfaceSubtle.opacity(0.8))
                .frame(width: 500, height: 500)
                .offset(x: -360, y: 260)
                .blur(radius: 32)
        }
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
                    .stroke(elevated ? RadixTheme.borderStrong : RadixTheme.border, lineWidth: 1)
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
        PrimaryStyledBody(configuration: configuration)
    }

    private struct PrimaryStyledBody: View {
        let configuration: ButtonStyle.Configuration
        @State private var isHovered: Bool = false

        var body: some View {
            configuration.label
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(backgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(RadixTheme.accent.opacity(0.9), lineWidth: isHovered ? 1.2 : 1)
                )
                .foregroundStyle(Color.white)
                .opacity(configuration.isPressed ? 0.96 : 1)
                .shadow(color: RadixTheme.accent.opacity(isHovered ? 0.33 : 0.22), radius: isHovered ? 8 : 4, y: 1)
                .onHover { hovering in
                    isHovered = hovering
                }
        }

        private var backgroundColor: Color {
            if configuration.isPressed {
                return RadixTheme.accent.opacity(0.82)
            }
            if isHovered {
                return RadixTheme.accent.opacity(0.94)
            }
            return RadixTheme.accent
        }
    }
}

struct RadixSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        SecondaryStyledBody(configuration: configuration)
    }

    private struct SecondaryStyledBody: View {
        let configuration: ButtonStyle.Configuration
        @State private var isHovered: Bool = false

        var body: some View {
            configuration.label
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(fillColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(strokeColor, lineWidth: isHovered ? 1.15 : 1)
                )
                .foregroundStyle(.primary)
                .onHover { hovering in
                    isHovered = hovering
                }
        }

        private var fillColor: Color {
            if configuration.isPressed {
                return RadixTheme.surfaceSubtle
            }
            if isHovered {
                return RadixTheme.accentSoft
            }
            return RadixTheme.surfaceElevated
        }

        private var strokeColor: Color {
            isHovered ? RadixTheme.borderStrong : RadixTheme.border
        }
    }
}

struct RadixIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        IconStyledBody(configuration: configuration)
    }

    private struct IconStyledBody: View {
        let configuration: ButtonStyle.Configuration
        @State private var isHovered: Bool = false

        var body: some View {
            configuration.label
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(fillColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(strokeColor, lineWidth: isHovered ? 1.15 : 1)
                )
                .onHover { hovering in
                    isHovered = hovering
                }
        }

        private var fillColor: Color {
            if configuration.isPressed {
                return RadixTheme.surfaceSubtle
            }
            if isHovered {
                return RadixTheme.accentSoft
            }
            return RadixTheme.surfaceElevated
        }

        private var strokeColor: Color {
            isHovered ? RadixTheme.borderStrong : RadixTheme.border
        }
    }
}
