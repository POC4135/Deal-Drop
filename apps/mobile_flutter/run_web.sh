#!/bin/bash
# Usage: ./run_web.sh YOUR_GOOGLE_MAPS_API_KEY
MAPS_KEY=${1:?Usage: ./run_web.sh YOUR_GOOGLE_MAPS_API_KEY}
flutter run -d chrome \
  --dart-define=DEALDROP_API_BASE_URL=https://deal-drop-y0qs.onrender.com \
  --dart-define=GOOGLE_MAPS_API_KEY="$MAPS_KEY" \
  --dart-define=GOOGLE_MAPS_MAP_ID=9c2fdf9a2ea1dcec1f71c085
