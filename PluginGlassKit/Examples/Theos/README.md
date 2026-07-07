# PluginGlassKit Theos Drop-in Example

This folder is a buildable Theos sample for copying the UIKit glass controls
into small WeChat tweak repositories such as WCDuang or wctodo.

## Files To Copy

Copy these files into the tweak repo:

- `Tweak.xm`, or copy the `LGKBuildFloatingBar` and
  `LGKMountFloatingBarInHostView` helpers into your existing tweak file.
- `Makefile` snippets for `PLUGIN_GLASS_KIT_SOURCE_DIR`, source files,
  `-I$(PLUGIN_GLASS_KIT_SOURCE_DIR)`, `UIKit`, and `QuartzCore`.
- `LiquidGlassDemo.plist` filter shape, renamed to your tweak target if needed.
- `control` metadata shape, renamed to your package id and dependency policy.

Also copy `PluginGlassKit/Sources/*` into a folder such as `GlassKit/`.

## Required Replacements

Replace the demo hook in `Tweak.xm`:

- Host controller: replace `%hook AppDelegate` with the controller or panel
  class that owns your feature surface.
- Mount point: replace
  `application:didFinishLaunchingWithOptions:` with a lifecycle method such as
  `viewDidAppear:`, or call `LGKMountFloatingBarInHostView(controller.view)`
  after creating your plugin-owned panel.
- Package metadata: rename `LiquidGlassDemo` in `Makefile`, `control`, and the
  plist filename to match your tweak target.

Keep `LGKMountFloatingBarInHostView` close to the real host view. It uses a
stable tag to avoid duplicate bars and asks `LGGlassFloatingBar` to handle safe
area and keyboard movement.

## Local Smoke

Run the smoke check before trying a device build:

```bash
cd PluginGlassKit/Examples/Theos
make smoke
```

The smoke check verifies the source paths, header include mode, package files,
README replacement markers, and plist syntax. If `THEOS` is configured, it also
runs a Theos dry-run for `make package`.

Then build the package normally:

```bash
make package
```

For rootless or roothide packages:

```bash
make package SCHEME=rootless
make package SCHEME=roothide
```
