#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

export MASJID_API_KEY="${MASJID_API_KEY:-dev-key}"
export MASJID_STATE_PATH="${MASJID_STATE_PATH:-$ROOT_DIR/storage/dev_state.json}"
export MASJID_UPLOAD_DIR="${MASJID_UPLOAD_DIR:-$ROOT_DIR/storage/uploads}"
mkdir -p "$(dirname "$MASJID_STATE_PATH")" "$MASJID_UPLOAD_DIR"

python3 -m uvicorn masjid_server:app --host 0.0.0.0 --port 8787 --reload
