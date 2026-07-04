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
    README.md
    smoke.sh
    Tweak.xm
    LiquidGlassDemo.plist
    control
```

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
hook is explicitly marked as a replacement point. For real work, replace it
with a specific WeChat controller or plugin-owned panel so the bar does not
cover unrelated screens.

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
