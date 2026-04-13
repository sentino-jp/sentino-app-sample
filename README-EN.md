# Sentino

Sentino is a cross-platform IoT smart device management app built with Flutter 3.x, supporting Android, iOS, Windows, and Web.

## Features

- **User Authentication** — Login, register (with email verification code), forgot password (3-step: email → code → new password), change password (auto logout on success), email format validation, token persistence
- **Device Management** — Device list with count stats, device details, device panel, unbind devices
- **Pairing** — BLE pairing (radar scan + device list), BLE direct connect, 4G bind code, barcode, scan code — unified via top-right + button
- **Agent Management** — Browse recommended/Sentino agents, create/edit/delete custom agents, bind agents to devices, switch agents on device panel, voice preview
- **MQTT** — Real-time device message push, signal detection result receiving
- **Network Detection** — Device signal strength detection (via MQTT)
- **OTA Upgrade** — Check firmware updates, download & flash with progress tracking
- **User Center** — Change avatar, edit nickname, clear cache, logout
- **Chat History** — View device/agent conversation history, clear support
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
| `mqtt_client` | MQTT real-time messaging |
| `permission_handler` | Runtime permission management |
| `wifi_scan` | WiFi scanning (pairing) |
| `audioplayers` | Audio playback (voice preview) |

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

### Build APK

```bash
flutter build apk --release
```

## Permissions

### Android
- Bluetooth scan/connect (BLUETOOTH_SCAN, BLUETOOTH_CONNECT)
- Location (ACCESS_FINE_LOCATION — required for BLE/WiFi scanning)
- Network (INTERNET)

### iOS
- Bluetooth (NSBluetoothAlwaysUsageDescription)
- Location (NSLocationWhenInUseUsageDescription)
- Camera (NSCameraUsageDescription — barcode scanning)
- Photo Library (NSPhotoLibraryUsageDescription — avatar)


