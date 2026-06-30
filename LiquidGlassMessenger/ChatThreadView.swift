import SwiftUI

struct ChatThreadView: View {
    @EnvironmentObject private var store: MessengerStore
    @Environment(\.dismiss) private var dismiss
    let conversationID: Conversation.ID
    @State private var showDetails = false

    var conversation: Conversation {
        store.conversations.first { $0.id == conversationID } ?? store.conversations[0]
    }

    var otherParticipants: [Participant] {
        conversation.participants.filter { $0.id != DemoData.currentUserID }
    }

    var body: some View {
        ZStack(alignment: .top) {
            ThreadBackdrop()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 7) {
                        TimestampDivider(date: conversation.messages.first?.sentAt ?? Date())
                            .padding(.top, 92)

                        ForEach(Array(conversation.messages.enumerated()), id: \.element.id) { index, message in
                            MessageRow(
                                message: message,
                                previous: index > 0 ? conversation.messages[index - 1] : nil,
                                participant: participant(for: message)
                            )
                            .id(message.id)
                        }

                        TypingIndicator(participants: otherParticipants)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: conversation.messages.count) { _, _ in
                    if let last = conversation.messages.last?.id {
                        withAnimation(.snappy) {
                            proxy.scrollTo(last, anchor: .bottom)
                        }
                    }
                }
            }

            PreviewTopBar(
                conversation: conversation,
                participants: otherParticipants,
                onBack: { dismiss() },
                onMore: { showDetails = true }
            )
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ComposerView()
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showDetails) {
            NavigationStack {
                ConversationDetailsView(conversation: conversation)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showDetails = false }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            store.selectedConversationID = conversationID
            store.isAppDrawerVisible = false
            store.select(conversation)
        }
    }

    private func participant(for message: ChatMessage) -> Participant {
        conversation.participants.first { $0.id == message.authorID } ?? otherParticipants.first ?? conversation.participants[0]
    }
}

private struct PreviewTopBar: View {
    let conversation: Conversation
    let participants: [Participant]
    let onBack: () -> Void
    let onMore: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            HStack(alignment: .top, spacing: 0) {
                Button(action: onBack) {
                    HStack(spacing: 7) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 22, weight: .bold))
                        Text("36")
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 3.5)
                            .background(Color.white.opacity(0.92), in: Capsule())
                    }
                    .foregroundStyle(.white)
                    .frame(height: 44)
                    .padding(.leading, 9)
                    .padding(.trailing, 10)
                    .background(Color.white.opacity(0.18), in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.8))
                    .liquidGlassBackground(cornerRadius: 22, interactive: true)
                }
                .buttonStyle(.plain)
                .shadow(color: .black.opacity(0.28), radius: 14, y: 8)

                Spacer()

                Button(action: onMore) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white.opacity(0.86))
                        .frame(width: 44, height: 44)
                        .background(Color(red: 0.08, green: 0.16, blue: 0.24).opacity(0.62), in: Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.8))
                        .liquidGlassBackground(cornerRadius: 22, interactive: true)
                }
                .buttonStyle(.plain)
                .shadow(color: .black.opacity(0.25), radius: 14, y: 8)
            }
            .padding(.horizontal, 16)

            VStack(spacing: -3) {
                if let first = participants.first {
                    AvatarView(participant: first, size: 44)
                        .overlay(Circle().stroke(Color.white.opacity(0.45), lineWidth: 1))
                        .shadow(color: .black.opacity(0.30), radius: 16, y: 8)
                }

                Text(conversation.title)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.30))
                    .lineLimit(1)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.15), in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.8))
                    .liquidGlassBackground(cornerRadius: 17)
            }
            .frame(maxWidth: 210)
            .offset(y: 6)
        }
        .padding(.top, 8)
        .frame(maxWidth: .infinity)
        .frame(height: 92, alignment: .top)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.52), Color.black.opacity(0.18), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        )
    }
}

private struct TimestampDivider: View {
    let date: Date

    var body: some View {
        Text(ChatFormatters.shortTime.string(from: date))
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.white.opacity(0.52))
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
    }
}

private struct MessageRow: View {
    let message: ChatMessage
    let previous: ChatMessage?
    let participant: Participant
    @State private var isPressed = false

    var isGroupedWithPrevious: Bool {
        previous?.authorID == message.authorID
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            if message.isOutgoing { Spacer(minLength: 46) }

            if !message.isOutgoing {
                if isGroupedWithPrevious {
                    Color.clear.frame(width: 31, height: 1)
                } else {
                    AvatarView(participant: participant, size: 31)
                }
            }

            VStack(alignment: message.isOutgoing ? .trailing : .leading, spacing: 3) {
                if !message.isOutgoing && !isGroupedWithPrevious {
                    Text(participant.displayName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.58))
                        .padding(.leading, 9)
                }

                VStack(alignment: .leading, spacing: 8) {
                    if let attachment = message.attachment {
                        AttachmentCard(attachment: attachment)
                    }
                    Text(message.text)
                        .font(.system(size: 16.5))
                        .lineSpacing(1.5)
                }
                .foregroundStyle(message.isOutgoing ? Color.black.opacity(0.86) : Color.white.opacity(0.88))
                .padding(.horizontal, 13)
                .padding(.vertical, 9)
                .background(
                    BubbleShape(isOutgoing: message.isOutgoing)
                        .fill(message.isOutgoing ? LGDesign.previewGreen : LGDesign.previewIncoming)
                )
                .overlay(alignment: message.isOutgoing ? .topLeading : .topTrailing) {
                    if !message.reactions.isEmpty {
                        ReactionStack(symbols: message.reactions)
                            .offset(x: message.isOutgoing ? -14 : 14, y: -14)
                    }
                }
                .frame(maxWidth: 298, alignment: message.isOutgoing ? .trailing : .leading)
                .scaleEffect(isPressed ? 0.985 : 1)
                .contextMenu {
                    Button {
                    } label: {
                        Label("Reply", systemImage: "arrowshape.turn.up.left.fill")
                    }
                    Button {
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    Button {
                    } label: {
                        Label("React", systemImage: "heart.fill")
                    }
                }
                .onLongPressGesture(minimumDuration: 0.18, pressing: { pressing in
                    withAnimation(.smooth(duration: 0.12)) {
                        isPressed = pressing
                    }
                }, perform: {})

                if message.isOutgoing {
                    Text(message.status)
                        .font(.system(size: 10.5))
                        .foregroundStyle(.white.opacity(0.44))
                        .padding(.trailing, 8)
                }
            }

            if !message.isOutgoing { Spacer(minLength: 46) }
        }
        .padding(.top, isGroupedWithPrevious ? 0 : 7)
    }
}

private struct ReactionStack: View {
    let symbols: [String]

    var body: some View {
        HStack(spacing: 1) {
            ForEach(symbols, id: \.self) { symbol in
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.red)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.10), radius: 8, y: 3)
    }
}

private struct TypingIndicator: View {
    let participants: [Participant]

    var body: some View {
        HStack(alignment: .bottom, spacing: 7) {
            if let first = participants.first {
                AvatarView(participant: first, size: 31)
            }

            HStack(spacing: 4) {
                ForEach(0..<3) { dot in
                    Circle()
                        .fill(.white.opacity(0.58))
                        .frame(width: 5, height: 5)
                        .opacity(dot == 1 ? 0.52 : 0.34)
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 12)
            .background(LGDesign.previewIncoming, in: BubbleShape(isOutgoing: false))

            Spacer()
        }
    }
}

private struct ThreadBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.07, blue: 0.11),
                    Color(red: 0.03, green: 0.17, blue: 0.25),
                    Color(red: 0.01, green: 0.04, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            WavePattern()
                .stroke(Color.white.opacity(0.20), lineWidth: 1.1)
                .blur(radius: 0.6)
            WavePattern(phase: 0.38, amplitude: 18)
                .stroke(Color(red: 0.22, green: 0.70, blue: 0.86).opacity(0.18), lineWidth: 1.2)
                .blur(radius: 1.4)
            LinearGradient(
                colors: [
                    Color.black.opacity(0.12),
                    Color.black.opacity(0.06),
                    Color.black.opacity(0.40)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

private struct WavePattern: Shape {
    var phase: CGFloat = 0
    var amplitude: CGFloat = 13

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let rows = stride(from: rect.minY - 40, through: rect.maxY + 80, by: 34)
        for (index, y) in rows.enumerated() {
            let rowPhase = phase * rect.width + CGFloat(index % 5) * 17
            path.move(to: CGPoint(x: rect.minX - 24, y: y))
            var x = rect.minX - 24
            while x <= rect.maxX + 24 {
                let relative = (x + rowPhase) / 34
                let offset = sin(relative) * amplitude + sin(relative * 0.43) * (amplitude * 0.54)
                path.addLine(to: CGPoint(x: x, y: y + offset))
                x += 9
            }
        }
        return path
    }
}

private struct ConversationDetailsView: View {
    let conversation: Conversation

    var body: some View {
        List {
            Section {
                HStack(spacing: 14) {
                    ForEach(conversation.participants.prefix(4)) { participant in
                        VStack(spacing: 8) {
                            AvatarView(participant: participant, size: 54)
                            Text(participant.displayName)
                                .font(.system(size: 12))
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.vertical, 10)
            }

            Section("Actions") {
                Label("Search Conversation", systemImage: "magnifyingglass")
                Label("Shared Photos", systemImage: "photo.on.rectangle.angled")
                Label("Pinned Items", systemImage: "pin.fill")
                Label(conversation.weChatThreadID ?? "No WeChat Thread", systemImage: "link")
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ChatThreadView(conversationID: DemoData.conversations[0].id)
            .environmentObject(MessengerStore())
    }
}
