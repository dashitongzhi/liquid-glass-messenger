import Combine
import Foundation

@MainActor
protocol WeChatOpenSDKHandling: AnyObject {
    var onShareResponse: ((WeChatShareCallback) -> Void)? { get set }

    func shareLink(config: WeChatBridgeConfig, target: WeChatShareTarget) throws
    func handleOpenURL(_ url: URL) throws -> Bool
    func handleUniversalLink(_ userActivity: NSUserActivity) throws -> Bool
}

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
    private let openSDKBridge: WeChatOpenSDKHandling
    private let now: () -> Date
    private var lastWeChatCallback: (key: String, date: Date)?

    init(
        openSDKBridge: WeChatOpenSDKHandling? = nil,
        now: @escaping () -> Date = Date.init
    ) {
        self.openSDKBridge = openSDKBridge ?? WeChatOpenSDKBridge()
        self.now = now
        selectedConversationID = conversations.first?.id
        self.openSDKBridge.onShareResponse = { [weak self] callback in
            self?.applyWeChatShareCallback(callback)
        }
        WeChatCallbackCenter.shared.configure(
            openURLMatcher: { [weak self] url in
                self?.isExpectedWeChatOpenURL(url) ?? false
            },
            universalLinkMatcher: { [weak self] userActivity in
                self?.isExpectedWeChatUniversalLink(userActivity) ?? false
            },
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
        guard isExpectedWeChatOpenURL(url) else { return false }

        let key = "url:\(url.absoluteString)"
        guard shouldHandleWeChatCallback(key: key) else { return true }

        do {
            let handled = try openSDKBridge.handleOpenURL(url)
            guard handled else {
                shareState = .failed(WeChatBridgeError.callbackNotHandled.localizedDescription)
                return false
            }
            return handled
        } catch {
            shareState = .failed(error.localizedDescription)
            return false
        }
    }

    @discardableResult
    func handleWeChatUniversalLink(_ userActivity: NSUserActivity) -> Bool {
        guard isExpectedWeChatUniversalLink(userActivity) else { return false }

        let key = "universal:\(userActivity.webpageURL?.absoluteString ?? userActivity.activityType)"
        guard shouldHandleWeChatCallback(key: key) else { return true }

        do {
            let handled = try openSDKBridge.handleUniversalLink(userActivity)
            guard handled else {
                shareState = .failed(WeChatBridgeError.callbackNotHandled.localizedDescription)
                return false
            }
            return handled
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
    }

    private func shouldHandleWeChatCallback(key: String) -> Bool {
        let now = now()
        if let lastWeChatCallback,
           lastWeChatCallback.key == key,
           now.timeIntervalSince(lastWeChatCallback.date) < 2 {
            return false
        }
        lastWeChatCallback = (key, now)
        return true
    }

    private func isExpectedWeChatOpenURL(_ url: URL) -> Bool {
        let expectedScheme = bridgeConfig.appID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !expectedScheme.isEmpty, let scheme = url.scheme else { return false }
        return scheme.caseInsensitiveCompare(expectedScheme) == .orderedSame
    }

    private func isExpectedWeChatUniversalLink(_ userActivity: NSUserActivity) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let webpageURL = userActivity.webpageURL else {
            return false
        }
        return isExpectedWeChatUniversalLink(webpageURL)
    }

    private func isExpectedWeChatUniversalLink(_ url: URL) -> Bool {
        let universalLink = bridgeConfig.universalLink.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let expectedURL = URL(string: universalLink),
              let expectedScheme = expectedURL.scheme?.lowercased(),
              expectedScheme.hasPrefix("http"),
              let actualScheme = url.scheme?.lowercased(),
              actualScheme == expectedScheme,
              let expectedHost = expectedURL.host,
              let actualHost = url.host,
              expectedHost.caseInsensitiveCompare(actualHost) == .orderedSame,
              normalizedHTTPPort(expectedURL) == normalizedHTTPPort(url) else {
            return false
        }

        let expectedPath = expectedURL.path
        guard !expectedPath.isEmpty, expectedPath != "/" else { return true }

        let pathPrefix = expectedPath.hasSuffix("/") ? expectedPath : "\(expectedPath)/"
        return url.path == expectedPath || url.path.hasPrefix(pathPrefix)
    }

    private func normalizedHTTPPort(_ url: URL) -> Int? {
        if let port = url.port { return port }

        switch url.scheme?.lowercased() {
        case "http":
            return 80
        case "https":
            return 443
        default:
            return nil
        }
    }
}
