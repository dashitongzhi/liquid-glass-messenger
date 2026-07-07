# LiquidGlassMessengerPlugin

Theos tweak shell that turns the Liquid Glass UI kit into a WeChat plugin.

The plugin injects only a reusable UIKit surface:

- a keyboard-aware Liquid Glass floating bar
- quick-reply text insertion or clipboard fallback
- placeholders for camera and file entry points
- WeChat bundle filtering through `com.tencent.xin`
- rootful, rootless, and roothide package switches through `SCHEME`

It intentionally does not implement private WeChat message transport, anti-recall,
envelope automation, login bypass, or account sync.

## Build

```bash
cd PluginGlassKit/Plugin/Theos
make smoke
make package
make package SCHEME=rootless
make package SCHEME=roothide
```

Or from the repository root:

```bash
./script/build_plugin.sh
./script/build_plugin.sh SCHEME=rootless
```

## Adapt

The production entry point is `Plugin/Theos/Tweak.xm`. It hooks
`UIViewController` in the WeChat process and delegates attach/detach decisions
to `Plugin/Sources/LGWeChatPluginController.m`.

By default the shell is opt-in and does not attach to any WeChat screen. To
enable it in your own environment, add exact, verified chat controller class
names to `LGWeChatEligibleControllerClassNames`. The controller also keeps one
active floating bar per window so container and child controller appearances do
not create duplicate bars. Keep feature actions in `LGWeChatPluginController`
so the visual kit remains reusable.
