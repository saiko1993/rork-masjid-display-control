# Masjid Display – Raspberry Pi Backend

A production-ready FastAPI server that implements the **Masjid Display API v3.0.0**.  
It stores state on disk, serves a kiosk HTML display page, and runs as a `systemd` service.

---

## Table of Contents

1. [Requirements](#requirements)
2. [Setup on Raspberry Pi](#setup-on-raspberry-pi)
3. [Environment Variables](#environment-variables)
4. [Starting / Stopping the Service](#starting--stopping-the-service)
5. [API Endpoints](#api-endpoints)
6. [Kiosk Mode](#kiosk-mode)
7. [Development (local)](#development-local)
8. [Running API Smoke Tests](#running-api-smoke-tests)
9. [Directory Structure](#directory-structure)

---

## Requirements

- Raspberry Pi running **Raspberry Pi OS** (Bullseye or later, 64-bit recommended)  
- Python **3.9+** (ships with Pi OS)
- Network connection (LAN or Wi-Fi)

> **Tip — pip behind a proxy or corporate network:**  
> If `pip install` fails due to proxy restrictions, either configure the proxy
> (`pip install --proxy http://proxy.example.com:8080 -r requirements.txt`) or
> install the system packages directly with `apt`:
> ```bash
> sudo apt-get install python3-fastapi python3-uvicorn python3-aiofiles
> ```

---

## Setup on Raspberry Pi

```bash
# 1. Clone or copy the repo to the Pi
git clone https://github.com/saiko1993/rork-masjid-display-control.git \
    /home/admin/masjid-display-control
cd /home/admin/masjid-display-control

# 2. Run the installer (requires sudo)
sudo bash raspberry-backend/scripts/install.sh
```

The installer will:

1. Install `python3-venv` (via `apt`).
2. Create a Python virtual environment at `/home/admin/masjid-display-control/venv`.
3. Install all dependencies from `requirements.txt`.
4. Create the upload directory `/home/admin/masjid_assets/uploads`.
5. Write an environment-variable template to `/etc/masjid/masjid.env`.
6. Install and enable the `masjid-api.service` systemd unit.

---

## Environment Variables

Edit `/etc/masjid/masjid.env` on the Raspberry Pi:

| Variable | Default | Description |
|---|---|---|
| `MASJID_API_KEY` | `""` (allow-all) | Required `X-API-Key` header value. **Set this in production.** |
| `MASJID_HMAC_SECRET` | `""` (disabled) | If set, every request must carry HMAC signature headers (`X-Timestamp`, `X-Nonce`, `X-Signature`). |
| `MASJID_STATE_PATH` | `/home/admin/masjid_state.json` | Path to the persisted state JSON file. |
| `MASJID_UPLOAD_DIR` | `/home/admin/masjid_assets/uploads` | Directory for uploaded background images. |

### HMAC signature scheme

When `MASJID_HMAC_SECRET` is set the canonical string to sign is:

```
{METHOD}\n{PATH}\n{TIMESTAMP}\n{NONCE}\n{SHA256_HEX(body)}
```

Signed with HMAC-SHA256. The iOS app (`HMACHelper.swift`) already produces compatible headers.

---

## Starting / Stopping the Service

```bash
# Start
sudo systemctl start masjid-api

# Stop
sudo systemctl stop masjid-api

# Restart
sudo systemctl restart masjid-api

# View live logs
sudo journalctl -u masjid-api -f

# Check status
sudo systemctl status masjid-api
```

The service auto-starts on boot after `network-online.target`.

---

## API Endpoints

All endpoints (except `GET /display`) require the `X-API-Key` header when  
`MASJID_API_KEY` is set.

| Method | Path | Description |
|---|---|---|
| `GET` | `/v1/info` | Server status, version, uptime, hostname |
| `GET` | `/v1/state` | Raw persisted state JSON |
| `GET` | `/v1/display` | Normalised display-ready payload |
| `POST` | `/v1/theme` | Accept `ThemePackPayload` (v3.0.0) |
| `POST` | `/v1/sync` | Accept `LightSyncPayload` (v3.0.0) |
| `POST` | `/v1/ticker` | Set custom ticker message `{"message":"..."}` |
| `POST` | `/v1/upload-background` | Upload JPEG/PNG/WEBP background image |
| `GET` | `/display` | Kiosk HTML page |
| `POST` | `/v1/audio` | Store audio config (Phase 2 stub) |
| `POST` | `/v1/power` | Store power config (Phase 2 stub) |
| `POST` | `/v1/ramadan` | Store Ramadan config (Phase 2 stub) |
| `POST` | `/v1/quran-program` | Store Quran program config (Phase 2 stub) |

Static files are served at:

- `/uploads/<filename>` – uploaded background images
- `/assets/focusRing.css`, `/assets/focusRing.js` – display web assets

---

## Kiosk Mode

Open **Chromium** in kiosk mode on the Pi's desktop:

```bash
chromium-browser \
    --kiosk \
    --noerrdialogs \
    --disable-infobars \
    --check-for-update-interval=31536000 \
    http://localhost:8787/display
```

Or add this command to `/etc/xdg/lxsession/LXDE-pi/autostart` so it launches automatically on boot.

For a headless Pi with a dedicated HDMI display you can use `cage` (a Wayland kiosk compositor):

```bash
sudo apt-get install cage
cage chromium-browser --kiosk http://localhost:8787/display
```

---

## Development (local)

```bash
cd raspberry-backend
bash scripts/run-dev.sh
```

This creates a local `.venv`, installs dependencies, and starts the server with  
`--reload` (auto-restarts on code changes).  
State is saved to `/tmp/masjid_state_dev.json` and uploads go to `/tmp/masjid_uploads_dev`.

---

## Running API Smoke Tests

With the server running:

```bash
# No auth (dev mode)
bash raspberry-backend/scripts/test-api.sh

# With API key
MASJID_API_KEY=my-secret bash raspberry-backend/scripts/test-api.sh

# Against a remote Pi
BASE_URL=http://192.168.1.42:8787 MASJID_API_KEY=my-secret \
    bash raspberry-backend/scripts/test-api.sh
```

---

## Directory Structure

```
raspberry-backend/
├── masjid_server.py          # FastAPI application
├── requirements.txt          # Python dependencies
├── README.md                 # This file
├── storage/
│   └── .gitkeep              # Placeholder (state file lives outside repo)
├── web/
│   ├── display.html          # Kiosk display page
│   └── assets/
│       ├── focusRing.css     # Next-prayer row & phase badge highlight
│       └── focusRing.js      # Focus-ring logic
├── systemd/
│   └── masjid-api.service    # systemd unit file
└── scripts/
    ├── install.sh            # One-shot installer for Raspberry Pi
    ├── run-dev.sh            # Local development runner
    └── test-api.sh           # curl-based smoke tests
```
