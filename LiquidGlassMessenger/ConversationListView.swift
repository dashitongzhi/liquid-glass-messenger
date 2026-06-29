import SwiftUI

struct ConversationListView: View {
    @EnvironmentObject private var store: MessengerStore
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.filteredConversations) { conversation in
                    NavigationLink {
                        ChatThreadView(conversationID: conversation.id)
                            .toolbar(.hidden, for: .tabBar)
                    } label: {
                        ConversationRow(conversation: conversation)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            store.togglePin(conversation)
                        } label: {
                            Label(conversation.isPinned ? "Unpin" : "Pin", systemImage: "pin.fill")
                        }
                        .tint(.yellow)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $store.searchText, placement: .navigationBarDrawer(displayMode: .automatic))
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Edit") { }
                        .foregroundStyle(LGDesign.sentBlue)
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }

                    Button { } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") { showSettings = false }
                            }
                        }
                }
            }
        }
    }
}

private struct ConversationRow: View {
    let conversation: Conversation

    var leadingParticipant: Participant {
        conversation.participants.first { $0.id != DemoData.currentUserID } ?? conversation.participants[0]
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                AvatarView(participant: leadingParticipant, size: LGDesign.avatar)
                if conversation.unreadCount > 0 {
                    Text("\(conversation.unreadCount)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(minWidth: 18, minHeight: 18)
                        .padding(.horizontal, 2)
                        .background(.red, in: Capsule())
                        .offset(x: 4, y: -5)
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    HStack(spacing: 5) {
                        if conversation.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                        Text(conversation.title)
                            .font(.system(size: 16.5, weight: .regular))
                            .lineLimit(1)
                    }

                    Spacer()

                    if let sentAt = conversation.lastMessage?.sentAt {
                        Text(ChatFormatters.relative.localizedString(for: sentAt, relativeTo: Date()))
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }

                HStack(spacing: 5) {
                    if conversation.isMuted {
                        Image(systemName: "bell.slash.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Text(conversation.lastMessage?.text ?? conversation.subtitle)
                        .font(.system(size: 14.5))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 7)
        .contentShape(Rectangle())
    }
}

#Preview {
    ConversationListView()
        .environmentObject(MessengerStore())
}
