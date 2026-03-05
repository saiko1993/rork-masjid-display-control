import asyncio
import hashlib
import hmac
import json
import os
import socket
import tempfile
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Optional
from urllib.error import URLError
from urllib.request import urlopen

from fastapi import Depends, FastAPI, File, Header, HTTPException, Request, UploadFile
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles

APP_VERSION = "3.0.0"
START_TS = time.time()

STATE_PATH = Path(os.getenv("MASJID_STATE_PATH", "/home/admin/masjid_state.json"))
UPLOAD_DIR = Path(os.getenv("MASJID_UPLOAD_DIR", "/home/admin/masjid_assets/uploads"))
WEB_DIR = Path(__file__).parent / "web"
ASSETS_DIR = WEB_DIR / "assets"

UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
STATE_PATH.parent.mkdir(parents=True, exist_ok=True)

state_lock = asyncio.Lock()
weather_lock = asyncio.Lock()

app = FastAPI(title="Masjid Raspberry Backend", version=APP_VERSION)
app.mount("/uploads", StaticFiles(directory=str(UPLOAD_DIR)), name="uploads")
app.mount("/assets", StaticFiles(directory=str(ASSETS_DIR)), name="assets")


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def atomic_write_json(path: Path, payload: Dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile("w", dir=str(path.parent), delete=False, encoding="utf-8") as tmp:
        json.dump(payload, tmp, ensure_ascii=False, indent=2)
        tmp.flush()
        os.fsync(tmp.fileno())
        tmp_name = tmp.name
    os.replace(tmp_name, path)


def load_state() -> Dict[str, Any]:
    if not STATE_PATH.exists():
        return {
            "theme": {},
            "sync": {},
            "ticker": {"mode": "default", "customMessage": ""},
            "weather": {"tempC": None, "lastFetchedAt": None},
            "received": {},
        }
    with STATE_PATH.open("r", encoding="utf-8") as f:
        return json.load(f)


def normalize_prayers(sync_payload: Dict[str, Any]) -> list[Dict[str, Any]]:
    prayers_in = sync_payload.get("prayers") or sync_payload.get("prayerTimes") or []
    out = []
    for p in prayers_in:
        out.append(
            {
                "key": p.get("key") or p.get("id") or "",
                "nameAr": p.get("nameAr") or "",
                "nameEn": p.get("nameEn") or "",
                "adhan": p.get("adhan") or p.get("adhanTime") or "",
                "iqama": p.get("iqama") or p.get("iqamaTime") or "",
                "adhanISO": p.get("adhanISO") or p.get("adhanDateTime") or None,
                "iqamaISO": p.get("iqamaISO") or p.get("iqamaDateTime") or None,
                "isJumuah": bool(p.get("isJumuah", False)),
            }
        )
    return out


def build_display_payload(state: Dict[str, Any]) -> Dict[str, Any]:
    sync_payload = state.get("sync", {})
    theme_payload = state.get("theme", {})
    ticker = state.get("ticker", {"mode": "default", "customMessage": ""})

    prayers = normalize_prayers(sync_payload)
    countdown_seconds = sync_payload.get("countdownSeconds")
    if countdown_seconds is None:
        countdown_seconds = 0

    return {
        "city": sync_payload.get("city") or sync_payload.get("location", {}).get("city") or "",
        "language": sync_payload.get("language") or "ar",
        "phase": sync_payload.get("phase") or "idle",
        "nextPrayerKey": sync_payload.get("nextPrayerKey") or "",
        "nextPrayerAr": sync_payload.get("nextPrayerAr") or "",
        "countdownSeconds": countdown_seconds,
        "prayers": prayers,
        "tickerDirection": sync_payload.get("tickerDirection") or "rtl",
        "tickerPaused": bool(sync_payload.get("tickerPaused", False)),
        "tickerMessage": ticker.get("customMessage") or sync_payload.get("tickerMessage") or "",
        "theme": {
            "version": theme_payload.get("version"),
            "themeId": theme_payload.get("themeId"),
            "pushId": theme_payload.get("pushId"),
            "palette": theme_payload.get("palette") or {},
            "gradientStops": theme_payload.get("gradientStops") or [],
            "pattern": theme_payload.get("pattern") or {},
            "vignette": theme_payload.get("vignette") or {},
            "backgroundImageUrl": theme_payload.get("backgroundImageUrl"),
        },
        "tempC": state.get("weather", {}).get("tempC"),
        "received": {
            "theme": state.get("received", {}).get("theme_received_at"),
            "sync": state.get("received", {}).get("sync_received_at"),
        },
    }


def sha256_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def unauthorized(msg: str) -> HTTPException:
    return HTTPException(status_code=401, detail={"error": msg})


@app.exception_handler(HTTPException)
async def http_exception_handler(_: Request, exc: HTTPException):
    detail = exc.detail
    if isinstance(detail, dict) and "error" in detail:
        return JSONResponse(status_code=exc.status_code, content=detail)
    return JSONResponse(status_code=exc.status_code, content={"error": str(detail)})


@app.exception_handler(Exception)
async def unhandled_exception_handler(_: Request, exc: Exception):
    return JSONResponse(status_code=500, content={"error": f"internal_error: {exc}"})


async def verify_auth(
    request: Request,
    x_api_key: Optional[str] = Header(default=None, alias="X-API-Key"),
    x_timestamp: Optional[str] = Header(default=None, alias="X-Timestamp"),
    x_nonce: Optional[str] = Header(default=None, alias="X-Nonce"),
    x_signature: Optional[str] = Header(default=None, alias="X-Signature"),
):
    configured_api_key = os.getenv("MASJID_API_KEY", "")
    if configured_api_key and x_api_key != configured_api_key:
        raise unauthorized("invalid_api_key")
    if not configured_api_key and not x_api_key:
        # local dev allow-all mode
        return

    hmac_secret = os.getenv("MASJID_HMAC_SECRET")
    if not hmac_secret:
        return

    if not x_timestamp or not x_nonce or not x_signature:
        raise unauthorized("missing_hmac_headers")

    body = await request.body()
    canonical = f"{request.method}\n{request.url.path}\n{x_timestamp}\n{x_nonce}\n{sha256_hex(body)}"
    expected = hmac.new(hmac_secret.encode("utf-8"), canonical.encode("utf-8"), hashlib.sha256).hexdigest()
    if not hmac.compare_digest(expected, x_signature.lower()):
        raise unauthorized("invalid_signature")


async def maybe_update_weather(state: Dict[str, Any]) -> Dict[str, Any]:
    sync_payload = state.get("sync", {})
    location = sync_payload.get("location", {})
    lat = location.get("lat") or location.get("latitude")
    lng = location.get("lng") or location.get("longitude")
    if lat is None or lng is None:
        return state

    weather = state.get("weather", {})
    last = weather.get("lastFetchedAt")
    if last:
        try:
            last_ts = datetime.fromisoformat(last).timestamp()
            if time.time() - last_ts < 600:
                return state
        except ValueError:
            pass

    async with weather_lock:
        url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lng}&current=temperature_2m"
        try:
            def fetch():
                with urlopen(url, timeout=5) as res:
                    return json.loads(res.read().decode("utf-8"))

            data = await asyncio.to_thread(fetch)
            temp = data.get("current", {}).get("temperature_2m")
            state.setdefault("weather", {})["tempC"] = temp
            state["weather"]["lastFetchedAt"] = now_iso()
        except (URLError, TimeoutError, json.JSONDecodeError):
            return state

    return state


@app.get("/v1/info", dependencies=[Depends(verify_auth)])
async def info():
    return {
        "status": "ok",
        "version": APP_VERSION,
        "uptime": int(time.time() - START_TS),
        "hostname": socket.gethostname(),
    }


@app.get("/v1/state", dependencies=[Depends(verify_auth)])
async def get_state():
    async with state_lock:
        state = load_state()
    return state


@app.get("/v1/display", dependencies=[Depends(verify_auth)])
async def get_display():
    async with state_lock:
        state = load_state()
        state = await maybe_update_weather(state)
        atomic_write_json(STATE_PATH, state)
    return build_display_payload(state)


@app.post("/v1/theme", dependencies=[Depends(verify_auth)])
async def set_theme(payload: Dict[str, Any]):
    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail={"error": "invalid_json_object"})
    for req in ["version", "themeId", "pushId"]:
        if req not in payload:
            raise HTTPException(status_code=400, detail={"error": f"missing_required_field:{req}"})

    async with state_lock:
        state = load_state()
        state["theme"] = payload
        state.setdefault("received", {})["theme_received_at"] = now_iso()
        atomic_write_json(STATE_PATH, state)
    return {"status": "ok"}


@app.post("/v1/sync", dependencies=[Depends(verify_auth)])
async def set_sync(payload: Dict[str, Any]):
    async with state_lock:
        state = load_state()
        state["sync"] = payload
        state.setdefault("received", {})["sync_received_at"] = now_iso()
        atomic_write_json(STATE_PATH, state)
    return {"status": "ok"}


@app.post("/v1/ticker", dependencies=[Depends(verify_auth)])
async def set_ticker(payload: Dict[str, Any]):
    message = payload.get("message") if isinstance(payload, dict) else None
    if not isinstance(message, str) or not message.strip():
        raise HTTPException(status_code=400, detail={"error": "message_required"})

    async with state_lock:
        state = load_state()
        state.setdefault("ticker", {})["customMessage"] = message
        state["ticker"]["mode"] = "custom"
        atomic_write_json(STATE_PATH, state)
    return {"status": "ok"}


@app.post("/v1/upload-background", dependencies=[Depends(verify_auth)])
async def upload_background(request: Request, file: UploadFile = File(...)):
    allowed_types = {"image/jpeg": ".jpg", "image/png": ".png", "image/webp": ".webp"}
    ext = allowed_types.get(file.content_type)
    if not ext:
        raise HTTPException(status_code=400, detail={"error": "unsupported_file_type"})

    filename = f"bg-{uuid.uuid4().hex}{ext}"
    destination = UPLOAD_DIR / filename
    data = await file.read()
    with destination.open("wb") as f:
        f.write(data)

    host = request.headers.get("host", "localhost:8787")
    return {"url": f"http://{host}/uploads/{filename}"}


@app.post("/v1/audio", dependencies=[Depends(verify_auth)])
async def set_audio(payload: Dict[str, Any]):
    async with state_lock:
        state = load_state()
        state["audio"] = payload
        atomic_write_json(STATE_PATH, state)
    return {"status": "ok"}


@app.post("/v1/power", dependencies=[Depends(verify_auth)])
async def set_power(payload: Dict[str, Any]):
    async with state_lock:
        state = load_state()
        state["power"] = payload
        atomic_write_json(STATE_PATH, state)
    return {"status": "ok"}


@app.post("/v1/ramadan", dependencies=[Depends(verify_auth)])
async def set_ramadan(payload: Dict[str, Any]):
    async with state_lock:
        state = load_state()
        state["ramadan"] = payload
        atomic_write_json(STATE_PATH, state)
    return {"status": "ok"}


@app.post("/v1/quran-program", dependencies=[Depends(verify_auth)])
async def set_quran_program(payload: Dict[str, Any]):
    async with state_lock:
        state = load_state()
        state["quranProgram"] = payload
        atomic_write_json(STATE_PATH, state)
    return {"status": "ok"}


@app.get("/display")
async def display_page():
    return FileResponse(WEB_DIR / "display.html")


@app.get("/healthz")
async def healthz():
    return {"status": "ok"}
