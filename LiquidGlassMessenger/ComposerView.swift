import SwiftUI

struct ComposerView: View {
    @EnvironmentObject private var store: MessengerStore
    @FocusState private var focused: Bool

    private let tools: [(String, String?)] = [
        ("快捷回复", nil),
        ("WeChat液态Glass.ai", nil),
        ("拍摄", "camera.fill"),
        ("文件", "folder.fill"),
        ("添加", "plus")
    ]

    var body: some View {
        VStack(spacing: 0) {
            if #available(iOS 26.0, *) {
                GlassEffectContainer(spacing: 12) {
                    composerStack
                }
            } else {
                composerStack
            }
        }
    }

    private var composerStack: some View {
        VStack(spacing: 7) {
            QuickToolStrip(tools: tools)

            HStack(alignment: .center, spacing: 9) {
                DarkComposerCircleButton(symbol: "plus", size: 48) {
                    withAnimation(.snappy) {
                        store.isAppDrawerVisible.toggle()
                    }
                }

                HStack(spacing: 10) {
                    TextField("输入消息", text: $store.composerText, axis: .vertical)
                        .focused($focused)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.88))
                        .tint(.white)
                        .lineLimit(1...5)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(.leading, 17)

                    Button {
                        if !store.composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            store.sendCurrentDraft()
                        } else {
                            focused.toggle()
                        }
                    } label: {
                        Image(systemName: store.composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "face.smiling" : "arrow.up.circle.fill")
                            .font(.system(size: 29, weight: .medium))
                            .foregroundStyle(.white.opacity(0.88))
                            .frame(width: 43, height: 43)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .frame(height: 48)
                .padding(.trailing, 6)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.22), lineWidth: 0.8)
                )
                .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
                .liquidGlassBackground(cornerRadius: 24, interactive: true, style: .clear)

                DarkComposerCircleButton(symbol: "speaker.wave.2", size: 48) {
                    focused = false
                }
            }
            .frame(minHeight: 54)

            if store.isAppDrawerVisible {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 14) {
                    ForEach(tools, id: \.0) { tool in
                        VStack(spacing: 7) {
                            Image(systemName: tool.1 ?? "sparkles")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.86))
                                .frame(width: 50, height: 44)
                                .liquidGlassBackground(cornerRadius: 14, interactive: true, style: .clear)

                            Text(tool.0)
                                .font(.system(size: 11.5))
                                .foregroundStyle(.white.opacity(0.72))
                        }
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
            }
        }
        .padding(.horizontal, 17)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
}

private struct QuickToolStrip: View {
    let tools: [(String, String?)]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(tools.enumerated()), id: \.offset) { index, tool in
                HStack(spacing: 5) {
                    if let symbol = tool.1 {
                        Image(systemName: symbol)
                            .font(.system(size: index == tools.count - 1 ? 19 : 17, weight: .semibold))
                    }

                    Text(tool.0)
                        .font(.system(size: index == 1 ? 13.5 : 15.5, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }
                .foregroundStyle(.white.opacity(0.88))
                .padding(.horizontal, index < 2 ? 8 : 9)
                .frame(minHeight: 28)
                .overlay(Capsule().stroke(Color.white.opacity(0.20), lineWidth: 0.7))
                .liquidGlassBackground(cornerRadius: 14, interactive: true, style: .clear)
            }
        }
        .frame(maxWidth: .infinity)
        .shadow(color: .black.opacity(0.20), radius: 5, y: 2)
    }
}

private struct DarkComposerCircleButton: View {
    let symbol: String
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: symbol == "plus" ? 27 : 25, weight: .medium))
                .foregroundStyle(.white.opacity(0.88))
                .frame(width: size, height: size)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .overlay(Circle().stroke(Color.white.opacity(0.24), lineWidth: 0.9))
        .shadow(color: .black.opacity(0.20), radius: 12, y: 6)
        .liquidGlassBackground(cornerRadius: size / 2, interactive: true, style: .clear)
    }
}

struct DoodlePattern: View {
    private let symbols = ["bicycle", "gamecontroller", "music.note", "cup.and.saucer", "camera", "sparkles", "heart", "paperplane"]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(Array(symbols.enumerated()), id: \.offset) { index, symbol in
                    Image(systemName: symbol)
                        .font(.system(size: CGFloat(20 + (index % 3) * 8), weight: .regular))
                        .foregroundStyle(.black.opacity(0.25))
                        .rotationEffect(.degrees(Double(index * 17 - 28)))
                        .position(
                            x: proxy.size.width * CGFloat(0.08 + Double((index * 23) % 82) / 100.0),
                            y: proxy.size.height * CGFloat(0.12 + Double((index * 31) % 72) / 100.0)
                        )
                }
            }
        }
    }
}

#Preview {
    ComposerView()
        .environmentObject(MessengerStore())
}
