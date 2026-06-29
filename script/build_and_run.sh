#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT/LiquidGlassMessenger.xcodeproj"
SCHEME="LiquidGlassMessenger"
DERIVED_DATA="$ROOT/DerivedData"
DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
export DEVELOPER_DIR

usage() {
  echo "Usage: $0 [--verify] [--launch] [--device <udid>]"
}

VERIFY=0
LAUNCH=0
DEVICE_ID=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --verify) VERIFY=1 ;;
    --launch) LAUNCH=1 ;;
    --device)
      DEVICE_ID="${2:-}"
      if [[ -z "$DEVICE_ID" ]]; then
        echo "--device requires a UDID" >&2
        exit 2
      fi
      shift
      ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 2 ;;
  esac
  shift
done

if [[ -n "$DEVICE_ID" ]]; then
  DESTINATION="id=$DEVICE_ID"
  DERIVED_DATA="$ROOT/DerivedDataDevice"
  SIGNING_ALLOWED="YES"
else
  DESTINATION="generic/platform=iOS Simulator"
  SIGNING_ALLOWED="NO"
fi

echo "Building $SCHEME for $DESTINATION..."
set +e
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -derivedDataPath "$DERIVED_DATA" \
  -destination "$DESTINATION" \
  CODE_SIGNING_ALLOWED="$SIGNING_ALLOWED" \
  build
BUILD_STATUS=$?
set -e

if [[ -n "$DEVICE_ID" ]]; then
  APP="$DERIVED_DATA/Build/Products/Debug-iphoneos/$SCHEME.app"
  XCENT="$DERIVED_DATA/Build/Intermediates.noindex/LiquidGlassMessenger.build/Debug-iphoneos/LiquidGlassMessenger.build/LiquidGlassMessenger.app.xcent"
  IDENTITY="${CODE_SIGN_IDENTITY_HASH:-D995CAF7456CE9A2210AB48CAA847AAB86F041DC}"
else
  APP="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/$SCHEME.app"
fi

if [[ ! -d "$APP" ]]; then
  echo "Built app not found at $APP" >&2
  exit 1
fi

if [[ "$BUILD_STATUS" -ne 0 && -z "$DEVICE_ID" ]]; then
  exit "$BUILD_STATUS"
fi

if [[ -n "$DEVICE_ID" ]]; then
  xattr -cr "$APP"
  if [[ -f "$XCENT" ]]; then
    /usr/bin/codesign --force --sign "$IDENTITY" --entitlements "$XCENT" --timestamp=none --generate-entitlement-der "$APP"
    /usr/bin/codesign --verify --deep --strict --verbose=2 "$APP"
  fi
  DEVELOPER_DIR="$DEVELOPER_DIR" xcrun devicectl device install app --device "$DEVICE_ID" "$APP"
  if [[ "$LAUNCH" -eq 1 ]]; then
    DEVELOPER_DIR="$DEVELOPER_DIR" xcrun devicectl device process launch --terminate-existing --device "$DEVICE_ID" Kral.LiquidGlassMessenger
  fi
elif [[ "$LAUNCH" -eq 1 ]]; then
  BOOTED_ID="$(xcrun simctl list devices booted | awk -F '[()]' '/Booted/ {print $2; exit}')"
  if [[ -z "${BOOTED_ID:-}" ]]; then
    echo "No booted simulator found; build succeeded, launch skipped."
  else
    echo "Installing on booted simulator $BOOTED_ID..."
    xcrun simctl install "$BOOTED_ID" "$APP"
    xcrun simctl launch "$BOOTED_ID" Kral.LiquidGlassMessenger || true
  fi
fi

if [[ "$VERIFY" -eq 1 ]]; then
  echo "Verified build artifact: $APP"
fi
