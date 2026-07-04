#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

fail() {
  printf 'smoke: %s\n' "$*" >&2
  exit 1
}

note() {
  printf 'smoke: %s\n' "$*"
}

[[ -f Makefile ]] || fail "missing Makefile"
[[ -f Tweak.xm ]] || fail "missing Tweak.xm"
[[ -f LiquidGlassMessengerPlugin.plist ]] || fail "missing LiquidGlassMessengerPlugin.plist"
[[ -f control ]] || fail "missing control"
[[ -f ../README.md ]] || fail "missing plugin README"

runtime_dir="$(sed -n 's/^[[:space:]]*PLUGIN_RUNTIME_SOURCE_DIR[[:space:]]*?=[[:space:]]*//p' Makefile | tail -n 1)"
glass_dir="$(sed -n 's/^[[:space:]]*PLUGIN_GLASS_KIT_SOURCE_DIR[[:space:]]*?=[[:space:]]*//p' Makefile | tail -n 1)"
[[ -n "${runtime_dir}" ]] || fail "Makefile must define PLUGIN_RUNTIME_SOURCE_DIR"
[[ -n "${glass_dir}" ]] || fail "Makefile must define PLUGIN_GLASS_KIT_SOURCE_DIR"
[[ -d "${runtime_dir}" ]] || fail "PLUGIN_RUNTIME_SOURCE_DIR does not exist: ${runtime_dir}"
[[ -d "${glass_dir}" ]] || fail "PLUGIN_GLASS_KIT_SOURCE_DIR does not exist: ${glass_dir}"

for file in LGWeChatPluginController.h LGWeChatPluginController.m; do
  [[ -f "${runtime_dir}/${file}" ]] || fail "missing plugin runtime source: ${runtime_dir}/${file}"
done

for file in LGGlassStyle.m LGGlassView.m LGGlassButton.m LGGlassFloatingBar.m LGGlassFloatingBar.h; do
  [[ -f "${glass_dir}/${file}" ]] || fail "missing glass source: ${glass_dir}/${file}"
done

grep -q -- '-I$(PLUGIN_RUNTIME_SOURCE_DIR)' Makefile || fail "Makefile must expose runtime headers through -I"
grep -q -- '-I$(PLUGIN_GLASS_KIT_SOURCE_DIR)' Makefile || fail "Makefile must expose glass headers through -I"
grep -q '#import <LGWeChatPluginController.h>' Tweak.xm || fail "Tweak.xm should import plugin controller through the include path"
grep -q 'installIfEligibleInViewController:self' Tweak.xm || fail "Tweak.xm must delegate install decisions"
grep -q 'com.tencent.xin' LiquidGlassMessengerPlugin.plist || fail "plist must filter the WeChat bundle"

plutil -lint LiquidGlassMessengerPlugin.plist >/dev/null || fail "LiquidGlassMessengerPlugin.plist is not valid"
grep -q '^Package:' control || fail "control is missing Package"
grep -q '^Depends:' control || fail "control is missing Depends"

if [[ -n "${THEOS:-}" && -r "${THEOS}/makefiles/common.mk" ]]; then
  note "THEOS found; running make package dry-run"
  make -n package >/dev/null
else
  note "THEOS is not configured; skipped Theos dry-run"
fi

note "ok"
