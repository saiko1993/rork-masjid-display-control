# Raspberry Pi Masjid Backend (API v3.0.0)

Production-ready FastAPI backend for the Masjid Display controller on Raspberry Pi.

## Features
- Implements core iOS API contract endpoints for `apiVersion: 3.0.0`.
- Disk-persisted state (`MASJID_STATE_PATH`, default `/home/admin/masjid_state.json`).
- Atomic writes (temp-file + rename) with in-process async lock.
- API key auth (`X-API-Key`) and optional request HMAC verification.
- Kiosk display page at `/display` with auto-refresh every 1.5 seconds.
- Background image upload endpoint + static `/uploads/*` serving.
- Optional weather (`Open-Meteo`) cached every 10 minutes.
- systemd service unit included.

## Folder Layout
```
raspberry-backend/
  README.md
  requirements.txt
  masjid_server.py
  systemd/masjid-api.service
  storage/
  web/
  scripts/
```

## Requirements
- Python 3.9+
- Raspberry Pi OS (or Linux with systemd)

> إذا فشل `pip` بسبب proxy/network restrictions في بيئة معيّنة، استخدم `apt` للحزم المتاحة أو اضبط إعدادات الـ proxy ثم أعد المحاولة.

## Local Development
```bash
cd raspberry-backend
python3 -m pip install -r requirements.txt
./scripts/run-dev.sh
```

Default local dev config in `run-dev.sh`:
- `MASJID_API_KEY=dev-key`
- `MASJID_STATE_PATH=raspberry-backend/storage/dev_state.json`
- `MASJID_UPLOAD_DIR=raspberry-backend/storage/uploads`

Then open:
- API info: `http://<pi-ip>:8787/v1/info`
- Display page: `http://<pi-ip>:8787/display`

## Environment Variables
- `MASJID_API_KEY`: required API key for all requests. If empty, server allows requests without key (local dev convenience).
- `MASJID_HMAC_SECRET`: if set, HMAC headers are required (`X-Timestamp`, `X-Nonce`, `X-Signature`).
- `MASJID_STATE_PATH`: JSON state path (default `/home/admin/masjid_state.json`).
- `MASJID_UPLOAD_DIR`: upload directory (default `/home/admin/masjid_assets/uploads`).

## Auth
### API key
Include in every request:
```http
X-API-Key: <your-key>
```

### Optional HMAC
When `MASJID_HMAC_SECRET` is set, each request must include:
- `X-Timestamp`
- `X-Nonce`
- `X-Signature` (hex)

Canonical string:
```
{METHOD}\n{PATH}\n{TIMESTAMP}\n{NONCE}\n{SHA256_HEX(body)}
```

## API Endpoints
- `GET /v1/info`
- `GET /v1/state`
- `GET /v1/display`
- `POST /v1/theme`
- `POST /v1/sync`
- `POST /v1/ticker`
- `POST /v1/upload-background`
- `POST /v1/audio` (phase-2 storage endpoint)
- `POST /v1/power` (phase-2 storage endpoint)
- `POST /v1/ramadan` (phase-2 storage endpoint)
- `POST /v1/quran-program` (phase-2 storage endpoint)
- `GET /display`

## Install on Raspberry Pi (systemd)
From repo root:
```bash
cd raspberry-backend
./scripts/install.sh
```

This will:
1. Install Python dependencies.
2. Create upload directory.
3. Install `/etc/systemd/system/masjid-api.service`.
4. Enable and restart service.

### Service management
```bash
sudo systemctl status masjid-api.service
sudo systemctl restart masjid-api.service
sudo systemctl stop masjid-api.service
journalctl -u masjid-api.service -f
```

### Set secure API key/HMAC for service
Create an override:
```bash
sudo systemctl edit masjid-api.service
```
Add:
```ini
[Service]
Environment=MASJID_API_KEY=your-strong-key
Environment=MASJID_HMAC_SECRET=your-strong-secret
```
Then:
```bash
sudo systemctl daemon-reload
sudo systemctl restart masjid-api.service
```

## Kiosk Mode
Chromium fullscreen kiosk on Pi:
```bash
chromium-browser --kiosk --incognito --disable-pinch --overscroll-history-navigation=0 http://127.0.0.1:8787/display
```

## API Smoke Test
```bash
cd raspberry-backend
MASJID_API_KEY=dev-key ./scripts/test-api.sh
```
