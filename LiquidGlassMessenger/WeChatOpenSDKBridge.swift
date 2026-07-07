import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(WechatOpenSDK)
import WechatOpenSDK
#endif

@MainActor
final class WeChatOpenSDKBridge: NSObject, WeChatOpenSDKHandling {
    var onShareResponse: ((WeChatShareCallback) -> Void)?

    func registerIfAvailable(config: WeChatBridgeConfig) throws {
        try validateConfiguration(config)

        #if canImport(WechatOpenSDK)
        WXApi.registerApp(config.appID, universalLink: config.universalLink)
        #else
        throw WeChatBridgeError.openSDKUnavailable
        #endif
    }

    func shareLink(config: WeChatBridgeConfig, target: WeChatShareTarget) throws {
        try validateConfiguration(config)
        guard config.linkPreview.isValid,
              let webpageURL = URL(string: config.linkPreview.webpageURL.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw WeChatBridgeError.invalidShareURL
        }

        #if canImport(WechatOpenSDK)
        WXApi.registerApp(config.appID, universalLink: config.universalLink)

        let object = WXWebpageObject()
        object.webpageUrl = webpageURL.absoluteString

        let message = WXMediaMessage()
        message.title = config.linkPreview.title
        message.description = config.linkPreview.summary
        message.mediaObject = object
        if let thumbData = thumbnailData(named: config.linkPreview.thumbnailAssetName) {
            message.thumbData = thumbData
        }

        let request = SendMessageToWXReq()
        request.bText = false
        request.message = message
        request.scene = Int32(target.wxScene)
        guard WXApi.send(request) else {
            throw WeChatBridgeError.shareRequestRejected
        }
        #else
        _ = webpageURL
        throw WeChatBridgeError.openSDKUnavailable
        #endif
    }

    @discardableResult
    func handleOpenURL(_ url: URL) throws -> Bool {
        #if canImport(WechatOpenSDK)
        let handled = WXApi.handleOpen(url, delegate: self)
        guard handled else { throw WeChatBridgeError.callbackNotHandled }
        return handled
        #else
        _ = url
        throw WeChatBridgeError.openSDKUnavailable
        #endif
    }

    @discardableResult
    func handleUniversalLink(_ userActivity: NSUserActivity) throws -> Bool {
        #if canImport(WechatOpenSDK)
        let handled = WXApi.handleOpenUniversalLink(userActivity, delegate: self)
        guard handled else { throw WeChatBridgeError.callbackNotHandled }
        return handled
        #else
        _ = userActivity
        throw WeChatBridgeError.openSDKUnavailable
        #endif
    }

    private func validateConfiguration(_ config: WeChatBridgeConfig) throws {
        guard config.mode != .demo else {
            throw WeChatBridgeError.demoOpenSDKShareBlocked
        }
        guard config.isOpenSDKConfigured else {
            throw WeChatBridgeError.missingOpenSDKConfiguration
        }

        let schemes = Bundle.main.weChatURLSchemes
        if schemes.contains(WeChatURLScheme.placeholder) {
            throw WeChatBridgeError.placeholderURLScheme(WeChatURLScheme.placeholder)
        }

        let expectedScheme = config.appID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard schemes.contains(expectedScheme) else {
            throw WeChatBridgeError.missingConfiguredURLScheme(expectedScheme)
        }
    }

    private func thumbnailData(named assetName: String) -> Data? {
        let trimmed = assetName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        #if canImport(UIKit)
        guard let image = UIImage(named: trimmed) else { return nil }
        let fitted = image.preparingThumbnail(of: CGSize(width: 120, height: 120)) ?? image
        return fitted.jpegData(compressionQuality: 0.82)
        #else
        return nil
        #endif
    }
}

struct WeChatShareCallback: Equatable {
    enum Status: Equatable {
        case completed
        case cancelled
        case failed
    }

    var status: Status
    var message: String
}

private extension WeChatShareTarget {
    var wxScene: Int {
        switch self {
        case .session: 0
        case .timeline: 1
        case .favorite: 2
        }
    }
}

private enum WeChatURLScheme {
    static let placeholder = "wxReplaceWithOpenPlatformAppID"
}

private extension Bundle {
    var weChatURLSchemes: Set<String> {
        guard let urlTypes = object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] else {
            return []
        }

        let schemes = urlTypes.flatMap { item -> [String] in
            guard let values = item["CFBundleURLSchemes"] as? [String] else { return [] }
            return values
        }
        return Set(schemes)
    }
}

#if canImport(WechatOpenSDK)
extension WeChatOpenSDKBridge: WXApiDelegate {
    func onReq(_ req: BaseReq) {}

    func onResp(_ resp: BaseResp) {
        guard resp is SendMessageToWXResp else { return }

        let message = resp.errStr?.isEmpty == false ? resp.errStr! : Self.message(for: resp.errCode)
        switch resp.errCode {
        case 0:
            onShareResponse?(WeChatShareCallback(status: .completed, message: message))
        case -2:
            onShareResponse?(WeChatShareCallback(status: .cancelled, message: message))
        default:
            onShareResponse?(WeChatShareCallback(status: .failed, message: message))
        }
    }

    private static func message(for errCode: Int32) -> String {
        switch errCode {
        case 0:
            "WeChat confirmed the share."
        case -1:
            "WeChat reported a common OpenSDK error."
        case -2:
            "WeChat share was cancelled."
        case -3:
            "WeChat failed to send the share."
        case -4:
            "WeChat authorization was denied."
        case -5:
            "WeChat does not support this request."
        default:
            "WeChat returned OpenSDK error \(errCode)."
        }
    }
}
#endif
