#!/bin/zsh
# Captures App Store screenshots from the simulators with the sample season.
# Usage: scripts/capture-store-screenshots.sh [shot-name ...]   (default: all shots)
# Output: docs/app-store/screenshots/<set>/<nn-name>.png  (PNG, no alpha)
# Plan and sizes: docs/app-store/submission-checklist.md, "Screenshots".
set -euo pipefail
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
cd "$(dirname "$0")/.."
OUT=docs/app-store/screenshots
DD=${DERIVED_DATA:-/tmp/dd_store_shots}
BUNDLE=com.oscars.tracker

# set | simulator name | OS | App Store pixel size (portrait)
SETS=(
  "iphone-6.9|iPhone 18 Pro Max|27.0|1320x2868"
  "iphone-6.1|iPhone 18 Pro|27.0|1206x2622"
  "ipad-13|iPad Pro 13-inch (M5)|27.0|2064x2752"
  "duo-outer|iPhone Duo|27.1|1398x2034"
)
# shot | launch arguments after -sample-data | tab to open
SHOTS=(
  "01-films|-tab films"
  "02-ballot|-tab ballot"
  "03-ballot-full|-tab ballot -full-ballot"
  "04-plan|-tab plan"
  "05-board|-tab board"
  "06-film|-tab films -movie 3"
  "07-live|-tab ballot -live"
)

xcodebuild build -project OscarsTracker/OscarsTracker.xcodeproj -scheme OscarsTracker \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath "$DD" -quiet
APP="$DD/Build/Products/Debug-iphonesimulator/OscarsTracker.app"

for set in "${SETS[@]}"; do
  IFS='|' read -r name device os size <<<"$set"
  udid=$(xcrun simctl list devices available "iOS $os" | grep -F "    $device (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
  [[ -n "$udid" ]] || { echo "no simulator: $device (iOS $os)"; continue; }
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b >/dev/null
  xcrun simctl ui "$udid" appearance dark
  xcrun simctl status_bar "$udid" override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
  xcrun simctl install "$udid" "$APP"
  mkdir -p "$OUT/$name"
  for shot in "${SHOTS[@]}"; do
    id=${shot%%|*}; args=${shot#*|}
    [[ $# -gt 0 && ! " $* " == *" $id "* ]] && continue
    xcrun simctl terminate "$udid" $BUNDLE 2>/dev/null || true
    xcrun simctl launch "$udid" $BUNDLE -sample-data ${=args} >/dev/null
    sleep 4   # live mode announces at +3 s
    xcrun simctl io "$udid" screenshot --type=png "$OUT/$name/$id.png"
  done
  xcrun simctl status_bar "$udid" clear
  # Verify the pixel size App Store Connect expects.
  for f in "$OUT/$name"/*.png; do
    got=$(sips -g pixelWidth -g pixelHeight "$f" | awk '/pixel/{a[++i]=$2} END{print a[1]"x"a[2]}')
    [[ "$got" == "$size" ]] || echo "WARN $f is $got, App Store wants $size"
  done
done
echo "Done. Review every image before upload (simctl PNGs have no alpha channel)."
