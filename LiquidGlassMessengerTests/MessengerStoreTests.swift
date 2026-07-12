import XCTest
@testable import LiquidGlassMessenger

@MainActor
final class MessengerStoreTests: XCTestCase {
    func testLinkPreviewRejectsCustomSchemesThatOnlyStartWithHTTP() {
        var preview = WeChatLinkPreview()

        preview.webpageURL = "httpx://evil.example/path"
        XCTAssertFalse(preview.isValid)

        preview.webpageURL = "httpsomething://evil.example/path"
        XCTAssertFalse(preview.isValid)

        preview.webpageURL = "https://example.com/path"
        XCTAssertTrue(preview.isValid)
    }

    func testUniversalLinkMatcherRejectsCustomSchemesThatOnlyStartWithHTTP() {
        var config = makeBridgeConfig()
        config.universalLink = "httpx://example.com/app/wechat/"

        XCTAssertFalse(
            WeChatCallbackMatcher.isExpectedWeChatUniversalLink(
                URL(string: "httpx://example.com/app/wechat/callback")!,
                config: config
            )
        )
    }

    func testWeComAccessTokenURLUsesCorporateParameters() throws {
        let url = try WeChatAPIEndpoint.weComAccessTokenURL(
            corpID: "ww123",
            corpSecret: "corporate-secret"
        )
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value) })

        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "qyapi.weixin.qq.com")
        XCTAssertEqual(components.path, "/cgi-bin/gettoken")
        XCTAssertEqual(query["corpid"], "ww123")
        XCTAssertEqual(query["corpsecret"], "corporate-secret")
        XCTAssertNil(query["appid"])
        XCTAssertNil(query["secret"])
    }

    func testPublicBridgeConfigurationSurvivesNewStoreWithoutPersistingSecrets() {
        resetCallbackCenter()

        let storage = InMemoryWeChatBridgeConfigurationStore()
        let firstStore = MessengerStore(openSDKBridge: SpyOpenSDKBridge(), configurationStore: storage)
        var config = makeBridgeConfig()
        config.mode = .openPlatform
        config.appSecret = "session-only-secret"
        config.token = "session-only-token"
        config.encodingAESKey = "session-only-aes-key"
        config.webhookURL = "https://example.com/webhook"
        config.linkPreview.title = "Persisted title"
        firstStore.bridgeConfig = config

        let restoredStore = MessengerStore(openSDKBridge: SpyOpenSDKBridge(), configurationStore: storage)

        XCTAssertEqual(restoredStore.bridgeConfig.mode, .openPlatform)
        XCTAssertEqual(restoredStore.bridgeConfig.appID, config.appID)
        XCTAssertEqual(restoredStore.bridgeConfig.universalLink, config.universalLink)
        XCTAssertEqual(restoredStore.bridgeConfig.webhookURL, config.webhookURL)
        XCTAssertEqual(restoredStore.bridgeConfig.linkPreview, config.linkPreview)
        XCTAssertEqual(restoredStore.bridgeConfig.appSecret, "")
        XCTAssertEqual(restoredStore.bridgeConfig.token, "")
        XCTAssertEqual(restoredStore.bridgeConfig.encodingAESKey, "")
    }

    func testDefaultUniversalLinkMatcherUsesPersistedConfigurationBeforeStoreExists() {
        let storage = InMemoryWeChatBridgeConfigurationStore()
        var config = makeBridgeConfig()
        config.universalLink = "https://callback.example.com/wechat/"
        storage.save(WeChatBridgePersistentConfiguration(config: config))

        let userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        userActivity.webpageURL = URL(string: "https://callback.example.com/wechat/result?state=abc")!

        XCTAssertTrue(
            WeChatCallbackMatcher.isDefaultWeChatUniversalLink(
                userActivity,
                configurationStore: storage
            )
        )
    }

    func testProductionBridgeValidationDoesNotClaimConnectedWithoutVerification() async {
        resetCallbackCenter()

        var config = makeBridgeConfig()
        config.mode = .officialAccount
        config.appSecret = "session-only-secret"
        let store = makeStore(openSDKBridge: SpyOpenSDKBridge(), bridgeConfig: config)

        await store.refreshFromWeChat()

        guard case .configured = store.connectionState else {
            return XCTFail("Expected configuration validation state, got \(store.connectionState)")
        }
    }

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

    func testCallbackCenterDeliversOpenURLReceivedBeforeMessengerStoreIsConfigured() {
        let bridgeConfig = makeBridgeConfig()
        resetCallbackCenter(openURLMatcher: { url in
            WeChatCallbackMatcher.isExpectedWeChatOpenURL(url, config: bridgeConfig)
        })

        let url = URL(string: "wx123://pay?nonce=abc")!

        XCTAssertTrue(WeChatCallbackCenter.shared.handleOpenURL(url))

        let bridge = SpyOpenSDKBridge()
        let store = makeStore(openSDKBridge: bridge, bridgeConfig: bridgeConfig)

        XCTAssertEqual(bridge.handledOpenURLs, [url])
        XCTAssertTrue(store.shareState.isConnected)
    }

    func testCallbackCenterDeliversUniversalLinkReceivedBeforeMessengerStoreIsConfigured() {
        let bridgeConfig = makeBridgeConfig()
        resetCallbackCenter(universalLinkMatcher: { userActivity in
            WeChatCallbackMatcher.isExpectedWeChatUniversalLink(userActivity, config: bridgeConfig)
        })

        let url = URL(string: "https://example.com/app/wechat/callback?nonce=abc")!
        let userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        userActivity.webpageURL = url

        XCTAssertTrue(WeChatCallbackCenter.shared.handleUniversalLink(userActivity))

        let bridge = SpyOpenSDKBridge()
        let store = makeStore(openSDKBridge: bridge)

        XCTAssertEqual(bridge.handledUniversalLinks, [url])
        XCTAssertTrue(store.shareState.isConnected)
    }

    func testCallbackCenterDoesNotClaimUnrelatedOpenURLBeforeMessengerStoreIsConfigured() {
        resetCallbackCenter()

        let url = URL(string: "liquidglass://conversation/123")!

        XCTAssertFalse(WeChatCallbackCenter.shared.handleOpenURL(url))

        let bridge = SpyOpenSDKBridge()
        _ = makeStore(openSDKBridge: bridge)

        XCTAssertTrue(bridge.handledOpenURLs.isEmpty)
    }

    func testCallbackCenterDoesNotClaimUnrelatedUniversalLinkBeforeMessengerStoreIsConfigured() {
        resetCallbackCenter()

        let userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        userActivity.webpageURL = URL(string: "https://example.com/app/wechatty/callback?nonce=abc")!

        XCTAssertFalse(WeChatCallbackCenter.shared.handleUniversalLink(userActivity))

        let bridge = SpyOpenSDKBridge()
        _ = makeStore(openSDKBridge: bridge)

        XCTAssertTrue(bridge.handledUniversalLinks.isEmpty)
    }

    private func resetCallbackCenter(
        openURLMatcher: ((URL) -> Bool)? = WeChatCallbackMatcher.isRegisteredWeChatOpenURL,
        universalLinkMatcher: ((NSUserActivity) -> Bool)? = WeChatCallbackMatcher.isDefaultWeChatUniversalLink
    ) {
        WeChatCallbackCenter.shared.resetForTesting(
            openURLMatcher: openURLMatcher,
            universalLinkMatcher: universalLinkMatcher
        )
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

private final class InMemoryWeChatBridgeConfigurationStore: WeChatBridgeConfigurationStoring {
    var configuration: WeChatBridgePersistentConfiguration?

    func load() -> WeChatBridgePersistentConfiguration? {
        configuration
    }

    func save(_ configuration: WeChatBridgePersistentConfiguration) {
        self.configuration = configuration
    }
}

@MainActor
private func makeStore(
    openSDKBridge: SpyOpenSDKBridge,
    bridgeConfig: WeChatBridgeConfig = makeBridgeConfig(),
    now: @escaping () -> Date = Date.init
) -> MessengerStore {
    MessengerStore(openSDKBridge: openSDKBridge, bridgeConfig: bridgeConfig, now: now)
}

private func makeBridgeConfig() -> WeChatBridgeConfig {
    var bridgeConfig = WeChatBridgeConfig()
    bridgeConfig.appID = "wx123"
    bridgeConfig.universalLink = "https://example.com/app/wechat/"
    return bridgeConfig
}

private extension BridgeConnectionState {
    var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }
}
