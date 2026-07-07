import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case messages
    case contacts
    case discover
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .messages: "Messages"
        case .contacts: "Contacts"
        case .discover: "Discover"
        case .profile: "Me"
        }
    }

    var symbol: String {
        switch self {
        case .messages: "message.fill"
        case .contacts: "person.2.fill"
        case .discover: "safari.fill"
        case .profile: "person.crop.circle.fill"
        }
    }
}

enum Presence: String, Codable, CaseIterable {
    case online
    case idle
    case offline
}

enum MessageKind: String, Codable, CaseIterable {
    case text
    case image
    case voice
    case location
    case transfer
    case miniProgram
    case system
}

struct Participant: Identifiable, Hashable, Codable {
    let id: UUID
    var displayName: String
    var handle: String
    var monogram: String
    var tintHex: String
    var presence: Presence
}

struct AttachmentPreview: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var subtitle: String
    var systemImage: String
    var tintHex: String
}

struct ChatMessage: Identifiable, Hashable, Codable {
    let id: UUID
    var authorID: UUID
    var sentAt: Date
    var text: String
    var kind: MessageKind
    var isOutgoing: Bool
    var status: String
    var reactions: [String]
    var attachment: AttachmentPreview?
}

struct Conversation: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var subtitle: String
    var participants: [Participant]
    var messages: [ChatMessage]
    var unreadCount: Int
    var isPinned: Bool
    var isMuted: Bool
    var weChatThreadID: String?

    var lastMessage: ChatMessage? {
        messages.sorted { $0.sentAt < $1.sentAt }.last
    }
}

enum WeChatMode: String, CaseIterable, Identifiable, Codable {
    case demo = "Demo Sandbox"
    case officialAccount = "Official Account"
    case weCom = "WeCom"
    case openPlatform = "Open Platform"

    var id: String { rawValue }
}

enum WeChatCapabilityStatus: String, Codable {
    case available
    case requiresCredential
    case unsupportedPublicAPI
}

enum WeChatShareTarget: String, CaseIterable, Identifiable, Codable {
    case session
    case timeline
    case favorite

    var id: String { rawValue }

    var title: String {
        switch self {
        case .session: "WeChat Chat"
        case .timeline: "Moments"
        case .favorite: "Favorites"
        }
    }

    var systemImage: String {
        switch self {
        case .session: "message.fill"
        case .timeline: "circle.grid.2x2.fill"
        case .favorite: "star.fill"
        }
    }
}

struct WeChatCapability: Identifiable, Hashable, Codable {
    let id: String
    var name: String
    var detail: String
    var status: WeChatCapabilityStatus
}

struct WeChatLinkPreview: Hashable, Codable {
    var title: String = "Liquid Glass Messenger"
    var summary: String = "A native SwiftUI chat experience with an official WeChat bridge."
    var webpageURL: String = "https://github.com/dashitongzhi/liquid-glass-messenger"
    var thumbnailAssetName: String = ""

    var isValid: Bool {
        guard let url = URL(string: webpageURL.trimmingCharacters(in: .whitespacesAndNewlines)) else { return false }
        return url.scheme?.hasPrefix("http") == true && url.host != nil
    }
}

struct WeChatBridgeConfig: Codable, Hashable {
    var mode: WeChatMode = .demo
    var appID: String = ""
    var appSecret: String = ""
    var token: String = ""
    var encodingAESKey: String = ""
    var webhookURL: String = "https://example.com/wechat/webhook"
    var apiBaseURL: String = "https://api.weixin.qq.com"
    var universalLink: String = "https://example.com/app/wechat/"
    var linkPreview = WeChatLinkPreview()

    var isCredentialed: Bool {
        !appID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !appSecret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isOpenSDKConfigured: Bool {
        let appID = appID.trimmingCharacters(in: .whitespacesAndNewlines)
        let universalLink = universalLink.trimmingCharacters(in: .whitespacesAndNewlines)
        return !appID.isEmpty && URL(string: universalLink)?.scheme?.hasPrefix("http") == true
    }
}

enum BridgeConnectionState: Equatable {
    case ready
    case checking
    case waitingForCallback(Date)
    case connected(Date)
    case cancelled(String)
    case failed(String)
}
