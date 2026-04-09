# Sentino

Sentino is a cross-platform IoT smart device management app built with Flutter 3.x, supporting Android, iOS, Windows, and Web.

## Features

- **User Authentication** — Login, register, forgot password, change password (auto logout on success), token persistence
- **Device Management** — Device list with count stats, device details, device panel, unbind devices
- **Pairing** — BLE pairing, 4G bind code, barcode, scan code — unified via top-right + button
- **Agent Management** — Browse recommended/Sentino agents, create/edit/delete custom agents, bind agents to devices, switch agents on device panel
- **OTA Upgrade** — Check firmware updates, download & flash with progress tracking
- **User Center** — Change avatar, edit nickname, logout
- **Theme** — Light/Dark/System mode, deep red brand color with red-to-black gradient
- **Internationalization** — zh_CN, ja_JP, en_US with real-time API header sync on language switch
- **App Icon** — Auto-generated for all platforms via flutter_launcher_icons

## Architecture

```
Pages / Widgets (UI)
    ↓
Providers (State Management - provider)
    ↓
Services (Business Logic)
    ↓
Repositories (Data Access - abstract)
    ├── mock/   (Mock data for development)
    └── api/    (Real API via Dio)
    ↓
Models / Theme / Utils
```

## Tech Stack

| Package | Purpose |
|---------|---------|
| `provider` | State management |
| `go_router` | Declarative routing with auth guard |
| `dio` | HTTP client |
| `shared_preferences` | Local key-value storage |
| `flutter_blue_plus` | BLE communication |
| `json_annotation` + `json_serializable` | JSON serialization |
| `flutter_localizations` + `intl` | i18n |
| `flutter_launcher_icons` | Multi-platform app icon generation |

## Project Structure

```
lib/
├── main.dart / app.dart          # Entry point, MultiProvider setup
├── models/                       # Data models with JSON serialization
├── repositories/
│   ├── mock/                     # Mock implementations
│   └── api/                      # Real API implementations (Dio)
├── services/                     # Business logic layer
├── providers/                    # State management (ChangeNotifier)
├── pages/                        # UI pages (splash, auth, device, agent, ota, settings, mine)
├── widgets/                      # Reusable UI components
├── routes/                       # go_router configuration
├── theme/                        # Colors & ThemeData
├── l10n/                         # ARB files & generated localizations
└── utils/                        # Constants, validators, storage, API client
```

## Getting Started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### Build Windows

```bash
flutter build windows --release
```

### Generate App Icons

```bash
dart run flutter_launcher_icons
```

## Adding a New Language

1. Create `lib/l10n/app_xx.arb` with translations
2. Run `flutter gen-l10n`
3. Add the new `Locale` to `SupportedLocales.all` in `lib/providers/locale_provider.dart`


