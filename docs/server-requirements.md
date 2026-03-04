# Masjid Display Controller — Server Requirements

> What the Raspberry Pi backend must implement to work with the iOS app.

---

## MVP Endpoints (Phase 1 — Must Implement)

These endpoints are required for the app to pair, sync, and display correctly.

| # | Method | Path | Purpose | Blocking for Pair? |
|---|--------|------|---------|-------------------|
| 1 | `GET` | `/v1/info` | Health check / ping. App polls this every 15–45 s. Must return 200 for the app to consider the server "connected". | **YES** |
| 2 | `POST` | `/v1/theme` | Receives full theme pack (colors, typography, tokens, layer stack, face config). Sent on pair and theme changes. | **YES** |
| 3 | `POST` | `/v1/sync` | Receives light sync (schedule, time, phase, all settings). Sent on pair and every settings change (debounced 300 ms). | **YES** |
| 4 | `POST` | `/v1/ticker` | Receives standalone ticker/broadcast message. | No |
| 5 | `POST` | `/v1/upload-background` | Receives multipart JPEG upload. Must return `{ "url": "..." }` with a URL the display can load. | No |
| 6 | `GET` | `/display` | Serves the HTML display page for the kiosk browser and app's WebView preview. | No |

### Pairing Flow

The app's **Pair Device** action does this in order:

1. `GET /v1/info` — verify server is reachable
2. `POST /v1/theme` — push full theme pack
3. `POST /v1/sync` — push full light sync

If any of these fail, pairing fails. All three must return `200`.

### Ongoing Sync

After pairing, the app sends `POST /v1/sync` on every settings change (debounced). The server should:

1. Accept and store the payload
2. Update the display page accordingly
3. Return `200`

### Authentication

Every request includes `X-API-Key` header. The server must:

1. Check the header exists
2. Compare against the configured API key
3. Return `401` if invalid

Optional HMAC support: when enabled, the app sends `X-Timestamp`, `X-Nonce`, `X-Signature` headers. See `docs/api-contract.md` for the signature scheme.

---

## Phase 2 Endpoints (Optional — Implement Later)

These endpoints appear in the diagnostics test suite but are **not called during normal app operation**. Audio, power, ramadan, and quran configs are already included in the `/v1/sync` payload.

| # | Method | Path | Purpose |
|---|--------|------|---------|
| 7 | `POST` | `/v1/audio` | Dedicated audio config push |
| 8 | `POST` | `/v1/power` | Dedicated power/screen schedule push |
| 9 | `POST` | `/v1/ramadan` | Dedicated Ramadan config push |
| 10 | `POST` | `/v1/quran-program` | Dedicated Quran program config push |
| 11 | `GET` | `/v1/state` | Read-back current server state |

These can return `404` safely — the app handles it gracefully and shows "Not implemented on server" in diagnostics.

---

## Minimum `/v1/info` Response

```json
{
  "status": "ok",
  "version": "1.0.0"
}
```

The app only checks for HTTP 200. The response body is not parsed currently, but including `status` and `version` is recommended for future compatibility.

---

## Upload Endpoint Details

`POST /v1/upload-background`:

- Content-Type: `multipart/form-data`
- Field name: `file`
- File type: `image/jpeg`
- The server should:
  1. Save the file to a static directory (e.g. `/uploads/`)
  2. Return `{ "url": "http://<host>:<port>/uploads/<filename>" }`
  3. Serve the file statically so the display HTML can load it

---

## Server Tech Stack Recommendation

- **Runtime:** Node.js or Python
- **Framework:** Express, Fastify, Flask, or Hono
- **Display:** Chromium in kiosk mode loading `http://localhost:<port>/display`
- **Process Manager:** systemd (`masjid-api.service`)
- **Storage:** JSON file on disk (no database needed for MVP)

---

## Error Response Format

The app doesn't parse error response bodies. Just return appropriate status codes:

| Status | When |
|--------|------|
| `200` | Success |
| `400` | Malformed JSON / missing fields |
| `401` | Invalid or missing API key |
| `404` | Endpoint not implemented yet |
| `413` | Upload file too large |
| `500` | Internal server error |

---

## Timeout Expectations

The app has these timeout limits. The server should respond well within them:

| Endpoint | App Timeout | Target Response |
|----------|-------------|-----------------|
| `GET /v1/info` | 3–5 s | < 500 ms |
| `POST /v1/theme` | 10 s | < 2 s |
| `POST /v1/sync` | 10 s | < 1 s |
| `POST /v1/ticker` | 10 s | < 500 ms |
| `POST /v1/upload-background` | 30 s | < 10 s |
| Diagnostics (all) | 8 s | < 2 s |
