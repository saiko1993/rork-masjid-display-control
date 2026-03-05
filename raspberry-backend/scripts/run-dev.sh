#!/usr/bin/env bash
# run-dev.sh – Start the Masjid API server in development mode (no auth)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(dirname "${SCRIPT_DIR}")"

cd "${BACKEND_DIR}"

# Create a local venv if not present
if [ ! -d "venv" ]; then
    echo "==> Creating local venv..."
    python3 -m venv venv
    venv/bin/pip install --upgrade pip --quiet
    venv/bin/pip install -r requirements.txt --quiet
fi

export MASJID_STATE_PATH="${MASJID_STATE_PATH:-/tmp/masjid_state_dev.json}"
export MASJID_API_KEY="${MASJID_API_KEY:-}"          # empty = allow-all
export MASJID_HMAC_SECRET="${MASJID_HMAC_SECRET:-}"  # empty = disabled
export MASJID_UPLOAD_DIR="${MASJID_UPLOAD_DIR:-/tmp/masjid_uploads_dev}"

echo "==> Starting Masjid API (dev mode)"
echo "    State file : ${MASJID_STATE_PATH}"
echo "    Upload dir : ${MASJID_UPLOAD_DIR}"
echo "    API key    : ${MASJID_API_KEY:-<none – allow-all>}"
echo ""

venv/bin/python3 -m uvicorn masjid_server:app \
    --host 0.0.0.0 \
    --port 8787 \
    --reload \
    --log-level info
