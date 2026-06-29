import SwiftUI

enum LGDesign {
    static let sentBlue = Color(red: 0.00, green: 0.47, blue: 1.00)
    static let weChatGreen = Color(red: 0.03, green: 0.76, blue: 0.38)
    static let previewGreen = Color(red: 0.06, green: 0.78, blue: 0.36)
    static let previewIncoming = Color(red: 0.08, green: 0.09, blue: 0.10).opacity(0.76)
    static let incomingDark = Color(red: 0.15, green: 0.15, blue: 0.16)
    static let incomingLight = Color(red: 0.91, green: 0.91, blue: 0.93)
    static let pageBackground = Color(uiColor: .systemGroupedBackground)
    static let rowHairline = Color.primary.opacity(0.10)
    static let bubbleRadius: CGFloat = 19
    static let composerHeight: CGFloat = 50
    static let avatar: CGFloat = 46
}

enum LGGlassStyle {
    case regular
    case clear
}

extension Color {
    init(hex: String) {
        var value = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if value.count == 3 {
            value = value.map { "\($0)\($0)" }.joined()
        }
        var int: UInt64 = 0
        Scanner(string: value).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xff) / 255
        let g = Double((int >> 8) & 0xff) / 255
        let b = Double(int & 0xff) / 255
        self.init(red: r, green: g, blue: b)
    }
}

extension View {
    @ViewBuilder
    func liquidGlassBackground(cornerRadius: CGFloat, interactive: Bool = false, style: LGGlassStyle = .regular) -> some View {
        if #available(iOS 26.0, *) {
            switch (style, interactive) {
            case (.clear, true):
                self.glassEffect(.clear.interactive(), in: .rect(cornerRadius: cornerRadius))
            case (.clear, false):
                self.glassEffect(.clear, in: .rect(cornerRadius: cornerRadius))
            case (.regular, true):
                self.glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
            case (.regular, false):
                self.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
            }
        } else {
            if style == .clear {
                self
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(.white.opacity(0.22), lineWidth: 0.7)
                    )
            } else {
                self
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(.white.opacity(0.34), lineWidth: 0.7)
                    )
            }
        }
    }
}

enum ChatFormatters {
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    static let relative: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
}
