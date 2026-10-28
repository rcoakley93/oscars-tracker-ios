#!/bin/zsh
# Captures App Store screenshots from the simulators with the sample season.
# Usage: [ONLY_SETS="ipad-13 iphone-6.9"] scripts/capture-store-screenshots.sh [shot-name ...]   (default: all sets, all shots)
# -store-shots keeps posters unfit for a 4+ store image off screen and the App Store badge off share cards.
# Output: docs/app-store/screenshots/raw/<set>/<nn-name>.png  (PNG, no alpha; raw is gitignored; scripts/frame-store-images.py frames them)
# Plan and sizes: docs/app-store/submission-checklist.md, "Screenshots".
set -euo pipefail
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
cd "$(dirname "$0")/.."
OUT=${OUT:-docs/app-store/screenshots/raw-2-1}
DD=${DERIVED_DATA:-/tmp/dd_store_shots}
BUNDLE=com.oscars.tracker

# set | simulator name | OS | App Store pixel size (portrait) | display to capture
# A new iPhone Duo simulator boots folded, so display 1 is its outer display.
# The inner display needs the Duo unfolded in Device Hub: capture it by hand.
SETS=(
  "iphone-6.9|iPhone 18 Pro Max|27.0|1320x2868"
  "iphone-6.1|iPhone 18 Pro|27.0|1206x2622"
  "ipad-13|iPad Pro 13-inch (M5)|27.0|2064x2752"
  "duo-outer|iPhone Duo|27.1|1398x2034|1"
)
# shot | launch arguments after -sample-data | tab to open
# The 2.1 set (Oct 28): contenders and the locked ballot before nominations,
# badges, past seasons, then the 2.0 shots that still hold. The 2.0 list is in git history.
P="-list-stage predicted"
SHOTS=(
  "01-films|-tab films $P"
  "02-badges|-tab board -board badges $P"
  "03-badge-case|-tab films -sheet profile -profile-page badges $P"
  "04-ballot-locked|-tab ballot $P"
  "05-archive|-tab films -sheet profile -profile-page archive $P"
  "06-groups|-tab groups $P"
  "07-board|-tab board $P"
  "08-live|-tab ballot -live"
  "09-plan|-tab plan $P"
)

xcodebuild build -project OscarsTracker/OscarsTracker.xcodeproj -scheme OscarsTracker \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath "$DD" -quiet
APP="$DD/Build/Products/Debug-iphonesimulator/OscarsTracker.app"

for set in "${SETS[@]}"; do
  IFS='|' read -r name device os size display <<<"$set"
  [[ -n "${ONLY_SETS:-}" && ! " $ONLY_SETS " == *" $name "* ]] && continue
  # Dedicated simulators, so other sessions' booted devices are never touched.
  sim="Store shots $name"
  udid=$(xcrun simctl list devices | grep -F "    $sim (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/' || true)
  if [[ -z "$udid" ]]; then
    type=$(xcrun simctl list devicetypes | grep -F "$device (com" | head -1 | sed -E 's/.*\((com\.apple[^)]*)\)$/\1/' || true)
    udid=$(xcrun simctl create "$sim" "$type" "com.apple.CoreSimulator.SimRuntime.iOS-${os//./-}")
  fi
  shoot=(xcrun simctl io "$udid" screenshot --type=png ${display:+--display=$display})
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b >/dev/null
  xcrun simctl ui "$udid" appearance dark
  xcrun simctl status_bar "$udid" override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
  xcrun simctl install "$udid" "$APP"
  mkdir -p "$OUT/$name"
  for shot in "${SHOTS[@]}"; do
    id=${shot%%|*}; args=${shot#*|}
    # Split views open on a film; pick one with a poster (KPop Demon Hunters).
    [[ "$name" == ipad-13 && "$id" == 01-films ]] && args="$args -movie 3"
    [[ $# -gt 0 && ! " $* " == *" $id "* ]] && continue
    xcrun simctl terminate "$udid" $BUNDLE 2>/dev/null || true
    xcrun simctl launch "$udid" $BUNDLE -sample-data -store-shots ${=args} >/dev/null
    # Wait for a real screen, not a splash or a black frame (the ambient MeshGradient
    # drifts, so frames are never byte-identical). Live mode announces at +3 s and the
    # reveal runs about 3 s more; a busy Mac is slower, so the checks are generous.
    if [[ "$id" == 07-live ]]; then sleep 10; else sleep 5; fi
    ok=0
    for attempt in {1..30}; do
      "${shoot[@]}" "$OUT/$name/$id.png" 2>/dev/null
      if [[ $(stat -f%z "$OUT/$name/$id.png") -gt 150000 ]]; then ok=1; break; fi
      sleep 2
    done
    (( ok )) && { sleep 2; "${shoot[@]}" "$OUT/$name/$id.png" 2>/dev/null; } || echo "WARN $name/$id never showed a real screen"
  done
  xcrun simctl status_bar "$udid" clear
  xcrun simctl shutdown "$udid" 2>/dev/null || true   # one simulator at a time
  # Verify the pixel size App Store Connect expects.
  for f in "$OUT/$name"/*.png; do
    got=$(sips -g pixelWidth -g pixelHeight "$f" | awk '/pixel/{a[++i]=$2} END{print a[1]"x"a[2]}')
    [[ "$got" == "$size" ]] || echo "WARN $f is $got, App Store wants $size"
  done
done
echo "Done. Review every image before upload (simctl PNGs have no alpha channel)."
