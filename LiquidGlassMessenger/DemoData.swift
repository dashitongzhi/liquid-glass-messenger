import Foundation

enum DemoData {
    static let currentUserID = UUID(uuidString: "8F7EBA45-0C9B-4AA9-B4D7-4C70FBC6C12A")!

    private static let me = Participant(
        id: currentUserID,
        displayName: "Kral",
        handle: "me",
        monogram: "K",
        tintHex: "007AFF",
        presence: .online
    )

    private static let ada = Participant(
        id: UUID(uuidString: "1D6F5FA5-0D4C-4C1B-A43F-65454844E889")!,
        displayName: "Ada",
        handle: "@ada.design",
        monogram: "A",
        tintHex: "8E8EFF",
        presence: .online
    )

    private static let lin = Participant(
        id: UUID(uuidString: "26759A5C-F86D-4F00-B280-C65A2F99B96B")!,
        displayName: "Lin",
        handle: "WeChat: lin_product",
        monogram: "L",
        tintHex: "34C759",
        presence: .idle
    )

    static let conversations: [Conversation] = [
        Conversation(
            id: UUID(),
            title: "Liquid Glass Build",
            subtitle: "Pixel pass, WeChat bridge, native materials",
            participants: [me, ada, lin],
            messages: [
                ChatMessage(
                    id: UUID(),
                    authorID: ada.id,
                    sentAt: Date().addingTimeInterval(-3600),
                    text: "I matched the title spacing, avatar scale, and bubble rhythm to iMessage. The WeChat bridge should stay explicit.",
                    kind: .text,
                    isOutgoing: false,
                    status: "Read",
                    reactions: ["heart.fill"],
                    attachment: nil
                ),
                ChatMessage(
                    id: UUID(),
                    authorID: currentUserID,
                    sentAt: Date().addingTimeInterval(-3000),
                    text: "Use Apple-native SwiftUI, keep the tab bar WeChat-shaped, and make the thread pixel-tight.",
                    kind: .text,
                    isOutgoing: true,
                    status: "Delivered",
                    reactions: [],
                    attachment: nil
                ),
                ChatMessage(
                    id: UUID(),
                    authorID: lin.id,
                    sentAt: Date().addingTimeInterval(-1620),
                    text: "Add photos, camera, voice, location, stickers, files, and mini program entry points.",
                    kind: .miniProgram,
                    isOutgoing: false,
                    status: "Delivered",
                    reactions: [],
                    attachment: AttachmentPreview(
                        id: UUID(),
                        title: "WeChat Mini Program",
                        subtitle: "Preview card placeholder",
                        systemImage: "app.connected.to.app.below.fill",
                        tintHex: "34C759"
                    )
                )
            ],
            unreadCount: 2,
            isPinned: true,
            isMuted: false,
            weChatThreadID: "demo_thread_liquid_glass"
        ),
        Conversation(
            id: UUID(),
            title: "Family",
            subtitle: "Dinner photos and location share",
            participants: [
                me,
                Participant(id: UUID(), displayName: "Mom", handle: "WeChat: mom", monogram: "M", tintHex: "FF9F0A", presence: .online)
            ],
            messages: [
                ChatMessage(id: UUID(), authorID: currentUserID, sentAt: Date().addingTimeInterval(-7200), text: "Arriving at 7:20.", kind: .text, isOutgoing: true, status: "Delivered", reactions: [], attachment: nil),
                ChatMessage(id: UUID(), authorID: UUID(), sentAt: Date().addingTimeInterval(-7000), text: "Send location when you park.", kind: .location, isOutgoing: false, status: "Delivered", reactions: [], attachment: AttachmentPreview(id: UUID(), title: "Shared Location", subtitle: "Apple Park Visitor Center", systemImage: "location.fill", tintHex: "007AFF"))
            ],
            unreadCount: 0,
            isPinned: true,
            isMuted: false,
            weChatThreadID: "demo_thread_family"
        ),
        Conversation(
            id: UUID(),
            title: "Design References",
            subtitle: "iMessage clone + SwiftUI WeChat",
            participants: [me, ada],
            messages: [
                ChatMessage(id: UUID(), authorID: ada.id, sentAt: Date().addingTimeInterval(-92000), text: "Reference locally, but keep the implementation yours.", kind: .text, isOutgoing: false, status: "Read", reactions: [], attachment: nil)
            ],
            unreadCount: 0,
            isPinned: false,
            isMuted: true,
            weChatThreadID: nil
        ),
        Conversation(
            id: UUID(),
            title: "WeChat Official Account",
            subtitle: "OAuth, callback, template message",
            participants: [me, Participant(id: UUID(), displayName: "Service Bot", handle: "Official Account", monogram: "W", tintHex: "07C160", presence: .online)],
            messages: [
                ChatMessage(id: UUID(), authorID: UUID(), sentAt: Date().addingTimeInterval(-18000), text: "Configured webhook verification is ready. Add AppID and AppSecret to test official flows.", kind: .system, isOutgoing: false, status: "Pending", reactions: [], attachment: nil)
            ],
            unreadCount: 1,
            isPinned: false,
            isMuted: false,
            weChatThreadID: "official_account_demo"
        )
    ]
}
