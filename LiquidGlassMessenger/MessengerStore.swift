import Foundation

@MainActor
final class MessengerStore: ObservableObject {
    @Published var tab: AppTab = .messages
    @Published var conversations: [Conversation] = DemoData.conversations
    @Published var selectedConversationID: Conversation.ID?
    @Published var composerText = ""
    @Published var searchText = ""
    @Published var isAppDrawerVisible = false
    @Published var bridgeConfig = WeChatBridgeConfig()
    @Published var connectionState: BridgeConnectionState = .ready
    @Published var capabilities: [WeChatCapability] = WeChatBridge.defaultCapabilities

    private let bridge = WeChatBridge()

    init() {
        selectedConversationID = conversations.first?.id
    }

    var selectedConversation: Conversation? {
        guard let selectedConversationID else { return conversations.first }
        return conversations.first { $0.id == selectedConversationID }
    }

    var filteredConversations: [Conversation] {
        let sorted = conversations.sorted {
            if $0.isPinned != $1.isPinned { return $0.isPinned && !$1.isPinned }
            return ($0.lastMessage?.sentAt ?? .distantPast) > ($1.lastMessage?.sentAt ?? .distantPast)
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return sorted }
        return sorted.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.subtitle.localizedCaseInsensitiveContains(query) ||
            $0.messages.contains { $0.text.localizedCaseInsensitiveContains(query) }
        }
    }

    func select(_ conversation: Conversation) {
        selectedConversationID = conversation.id
        guard let index = conversations.firstIndex(where: { $0.id == conversation.id }) else { return }
        conversations[index].unreadCount = 0
    }

    func sendCurrentDraft() {
        let body = composerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty, let selectedConversationID,
              let index = conversations.firstIndex(where: { $0.id == selectedConversationID }) else { return }

        conversations[index].messages.append(
            ChatMessage(
                id: UUID(),
                authorID: DemoData.currentUserID,
                sentAt: Date(),
                text: body,
                kind: .text,
                isOutgoing: true,
                status: bridgeConfig.mode == .demo ? "Delivered" : "Queued for official WeChat bridge",
                reactions: [],
                attachment: nil
            )
        )
        composerText = ""
        isAppDrawerVisible = false
    }

    func togglePin(_ conversation: Conversation) {
        guard let index = conversations.firstIndex(where: { $0.id == conversation.id }) else { return }
        conversations[index].isPinned.toggle()
    }

    func refreshFromWeChat() async {
        connectionState = .checking
        do {
            let result = try await bridge.refresh(config: bridgeConfig)
            capabilities = result.capabilities
            connectionState = .connected(Date())
        } catch {
            connectionState = .failed(error.localizedDescription)
        }
    }
}
