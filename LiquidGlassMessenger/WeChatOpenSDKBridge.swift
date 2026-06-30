import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(WechatOpenSDK)
import WechatOpenSDK
#endif

@MainActor
final class WeChatOpenSDKBridge {
    func registerIfAvailable(config: WeChatBridgeConfig) throws {
        guard config.isOpenSDKConfigured else {
            throw WeChatBridgeError.missingOpenSDKConfiguration
        }

        #if canImport(WechatOpenSDK)
        WXApi.registerApp(config.appID, universalLink: config.universalLink)
        #else
        throw WeChatBridgeError.openSDKUnavailable
        #endif
    }

    func shareLink(config: WeChatBridgeConfig, target: WeChatShareTarget) throws {
        guard config.isOpenSDKConfigured else {
            throw WeChatBridgeError.missingOpenSDKConfiguration
        }
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
        WXApi.send(request)
        #else
        _ = webpageURL
        throw WeChatBridgeError.openSDKUnavailable
        #endif
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

private extension WeChatShareTarget {
    var wxScene: Int {
        switch self {
        case .session: 0
        case .timeline: 1
        case .favorite: 2
        }
    }
}
