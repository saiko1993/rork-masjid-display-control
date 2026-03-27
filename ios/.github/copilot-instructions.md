# Copilot Instructions

## Project Overview

MasjidDisplayControl is a native iOS app (with an Apple Watch companion) that lets masjid administrators configure and control digital display hardware showing prayer times, announcements, and Islamic content. The project is built entirely in **Swift** using **SwiftUI** and targets **iOS** and **watchOS**.

## Repository Structure

```
MasjidDisplayControl/          # Main iOS app
├── Models/                    # Data models (prayer times, themes, faces, scenes)
├── Views/                     # SwiftUI views (settings, editors, diagnostics)
├── ViewModels/                # Observable state (AppStore)
├── Services/                  # BLE, REST, push, sync transports; prayer logic
├── Components/                # Reusable display components (clock, countdown, table)
├── DesignSystem/              # Tokens, buttons, cards, glass layers, motion presets
├── Utilities/                 # Helpers (Hijri dates, image compression, toasts)
├── Config.swift               # Build-time environment variable injection
├── ContentView.swift          # Root view
└── web/                       # Small JS/CSS assets loaded in web previews
MasjidWatch/                   # watchOS companion app
MasjidDisplayControlTests/     # Unit tests
MasjidDisplayControlUITests/   # UI tests
```

## Architecture

- **MVVM** — `AppStore` (an `@Observable @MainActor` class) holds all app state. Views read from it directly; services mutate it.
- **Transport layer** — Communication with display hardware uses `BLETransport`, `RestTransport`, and `PushService`, unified behind `SyncTransport`.
- **Prayer state machine** — `PrayerStateMachine` evaluates the current prayer state from schedule data and the current time.
- **Theme system** — `ThemeDefinition` provides base themes; `ThemeCustomizationStore` applies user overrides.
- **Design system** — Custom SwiftUI components (`DSButton`, `DSCard`, `GlassLayer`, etc.) and `DesignTokens` enforce consistent styling.

## Build & Test

This is an Xcode project (`.xcodeproj`). CI runs on `macos-latest`:

```bash
# Swift package build/test (used in swift.yml workflow)
swift build -v
swift test -v

# Xcode build/test (used in ios.yml workflow)
xcodebuild build-for-testing -scheme MasjidDisplayControl -destination "platform=iOS Simulator,name=iPhone 16"
xcodebuild test-without-building -scheme MasjidDisplayControl -destination "platform=iOS Simulator,name=iPhone 16"
```

## Coding Conventions

- **Swift 5+ / SwiftUI** — Use modern Swift concurrency (`async`/`await`, `@MainActor`) where appropriate.
- **Observation** — Prefer `@Observable` (Observation framework) over `ObservableObject`/`@Published`.
- **Access control** — Mark types and members with the narrowest visibility needed (`private`, `internal`).
- **Naming** — Follow Swift API Design Guidelines: clear, descriptive names; no abbreviations.
- **Design system** — Use `DesignTokens` and `DS*` components for any new UI instead of ad-hoc styling.
- **Models** — Keep models as plain structs conforming to `Codable` when possible.
- **Error handling** — Prefer `Result` or `throws` over force-unwraps and silent failures.
- **No third-party package manager dependencies** — The project does not use SPM, CocoaPods, or Carthage for external packages. Avoid adding external dependencies unless absolutely necessary.
