#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_DIR="$ROOT/PluginGlassKit/Plugin/Theos"

if [[ -z "${THEOS:-}" ]]; then
  echo "THEOS is not set. Install Theos or export THEOS=/path/to/theos before building the plugin." >&2
  exit 2
fi

cd "$PLUGIN_DIR"
make package "$@"
