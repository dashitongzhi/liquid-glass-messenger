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
- Offline demo data so the app can be inspected immediately.

## Important boundary

Personal WeChat full chat sync, Moments, payments, arbitrary contact access, and
private message transport are not available through ordinary public APIs. The
app exposes a replaceable `WeChatBridge` layer for official integrations and
marks unsupported private-protocol surfaces explicitly.

## Run

```bash
/bin/bash script/build_and_run.sh --verify
```

The script builds for an available iOS Simulator. Install/launch is attempted
only when called with `--launch` and a booted simulator is available.
