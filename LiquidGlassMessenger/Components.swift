import SwiftUI

struct AvatarView: View {
    let participant: Participant
    var size: CGFloat = LGDesign.avatar

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: participant.tintHex), Color(hex: participant.tintHex).opacity(0.62)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Text(participant.monogram)
                        .font(.system(size: size * 0.42, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                )

            if participant.presence != .offline {
                Circle()
                    .fill(participant.presence == .online ? LGDesign.weChatGreen : .yellow)
                    .frame(width: max(9, size * 0.23), height: max(9, size * 0.23))
                    .overlay(Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 2))
                    .offset(x: 1, y: 1)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel(participant.displayName)
    }
}

struct IconBubbleButton: View {
    let symbol: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .liquidGlassBackground(cornerRadius: 17, interactive: true)
        .accessibilityLabel(symbol)
    }
}

struct BubbleShape: Shape {
    var isOutgoing: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = LGDesign.bubbleRadius
        var path = Path()

        let bubbleRect = rect.inset(by: UIEdgeInsets(top: 0, left: isOutgoing ? 0 : 6, bottom: 0, right: isOutgoing ? 6 : 0))
        path.addRoundedRect(in: bubbleRect, cornerSize: CGSize(width: radius, height: radius), style: .continuous)

        if isOutgoing {
            path.move(to: CGPoint(x: rect.maxX - 13, y: rect.maxY - 7))
            path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY - 1), control: CGPoint(x: rect.maxX - 3, y: rect.maxY - 2))
            path.addQuadCurve(to: CGPoint(x: rect.maxX - 9, y: rect.maxY - 15), control: CGPoint(x: rect.maxX - 3, y: rect.maxY - 13))
        } else {
            path.move(to: CGPoint(x: rect.minX + 13, y: rect.maxY - 7))
            path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - 1), control: CGPoint(x: rect.minX + 3, y: rect.maxY - 2))
            path.addQuadCurve(to: CGPoint(x: rect.minX + 9, y: rect.maxY - 15), control: CGPoint(x: rect.minX + 3, y: rect.maxY - 13))
        }

        return path
    }
}

struct AttachmentCard: View {
    let attachment: AttachmentPreview

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: attachment.systemImage)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color(hex: attachment.tintHex))
                .frame(width: 42, height: 42)
                .background(Color(hex: attachment.tintHex).opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(attachment.title)
                    .font(.system(size: 15, weight: .semibold))
                Text(attachment.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
