# Copilot Instructions for macOS Wireless Auto-Switch

## Project Overview
This is a simple macOS utility that automatically toggles WiFi off when a wired Ethernet connection is detected, and back on when disconnected. The system uses a LaunchDaemon to monitor network configuration changes.

## Architecture Components

### Core Files
- `wireless.sh` - Main logic script that detects wired connections and toggles WiFi
- `com.computernetworkbasics.wifionoff.plist` - LaunchDaemon configuration that watches `/Library/Preferences/SystemConfiguration` for network changes
- `install.sh` - Installation/management script with interactive menu system

### Key Patterns

#### Network Detection Logic (`wireless.sh`)
- Detects ethernet interfaces using `networksetup -listnetworkserviceorder` with hardware port filtering
- Looks for "Ethernet", "LAN", "Thunderbolt", or "AX88179A" adapter types
- Uses `ifconfig` + `grep` to find valid IP addresses (excludes 127.0.0.1 and 169.254.x.x)
- OS version detection via `uname -a` determines compatibility (supports Sonoma #23, Sequoia #24, Tahoe #25)

#### Installation Structure
- Scripts install to `/Library/Scripts/NetBasics/`
- LaunchDaemon plist goes to `/Library/LaunchDaemons/`
- Requires root permissions for system-level network control

### Development Workflows

#### Testing Network Detection
```bash
# Test interface detection manually
networksetup -listnetworkserviceorder | grep "Hardware Port" | grep "Ethernet\|LAN\|Thunderbolt\|AX88179A"

# Check current WiFi interfaces
networksetup -listallhardwareports | tr '\n' ' ' | sed -e 's/Hardware Port:/\'$'\n/g' | grep Wi-Fi
```

#### Installation Commands
- Install: `./install.sh i`
- Update: `./install.sh up` 
- Uninstall: `./install.sh ui`

### macOS-Specific Considerations
- Uses `networksetup -setairportpower` for WiFi control (requires admin privileges)
- LaunchDaemon watches SystemConfiguration for network state changes
- Sleep delay (10s) prevents LaunchDaemon restart loops
- Logging via `logger` command integrates with system logs

### Error Handling Patterns
- Exit codes used for LaunchDaemon error detection (`|| exit 1`)
- Conditional logic ensures WiFi interfaces exist before control attempts
- Sudo detection and privilege escalation in install script

### Compatibility Notes
- Bash 4+ recommended for proper array handling
- Hardware port detection includes modern adapter types (AX88179A for USB-C)
- OS version checks ensure compatibility with recent macOS releases

When modifying this codebase, always test network detection logic thoroughly and ensure LaunchDaemon integration works correctly with system network events.

## Maintenance Matrix

When you change a file, also update these:

| Changed file | Also update |
|---|---|
| `wireless.sh` — `SUPPORTED_ADAPTERS` | `README.md` adapter list, `validate.yml` adapter grep |
| `wireless.sh` — `SUPPORTED_OS_VERSIONS` | `README.md` badges + System Requirements, `release.yml` compatibility notes (lines ~117–119), `validate.yml` version check comment, `AGENTS.md` supported macOS table |
| `wireless.sh` — `LOOP_PREVENTION_DELAY` | `com.computernetworkbasics.wifionoff.plist` `ThrottleInterval` (should match or exceed) |
| `wireless.sh` — any function signature | `AGENTS.md` network detection flow diagram |
| `install.sh` — install paths | `com.computernetworkbasics.wifionoff.plist` `ProgramArguments`, `validate.yml` path checks, `AGENTS.md` install locations |
| `com.computernetworkbasics.wifionoff.plist` | `validate.yml` plist key checks, `AGENTS.md` LaunchDaemon behavior notes |
| Any core file (`wireless.sh`, `install.sh`, `*.plist`) | `CHANGELOG.md` under `[Unreleased]` |
| `.github/workflows/release.yml` — compatibility notes | Keep in sync with `SUPPORTED_OS_VERSIONS` in `wireless.sh` |