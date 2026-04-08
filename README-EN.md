# AG Play

AG Play is a cross-platform IoT smart device management app built with Flutter 3.x, supporting both Android and iOS.

## Features

- **User Authentication** — Login, register, forgot password, change password with token persistence
- **Device Management** — View device list, device details (firmware, MAC, signal strength), unbind devices
- **BLE Pairing** — Scan nearby BLE devices, configure WiFi, bind to account
- **4G Pairing** — Bind devices via 5-digit bind code
- **Agent Management** — Browse recommended agents, create/delete custom agents, bind agents to devices
- **OTA Upgrade** — Check firmware updates, download & flash with progress tracking
- **Theme** — Light/Dark/System mode, deep red brand color with red-to-black gradient
- **Internationalization** — Supports zh_CN, ja_JP, en_US with extensible ARB-based architecture
- **Language follows system** — API requests carry `language` parameter (e.g. `zh_CN`, `en_US`, `ja_JP`) based on device locale

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
├── pages/                        # UI pages (splash, auth, home, device, agent, ota, settings)
├── widgets/                      # Reusable UI components
├── routes/                       # go_router configuration
├── theme/                        # Colors & ThemeData
├── l10n/                         # ARB files & generated localizations
└── utils/                        # Constants, validators, storage, API client
```

## Configuration

Edit `lib/utils/app_config.dart` to switch between mock and real API:

```dart
class AppConfig {
  static const bool useMock = true;           // true=Mock, false=Real API
  static const String baseUrl = 'https://api.example.com/';
}
```

## Getting Started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Adding a New Language

1. Create `lib/l10n/app_xx.arb` with translations
2. Run `flutter gen-l10n`
3. Add the new `Locale` to `SupportedLocales.all` in `lib/providers/locale_provider.dart`
