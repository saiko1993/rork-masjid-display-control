import SwiftUI

struct DocsView: View {
    var body: some View {
        List {
            ForEach(DocSection.allCases, id: \.self) { section in
                NavigationLink(value: section) {
                    HStack(spacing: DS.Spacing.sm) {
                        Image(systemName: section.icon)
                            .font(.body)
                            .foregroundStyle(.tint)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(section.title)
                                .font(.body.weight(.medium))
                            Text(section.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Documentation")
    }
}

nonisolated enum DocSection: String, CaseIterable, Hashable, Sendable {
    case mvp, prd, themeSystem, iqamaSystem, stateMachine, restAPI, bleService, payloadSchema, operational

    var title: String {
        switch self {
        case .mvp: return "MVP Definition"
        case .prd: return "PRD Summary"
        case .themeSystem: return "Theme System"
        case .iqamaSystem: return "Iqama System"
        case .stateMachine: return "State Machine"
        case .restAPI: return "REST API Endpoints"
        case .bleService: return "BLE Service"
        case .payloadSchema: return "Payload Schema"
        case .operational: return "Operational Notes"
        }
    }

    var subtitle: String {
        switch self {
        case .mvp: return "Core features and scope"
        case .prd: return "Product requirements"
        case .themeSystem: return "Composite layered themes"
        case .iqamaSystem: return "Adhan and iqama management"
        case .stateMachine: return "Prayer phase transitions"
        case .restAPI: return "Theme Pack + Light Sync endpoints"
        case .bleService: return "Bluetooth Low Energy protocol"
        case .payloadSchema: return "JSON payload examples"
        case .operational: return "Mosque deployment guide"
        }
    }

    var icon: String {
        switch self {
        case .mvp: return "star.fill"
        case .prd: return "doc.text.fill"
        case .themeSystem: return "paintpalette.fill"
        case .iqamaSystem: return "bell.fill"
        case .stateMachine: return "arrow.triangle.branch"
        case .restAPI: return "network"
        case .bleService: return "antenna.radiowaves.left.and.right"
        case .payloadSchema: return "curlybraces"
        case .operational: return "building.2.fill"
        }
    }

    var content: String {
        switch self {
        case .mvp:
            return """
            # MVP Definition

            ## Masjid Smart Display Controller v2.0

            ### Core Features
            - Configure Raspberry Pi mosque display remotely from iOS
            - 4 built-in Islamic themes with composite layered rendering
            - Live preview of the display with responsive scaling
            - Prayer schedule simulation (Cairo default)
            - Iqama configuration per-prayer with Jumu'ah mode
            - **Theme Pack** — sent once when theme changes
            - **Light Sync** — sent frequently with schedule + time sync

            ### What's Included
            - Theme Engine: 4 themes with fixed layouts, layer stacks, and stable styling
            - Adhan/Iqama display manager (visual only, no audio)
            - State machine with edge case handling (mid-adhan, missed prayer, midnight rollover)
            - Responsive preview for multiple screen resolutions
            - HMAC-SHA256 optional security
            - Push retry queue with exponential backoff
            - Export/Share payload JSON
            - Built-in documentation

            ### What's NOT in MVP
            - Real prayer time calculation (uses simulated schedules)
            - Audio playback
            - Multi-device management
            - Cloud sync
            """

        case .prd:
            return """
            # Product Requirements Document

            ## Problem Statement
            Mosques need a centralized way to configure digital displays showing prayer times, countdowns, and Islamic content. Current solutions require manual configuration on the display device itself.

            ## Solution
            A mobile app that generates a complete configuration payload and pushes it to a Raspberry Pi running the display software.

            ## Target Users
            - Mosque administrators
            - Imam / Muezzin
            - Community volunteers managing mosque technology

            ## User Journey
            1. Install app → Complete setup wizard
            2. Choose theme, configure location, set iqama times
            3. Preview the display on phone
            4. Push configuration to Raspberry Pi
            5. Display updates automatically

            ## Sync Protocol
            The app uses a two-payload architecture:
            - **Theme Pack** (POST /v1/theme) — Heavy, sent rarely. Contains full theme definition, palette, typography, tokens, and layer stack instructions.
            - **Light Sync** (POST /v1/sync) — Lightweight, sent frequently. Contains today's schedule, time sync data, brightness, and minimal display config.

            ## Multi-Transport
            Supports WiFi (REST) and Bluetooth Low Energy (BLE) transports. Transport layer is abstracted via `SyncTransport` protocol, allowing seamless switching.

            This ensures efficient network usage after initial setup.
            """

        case .themeSystem:
            return """
            # Theme System

            ## Overview
            Each theme defines a complete visual identity using a composite layer stack.

            ## Theme Components
            - **Palette**: background, surface, primary, secondary, textPrimary, textSecondary, accent, adhanGlow
            - **Typography**: font design (default/serif/monospaced), weights for time and headings
            - **Background Pattern**: geometric stars, arabesque, minimal dots, or none
            - **Tokens**: cornerRadius, padding, spacing, border, shadow, safeMargins, minReadableFontSize, tableDensity, tickerDirection
            - **Contrast Ratio**: Enforced minimum 4.5:1 for text readability

            ## Layer Stack (Composite Rendering)
            1. Background base color + gradient
            2. Islamic pattern layer (Canvas-drawn, procedural)
            3. Vignette/lighting overlay (dark themes)
            4. Optional shimmer effect (Islamic Geometric Dark)
            5. Card surfaces with semi-transparent backgrounds
            6. Adhan glow highlight layer (active during adhan)

            ## Built-in Themes

            ### 1. Islamic Geometric Dark
            Dark navy background with gold accents. Eight-pointed star pattern. Premium depth with shimmer.

            ### 2. Ottoman Classic
            Deep green with ivory text. Arabesque ornament pattern. Classic serif typography.

            ### 3. Minimal Noor
            Light cream background. Clean minimal dots. Modern calm aesthetic. Best for well-lit spaces.

            ### 4. LED Mosque
            Pure black with green LED-style monospaced digits. High contrast for LED displays.

            ## Layout Modes
            - **Wide (wide-v1)**: Side-by-side clock + prayer table. Best for 16:9.
            - **Compact (compact-v1)**: Stacked vertical. Best for smaller or 4:3 displays.
            """

        case .iqamaSystem:
            return """
            # Iqama System

            ## Overview
            The Iqama system manages the wait time between Adhan and Iqama for each prayer.

            ## Configuration
            - Enable/disable per mosque preference
            - Individual minutes per prayer (Fajr: 20, Dhuhr: 15, Asr: 15, Maghrib: 10, Isha: 15 defaults)
            - Maghrib capped at 8 minutes maximum to prevent overlap
            - Mode: "afterAdhan" — iqama countdown starts after adhan duration ends

            ## Jumu'ah Mode
            - Replaces Dhuhr with Jumu'ah on Fridays
            - Independent iqama time for Jumu'ah
            - Optional second Jumu'ah prayer
            - Shows mosque icon and الجمعة label

            ## Display Behavior
            - During Adhan: Glow effect, "حان الآن وقت صلاة [name]"
            - During Iqama Countdown: Timer showing "الإقامة بعد MM:SS"
            - During Prayer: "صلاة [name] جارية" indicator
            - Dhikr ticker pauses during adhan/iqama (configurable)

            ## Edge Cases
            - App opens mid-adhan/iqama: correctly resolves current phase from timestamps
            - Missed prayers: auto-skips to next upcoming prayer
            - Midnight rollover: shows next day's Fajr with estimated time
            """

        case .stateMachine:
            return """
            # Prayer State Machine

            ## States

            ```
            NORMAL → ADHAN_ACTIVE → IQAMA_COUNTDOWN → PRAYER_IN_PROGRESS → NORMAL
            ```

            ## State Details

            ### NORMAL
            - Default state between prayers
            - Shows countdown to next prayer
            - Standard display layout

            ### ADHAN_ACTIVE
            - Triggered at exact prayer time
            - Duration: adhanActiveSeconds (default: 120s)
            - Visual: background glow, announcement text
            - Separate adhanRemainingSeconds counter

            ### IQAMA_COUNTDOWN
            - Starts after ADHAN_ACTIVE ends
            - Duration: per-prayer iqamaMinutes
            - Separate iqamaCountdownSeconds counter
            - Only active if iqama is enabled

            ### PRAYER_IN_PROGRESS
            - Starts after iqama (or adhan if iqama disabled)
            - Duration: prayerInProgressMinutes (default: 10 min)
            - Shows prayer name with "in progress" indicator

            ## Key Design Decisions
            - currentPrayer = the prayer whose adhan/iqama is active
            - nextPrayer = the prayer AFTER the current one
            - Each phase has its own dedicated countdown field
            - After Isha completes, estimates tomorrow's Fajr time
            """

        case .restAPI:
            return """
            # REST API Endpoints

            ## Base URL
            `http://masjidclock.local:8787` (configurable)

            ## Authentication
            - API Key: `X-API-Key` header
            - Optional HMAC-SHA256: `X-Timestamp`, `X-Nonce`, `X-Signature` headers

            ---

            ## GET /v1/info
            Returns display device information. Used for connection testing.

            **Response:**
            ```json
            {
              "version": "2.0.0",
              "hostname": "masjidclock",
              "uptime": 3600,
              "display": { "width": 1920, "height": 1080 }
            }
            ```

            ---

            ## POST /v1/theme (Theme Pack)
            Push full theme definition. Sent only when theme changes or device is paired.

            **Headers:** Content-Type: application/json, X-API-Key
            **Body:** ThemePackPayload JSON
            **Contains:** themeId, palette (hex), typography, tokens, layer stack, pattern config

            ---

            ## POST /v1/sync (Light Sync)
            Push schedule and minimal config. Sent frequently.

            **Headers:** Content-Type: application/json, X-API-Key
            **Body:** LightSyncPayload JSON
            **Contains:** pushId (UUID), sentAtISO, nowEpoch, tzOffsetMinutes, schedule (adhan HH:mm + ISO, iqama), display config, brightness schedule

            **Idempotency:** pushId prevents duplicate processing.

            ---

            ## GET /v1/status
            Returns current display state.

            ```json
            {
              "theme": "islamic-geo-dark",
              "lastSync": "2025-01-01T12:00:00Z",
              "phase": "normal",
              "nextPrayer": "dhuhr"
            }
            ```
            """

        case .payloadSchema:
            return """
            # Payload Schemas

            ## Theme Pack (POST /v1/theme)
            ```json
            {
              "version": "2.0.0",
              "pushId": "uuid",
              "sentAtISO": "ISO8601",
              "themeId": "islamic-geo-dark",
              "nameAr": "هندسي إسلامي داكن",
              "isDark": true,
              "contrastRatio": 7.5,
              "palette": {
                "background": "#121224",
                "surface": "#1E1E33",
                "primary": "#D9AD52",
                "accent": "#D9AD52",
                "textPrimary": "#F2EDE0",
                "textSecondary": "#B3AD9E"
              },
              "typography": {
                "timeFontDesign": "default",
                "timeWeight": "bold"
              },
              "tokens": {
                "cornerRadius": 16,
                "safeMargins": 20,
                "tableDensity": "comfortable",
                "tickerDirection": "ltr"
              },
              "layerStack": {
                "patternType": "geometric_stars",
                "patternOpacity": 0.08,
                "hasVignette": true,
                "hasShimmer": true
              }
            }
            ```

            ## Light Sync (POST /v1/sync)
            ```json
            {
              "version": "2.0.0",
              "pushId": "uuid",
              "sentAtISO": "ISO8601",
              "nowEpoch": 1704067200,
              "deviceTime": "2025-01-01 12:00:00",
              "tz": "Africa/Cairo",
              "tzOffsetMinutes": 120,
              "schedule": [
                {
                  "prayer": "fajr",
                  "adhan": "04:50",
                  "adhanISO": "ISO8601",
                  "iqama": "05:10",
                  "iqamaISO": "ISO8601",
                  "isJumuah": false
                }
              ],
              "display": {
                "brightness": 80,
                "layout": "wide-v1",
                "showDhikrTicker": true
              },
              "brightnessSchedule": {
                "enabled": true,
                "dayBrightness": 80,
                "nightBrightness": 30
              }
            }
            ```
            """

        case .bleService:
            return """
            # Bluetooth Low Energy Service

            ## Overview
            The app supports BLE as an alternative transport for pushing Theme Pack and Light Sync payloads to the display device. This is useful when WiFi is unavailable or unreliable.

            ## Architecture
            - **App** acts as BLE Central (CBCentralManager)
            - **Device** (Raspberry Pi + BLE adapter, or ESP32) acts as BLE Peripheral

            ## Service Definition

            ### MasjidDisplayService
            **UUID:** `9B2F6A6E-2C3A-4C6D-9E5F-2A7B1E0C8D11`

            ### Characteristics

            | Name | UUID | Properties |
            |------|------|------------|
            | ThemeCharacteristic | `6D1C2A8B-7F7C-4B53-9D3B-10C78E8A4F01` | Write with Response |
            | SyncCharacteristic | `3A91A0C4-1E1F-4D5A-8A2F-5D2B6E7C9012` | Write without Response (preferred) |
            | AckCharacteristic | `0E6F1D2C-3B4A-4C5D-8E9F-1A2B3C4D5E6F` | Notify |

            ## Chunking Protocol
            BLE has limited MTU (typically 20-512 bytes). Large payloads are chunked:

            1. **Header:** `MSDC:<pushId>:<totalChunks>:<totalBytes>`
            2. **Data chunks:** Raw bytes, each ≤ MTU-3
            3. **Footer:** `MSDC:END:<pushId>`

            The device reassembles chunks using the pushId and validates total bytes.

            ## ACK Mechanism
            The device sends ACK via the AckCharacteristic (Notify) after processing:
            - `ACK:<pushId>:OK` — Success
            - `ACK:<pushId>:ERR:<message>` — Failure

            The app waits up to 10 seconds for an ACK after sending a ThemePack. If no ACK is received or an ERR is returned, the send is marked as failed. Individual chunks are retried up to 3 times with progressive backoff before giving up.

            ## Transport Selection
            Users can choose in Settings:
            - **WiFi** — REST only
            - **Bluetooth** — BLE only
            - **Auto** — Prefer BLE if connected, fallback to WiFi

            ## Reliability
            - Each payload send uses the PushService retry queue (3 retries with exponential backoff)
            - Push history tracks transport used (WiFi/Bluetooth) per entry
            - pushId (UUID) ensures idempotency — device should ignore duplicate pushIds
            - ThemePack chunks include sequence numbers for reassembly

            ## Device Implementation Notes
            The Raspberry Pi or ESP32 must:
            1. Advertise the MasjidDisplayService UUID (`9B2F6A6E-2C3A-4C6D-9E5F-2A7B1E0C8D11`)
            2. Accept chunked writes on Theme and Sync characteristics
            3. Reassemble chunks using the `MSDC:<pushId>:<totalChunks>:<totalBytes>` header
            4. Parse JSON payloads after receiving `MSDC:END:<pushId>` footer
            5. Send ACK via notify on AckCharacteristic
            6. Use the same ThemeDefinition contract to render the display
            7. Ignore duplicate pushIds for idempotency
            """

        case .operational:
            return """
            # Operational Notes for Mosques

            ## Initial Setup
            1. Connect Raspberry Pi to mosque display via HDMI
            2. Connect Pi to the same WiFi/LAN as the controller phone
            3. Install the Masjid Controller app
            4. Complete the setup wizard
            5. Use "Pair Device" to send initial Theme Pack + Light Sync

            ## Daily Operation
            - The Pi runs independently once configured
            - Use "Send Today's Schedule" for manual daily updates
            - Theme Pack only needs resending when you change themes

            ## Network Requirements
            - **WiFi:** Both devices must be on the same local network
            - Default address: http://masjidclock.local:8787
            - Use a static IP on the Pi for reliability
            - **Bluetooth:** No WiFi needed. Pi must have BLE adapter or use ESP32
            - Select transport mode in Settings → Transport

            ## Brightness Schedule
            - Configure day/night brightness levels
            - Automatically adjusts based on configured hours
            - Reduces power consumption at night

            ## Security
            - API Key provides basic authentication
            - Enable HMAC for cryptographic request signing
            - HMAC uses timestamp + nonce to prevent replay attacks

            ## Troubleshooting
            - "Test Connection" verifies network connectivity
            - Check push history for send/fail status
            - Retry queue automatically retries failed sends (3 attempts)
            - If connection fails, payload can still be copied/shared manually

            ## Demo Mode
            - Use to demonstrate display states to mosque committee
            - Steps through Normal → Adhan → Iqama → Prayer phases
            - Does not affect actual schedule
            """
        }
    }
}

struct DocDetailView: View {
    let section: DocSection

    var body: some View {
        ScrollView {
            Text(markdownToAttributed(section.content))
                .font(.body)
                .padding(DS.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(section.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func markdownToAttributed(_ text: String) -> AttributedString {
        (try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(text)
    }
}
