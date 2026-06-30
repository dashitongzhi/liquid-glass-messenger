# PluginGlassKit

Objective-C/UIKit Liquid Glass components for small Theos WeChat tweaks.

This kit ports the visual direction from the SwiftUI chat prototype into a
plugin-friendly layer:

- independent floating glass buttons, not a single solid bottom sheet
- clear/dark material blur with white rim highlights
- compact iMessage-like 48 pt composer controls
- keyboard-aware bottom positioning
- Theos-friendly `.m/.h` files with no Swift runtime requirement

It is intended for UI polish in projects shaped like:

- `huami1314/WCDuang`: small Logos hook plus a Theos `Makefile`
- `52lxcloud/wctodo`: minimal `Tweak.x` with a WeChat bundle filter
- `huami1314/WCFix27LoginQR`: UIKit tweak helper functions plus Logos hook

It does not implement message interception, anti-recall, envelope automation,
login bypass, private sync, or any WeChat account behavior. Keep feature logic
separate from this UI layer.

## Files

```text
PluginGlassKit/
  Sources/
    LGGlassStyle.h/.m
    LGGlassView.h/.m
    LGGlassButton.h/.m
    LGGlassFloatingBar.h/.m
  Examples/Theos/
    Makefile
    Tweak.xm
    LiquidGlassDemo.plist
    control
```

## Copy Into An Existing Tweak

1. Copy `PluginGlassKit/Sources` into your tweak repo, for example `GlassKit/`.
2. Add the files to the Theos target:

```makefile
$(TWEAK_NAME)_FILES = $(shell find . -name "*.m" -o -name "*.xm")
$(TWEAK_NAME)_CFLAGS += -fobjc-arc -Wno-deprecated-declarations
$(TWEAK_NAME)_FRAMEWORKS += UIKit QuartzCore
```

3. Import the bar where you own the UI surface:

```objc
#import "GlassKit/LGGlassFloatingBar.h"
```

4. Attach it to the target view:

```objc
LGGlassButton *reply = [LGGlassButton chipButtonWithTitle:@"快捷回复" symbolName:nil];
LGGlassButton *camera = [LGGlassButton chipButtonWithTitle:@"拍摄" symbolName:@"camera.fill"];
LGGlassFloatingBar *bar = [[LGGlassFloatingBar alloc] initWithQuickActions:@[reply, camera]];
[bar attachToView:controller.view keyboardAware:YES];
```

## Example

`Examples/Theos` is a small tweak demo that mirrors the structure of the three
reference repositories. It hooks `AppDelegate` only to show where the glass UI
could be mounted. For real work, mount the bar in a specific WeChat controller
or plugin-owned panel so it does not cover unrelated screens.

```bash
cd PluginGlassKit/Examples/Theos
make package
```

## Visual Notes

The design matches the SwiftUI prototype's bottom composer:

- 48 pt round controls
- 48 pt input capsule
- 7-9 pt gaps between independent glass items
- transparent space behind controls so chat text remains visible
- white stroke opacity around 0.20-0.30
- black shadow opacity around 0.20-0.26

If a screen has busy content underneath, prefer `LGGlassMaterialRegular` or
`LGGlassStyle.regularPanelStyle`. For clean chat backgrounds, use the clear
capsule style.
