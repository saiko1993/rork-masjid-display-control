#!/usr/bin/env bash
# test-api.sh – Smoke-test all Masjid Display API endpoints with curl
set -euo pipefail

BASE="${BASE_URL:-http://localhost:8787}"
API_KEY="${MASJID_API_KEY:-}"
PASS=0
FAIL=0

# Colour helpers
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

auth_header() {
    if [ -n "${API_KEY}" ]; then
        echo "-H" "X-API-Key: ${API_KEY}"
    else
        echo ""
    fi
}

check() {
    local name="$1"; local expected_status="$2"
    shift 2
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" "$@")
    if [ "${http_code}" -eq "${expected_status}" ]; then
        echo -e "${GREEN}[PASS]${NC} ${name}  (HTTP ${http_code})"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}[FAIL]${NC} ${name}  expected ${expected_status}, got ${http_code}"
        FAIL=$((FAIL + 1))
    fi
}

AUTH=$(auth_header)

echo ""
echo "=== Masjid API smoke tests against ${BASE} ==="
echo ""

# ── 1) GET /v1/info ─────────────────────────────────────────────────────────
check "GET /v1/info" 200 \
    ${AUTH:+${AUTH}} "${BASE}/v1/info"

# ── 2) GET /v1/state ────────────────────────────────────────────────────────
check "GET /v1/state" 200 \
    ${AUTH:+${AUTH}} "${BASE}/v1/state"

# ── 3) GET /v1/display ──────────────────────────────────────────────────────
check "GET /v1/display" 200 \
    ${AUTH:+${AUTH}} "${BASE}/v1/display"

# ── 4) POST /v1/theme ───────────────────────────────────────────────────────
THEME_BODY='{"version":"3.0.0","themeId":"minimal-noor","pushId":"test-push-01","nameEn":"Minimal Noor","nameAr":"نور بسيط","isDark":true,"contrastRatio":7.0,"palette":{"background":"#0d1117","surface":"#161b22","primary":"#c9a84c","secondary":"#9e7c35","textPrimary":"#f0e6d3","textSecondary":"#a0927a","accent":"#e8c86d","adhanGlow":"#e8c86d"},"typography":{"timeFontDesign":"monospaced","arabicFontDesign":"default","latinFontDesign":"default","timeWeight":"bold","headingWeight":"semibold"},"tokens":{"cornerRadius":12,"cardPadding":16,"sectionSpacing":12,"borderWidth":1,"shadowRadius":8,"minReadableFontSize":12,"safeMargins":16,"tableDensity":"comfortable","tickerDirection":"rtl","minFontScale":0.7,"maxFontScale":1.4},"backgroundPattern":"geometric","layerStack":{"backgroundBase":"#0d1117","gradientStops":[{"color":"#0d1117","location":0},{"color":"#1a2236","location":0.55},{"color":"#0d1117","location":1}],"gradientAngle":160,"patternType":"geometric","patternColor":"#c9a84c","patternOpacity":0.06,"vignetteType":"radial","vignetteIntensity":0.65,"elevationStyle":"shadow","cardBorderColor":null,"cardBorderOpacity":0.2,"hasShimmer":false,"shimmerSpeed":1,"adhanGlowStyle":"radial","adhanGlowColor":"#e8c86d","countdownGlowRadius":8,"tableRowSeparator":true,"tableRowInset":false,"tickerBackground":null,"backgroundImageUrl":null,"backgroundImageFit":null}}'
check "POST /v1/theme" 200 \
    ${AUTH:+${AUTH}} \
    -X POST \
    -H "Content-Type: application/json" \
    -d "${THEME_BODY}" \
    "${BASE}/v1/theme"

# ── 5) POST /v1/sync ────────────────────────────────────────────────────────
NOW_EPOCH=$(date +%s)
SYNC_BODY="{\"version\":\"3.0.0\",\"pushId\":\"sync-test-01\",\"sentAtISO\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"nowEpoch\":${NOW_EPOCH},\"deviceTime\":\"$(date '+%Y-%m-%d %H:%M:%S')\",\"tz\":\"Africa/Cairo\",\"tzOffsetMinutes\":120,\"schedule\":[{\"prayer\":\"fajr\",\"adhan\":\"05:10\",\"adhanISO\":\"2026-01-01T03:10:00Z\",\"iqama\":\"05:25\",\"iqamaISO\":\"2026-01-01T03:25:00Z\",\"isJumuah\":false},{\"prayer\":\"dhuhr\",\"adhan\":\"12:06\",\"adhanISO\":\"2026-01-01T10:06:00Z\",\"iqama\":\"12:20\",\"iqamaISO\":\"2026-01-01T10:20:00Z\",\"isJumuah\":false},{\"prayer\":\"asr\",\"adhan\":\"15:24\",\"adhanISO\":\"2026-01-01T13:24:00Z\",\"iqama\":\"15:39\",\"iqamaISO\":\"2026-01-01T13:39:00Z\",\"isJumuah\":false},{\"prayer\":\"maghrib\",\"adhan\":\"17:36\",\"adhanISO\":\"2026-01-01T15:36:00Z\",\"iqama\":\"17:41\",\"iqamaISO\":\"2026-01-01T15:41:00Z\",\"isJumuah\":false},{\"prayer\":\"isha\",\"adhan\":\"19:02\",\"adhanISO\":\"2026-01-01T17:02:00Z\",\"iqama\":\"19:17\",\"iqamaISO\":\"2026-01-01T17:17:00Z\",\"isJumuah\":false}],\"currentPhase\":{\"phase\":\"normal\",\"currentPrayer\":null,\"nextPrayer\":\"fajr\"},\"display\":{\"language\":\"ar\",\"brightness\":80,\"layout\":\"wide-v1\",\"showDhikrTicker\":true,\"tickerDirection\":\"rtl\",\"pauseTickerDuringAdhan\":true,\"lockLayout\":false},\"brightnessSchedule\":{\"enabled\":true,\"dayBrightness\":80,\"nightBrightness\":40,\"dayStartHour\":6,\"nightStartHour\":20},\"location\":{\"cityName\":\"Cairo\",\"lat\":30.0444,\"lng\":31.2357,\"timezone\":\"Africa/Cairo\"},\"timeFormat\":\"24h\",\"largeMode\":false}"
check "POST /v1/sync" 200 \
    ${AUTH:+${AUTH}} \
    -X POST \
    -H "Content-Type: application/json" \
    -d "${SYNC_BODY}" \
    "${BASE}/v1/sync"

# ── 6) POST /v1/ticker ──────────────────────────────────────────────────────
check "POST /v1/ticker" 200 \
    ${AUTH:+${AUTH}} \
    -X POST \
    -H "Content-Type: application/json" \
    -d '{"message":"جمعة مباركة لجميع المصلين"}' \
    "${BASE}/v1/ticker"

# ── 7) POST /v1/upload-background (PNG) ─────────────────────────────────────
TMPIMG=$(mktemp /tmp/test_upload_XXXXXX.png)
# minimal 1×1 white PNG
printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc\xf8\x0f\x00\x00\x01\x01\x00\x05\x18\xd8N\x00\x00\x00\x00IEND\xaeB`\x82' > "${TMPIMG}"
check "POST /v1/upload-background" 200 \
    ${AUTH:+${AUTH}} \
    -X POST \
    -F "file=@${TMPIMG};type=image/png" \
    "${BASE}/v1/upload-background"
rm -f "${TMPIMG}"

# ── 8) POST /v1/upload-background wrong type ────────────────────────────────
TMPTXT=$(mktemp /tmp/test_upload_XXXXXX.txt)
echo "not an image" > "${TMPTXT}"
check "POST /v1/upload-background (bad type → 415)" 415 \
    ${AUTH:+${AUTH}} \
    -X POST \
    -F "file=@${TMPTXT};type=text/plain" \
    "${BASE}/v1/upload-background"
rm -f "${TMPTXT}"

# ── 9) GET /display ─────────────────────────────────────────────────────────
check "GET /display (HTML)" 200 \
    "${BASE}/display"

# ── 10) Phase 2 stubs ───────────────────────────────────────────────────────
check "POST /v1/audio" 200 \
    ${AUTH:+${AUTH}} \
    -X POST -H "Content-Type: application/json" \
    -d '{"adhanMode":"default","globalVolume":80}' \
    "${BASE}/v1/audio"

check "POST /v1/power" 200 \
    ${AUTH:+${AUTH}} \
    -X POST -H "Content-Type: application/json" \
    -d '{"screenOffEnabled":false}' \
    "${BASE}/v1/power"

check "POST /v1/ramadan" 200 \
    ${AUTH:+${AUTH}} \
    -X POST -H "Content-Type: application/json" \
    -d '{"autoDetect":true}' \
    "${BASE}/v1/ramadan"

check "POST /v1/quran-program" 200 \
    ${AUTH:+${AUTH}} \
    -X POST -H "Content-Type: application/json" \
    -d '{"enabled":false}' \
    "${BASE}/v1/quran-program"

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "=== Results: ${GREEN}${PASS} passed${NC}  ${RED}${FAIL} failed${NC} ==="
[ "${FAIL}" -eq 0 ] && exit 0 || exit 1
