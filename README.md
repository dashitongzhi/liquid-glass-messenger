# Liquid Glass Messenger for iOS

Apple-native SwiftUI iPhone chat prototype that recreates the structure,
spacing, bubble behavior, toolbar rhythm, and translucent Liquid Glass feel of
Messages/iMessage without bundling proprietary Apple or WeChat assets.

## What is implemented

- iOS app scaffolded as an Xcode project.
- SwiftUI-first UI with native iOS Liquid Glass APIs on iOS 26+ and material
  fallbacks on earlier systems.
- Messages-like iPhone flow: conversation list, transcript, compact navigation,
  bubble tails, composer, app drawer, typing state, reactions, attachments,
  pinned/share/reply affordances, and WeChat capability settings.
- WeChat bridge architecture for official WeChat/WeCom/Open Platform endpoints.
- Settings surface for app id, secret, token, encoding AES key, webhook URL, and
  connection mode.
- `PluginGlassKit`, an Objective-C/UIKit Liquid Glass UI layer for Theos-style
  WeChat tweak projects that need the same floating glass controls.
- Official WeChat link-card configuration surface for AppID, Universal Link,
  share title, description, URL, thumbnail asset name, and WeChat share targets.
- Offline demo data so the app can be inspected immediately.

## Important boundary

Personal WeChat full chat sync, Moments, payments, arbitrary contact access, and
private message transport are not available through ordinary public APIs. The
app exposes a replaceable `WeChatBridge` layer for official integrations and
marks unsupported private-protocol surfaces explicitly.

The project intentionally does not include a WeChat IPA hook, injected dynamic
library, anti-recall tweak, envelope automation, location spoofing, or a
modified personal WeChat client. Those approaches are useful only as reverse
engineering references and are not part of the public app.

## Official WeChat Setup

The SwiftUI app is prepared for the official WeChat OpenSDK link-card path:

1. Register the app in WeChat Open Platform and obtain the production AppID.
2. Configure the production Universal Link domain in WeChat Open Platform.
3. Set `WECHAT_APP_URL_SCHEME` in `LiquidGlassMessenger.xcodeproj` to the
   WeChat URL scheme, usually the AppID such as `wx123...`.
4. Add/link the official WeChat OpenSDK so `canImport(WechatOpenSDK)` is true.
5. In the app Settings screen, fill AppID, Universal Link, and the link card
   title/summary/URL/thumbnail asset.

Without the OpenSDK linked, the app still builds and shows the configuration
surface, but native share buttons report that the SDK is unavailable.

The checked-in `WECHAT_APP_URL_SCHEME` value is a demo placeholder. Native
OpenSDK sharing is blocked in Demo Sandbox mode and fails fast outside demo mode
until the placeholder is replaced with the production scheme registered in
WeChat Open Platform. After `WXApi.send` accepts a request, the UI waits for the
WeChat callback and only marks the share confirmed from the OpenSDK response.

## Run

```bash
/bin/bash script/build_and_run.sh --verify
```

The script builds for an available iOS Simulator. Install/launch is attempted
only when called with `--launch` and a booted simulator is available.
