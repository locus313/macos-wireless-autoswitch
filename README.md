# macOS Wireless Auto-Switch

[![macOS](https://img.shields.io/badge/macOS-14%2B-blue?style=flat-square)](https://www.apple.com/macos/)
[![Version](https://img.shields.io/github/v/release/locus313/macos-wireless-autoswitch?style=flat-square)](https://github.com/locus313/macos-wireless-autoswitch/releases)
[![CI](https://img.shields.io/github/actions/workflow/status/locus313/macos-wireless-autoswitch/validate.yml?style=flat-square&label=CI)](https://github.com/locus313/macos-wireless-autoswitch/actions)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)](LICENSE)

[Features](#features) • [Installation](#installation) • [Usage](#usage) • [How it works](#how-it-works) • [Troubleshooting](#troubleshooting)

Automatically turns WiFi off when a wired Ethernet connection is active, and back on when you unplug. No polling, no tray icon — runs as a native macOS LaunchDaemon triggered by real network events.

## Features

- **Zero-interaction** — fires on actual network change events, not a timer
- **Multi-adapter support** — detects built-in Ethernet, Thunderbolt, LAN, and USB-C adapters (AX88179A)
- **Smart IP validation** — ignores loopback and self-assigned (169.254.x.x) addresses
- **All WiFi interfaces** — handles Macs with multiple wireless adapters without leaving any in a split state
- **Structured logging** — output written to `/var/log/wireless-autoswitch.log` and the system log

## Installation

**Prerequisites:** macOS 14+ and administrator privileges.

```bash
git clone https://github.com/locus313/macos-wireless-autoswitch.git
cd macos-wireless-autoswitch
./install.sh i
```

The installer copies scripts to `/Library/Scripts/NetBasics/`, installs the LaunchDaemon plist, sets permissions, and starts the service immediately.

> [!NOTE]
> Installation requires `sudo` — you will be prompted if not already root.

## Usage

All management is handled through `install.sh`:

```bash
./install.sh i    # Install
./install.sh up   # Update to the latest files
./install.sh ui   # Uninstall
./install.sh      # Interactive menu
```

### Verify the service is running

```bash
# Check daemon status
sudo launchctl list | grep com.computernetworkbasics.wifionoff

# Tail the log
tail -f /var/log/wireless-autoswitch.log
```

## How it works

```
Network change event (launchd watches /Library/Preferences/SystemConfiguration)
  └─> wireless.sh runs as root
        ├─ Enumerate wired interfaces (Ethernet | LAN | Thunderbolt | AX88179A)
        ├─ Check each interface for a valid DHCP address
        │    wired address found → networksetup -setairportpower <iface> off
        │    no wired address    → networksetup -setairportpower <iface> on
        └─ Sleep 10 s  (matches ThrottleInterval; prevents restart loop)
```

The LaunchDaemon (`com.computernetworkbasics.wifionoff.plist`) uses `WatchPaths` rather than `KeepAlive`, so it only runs when the network configuration directory changes — no persistent process, no polling.

### Supported adapters

| Type | Matched by |
|---|---|
| Built-in Ethernet | `Ethernet` |
| Thunderbolt Ethernet | `Thunderbolt` |
| USB-C / USB Ethernet | `AX88179A` |
| Generic wired | `LAN` |

## Troubleshooting

**WiFi isn't switching:**

```bash
# Restart the daemon
sudo launchctl bootout system /Library/LaunchDaemons/com.computernetworkbasics.wifionoff.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/com.computernetworkbasics.wifionoff.plist
```

**Wired connection not detected:**

```bash
# Run the script manually to see full output
sudo /Library/Scripts/NetBasics/wireless.sh

# List all hardware ports to confirm your adapter name
networksetup -listallhardwareports
```

> [!TIP]
> If your adapter isn't listed in the table above, open an issue or PR — adding support requires a one-line change to `SUPPORTED_ADAPTERS` in `wireless.sh`.

**Permission errors:**

```bash
ls -la /Library/Scripts/NetBasics/wireless.sh
ls -la /Library/LaunchDaemons/com.computernetworkbasics.wifionoff.plist
```

## Contributing

1. Fork and branch from `main`
2. Check `AGENTS.md` for the architecture overview and maintenance matrix
3. Run `shellcheck wireless.sh install.sh` before opening a PR
4. Update `CHANGELOG.md` under `[Unreleased]` for any user-facing change

## Credits

Originally created by Ryan Lininger. Modernized and maintained by [@locus313](https://github.com/locus313).

## Resources

- [macOS LaunchDaemon guide](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)
- [networksetup reference](https://ss64.com/osx/networksetup.html)
- [Original blog post (archive)](https://web.archive.org/web/20180508004545/www.computernetworkbasics.com/2012/12/automatically-turn-off-wireless-in-osx-including-mountain-lion/)