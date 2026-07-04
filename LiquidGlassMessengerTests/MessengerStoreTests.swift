import XCTest
@testable import LiquidGlassMessenger

@MainActor
final class MessengerStoreTests: XCTestCase {
    func testDuplicateOpenURLFromAppDelegateAndSwiftUIOnlyReachesOpenSDKOnce() {
        let url = URL(string: "wx123://pay?nonce=abc")!
        var currentDate = Date(timeIntervalSince1970: 1_000)
        let bridge = SpyOpenSDKBridge()
        let store = MessengerStore(openSDKBridge: bridge, now: { currentDate })

        XCTAssertTrue(WeChatCallbackCenter.shared.handleOpenURL(url))
        currentDate.addTimeInterval(0.25)
        XCTAssertTrue(store.handleWeChatOpenURL(url))

        XCTAssertEqual(bridge.handledOpenURLs, [url])
        XCTAssertTrue(store.shareState.isConnected)
    }

    func testDuplicateUniversalLinkFromAppDelegateAndSwiftUIOnlyReachesOpenSDKOnce() {
        let url = URL(string: "https://example.com/app/wechat/callback?nonce=abc")!
        var currentDate = Date(timeIntervalSince1970: 2_000)
        let bridge = SpyOpenSDKBridge()
        let store = MessengerStore(openSDKBridge: bridge, now: { currentDate })
        let userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        userActivity.webpageURL = url

        XCTAssertTrue(WeChatCallbackCenter.shared.handleUniversalLink(userActivity))
        currentDate.addTimeInterval(0.25)
        XCTAssertTrue(store.handleWeChatUniversalLink(userActivity))

        XCTAssertEqual(bridge.handledUniversalLinks, [url])
        XCTAssertTrue(store.shareState.isConnected)
    }
}

@MainActor
private final class SpyOpenSDKBridge: WeChatOpenSDKHandling {
    var onShareResponse: ((WeChatShareCallback) -> Void)?
    private(set) var handledOpenURLs: [URL] = []
    private(set) var handledUniversalLinks: [URL] = []

    func shareLink(config: WeChatBridgeConfig, target: WeChatShareTarget) throws {}

    func handleOpenURL(_ url: URL) throws -> Bool {
        handledOpenURLs.append(url)
        onShareResponse?(WeChatShareCallback(status: .completed, message: "OK"))
        return true
    }

    func handleUniversalLink(_ userActivity: NSUserActivity) throws -> Bool {
        if let url = userActivity.webpageURL {
            handledUniversalLinks.append(url)
        }
        onShareResponse?(WeChatShareCallback(status: .completed, message: "OK"))
        return true
    }
}

private extension BridgeConnectionState {
    var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }
}
