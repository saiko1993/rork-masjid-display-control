# Masjid Display Controller — API Contract

> **Auto-generated from iOS codebase.** This document is the single source-of-truth
> for every HTTP endpoint the iOS app calls on the Raspberry Pi server.

---

## Global Conventions

| Item | Value |
|------|-------|
| Base URL construction | `pushTarget.baseUrl` trimmed of trailing `/` (e.g. `http://masjidclock.local:8787`) |
| Authentication | `X-API-Key` header on **every** request |
| HMAC (optional) | When `useHMAC=true`: adds `X-Timestamp`, `X-Nonce`, `X-Signature` headers (HMAC-SHA256) |
| Content-Type (POST JSON) | `application/json` |
| Content-Type (upload) | `multipart/form-data; boundary=<uuid>` |
| Success range | `200–299` |
| Timeout (ping/info) | 3–5 s |
| Timeout (POST sync) | 10 s |
| Timeout (upload) | 30 s |
| Timeout (diagnostics) | 8 s |
| Retry strategy | Exponential backoff: 2 s → 4 s → 8 s → 16 s → 30 s (max 5 retries for ConnectionManager, 3 for PushService) |

### HMAC Signature Scheme

When HMAC is enabled, the canonical string is:

```
{METHOD}\n{PATH}\n{TIMESTAMP}\n{NONCE}\n{SHA256_HEX(body)}
```

Signed with `HMAC-SHA256` using the shared secret. Headers sent:

| Header | Description |
|--------|-------------|
| `X-API-Key` | API key string |
| `X-Timestamp` | Unix epoch seconds (string) |
| `X-Nonce` | Random UUID string |
| `X-Signature` | Hex-encoded HMAC-SHA256 signature |

---

## Endpoints

### 1. GET /v1/info

**Purpose:** Health check / ping. Used by ConnectionManager (periodic ping every 15–45 s), PreviewView, MirrorModeView, and diagnostics.

| Field | Value |
|-------|-------|
| Method | `GET` |
| Path | `/v1/info` |
| Headers | `X-API-Key` |
| Body | None |
| Timeout | 3–5 s |

**Expected Response:**

```json
{
  "status": "ok",
  "version": "1.0.0",
  "uptime": 123456,
  "hostname": "masjidclock"
}
```

| Status | Meaning |
|--------|---------|
| 200 | Server is healthy |
| 401 | Invalid API key |
| 5xx | Server error |

---

### 2. POST /v1/theme

**Purpose:** Push full theme pack (colors, typography, layout tokens, layer stack, face config, background image URL). Sent on pair, manual push, and pending queue flush.

| Field | Value |
|-------|-------|
| Method | `POST` |
| Path | `/v1/theme` |
| Headers | `Content-Type: application/json`, `X-API-Key` (or HMAC headers) |
| Timeout | 10 s |

**Request Body — `ThemePackPayload`:**

```json
{
  "version": "3.0.0",
  "pushId": "UUID",
  "sentAtISO": "2025-01-15T12:00:00Z",
  "themeId": "islamic-geo-dark",
  "nameAr": "هندسي إسلامي داكن",
  "nameEn": "Islamic Geometric Dark",
  "isDark": true,
  "contrastRatio": 7.5,
  "palette": {
    "background": "#0A0E1A",
    "surface": "#141B2D",
    "primary": "#D4AF37",
    "secondary": "#8B7355",
    "textPrimary": "#FFFFFF",
    "textSecondary": "#B0B0B0",
    "accent": "#D4AF37",
    "adhanGlow": "#FFD700"
  },
  "typography": {
    "timeFontDesign": "default|serif|monospaced|rounded",
    "arabicFontDesign": "default|serif|monospaced|rounded",
    "latinFontDesign": "default|serif|monospaced|rounded",
    "timeWeight": "bold|semibold|medium|heavy|black|light|thin|ultraLight|regular",
    "headingWeight": "bold|semibold|medium|heavy|black|light|thin|ultraLight|regular"
  },
  "tokens": {
    "cornerRadius": 12.0,
    "cardPadding": 16.0,
    "sectionSpacing": 20.0,
    "borderWidth": 1.0,
    "shadowRadius": 8.0,
    "minReadableFontSize": 14.0,
    "safeMargins": 16.0,
    "tableDensity": "compact|comfortable",
    "tickerDirection": "ltr|rtl",
    "minFontScale": 0.8,
    "maxFontScale": 1.5
  },
  "backgroundPattern": "geometric_stars|arabesque|minimal|none|relief_starfield|arch_mosaic|hex_grid|glass_tile|led_matrix|mosque_silhouette",
  "layerStack": {
    "backgroundBase": "#0A0E1A",
    "gradientStops": [
      { "color": "#0A0E1A", "location": 0.0 },
      { "color": "#1A2744", "location": 1.0 }
    ],
    "gradientAngle": 180.0,
    "patternType": "geometric_stars",
    "patternColor": "#D4AF37",
    "patternOpacity": 0.15,
    "vignetteType": "none|radial_dark|radial_light|top_fade|bottom_fade|edge_burn",
    "vignetteIntensity": 0.3,
    "elevationStyle": "flat|raised|inset|floating|glassmorphic|neumorphic",
    "cardBorderColor": "#D4AF37",
    "cardBorderOpacity": 0.2,
    "hasShimmer": false,
    "shimmerSpeed": 3.0,
    "adhanGlowStyle": "pulse|radial_burst|border_glow|shimmer_wave|neon_flicker|soft_breath",
    "adhanGlowColor": "#FFD700",
    "countdownGlowRadius": 20.0,
    "tableRowSeparator": true,
    "tableRowInset": false,
    "tickerBackground": "#1A2744",
    "backgroundImageUrl": "http://masjidclock.local:8787/uploads/bg.jpg",
    "backgroundImageFit": "cover|contain|fill"
  },
  "customOverrides": {
    "backgroundHex": "#112233",
    "surfaceHex": null,
    "primaryHex": null,
    "secondaryHex": null,
    "textPrimaryHex": null,
    "textSecondaryHex": null,
    "accentHex": null,
    "patternOpacity": null,
    "vignetteIntensity": null,
    "backgroundImageUrl": null
  },
  "face": {
    "faceId": "classicSplit",
    "enabledComponents": ["clock", "countdownText", "dateBlock", "footer", "phaseBadge", "prayerTable", "ticker"]
  }
}
```

> `customOverrides` is `null` when no overrides are set.
> `face` is always present.

**Expected Response:**

| Status | Meaning |
|--------|---------|
| 200 | Theme applied successfully |
| 400 | Invalid payload |
| 401 | Unauthorized |
| 404 | Endpoint not implemented |
| 5xx | Server error |

---

### 3. POST /v1/sync

**Purpose:** Lightweight sync of schedule, time, phase, display settings, and all configuration. Sent frequently (debounced 300 ms) on any settings change. This is the primary sync mechanism.

| Field | Value |
|-------|-------|
| Method | `POST` |
| Path | `/v1/sync` |
| Headers | `Content-Type: application/json`, `X-API-Key` (or HMAC headers) |
| Timeout | 10 s |

**Request Body — `LightSyncPayload`:**

```json
{
  "version": "3.0.0",
  "pushId": "UUID",
  "sentAtISO": "2025-01-15T12:00:00Z",
  "nowEpoch": 1705312800,
  "deviceTime": "2025-01-15 12:00:00",
  "tz": "Africa/Cairo",
  "tzOffsetMinutes": 120,
  "schedule": [
    {
      "prayer": "fajr|dhuhr|asr|maghrib|isha|jumuah",
      "adhan": "05:15",
      "adhanISO": "2025-01-15T05:15:00Z",
      "iqama": "05:35",
      "iqamaISO": "2025-01-15T05:35:00Z",
      "isJumuah": false
    }
  ],
  "currentPhase": {
    "phase": "normal|adhan_active|iqama_countdown|prayer_in_progress",
    "currentPrayer": "fajr",
    "nextPrayer": "dhuhr"
  },
  "display": {
    "language": "ar|en",
    "brightness": 80,
    "layout": "wide-v1|compact-v1",
    "showDhikrTicker": true,
    "tickerDirection": "ltr|rtl",
    "pauseTickerDuringAdhan": true,
    "lockLayout": false
  },
  "brightnessSchedule": {
    "enabled": false,
    "dayBrightness": 80,
    "nightBrightness": 30,
    "dayStartHour": 6,
    "nightStartHour": 20
  },
  "calculation": {
    "method": "MWL|UmmAlQura|ISNA|Egyptian|Karachi",
    "madhab": "Shafi|Hanafi",
    "offsetsMinutes": {
      "fajr": 0,
      "dhuhr": 0,
      "asr": 0,
      "maghrib": 0,
      "isha": 0
    }
  },
  "iqama": {
    "enabled": true,
    "mode": "afterAdhan|fixedTime",
    "minutes": {
      "fajr": 20,
      "dhuhr": 15,
      "asr": 15,
      "maghrib": 10,
      "isha": 15
    },
    "iqamaMode": "afterAdhan|fixedTime",
    "fixedTimes": {
      "fajr": "05:30",
      "dhuhr": "13:00",
      "asr": "16:30",
      "maghrib": "18:15",
      "isha": "20:00"
    }
  },
  "jumuah": {
    "enabled": true,
    "jumuahTime": "12:30",
    "jumuahIqamaMinutes": 15,
    "secondJumuahEnabled": false,
    "secondJumuahTime": "13:30"
  },
  "location": {
    "cityName": "Cairo",
    "lat": 30.0444,
    "lng": 31.2357,
    "timezone": "Africa/Cairo"
  },
  "timeFormat": "24h|12h",
  "ticker": {
    "mode": "quran|custom|announcement|off",
    "customMessage": "Welcome to our masjid",
    "pauseDuringAdhan": true,
    "announcements": [
      {
        "id": "UUID",
        "text": "Announcement text",
        "isPinned": false
      }
    ],
    "rotationIntervalMinutes": 5
  },
  "largeMode": false,
  "faceId": "classicSplit",
  "audio": {
    "adhanMode": "adhanOnly|iqamaOnly|both|mute",
    "globalVolume": 80,
    "perPrayerVolume": {
      "fajr": 60,
      "isha": 70
    },
    "preAdhanReminderMinutes": 0,
    "reminderSoundType": "beep|bell|chime|none"
  },
  "dateConfig": {
    "displayMode": "hijri|gregorian|both|rotate",
    "hijriOffsetDays": 0,
    "showGregorian": true,
    "showHijri": true,
    "showWeekdayArabic": true,
    "showWeekdayEnglish": false
  },
  "power": {
    "screenOffEnabled": false,
    "screenOffFromHour": 23,
    "screenOffToHour": 4,
    "autoWakeBeforeFajrMinutes": 15
  },
  "ramadan": {
    "ishaMode": "normal|afterMaghribMinutes|fixedTimeInRamadan",
    "ishaAfterMaghribMinutes": 90,
    "ishaFixedTime": "21:00",
    "autoDetect": true,
    "isCurrentlyRamadan": false
  },
  "quranProgram": {
    "enabled": true,
    "khatmaMode": "juzDaily|hizbDaily|surah",
    "playbackMode": "once|continuous|repeat",
    "reciterId": "mishari",
    "reciterName": "Mishari Rashid",
    "dailyStartTime": "04:30",
    "currentDay": 1
  },
  "prayerEnabled": {
    "fajr": true,
    "dhuhr": true,
    "asr": true,
    "maghrib": true,
    "isha": true
  },
  "activeProfile": "normal|ramadan|summer|winter"
}
```

> Nullable fields: `currentPhase.currentPrayer`, `currentPhase.nextPrayer`, `schedule[].iqama`, `schedule[].iqamaISO`, `calculation`, `iqama`, `jumuah`, `ticker.announcements`, `audio`, `audio.perPrayerVolume`, `dateConfig`, `power`, `ramadan`, `quranProgram`, `prayerEnabled`, `activeProfile`, `iqama.fixedTimes`, `iqama.iqamaMode`.

**Expected Response:**

| Status | Meaning |
|--------|---------|
| 200 | Sync accepted |
| 400 | Invalid payload |
| 401 | Unauthorized |
| 5xx | Server error |

---

### 4. POST /v1/ticker

**Purpose:** Push a standalone ticker message (quick broadcast). Used by `ConnectionManager.sendTickerMessage()`.

| Field | Value |
|-------|-------|
| Method | `POST` |
| Path | `/v1/ticker` |
| Headers | `Content-Type: application/json`, `X-API-Key` (or HMAC headers) |
| Timeout | 10 s |

**Request Body:**

```json
{
  "message": "Important announcement text"
}
```

**Expected Response:**

| Status | Meaning |
|--------|---------|
| 200 | Message accepted |
| 401 | Unauthorized |
| 5xx | Server error |

---

### 5. POST /v1/upload-background

**Purpose:** Upload a background image (JPEG). Returns a URL the server hosts for the display to load.

| Field | Value |
|-------|-------|
| Method | `POST` |
| Path | `/v1/upload-background` |
| Headers | `Content-Type: multipart/form-data; boundary=<uuid>`, `X-API-Key` |
| Timeout | 30 s |

**Request Body (multipart):**

| Part | Field name | Content-Type | Description |
|------|------------|-------------|-------------|
| File | `file` | `image/jpeg` | JPEG image data. Filename included in Content-Disposition. |

**Expected Response:**

```json
{
  "url": "http://masjidclock.local:8787/uploads/bg-12345.jpg"
}
```

| Status | Meaning |
|--------|---------|
| 200 | Upload successful, `url` field returned |
| 401 | Unauthorized |
| 413 | File too large |
| 5xx | Server error |

---

### 6. POST /v1/audio

**Purpose:** Push audio configuration. Referenced in diagnostics endpoint list.

| Field | Value |
|-------|-------|
| Method | `POST` |
| Path | `/v1/audio` |
| Headers | `Content-Type: application/json`, `X-API-Key` (or HMAC headers) |
| Timeout | 10 s |

**Request Body — `AudioSyncPayload`:**

```json
{
  "adhanMode": "adhanOnly|iqamaOnly|both|mute",
  "globalVolume": 80,
  "perPrayerVolume": { "fajr": 60, "isha": 70 },
  "preAdhanReminderMinutes": 5,
  "reminderSoundType": "beep|bell|chime|none"
}
```

**Expected Response:**

| Status | Meaning |
|--------|---------|
| 200 | Audio config applied |
| 401 | Unauthorized |
| 404 | Not implemented |
| 5xx | Server error |

---

### 7. POST /v1/power

**Purpose:** Push power/screen schedule. Referenced in diagnostics endpoint list.

| Field | Value |
|-------|-------|
| Method | `POST` |
| Path | `/v1/power` |
| Headers | `Content-Type: application/json`, `X-API-Key` (or HMAC headers) |
| Timeout | 10 s |

**Request Body — `PowerSyncPayload`:**

```json
{
  "screenOffEnabled": false,
  "screenOffFromHour": 23,
  "screenOffToHour": 4,
  "autoWakeBeforeFajrMinutes": 15
}
```

**Expected Response:**

| Status | Meaning |
|--------|---------|
| 200 | Power config applied |
| 401 | Unauthorized |
| 404 | Not implemented |
| 5xx | Server error |

---

### 8. POST /v1/ramadan

**Purpose:** Push Ramadan-specific configuration. Referenced in diagnostics endpoint list.

| Field | Value |
|-------|-------|
| Method | `POST` |
| Path | `/v1/ramadan` |
| Headers | `Content-Type: application/json`, `X-API-Key` (or HMAC headers) |
| Timeout | 10 s |

**Request Body — `RamadanSyncPayload`:**

```json
{
  "ishaMode": "normal|afterMaghribMinutes|fixedTimeInRamadan",
  "ishaAfterMaghribMinutes": 90,
  "ishaFixedTime": "21:00",
  "autoDetect": true,
  "isCurrentlyRamadan": false
}
```

**Expected Response:**

| Status | Meaning |
|--------|---------|
| 200 | Ramadan config applied |
| 401 | Unauthorized |
| 404 | Not implemented |
| 5xx | Server error |

---

### 9. POST /v1/quran-program

**Purpose:** Push Quran program configuration. Referenced in diagnostics endpoint list.

| Field | Value |
|-------|-------|
| Method | `POST` |
| Path | `/v1/quran-program` |
| Headers | `Content-Type: application/json`, `X-API-Key` (or HMAC headers) |
| Timeout | 10 s |

**Request Body — `QuranProgramSyncPayload`:**

```json
{
  "enabled": true,
  "khatmaMode": "juzDaily|hizbDaily|surah",
  "playbackMode": "once|continuous|repeat",
  "reciterId": "mishari",
  "reciterName": "Mishari Rashid",
  "dailyStartTime": "04:30",
  "currentDay": 1
}
```

**Expected Response:**

| Status | Meaning |
|--------|---------|
| 200 | Quran program config applied |
| 401 | Unauthorized |
| 404 | Not implemented |
| 5xx | Server error |

---

### 10. GET /v1/state

**Purpose:** Retrieve current server state. Used in diagnostics only.

| Field | Value |
|-------|-------|
| Method | `GET` |
| Path | `/v1/state` |
| Headers | `X-API-Key` |
| Body | None |
| Timeout | 8 s |

**Expected Response:**

```json
{
  "currentPhase": "normal",
  "currentPrayer": "dhuhr",
  "nextPrayer": "asr",
  "brightness": 80,
  "screenOn": true,
  "lastSyncAt": "2025-01-15T12:00:00Z",
  "themeId": "islamic-geo-dark"
}
```

| Status | Meaning |
|--------|---------|
| 200 | State returned |
| 401 | Unauthorized |
| 404 | Not implemented |
| 5xx | Server error |

---

### 11. GET /display

**Purpose:** Serve the HTML display page (rendered by the Raspberry Pi browser in kiosk mode). Used in diagnostics, PreviewView (WebView), and MirrorModeView.

| Field | Value |
|-------|-------|
| Method | `GET` |
| Path | `/display` |
| Headers | `X-API-Key` (optional for browser) |
| Body | None |

**Expected Response:**

| Status | Meaning |
|--------|---------|
| 200 | HTML page returned |
| 404 | Not implemented |
| 5xx | Server error |

---

## BLE Transport (Bluetooth Low Energy)

The app also supports BLE as an alternative transport. Same payloads are sent over BLE characteristics.

| UUID | Purpose |
|------|---------|
| Service: `9B2F6A6E-2C3A-4C6D-9E5F-2A7B1E0C8D11` | Masjid Display service |
| Characteristic: `6D1C2A8B-7F7C-4B53-9D3B-10C78E8A4F01` | Theme pack write |
| Characteristic: `3A91A0C4-1E1F-4D5A-8A2F-5D2B6E7C9012` | Light sync write |
| Characteristic: `0E6F1D2C-3B4A-4C5D-8E9F-1A2B3C4D5E6F` | ACK notification |

Data is chunked by MTU size with retry logic.

---

## Enum Value References

### ThemeId values
`islamic-geo-dark`, `ottoman-classic`, `minimal-noor`, `led-mosque`, `islamic-relief`, `ottoman-gold-night`, `modern-arch-depth`, `smart-glass`, `led-digital-premium`, `sky-silhouette`

### BackgroundPattern values
`geometric_stars`, `arabesque`, `minimal`, `none`, `relief_starfield`, `arch_mosaic`, `hex_grid`, `glass_tile`, `led_matrix`, `mosque_silhouette`

### VignetteType values
`none`, `radial_dark`, `radial_light`, `top_fade`, `bottom_fade`, `edge_burn`

### ElevationStyle values
`flat`, `raised`, `inset`, `floating`, `glassmorphic`, `neumorphic`

### GlowStyle values
`pulse`, `radial_burst`, `border_glow`, `shimmer_wave`, `neon_flicker`, `soft_breath`

### PrayerPhase values
`normal`, `adhan_active`, `iqama_countdown`, `prayer_in_progress`

### SettingsProfile values
`normal`, `ramadan`, `summer`, `winter`

### TimeFormat values
`24h`, `12h`
