import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: MessengerStore

    var body: some View {
        Form {
            Section("Connection") {
                Picker("Mode", selection: $store.bridgeConfig.mode) {
                    ForEach(WeChatMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }

                LabeledContent("State") {
                    connectionStateLabel
                }

                Button {
                    Task { await store.refreshFromWeChat() }
                } label: {
                    Label("Validate Configuration", systemImage: "checkmark.shield")
                }
            }

            Section("Official Credentials") {
                TextField("AppID", text: $store.bridgeConfig.appID)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("AppSecret", text: $store.bridgeConfig.appSecret)
                SecureField("Token", text: $store.bridgeConfig.token)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("EncodingAESKey", text: $store.bridgeConfig.encodingAESKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section("Endpoints") {
                TextField("Webhook URL", text: $store.bridgeConfig.webhookURL)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                LabeledContent("Official API") {
                    Text("api.weixin.qq.com")
                        .foregroundStyle(.secondary)
                }
                TextField("Universal Link", text: $store.bridgeConfig.universalLink)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
            }

            Section("Official Link Card") {
                TextField("Card Title", text: $store.bridgeConfig.linkPreview.title)
                    .textInputAutocapitalization(.sentences)
                TextField("Card Summary", text: $store.bridgeConfig.linkPreview.summary, axis: .vertical)
                    .lineLimit(2...4)
                TextField("Link URL", text: $store.bridgeConfig.linkPreview.webpageURL)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                TextField("Thumbnail Asset Name", text: $store.bridgeConfig.linkPreview.thumbnailAssetName)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                LabeledContent("Share State") {
                    shareStateLabel
                }

                ForEach(WeChatShareTarget.allCases) { target in
                    Button {
                        store.shareOfficialLink(to: target)
                    } label: {
                        Label("Share to \(target.title)", systemImage: target.systemImage)
                    }
                }
            }

            Section("Capabilities") {
                ForEach(store.capabilities) { capability in
                    CapabilityRow(capability: capability)
                }
            }
        }
        .navigationTitle("WeChat Bridge")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var connectionStateLabel: some View {
        switch store.connectionState {
        case .ready:
            Text("Ready").foregroundStyle(.secondary)
        case .checking:
            ProgressView()
        case .configured(let message):
            Text(message)
                .foregroundStyle(.orange)
                .multilineTextAlignment(.trailing)
        case .waitingForCallback:
            Text("Waiting").foregroundStyle(.secondary)
        case .connected(let date):
            Text("Connected \(ChatFormatters.shortTime.string(from: date))")
                .foregroundStyle(LGDesign.weChatGreen)
        case .cancelled(let message):
            Text(message)
                .foregroundStyle(.orange)
                .multilineTextAlignment(.trailing)
        case .failed(let message):
            Text(message)
                .foregroundStyle(.red)
                .multilineTextAlignment(.trailing)
        }
    }

    @ViewBuilder
    private var shareStateLabel: some View {
        switch store.shareState {
        case .ready:
            Text("Ready").foregroundStyle(.secondary)
        case .checking:
            ProgressView()
        case .configured(let message):
            Text(message)
                .foregroundStyle(.orange)
                .multilineTextAlignment(.trailing)
        case .waitingForCallback(let date):
            Text("Waiting for WeChat \(ChatFormatters.shortTime.string(from: date))")
                .foregroundStyle(.secondary)
        case .connected(let date):
            Text("Confirmed \(ChatFormatters.shortTime.string(from: date))")
                .foregroundStyle(LGDesign.weChatGreen)
        case .cancelled(let message):
            Text(message)
                .foregroundStyle(.orange)
                .multilineTextAlignment(.trailing)
        case .failed(let message):
            Text(message)
                .foregroundStyle(.red)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct CapabilityRow: View {
    let capability: WeChatCapability

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 24)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(capability.name)
                    .font(.system(size: 15, weight: .semibold))
                Text(capability.detail)
                    .font(.system(size: 12.5))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    var symbol: String {
        switch capability.status {
        case .available: "checkmark.circle.fill"
        case .requiresCredential: "key.fill"
        case .unsupportedPublicAPI: "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch capability.status {
        case .available: LGDesign.weChatGreen
        case .requiresCredential: .orange
        case .unsupportedPublicAPI: .red
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(MessengerStore())
    }
}
