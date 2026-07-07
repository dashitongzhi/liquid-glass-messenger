# PluginGlassKit

Objective-C/UIKit Liquid Glass components and a Theos plugin shell for small
WeChat tweaks.

This kit ports the visual direction from the SwiftUI chat prototype into a
plugin-friendly layer and now includes a packageable tweak target:

- independent floating glass buttons, not a single solid bottom sheet
- clear/dark material blur with white rim highlights
- compact iMessage-like 48 pt composer controls
- keyboard-aware bottom positioning
- Theos-friendly `.m/.h` files with no Swift runtime requirement
- a `Plugin/Theos` target filtered to the WeChat bundle

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
  Plugin/
    Sources/
      LGWeChatPluginController.h/.m
    Theos/
      Makefile
      Tweak.xm
      LiquidGlassMessengerPlugin.plist
      control
  Examples/Theos/
    Makefile
    README.md
    smoke.sh
    Tweak.xm
    LiquidGlassDemo.plist
    control
```

## Build As A Plugin

The production-shaped plugin shell lives in `Plugin/Theos`:

```bash
cd PluginGlassKit/Plugin/Theos
make smoke
make package
make package SCHEME=rootless
make package SCHEME=roothide
```

From the repository root you can also run:

```bash
./script/build_plugin.sh
./script/build_plugin.sh SCHEME=rootless
```

`Plugin/Sources/LGWeChatPluginController.m` is the place to wire real feature
actions. The default implementation only mounts the Liquid Glass bar, inserts a
safe quick reply into the active input when possible, and uses clipboard/status
fallbacks when it cannot find a WeChat-owned text field.

## Copy Into An Existing Tweak

1. Copy `PluginGlassKit/Sources/*` into your tweak repo, for example
   `GlassKit/`.
2. Add the files to the Theos target:

```makefile
PLUGIN_GLASS_KIT_SOURCE_DIR ?= GlassKit
PLUGIN_GLASS_KIT_FILES := \
    $(PLUGIN_GLASS_KIT_SOURCE_DIR)/LGGlassStyle.m \
    $(PLUGIN_GLASS_KIT_SOURCE_DIR)/LGGlassView.m \
    $(PLUGIN_GLASS_KIT_SOURCE_DIR)/LGGlassButton.m \
    $(PLUGIN_GLASS_KIT_SOURCE_DIR)/LGGlassFloatingBar.m

$(TWEAK_NAME)_FILES += Tweak.xm $(PLUGIN_GLASS_KIT_FILES)
$(TWEAK_NAME)_CFLAGS += -fobjc-arc -Wno-deprecated-declarations -I$(PLUGIN_GLASS_KIT_SOURCE_DIR)
$(TWEAK_NAME)_FRAMEWORKS += UIKit QuartzCore
```

3. Import the bar where you own the UI surface:

```objc
#import <LGGlassFloatingBar.h>
```

4. Copy the `LGKBuildFloatingBar` and `LGKMountFloatingBarInHostView` helpers
   from `Examples/Theos/Tweak.xm`, then replace the host controller and
   lifecycle method with the real surface from your tweak:

```objc
%hook YourHostViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    LGKMountFloatingBarInHostView(self.view);
}
%end
```

The helper uses a stable view tag so repeated lifecycle calls do not add
duplicate bars.

## Example

`Examples/Theos` is a small tweak demo that mirrors the structure of the three
reference repositories. It stays buildable by hooking `AppDelegate`, but that
hook is explicitly marked as a replacement point. For real plugin work, start
from `Plugin/Theos`; it adds a separate controller, bundle filtering, lifecycle
attach/detach, and rootless / roothide package switches.

Run the local smoke check first. It does not require Theos unless `THEOS` is
already configured:

```bash
cd PluginGlassKit/Examples/Theos
make smoke
```

```bash
cd PluginGlassKit/Examples/Theos
make package
```

The example `Makefile` supports these drop-in knobs:

- `TWEAK_NAME`: package target name, default `LiquidGlassDemo`.
- `PLUGIN_GLASS_KIT_SOURCE_DIR`: folder containing the copied glass `.h/.m`
  files, default `../../Sources` in this repository.
- `SCHEME=rootless` or `SCHEME=roothide`: forwards to the matching Theos
  package scheme.

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
