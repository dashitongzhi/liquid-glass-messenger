import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@main
struct LiquidGlassMessengerApp: App {
    #if canImport(UIKit)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

    @StateObject private var store = MessengerStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onOpenURL { url in
                    store.handleWeChatOpenURL(url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    store.handleWeChatUniversalLink(userActivity)
                }
        }
    }
}

@MainActor
final class WeChatCallbackCenter {
    static let shared = WeChatCallbackCenter()

    private var openURLHandler: ((URL) -> Bool)?
    private var universalLinkHandler: ((NSUserActivity) -> Bool)?
    private var openURLMatcher: ((URL) -> Bool)? = WeChatCallbackMatcher.isRegisteredWeChatOpenURL
    private var universalLinkMatcher: ((NSUserActivity) -> Bool)? = WeChatCallbackMatcher.isDefaultWeChatUniversalLink
    private var pendingURLs: [URL] = []
    private var pendingUniversalLinks: [NSUserActivity] = []

    func configure(
        openURLMatcher: @escaping (URL) -> Bool,
        universalLinkMatcher: @escaping (NSUserActivity) -> Bool,
        openURLHandler: @escaping (URL) -> Bool,
        universalLinkHandler: @escaping (NSUserActivity) -> Bool
    ) {
        self.openURLMatcher = openURLMatcher
        self.universalLinkMatcher = universalLinkMatcher
        self.openURLHandler = openURLHandler
        self.universalLinkHandler = universalLinkHandler

        let urls = pendingURLs
        pendingURLs.removeAll()
        urls.forEach { _ = handleOpenURL($0) }

        let universalLinks = pendingUniversalLinks
        pendingUniversalLinks.removeAll()
        universalLinks.forEach { _ = handleUniversalLink($0) }
    }

    @discardableResult
    func handleOpenURL(_ url: URL) -> Bool {
        guard let openURLMatcher else {
            pendingURLs.append(url)
            return true
        }
        guard openURLMatcher(url) else { return false }
        guard let openURLHandler else {
            pendingURLs.append(url)
            return true
        }
        return openURLHandler(url)
    }

    @discardableResult
    func handleUniversalLink(_ userActivity: NSUserActivity) -> Bool {
        guard let universalLinkMatcher else {
            pendingUniversalLinks.append(userActivity)
            return true
        }
        guard universalLinkMatcher(userActivity) else { return false }
        guard let universalLinkHandler else {
            pendingUniversalLinks.append(userActivity)
            return true
        }
        return universalLinkHandler(userActivity)
    }

    func resetForTesting(
        openURLMatcher: ((URL) -> Bool)? = WeChatCallbackMatcher.isRegisteredWeChatOpenURL,
        universalLinkMatcher: ((NSUserActivity) -> Bool)? = WeChatCallbackMatcher.isDefaultWeChatUniversalLink
    ) {
        openURLHandler = nil
        universalLinkHandler = nil
        self.openURLMatcher = openURLMatcher
        self.universalLinkMatcher = universalLinkMatcher
        pendingURLs.removeAll()
        pendingUniversalLinks.removeAll()
    }
}

enum WeChatCallbackMatcher {
    static func isRegisteredWeChatOpenURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme else { return false }
        return registeredWeChatURLSchemes.contains { $0.caseInsensitiveCompare(scheme) == .orderedSame }
    }

    static func isDefaultWeChatUniversalLink(_ userActivity: NSUserActivity) -> Bool {
        isExpectedWeChatUniversalLink(userActivity, config: WeChatBridgeConfig())
    }

    static func isExpectedWeChatOpenURL(_ url: URL, config: WeChatBridgeConfig) -> Bool {
        let expectedScheme = config.appID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !expectedScheme.isEmpty, let scheme = url.scheme else { return false }
        return scheme.caseInsensitiveCompare(expectedScheme) == .orderedSame
    }

    static func isExpectedWeChatUniversalLink(_ userActivity: NSUserActivity, config: WeChatBridgeConfig) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let webpageURL = userActivity.webpageURL else {
            return false
        }
        return isExpectedWeChatUniversalLink(webpageURL, config: config)
    }

    static func isExpectedWeChatUniversalLink(_ url: URL, config: WeChatBridgeConfig) -> Bool {
        let universalLink = config.universalLink.trimmingCharacters(in: .whitespacesAndNewlines)
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

    private static var registeredWeChatURLSchemes: [String] {
        guard let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] else {
            return []
        }

        return urlTypes.flatMap { item -> [String] in
            guard (item["CFBundleURLName"] as? String) == "wechat",
                  let values = item["CFBundleURLSchemes"] as? [String] else {
                return []
            }
            return values.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        }
    }

    private static func normalizedHTTPPort(_ url: URL) -> Int? {
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

#if canImport(UIKit)
@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        WeChatCallbackCenter.shared.handleOpenURL(url)
    }

    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb else {
            return false
        }
        return WeChatCallbackCenter.shared.handleUniversalLink(userActivity)
    }
}
#endif
