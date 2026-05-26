#!/usr/bin/env bash
# Run Flutter web in Chrome against the local API (localhost:3000) with Supabase auth.
# Copy .env.local.example to .env.local and fill in your values before running.
# Usage: ./run_web_dev.sh
set -euo pipefail

ENV_FILE="$(dirname "$0")/.env.local"
if [ ! -f "$ENV_FILE" ]; then
  echo "Missing .env.local — copy .env.local.example and fill in your keys."
  exit 1
fi

# shellcheck source=/dev/null
source "$ENV_FILE"

flutter run -d chrome \
  --dart-define=DEALDROP_API_BASE_URL="${DEALDROP_API_BASE_URL:-http://localhost:3000}" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY" \
  --dart-define=GOOGLE_MAPS_API_KEY="$GOOGLE_MAPS_API_KEY"
