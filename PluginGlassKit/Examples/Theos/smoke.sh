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
[[ -f LiquidGlassDemo.plist ]] || fail "missing LiquidGlassDemo.plist"
[[ -f control ]] || fail "missing control"
[[ -f README.md ]] || fail "missing README.md"

source_dir="$(sed -n 's/^[[:space:]]*PLUGIN_GLASS_KIT_SOURCE_DIR[[:space:]]*?=[[:space:]]*//p' Makefile | tail -n 1)"
[[ -n "${source_dir}" ]] || fail "Makefile must define PLUGIN_GLASS_KIT_SOURCE_DIR"
[[ -d "${source_dir}" ]] || fail "PLUGIN_GLASS_KIT_SOURCE_DIR does not exist: ${source_dir}"

for file in LGGlassStyle.m LGGlassView.m LGGlassButton.m LGGlassFloatingBar.m LGGlassFloatingBar.h; do
  [[ -f "${source_dir}/${file}" ]] || fail "missing glass source: ${source_dir}/${file}"
done

grep -q -- '-I$(PLUGIN_GLASS_KIT_SOURCE_DIR)' Makefile || fail "Makefile must expose glass headers through -I"
grep -q '#import <LGGlassFloatingBar.h>' Tweak.xm || fail "Tweak.xm should import LGGlassFloatingBar through the include path"
grep -q 'DROP-IN REPLACEMENT POINT' Tweak.xm || fail "Tweak.xm must mark the host hook replacement point"
grep -q 'LGKMountFloatingBarInHostView(self.view)' Tweak.xm || fail "Tweak.xm must show the controller-view mount call"
grep -q 'PLUGIN_GLASS_KIT_SOURCE_DIR' README.md || fail "README.md must document the source-dir knob"
grep -q 'Host controller' README.md || fail "README.md must mark the host controller replacement"
grep -q 'Mount point' README.md || fail "README.md must mark the mount point replacement"

plutil -lint LiquidGlassDemo.plist >/dev/null || fail "LiquidGlassDemo.plist is not valid"
grep -q '^Package:' control || fail "control is missing Package"
grep -q '^Depends:' control || fail "control is missing Depends"

if [[ -n "${THEOS:-}" && -r "${THEOS}/makefiles/common.mk" ]]; then
  note "THEOS found; running make package dry-run"
  make -n package >/dev/null
else
  note "THEOS is not configured; skipped Theos dry-run"
fi

note "ok"
