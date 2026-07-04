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
    @Published var shareState: BridgeConnectionState = .ready
    @Published var capabilities: [WeChatCapability] = WeChatBridge.defaultCapabilities

    private let bridge = WeChatBridge()
    private let openSDKBridge = WeChatOpenSDKBridge()
    private var lastWeChatCallback: (key: String, date: Date)?

    init() {
        selectedConversationID = conversations.first?.id
        openSDKBridge.onShareResponse = { [weak self] callback in
            self?.applyWeChatShareCallback(callback)
        }
        WeChatCallbackCenter.shared.configure(
            openURLHandler: { [weak self] url in
                self?.handleWeChatOpenURL(url) ?? false
            },
            universalLinkHandler: { [weak self] userActivity in
                self?.handleWeChatUniversalLink(userActivity) ?? false
            }
        )
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

    func shareOfficialLink(to target: WeChatShareTarget) {
        shareState = .checking
        lastWeChatCallback = nil
        do {
            try openSDKBridge.shareLink(config: bridgeConfig, target: target)
            shareState = .waitingForCallback(Date())
        } catch {
            shareState = .failed(error.localizedDescription)
        }
    }

    @discardableResult
    func handleWeChatOpenURL(_ url: URL) -> Bool {
        let key = "url:\(url.absoluteString)"
        guard shouldHandleWeChatCallback(key: key) else { return true }

        do {
            try openSDKBridge.handleOpenURL(url)
            return true
        } catch {
            shareState = .failed(error.localizedDescription)
            return false
        }
    }

    @discardableResult
    func handleWeChatUniversalLink(_ userActivity: NSUserActivity) -> Bool {
        let key = "universal:\(userActivity.webpageURL?.absoluteString ?? userActivity.activityType)"
        guard shouldHandleWeChatCallback(key: key) else { return true }

        do {
            try openSDKBridge.handleUniversalLink(userActivity)
            return true
        } catch {
            shareState = .failed(error.localizedDescription)
            return false
        }
    }

    private func applyWeChatShareCallback(_ callback: WeChatShareCallback) {
        switch callback.status {
        case .completed:
            shareState = .connected(Date())
        case .cancelled:
            shareState = .cancelled(callback.message)
        case .failed:
            shareState = .failed(callback.message)
        }
        lastWeChatCallback = nil
    }

    private func shouldHandleWeChatCallback(key: String) -> Bool {
        let now = Date()
        if let lastWeChatCallback,
           lastWeChatCallback.key == key,
           now.timeIntervalSince(lastWeChatCallback.date) < 2 {
            return false
        }
        lastWeChatCallback = (key, now)
        return true
    }
}
