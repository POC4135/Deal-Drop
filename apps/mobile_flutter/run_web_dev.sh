#!/usr/bin/env bash
# Run Flutter web in Chrome against the local API (localhost:3000) with Supabase auth.
# Usage: ./run_web_dev.sh
set -euo pipefail

SUPABASE_URL="https://lkjrdtcisklbpyvqugej.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxranJkdGNpc2tsYnB5dnF1Z2VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc3MzM0NjQsImV4cCI6MjA5MzMwOTQ2NH0.IjQOBtXivXKMw_Q36Sw69jsmhZJNhsTyIvLrmb8c6hY"
MAPS_KEY="AIzaSyD1LAtIS1SCU4WKXuSwKMQjjs8zTD92SeA"

flutter run -d chrome \
  --dart-define=DEALDROP_API_BASE_URL="http://localhost:3000" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_KEY" \
  --dart-define=GOOGLE_MAPS_API_KEY="$MAPS_KEY"
