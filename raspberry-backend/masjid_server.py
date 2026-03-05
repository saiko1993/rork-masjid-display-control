"""
Masjid Display – Raspberry Pi Backend
API version: 3.0.0

Environment variables
---------------------
MASJID_STATE_PATH   – path to the persisted state JSON file
                       (default: /home/admin/masjid_state.json)
MASJID_API_KEY      – required X-API-Key header value
                       (default: "" → allow-all for local dev)
MASJID_HMAC_SECRET  – if set, every request must carry HMAC headers
MASJID_UPLOAD_DIR   – directory for uploaded background images
                       (default: /home/admin/masjid_assets/uploads)
MASJID_HOST         – host/IP used in upload URL responses
                       (default: auto-detected from request)
"""

import asyncio
import hashlib
import hmac
import json
import logging
import os
import socket
import time
import uuid
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Optional

import aiofiles
from fastapi import Depends, FastAPI, File, HTTPException, Request, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

STATE_PATH = Path(os.environ.get("MASJID_STATE_PATH", "/home/admin/masjid_state.json"))
UPLOAD_DIR = Path(os.environ.get("MASJID_UPLOAD_DIR", "/home/admin/masjid_assets/uploads"))
API_KEY = os.environ.get("MASJID_API_KEY", "")
HMAC_SECRET = os.environ.get("MASJID_HMAC_SECRET", "")
API_VERSION = "3.0.0"

# Allowed image MIME types for background uploads
ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp"}

# Directory containing this file – used to locate web/ assets
BASE_DIR = Path(__file__).parent

START_TIME = time.time()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)
logger = logging.getLogger("masjid")

# ---------------------------------------------------------------------------
# State persistence
# ---------------------------------------------------------------------------

_state_lock = asyncio.Lock()


def _default_state() -> dict:
    return {
        "theme": None,
        "theme_received_at": None,
        "sync": None,
        "sync_received_at": None,
        "ticker": {"mode": "dhikr", "customMessage": "", "pauseDuringAdhan": True},
        "weather": {"tempC": None, "fetchedAt": None},
        "audio": None,
        "power": None,
        "ramadan": None,
        "quran_program": None,
    }


async def load_state() -> dict:
    try:
        async with aiofiles.open(STATE_PATH, "r", encoding="utf-8") as f:
            data = await f.read()
        return json.loads(data)
    except (FileNotFoundError, json.JSONDecodeError):
        return _default_state()


async def save_state(state: dict) -> None:
    STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    tmp = STATE_PATH.with_suffix(".tmp")
    async with aiofiles.open(tmp, "w", encoding="utf-8") as f:
        await f.write(json.dumps(state, ensure_ascii=False, indent=2))
    tmp.replace(STATE_PATH)


async def get_state() -> dict:
    async with _state_lock:
        return await load_state()


async def update_state(updates: dict) -> dict:
    async with _state_lock:
        state = await load_state()
        state.update(updates)
        await save_state(state)
        return state


# ---------------------------------------------------------------------------
# Weather background task
# ---------------------------------------------------------------------------

_weather_task: Optional[asyncio.Task] = None


async def _weather_loop() -> None:
    """Fetch temperature from Open-Meteo every 10 minutes using sync.location."""
    try:
        import httpx
    except ImportError:
        logger.warning("httpx not installed; weather updates disabled")
        return

    while True:
        try:
            state = await get_state()
            sync = state.get("sync") or {}
            location = sync.get("location") or {}
            lat = location.get("lat")
            lng = location.get("lng")
            if lat is not None and lng is not None:
                url = (
                    f"https://api.open-meteo.com/v1/forecast"
                    f"?latitude={lat}&longitude={lng}"
                    f"&current_weather=true"
                )
                async with httpx.AsyncClient(timeout=10) as client:
                    resp = await client.get(url)
                    if resp.status_code == 200:
                        data = resp.json()
                        temp = data.get("current_weather", {}).get("temperature")
                        await update_state(
                            {"weather": {"tempC": temp, "fetchedAt": time.time()}}
                        )
                        logger.info("Weather updated: %s°C", temp)
        except Exception as exc:
            logger.warning("Weather fetch failed: %s", exc)
        await asyncio.sleep(600)


# ---------------------------------------------------------------------------
# FastAPI application lifecycle
# ---------------------------------------------------------------------------

@asynccontextmanager
async def lifespan(app: FastAPI):
    global _weather_task
    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
    if not STATE_PATH.exists():
        await save_state(_default_state())
    _weather_task = asyncio.create_task(_weather_loop())
    yield
    if _weather_task:
        _weather_task.cancel()


app = FastAPI(title="Masjid Display API", version=API_VERSION, lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Ensure upload directory exists before mounting (StaticFiles requires it at startup)
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

# Serve uploaded backgrounds at /uploads/*
app.mount("/uploads", StaticFiles(directory=str(UPLOAD_DIR)), name="uploads")

# Serve web assets at /assets/*
app.mount(
    "/assets",
    StaticFiles(directory=str(BASE_DIR / "web" / "assets")),
    name="assets",
)

# ---------------------------------------------------------------------------
# Authentication middleware helpers
# ---------------------------------------------------------------------------

HMAC_TIMESTAMP_TOLERANCE = 300  # seconds


def _verify_api_key(request: Request) -> None:
    if not API_KEY:
        return
    key = request.headers.get("X-API-Key", "")
    if key != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid or missing X-API-Key")


async def _verify_hmac(request: Request, body: bytes) -> None:
    if not HMAC_SECRET:
        return
    ts_str = request.headers.get("X-Timestamp", "")
    nonce = request.headers.get("X-Nonce", "")
    sig = request.headers.get("X-Signature", "")
    if not (ts_str and nonce and sig):
        raise HTTPException(
            status_code=401, detail="Missing HMAC headers (X-Timestamp, X-Nonce, X-Signature)"
        )
    try:
        ts = int(ts_str)
    except ValueError:
        raise HTTPException(status_code=401, detail="Invalid X-Timestamp")
    if abs(time.time() - ts) > HMAC_TIMESTAMP_TOLERANCE:
        raise HTTPException(status_code=401, detail="Request timestamp out of tolerance")

    body_hash = hashlib.sha256(body).hexdigest()
    canonical = f"{request.method}\n{request.url.path}\n{ts_str}\n{nonce}\n{body_hash}"
    expected = hmac.new(
        HMAC_SECRET.encode(),
        canonical.encode(),
        hashlib.sha256,
    ).hexdigest()
    if not hmac.compare_digest(expected, sig):
        raise HTTPException(status_code=401, detail="HMAC signature mismatch")


async def auth(request: Request) -> None:
    _verify_api_key(request)
    if HMAC_SECRET:
        body = await request.body()
        await _verify_hmac(request, body)


# ---------------------------------------------------------------------------
# Helper: build display-ready payload
# ---------------------------------------------------------------------------

def _build_display(state: dict) -> dict:
    sync = state.get("sync") or {}
    theme = state.get("theme") or {}
    ticker_state = state.get("ticker") or {}
    weather = state.get("weather") or {}

    schedule = sync.get("schedule") or []
    phase_info = sync.get("currentPhase") or {}
    location = sync.get("location") or {}
    display_cfg = sync.get("display") or {}

    city = location.get("cityName", "")
    language = display_cfg.get("language", "ar")
    phase = phase_info.get("phase", "normal")
    next_prayer_key = phase_info.get("nextPrayer") or (schedule[0]["prayer"] if schedule else None)

    prayer_names_ar = {
        "fajr": "الفجر",
        "dhuhr": "الظهر",
        "asr": "العصر",
        "maghrib": "المغرب",
        "isha": "العشاء",
        "jumuah": "الجمعة",
    }
    next_prayer_ar = prayer_names_ar.get(next_prayer_key, "") if next_prayer_key else ""

    # Compute countdown to next prayer
    countdown_seconds: Optional[int] = None
    now_epoch = int(time.time())
    for entry in schedule:
        try:
            # adhanISO is in ISO 8601 format
            adhan_iso = entry.get("adhanISO", "")
            dt = datetime.fromisoformat(adhan_iso.replace("Z", "+00:00"))
            epoch = int(dt.timestamp())
            if epoch > now_epoch:
                countdown_seconds = epoch - now_epoch
                break
        except Exception:
            pass

    prayers_out = []
    for entry in schedule:
        key = entry.get("prayer", "")
        prayers_out.append(
            {
                "key": key,
                "nameAr": prayer_names_ar.get(key, key),
                "nameEn": key.capitalize(),
                "adhan": entry.get("adhan", ""),
                "iqama": entry.get("iqama"),
                "adhanISO": entry.get("adhanISO", ""),
                "iqamaISO": entry.get("iqamaISO"),
                "isJumuah": entry.get("isJumuah", False),
            }
        )

    ticker_direction = display_cfg.get("tickerDirection", "rtl")
    ticker_paused = display_cfg.get("pauseTickerDuringAdhan", True)

    return {
        "city": city,
        "language": language,
        "phase": phase,
        "nextPrayerKey": next_prayer_key,
        "nextPrayerAr": next_prayer_ar,
        "countdownSeconds": countdown_seconds,
        "prayers": prayers_out,
        "tickerDirection": ticker_direction,
        "tickerPaused": ticker_paused,
        "ticker": ticker_state,
        "theme": theme,
        "tempC": weather.get("tempC"),
        "themeReceivedAt": state.get("theme_received_at"),
        "syncReceivedAt": state.get("sync_received_at"),
    }


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------

@app.get("/v1/info")
async def info(_: None = Depends(auth)):
    return {
        "status": "ok",
        "version": API_VERSION,
        "uptime": round(time.time() - START_TIME, 1),
        "hostname": socket.gethostname(),
    }


@app.get("/v1/state")
async def get_state_endpoint(_: None = Depends(auth)):
    return await get_state()


@app.get("/v1/display")
async def display_endpoint(_: None = Depends(auth)):
    state = await get_state()
    return _build_display(state)


@app.post("/v1/theme")
async def post_theme(request: Request, _: None = Depends(auth)):
    try:
        payload = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON body")
    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="Body must be a JSON object")
    for required in ("version", "themeId", "pushId"):
        if required not in payload:
            raise HTTPException(
                status_code=422, detail=f"Missing required field: {required}"
            )
    await update_state(
        {
            "theme": payload,
            "theme_received_at": time.time(),
        }
    )
    return {"status": "ok", "pushId": payload.get("pushId")}


@app.post("/v1/sync")
async def post_sync(request: Request, _: None = Depends(auth)):
    try:
        payload = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON body")
    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="Body must be a JSON object")
    await update_state(
        {
            "sync": payload,
            "sync_received_at": time.time(),
        }
    )
    return {"status": "ok", "pushId": payload.get("pushId")}


@app.post("/v1/ticker")
async def post_ticker(request: Request, _: None = Depends(auth)):
    try:
        payload = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON body")
    message = payload.get("message", "")
    state = await get_state()
    ticker = dict(state.get("ticker") or {})
    ticker["customMessage"] = message
    ticker["mode"] = "custom"
    await update_state({"ticker": ticker})
    return {"status": "ok"}


@app.post("/v1/upload-background")
async def upload_background(
    request: Request,
    file: UploadFile = File(...),
    _: None = Depends(auth),
):
    content_type = file.content_type or ""
    if content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(
            status_code=415,
            detail=f"Unsupported media type: {content_type}. Allowed: jpeg, png, webp",
        )

    ext_map = {
        "image/jpeg": ".jpg",
        "image/png": ".png",
        "image/webp": ".webp",
    }
    ext = ext_map.get(content_type, ".bin")
    filename = f"{uuid.uuid4().hex}{ext}"
    dest = UPLOAD_DIR / filename

    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
    async with aiofiles.open(dest, "wb") as f:
        while chunk := await file.read(1024 * 256):
            await f.write(chunk)

    # Build URL from the incoming request's base URL
    base = str(request.base_url).rstrip("/")
    url = f"{base}/uploads/{filename}"
    return {"url": url, "filename": filename}


@app.get("/display")
async def serve_display():
    html_path = BASE_DIR / "web" / "display.html"
    if not html_path.exists():
        raise HTTPException(status_code=404, detail="display.html not found")
    return FileResponse(str(html_path), media_type="text/html")


# ---------------------------------------------------------------------------
# Phase 2 stubs
# ---------------------------------------------------------------------------

@app.post("/v1/audio")
async def post_audio(request: Request, _: None = Depends(auth)):
    try:
        payload = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON body")
    await update_state({"audio": payload})
    return {"status": "ok"}


@app.post("/v1/power")
async def post_power(request: Request, _: None = Depends(auth)):
    try:
        payload = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON body")
    await update_state({"power": payload})
    return {"status": "ok"}


@app.post("/v1/ramadan")
async def post_ramadan(request: Request, _: None = Depends(auth)):
    try:
        payload = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON body")
    await update_state({"ramadan": payload})
    return {"status": "ok"}


@app.post("/v1/quran-program")
async def post_quran_program(request: Request, _: None = Depends(auth)):
    try:
        payload = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON body")
    await update_state({"quran_program": payload})
    return {"status": "ok"}
