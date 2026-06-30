import CryptoKit
import Foundation

struct WeChatBridgeRefresh {
    var capabilities: [WeChatCapability]
}

private struct AccessTokenResponse: Decodable {
    var accessToken: String?
    var expiresIn: Int?
    var errcode: Int?
    var errmsg: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case errcode
        case errmsg
    }
}

private struct WeChatAPIResult: Decodable {
    var errcode: Int
    var errmsg: String
}

enum WeChatBridgeError: LocalizedError {
    case missingCredentials
    case missingOpenSDKConfiguration
    case invalidShareURL
    case openSDKUnavailable
    case unsupportedPrivateProtocol(String)
    case invalidURL
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .missingCredentials:
            "WeChat credentials are missing. Add official AppID and AppSecret in Settings."
        case .missingOpenSDKConfiguration:
            "WeChat OpenSDK needs an AppID and Universal Link before sharing."
        case .invalidShareURL:
            "The WeChat link card URL must be a valid http or https URL."
        case .openSDKUnavailable:
            "WeChat OpenSDK is not linked in this build. Add the official SDK to enable native sharing."
        case .unsupportedPrivateProtocol(let feature):
            "\(feature) is not exposed through public WeChat APIs."
        case .invalidURL:
            "The WeChat API URL could not be constructed."
        case .apiError(let message):
            message
        }
    }
}

actor WeChatBridge {
    static let defaultCapabilities: [WeChatCapability] = [
        .init(
            id: "open-sdk-link-share",
            name: "OpenSDK Link Share",
            detail: "Native WeChat link-card sharing through AppID, URL scheme, and Universal Links.",
            status: .requiresCredential
        ),
        .init(
            id: "oauth-login",
            name: "WeChat OAuth Login",
            detail: "Open Platform QR/OAuth flow after AppID and AppSecret are configured.",
            status: .requiresCredential
        ),
        .init(
            id: "official-account-message",
            name: "Official Account Messaging",
            detail: "Customer-service, template, and subscription-style flows allowed by official account APIs.",
            status: .requiresCredential
        ),
        .init(
            id: "wecom-contact",
            name: "WeCom Contacts and Messages",
            detail: "Enterprise contacts and app messages through WeCom tenant credentials.",
            status: .requiresCredential
        ),
        .init(
            id: "webhook",
            name: "Webhook Verification",
            detail: "SHA1 signature verification is implemented for callback handshakes.",
            status: .requiresCredential
        ),
        .init(
            id: "personal-chat-sync",
            name: "Personal WeChat Full Chat Sync",
            detail: "Private desktop/mobile WeChat protocols are intentionally not used.",
            status: .unsupportedPublicAPI
        ),
        .init(
            id: "moments-pay-miniapps",
            name: "Moments, Pay, Mini Programs",
            detail: "These require separate official products, approvals, and API contracts.",
            status: .unsupportedPublicAPI
        )
    ]

    func refresh(config: WeChatBridgeConfig) async throws -> WeChatBridgeRefresh {
        if config.mode == .demo {
            return WeChatBridgeRefresh(capabilities: Self.defaultCapabilities.map { item in
                var item = item
                if item.status == .requiresCredential {
                    item.status = .available
                    item.detail += " Demo mode is active."
                }
                return item
            })
        }

        guard config.isCredentialed else { throw WeChatBridgeError.missingCredentials }
        return WeChatBridgeRefresh(capabilities: Self.defaultCapabilities.map { item in
            var item = item
            if item.status == .requiresCredential {
                item.status = .available
            }
            if item.id == "open-sdk-link-share", !config.isOpenSDKConfigured {
                item.status = .requiresCredential
            }
            return item
        })
    }

    func oauthURL(config: WeChatBridgeConfig, redirectURI: String, state: String) throws -> URL {
        guard config.isCredentialed else { throw WeChatBridgeError.missingCredentials }
        var components = URLComponents(string: "https://open.weixin.qq.com/connect/qrconnect")!
        components.queryItems = [
            URLQueryItem(name: "appid", value: config.appID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "snsapi_login"),
            URLQueryItem(name: "state", value: state)
        ]
        return components.url!
    }

    func fetchOfficialAccountAccessToken(config: WeChatBridgeConfig) async throws -> String {
        guard config.isCredentialed else { throw WeChatBridgeError.missingCredentials }
        var components = URLComponents(string: "\(config.apiBaseURL)/cgi-bin/token")
        components?.queryItems = [
            URLQueryItem(name: "grant_type", value: "client_credential"),
            URLQueryItem(name: "appid", value: config.appID),
            URLQueryItem(name: "secret", value: config.appSecret)
        ]
        guard let url = components?.url else { throw WeChatBridgeError.invalidURL }
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(AccessTokenResponse.self, from: data)
        if let token = decoded.accessToken { return token }
        throw WeChatBridgeError.apiError(decoded.errmsg ?? "WeChat access_token request failed.")
    }

    func sendOfficialAccountText(openID: String, text: String, accessToken: String, config: WeChatBridgeConfig) async throws {
        var components = URLComponents(string: "\(config.apiBaseURL)/cgi-bin/message/custom/send")
        components?.queryItems = [URLQueryItem(name: "access_token", value: accessToken)]
        guard let url = components?.url else { throw WeChatBridgeError.invalidURL }

        let payload: [String: Any] = [
            "touser": openID,
            "msgtype": "text",
            "text": ["content": text]
        ]
        try await postJSON(payload, to: url)
    }

    func sendWeComText(corpID: String, corpSecret: String, agentID: Int, toUser: String, text: String) async throws {
        var config = WeChatBridgeConfig()
        config.appID = corpID
        config.appSecret = corpSecret
        config.apiBaseURL = "https://qyapi.weixin.qq.com"
        let accessToken = try await fetchOfficialAccountAccessToken(config: config)
        var components = URLComponents(string: "https://qyapi.weixin.qq.com/cgi-bin/message/send")
        components?.queryItems = [URLQueryItem(name: "access_token", value: accessToken)]
        guard let url = components?.url else { throw WeChatBridgeError.invalidURL }

        let payload: [String: Any] = [
            "touser": toUser,
            "msgtype": "text",
            "agentid": agentID,
            "text": ["content": text],
            "safe": 0
        ]
        try await postJSON(payload, to: url)
    }

    nonisolated func verifyWebhookSignature(token: String, timestamp: String, nonce: String, signature: String) -> Bool {
        let joined = [token, timestamp, nonce].sorted().joined()
        let digest = Insecure.SHA1.hash(data: Data(joined.utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return hex.caseInsensitiveCompare(signature) == .orderedSame
    }

    func sendPersonalMessage() throws {
        throw WeChatBridgeError.unsupportedPrivateProtocol("Personal message transport")
    }

    private func postJSON(_ payload: [String: Any], to url: URL) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])

        let (data, _) = try await URLSession.shared.data(for: request)
        let result = try JSONDecoder().decode(WeChatAPIResult.self, from: data)
        guard result.errcode == 0 else {
            throw WeChatBridgeError.apiError(result.errmsg)
        }
    }
}
