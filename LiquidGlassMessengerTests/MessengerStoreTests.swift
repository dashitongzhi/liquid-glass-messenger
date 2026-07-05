import XCTest
@testable import LiquidGlassMessenger

@MainActor
final class MessengerStoreTests: XCTestCase {
    func testDuplicateOpenURLFromAppDelegateAndSwiftUIOnlyReachesOpenSDKOnce() {
        resetCallbackCenter()

        let url = URL(string: "wx123://pay?nonce=abc")!
        var currentDate = Date(timeIntervalSince1970: 1_000)
        let bridge = SpyOpenSDKBridge()
        let store = makeStore(openSDKBridge: bridge, now: { currentDate })

        XCTAssertTrue(WeChatCallbackCenter.shared.handleOpenURL(url))
        currentDate.addTimeInterval(0.25)
        XCTAssertTrue(store.handleWeChatOpenURL(url))

        XCTAssertEqual(bridge.handledOpenURLs, [url])
        XCTAssertTrue(store.shareState.isConnected)
    }

    func testDuplicateUniversalLinkFromAppDelegateAndSwiftUIOnlyReachesOpenSDKOnce() {
        resetCallbackCenter()

        let url = URL(string: "https://example.com/app/wechat/callback?nonce=abc")!
        var currentDate = Date(timeIntervalSince1970: 2_000)
        let bridge = SpyOpenSDKBridge()
        let store = makeStore(openSDKBridge: bridge, now: { currentDate })
        let userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        userActivity.webpageURL = url

        XCTAssertTrue(WeChatCallbackCenter.shared.handleUniversalLink(userActivity))
        currentDate.addTimeInterval(0.25)
        XCTAssertTrue(store.handleWeChatUniversalLink(userActivity))

        XCTAssertEqual(bridge.handledUniversalLinks, [url])
        XCTAssertTrue(store.shareState.isConnected)
    }

    func testUnrelatedOpenURLIsNotClaimedOrForwardedToOpenSDK() {
        resetCallbackCenter()

        let bridge = SpyOpenSDKBridge()
        let store = makeStore(openSDKBridge: bridge)
        let url = URL(string: "liquidglass://conversation/123")!

        XCTAssertFalse(WeChatCallbackCenter.shared.handleOpenURL(url))
        XCTAssertFalse(store.handleWeChatOpenURL(url))

        XCTAssertTrue(bridge.handledOpenURLs.isEmpty)
        XCTAssertEqual(store.shareState, .ready)
    }

    func testDifferentWeChatURLSchemeIsNotClaimedOrForwardedToOpenSDK() {
        resetCallbackCenter()

        let bridge = SpyOpenSDKBridge()
        let store = makeStore(openSDKBridge: bridge)
        let url = URL(string: "wx999://pay?nonce=abc")!

        XCTAssertFalse(WeChatCallbackCenter.shared.handleOpenURL(url))
        XCTAssertFalse(store.handleWeChatOpenURL(url))

        XCTAssertTrue(bridge.handledOpenURLs.isEmpty)
        XCTAssertEqual(store.shareState, .ready)
    }

    func testUnrelatedUniversalLinkIsNotClaimedOrForwardedToOpenSDK() {
        resetCallbackCenter()

        let bridge = SpyOpenSDKBridge()
        let store = makeStore(openSDKBridge: bridge)
        let userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        userActivity.webpageURL = URL(string: "https://example.com/app/wechatty/callback?nonce=abc")!

        XCTAssertFalse(WeChatCallbackCenter.shared.handleUniversalLink(userActivity))
        XCTAssertFalse(store.handleWeChatUniversalLink(userActivity))

        XCTAssertTrue(bridge.handledUniversalLinks.isEmpty)
        XCTAssertEqual(store.shareState, .ready)
    }

    func testOpenSDKFalseReturnFailsOpenURLCallback() {
        resetCallbackCenter()

        let url = URL(string: "wx123://pay?nonce=abc")!
        let bridge = SpyOpenSDKBridge()
        bridge.openURLResult = false
        bridge.callback = nil
        let store = makeStore(openSDKBridge: bridge)

        XCTAssertFalse(store.handleWeChatOpenURL(url))

        XCTAssertEqual(bridge.handledOpenURLs, [url])
        XCTAssertEqual(store.shareState, .failed("WeChat OpenSDK did not handle the callback URL."))
    }

    func testOpenSDKFalseReturnFailsUniversalLinkCallback() {
        resetCallbackCenter()

        let bridge = SpyOpenSDKBridge()
        bridge.universalLinkResult = false
        bridge.callback = nil
        let store = makeStore(openSDKBridge: bridge)
        let userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        userActivity.webpageURL = URL(string: "https://example.com/app/wechat/callback?nonce=abc")!

        XCTAssertFalse(store.handleWeChatUniversalLink(userActivity))

        XCTAssertEqual(bridge.handledUniversalLinks, [userActivity.webpageURL!])
        XCTAssertEqual(store.shareState, .failed("WeChat OpenSDK did not handle the callback URL."))
    }

    func testCallbackCenterDoesNotQueueURLsBeforeWeChatMatcherIsConfigured() {
        resetCallbackCenter()

        let url = URL(string: "liquidglass://conversation/123")!

        XCTAssertFalse(WeChatCallbackCenter.shared.handleOpenURL(url))

        let bridge = SpyOpenSDKBridge()
        _ = makeStore(openSDKBridge: bridge)

        XCTAssertTrue(bridge.handledOpenURLs.isEmpty)
    }

    private func resetCallbackCenter() {
        WeChatCallbackCenter.shared.resetForTesting()
    }
}

@MainActor
private final class SpyOpenSDKBridge: WeChatOpenSDKHandling {
    var onShareResponse: ((WeChatShareCallback) -> Void)?
    var openURLResult = true
    var universalLinkResult = true
    var callback: WeChatShareCallback? = WeChatShareCallback(status: .completed, message: "OK")
    private(set) var handledOpenURLs: [URL] = []
    private(set) var handledUniversalLinks: [URL] = []

    func shareLink(config: WeChatBridgeConfig, target: WeChatShareTarget) throws {}

    func handleOpenURL(_ url: URL) throws -> Bool {
        handledOpenURLs.append(url)
        if let callback {
            onShareResponse?(callback)
        }
        return openURLResult
    }

    func handleUniversalLink(_ userActivity: NSUserActivity) throws -> Bool {
        if let url = userActivity.webpageURL {
            handledUniversalLinks.append(url)
        }
        if let callback {
            onShareResponse?(callback)
        }
        return universalLinkResult
    }
}

@MainActor
private func makeStore(
    openSDKBridge: SpyOpenSDKBridge,
    now: @escaping () -> Date = Date.init
) -> MessengerStore {
    let store = MessengerStore(openSDKBridge: openSDKBridge, now: now)
    store.bridgeConfig.appID = "wx123"
    store.bridgeConfig.universalLink = "https://example.com/app/wechat/"
    return store
}

private extension BridgeConnectionState {
    var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }
}
