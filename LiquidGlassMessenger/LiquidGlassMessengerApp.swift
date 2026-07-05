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
    private var openURLMatcher: ((URL) -> Bool)?
    private var universalLinkMatcher: ((NSUserActivity) -> Bool)?
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
        urls.forEach { _ = openURLHandler($0) }

        let universalLinks = pendingUniversalLinks
        pendingUniversalLinks.removeAll()
        universalLinks.forEach { _ = universalLinkHandler($0) }
    }

    @discardableResult
    func handleOpenURL(_ url: URL) -> Bool {
        guard openURLMatcher?(url) == true else { return false }
        guard let openURLHandler else {
            pendingURLs.append(url)
            return true
        }
        return openURLHandler(url)
    }

    @discardableResult
    func handleUniversalLink(_ userActivity: NSUserActivity) -> Bool {
        guard universalLinkMatcher?(userActivity) == true else { return false }
        guard let universalLinkHandler else {
            pendingUniversalLinks.append(userActivity)
            return true
        }
        return universalLinkHandler(userActivity)
    }

    func resetForTesting() {
        openURLHandler = nil
        universalLinkHandler = nil
        openURLMatcher = nil
        universalLinkMatcher = nil
        pendingURLs.removeAll()
        pendingUniversalLinks.removeAll()
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
