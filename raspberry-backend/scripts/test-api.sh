#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://127.0.0.1:8787}"
API_KEY="${MASJID_API_KEY:-dev-key}"
HDR=(-H "X-API-Key: ${API_KEY}")

echo "== GET /v1/info"
curl -sS "${HDR[@]}" "$BASE_URL/v1/info" | python3 -m json.tool

echo "== POST /v1/theme"
curl -sS "${HDR[@]}" -H "Content-Type: application/json" \
  -d '{"version":"3.0.0","themeId":"night","pushId":"abc123","gradientStops":[{"position":0,"color":"#111"},{"position":100,"color":"#222"}],"pattern":{"enabled":true}}' \
  "$BASE_URL/v1/theme" | python3 -m json.tool

echo "== POST /v1/sync"
curl -sS "${HDR[@]}" -H "Content-Type: application/json" \
  -d '{"city":"Riyadh","language":"ar","phase":"countdown","nextPrayerKey":"asr","nextPrayerAr":"العصر","countdownSeconds":1800,"tickerDirection":"rtl","tickerPaused":false,"location":{"lat":24.7136,"lng":46.6753},"prayers":[{"key":"fajr","nameAr":"الفجر","nameEn":"Fajr","adhan":"04:30","iqama":"04:50"},{"key":"dhuhr","nameAr":"الظهر","nameEn":"Dhuhr","adhan":"12:05","iqama":"12:20"},{"key":"asr","nameAr":"العصر","nameEn":"Asr","adhan":"15:30","iqama":"15:45"},{"key":"maghrib","nameAr":"المغرب","nameEn":"Maghrib","adhan":"18:20","iqama":"18:25"},{"key":"isha","nameAr":"العشاء","nameEn":"Isha","adhan":"19:40","iqama":"20:00"}]}' \
  "$BASE_URL/v1/sync" | python3 -m json.tool

echo "== POST /v1/ticker"
curl -sS "${HDR[@]}" -H "Content-Type: application/json" \
  -d '{"message":"السلام عليكم ورحمة الله"}' "$BASE_URL/v1/ticker" | python3 -m json.tool

TMP_IMG="$(mktemp /tmp/masjid-upload-XXXXXX.png)"
python3 - <<'PY' "$TMP_IMG"
import base64, sys
png = b'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO6p8mQAAAAASUVORK5CYII='
open(sys.argv[1], 'wb').write(base64.b64decode(png))
PY

echo "== POST /v1/upload-background"
curl -sS "${HDR[@]}" -F "file=@$TMP_IMG;type=image/png" "$BASE_URL/v1/upload-background" | python3 -m json.tool

rm -f "$TMP_IMG"

echo "== GET /v1/display"
curl -sS "${HDR[@]}" "$BASE_URL/v1/display" | python3 -m json.tool

echo "== GET /v1/state"
curl -sS "${HDR[@]}" "$BASE_URL/v1/state" | python3 -m json.tool

echo "== POST phase2 endpoints"
for ep in audio power ramadan quran-program; do
  curl -sS "${HDR[@]}" -H "Content-Type: application/json" -d '{"enabled":true}' "$BASE_URL/v1/$ep" | python3 -m json.tool
  echo "ok: $ep"
done

echo "== Concurrency check (/v1/sync + /v1/theme in parallel)"
for i in $(seq 1 10); do
  theme_payload=$(printf '{"version":"3.0.0","themeId":"t%s","pushId":"p%s"}' "$i" "$i")
  sync_payload=$(printf '{"phase":"countdown","nextPrayerKey":"asr","countdownSeconds":%s}' "$((1000+i))")

  curl -sS "${HDR[@]}" -H "Content-Type: application/json" -d "$theme_payload" "$BASE_URL/v1/theme" >/dev/null &
  curl -sS "${HDR[@]}" -H "Content-Type: application/json" -d "$sync_payload" "$BASE_URL/v1/sync" >/dev/null &
done
wait
curl -sS "${HDR[@]}" "$BASE_URL/v1/state" | python3 -m json.tool
echo "concurrency: completed"
