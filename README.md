# ZeroTrustClient

Cross-platform VPN/proxy client built with Flutter. Supports **HTTP Proxy** and **Shadowsocks**, with system-wide traffic tunneling on desktop platforms.

## Features

- Custom modern desktop window with frameless title bar
- Narrow default window (380×640), fully resizable
- HTTP Proxy and Shadowsocks protocol support
- System-wide proxy configuration (Linux, Windows, macOS)
- Profile management with persistent storage
- Real-time connection status and traffic stats

## Supported Platforms

| Platform | Status |
|----------|--------|
| Linux    | Primary desktop target |
| Windows  | Supported |
| macOS    | Supported |
| Android  | Supported (no system-wide proxy) |
| iOS      | Supported (no system-wide proxy) |
| Web      | UI only (proxy tunneling not available) |

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.16+
- Linux: `gsettings` (GNOME) for system proxy
- Windows: Administrator rights may be needed for system proxy
- macOS: `networksetup` for system proxy

### Setup

```bash
cd ZeroTrustClient
flutter pub get
```

### Run

```bash
# Linux desktop (primary)
flutter run -d linux

# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Web (UI preview)
flutter run -d chrome

# Mobile
flutter run -d android
flutter run -d ios
```

### Build

```bash
flutter build linux --release
flutter build windows --release
flutter build macos --release
```

## CI/CD

GitHub Actions builds release binaries and publishes them to [GitHub Releases](https://docs.github.com/en/repositories/releasing-projects-on-github).

### Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `CI` | Push/PR to `main` | `flutter analyze`, tests, Linux smoke build |
| `Release` | Tag `v*` or manual dispatch | Build all platforms and publish release assets |

### Publish a release

**Option 1 — Git tag (recommended)**

```bash
git tag v1.0.0
git push origin v1.0.0
```

**Option 2 — Manual dispatch**

1. Open **Actions → Release → Run workflow**
2. Enter a tag such as `v1.0.0`
3. Run on the branch you want to release

### Release artifacts

Each release includes:

| Artifact | Platform |
|----------|----------|
| `zero-trust-client_<version>_linux-x64.tar.gz` | Linux desktop |
| `zero-trust-client_<version>_windows-x64.zip` | Windows desktop |
| `zero-trust-client_<version>_macos-universal.zip` | macOS desktop |
| `zero-trust-client_<version>_android-arm64.apk` | Android |

Pre-release tags containing a hyphen (e.g. `v1.0.0-beta.1`) are marked as GitHub pre-releases.


```
lib/
├── main.dart                 # App entry + window setup
├── models/                   # ProxyProfile, ConnectionInfo
├── services/
│   ├── connection_manager.dart   # Orchestrates connect/disconnect
│   ├── http_proxy_service.dart   # Local HTTP proxy → upstream
│   ├── shadowsocks_service.dart  # Local SOCKS5 → SS server
│   ├── system_proxy_service.dart # OS-level proxy config
│   └── profile_repository.dart   # Profile persistence
├── providers/                # App state (Provider)
├── screens/                  # Home, profile editor
└── widgets/                  # Custom title bar, cards
```

## How It Works

1. **Connect** starts a local proxy listener on `127.0.0.1:<localPort>`
2. For **HTTP Proxy**: forwards traffic to your upstream HTTP proxy
3. For **Shadowsocks**: runs a local SOCKS5 server that encrypts traffic via SS
4. When **System-wide proxy** is enabled, the OS HTTP/HTTPS proxy is set to the local listener

## Shadowsocks Ciphers

Currently supported:
- `aes-256-gcm`
- `aes-128-gcm`

## License

MIT
