# AGENTS.md — macOS Wireless Auto-Switch

## Project Overview

A lightweight macOS system utility that automatically toggles WiFi off when a wired Ethernet connection is detected and back on when disconnected. Runs as a native LaunchDaemon, triggered by macOS network configuration changes — no polling, no user interaction required.

**Supported macOS:** Sonoma (14.x / kernel 23), Sequoia (15.x / kernel 24), Tahoe (16.x / kernel 25)

---

## Repository Structure

```
macos-wireless-autoswitch/
├── wireless.sh                              # Core logic: detect wired connection, toggle WiFi
├── install.sh                               # Installation/update/uninstall management script
├── com.computernetworkbasics.wifionoff.plist  # LaunchDaemon plist (watches SystemConfiguration)
├── LICENSE                                  # MIT
├── README.md
├── CHANGELOG.md
└── .github/
    ├── copilot-instructions.md
    ├── workflows/
    │   ├── validate.yml                     # CI: shellcheck + plist/compat validation on PR
    │   ├── release.yml                      # Auto-release on merged PR to core files
    │   └── copilot-setup-steps.yml          # Copilot agent environment setup
    ├── ISSUE_TEMPLATE/
    ├── PULL_REQUEST_TEMPLATE.md
    ├── agents/                              # Copilot custom agents
    ├── instructions/                        # Copilot instruction files
    └── skills/                              # Copilot skills (17 installed; includes sync-docs)
```

---

## Tech Stack

| Layer | Tool | Notes |
|---|---|---|
| Language | Bash 4+ | `set -euo pipefail` throughout |
| System integration | macOS LaunchDaemon (`launchd`) | Watches `/Library/Preferences/SystemConfiguration` |
| Network control | `networksetup` (macOS built-in) | Requires root |
| Interface inspection | `ifconfig` | IP validation, excludes 127.x and 169.254.x |
| Logging | `logger` | Writes to system log (visible in Console.app) |
| CI | GitHub Actions | shellcheck + xmllint + compatibility checks |

---

## Build & Run

This repo has no build step — scripts are executed directly.

```bash
# Install the LaunchDaemon service
./install.sh i          # Install
./install.sh up         # Update (reinstall)
./install.sh ui         # Uninstall
./install.sh            # Interactive menu

# Run detection logic manually (requires root)
sudo /Library/Scripts/NetBasics/wireless.sh

# Lint both shell scripts
shellcheck wireless.sh install.sh
```

**Install locations (post-install):**
- Scripts: `/Library/Scripts/NetBasics/`
- Daemon plist: `/Library/LaunchDaemons/com.computernetworkbasics.wifionoff.plist`

---

## Testing

There is no automated test suite — the scripts interact with macOS system APIs that cannot run in a Linux CI environment. Validation in CI covers:

1. **shellcheck** — lint `wireless.sh` and `install.sh` for common bash errors
2. **xmllint** — validate plist XML structure
3. **Content checks** — verify `networksetup` usage and install paths
4. **BATS** — 51 unit tests for all core functions

**Manual testing steps:**
```bash
# Verify wired interface detection
networksetup -listnetworkserviceorder | grep "Hardware Port" | grep "Ethernet\|LAN\|Thunderbolt\|AX88179A"

# Verify WiFi interface detection
networksetup -listallhardwareports | tr '\n' ' ' | sed -e 's/Hardware Port:/\n/g' | grep Wi-Fi

# Check system logs after running
log show --predicate 'process == "logger"' --last 5m | grep wireless
```

---

## Key Patterns & Conventions

### Function Design
- All functions use `local` variables — no global side-effects except the two module-level globals (`INTERFACES`, `WIFIINTERFACES`) set in `main()`
- Functions return data via `echo`, callers capture with `$(…)`
- Error paths call `exit 1` — LaunchDaemon treats non-zero exit as restart trigger

### Network Detection Flow
```
main()
  ├─ get_wired_interfaces()  → filters by SUPPORTED_ADAPTERS, excludes "bridge"
  ├─ get_wifi_interfaces()   → greps for "Wi-Fi" in hardware ports
  ├─ detect_wired_connection()
  │    └─ get_interface_ip() per interface (excludes 127.x, 169.254.x)
  └─ toggle_wifi("on"|"off")
       └─ networksetup -setairportpower $WIFIINTERFACES on|off
```

### Constants (top of `wireless.sh`)
- `SUPPORTED_ADAPTERS` — pipe-delimited regex: `"Ethernet|LAN|Thunderbolt|AX88179A"`
- `LOOP_PREVENTION_DELAY` — seconds to sleep at end (prevents LaunchDaemon restart loop): `10`

### LaunchDaemon Behavior
- Triggered on changes to `/Library/Preferences/SystemConfiguration` — fires on any network change
- `KeepAlive: false` — runs once per trigger, does not stay resident
- 10-second sleep at end of `wireless.sh` prevents rapid re-triggering

---

## CI/CD

| Workflow | Trigger | What it does |
|---|---|---|
| `validate.yml` | push or PR touching `wireless.sh`, `install.sh`, `*.plist` | shellcheck + xmllint + compatibility assertions |
| `release.yml` | PR merged to `main` touching core files | Auto-bumps patch version, creates GitHub Release with `.tar.gz` + `.zip` |

---

## Adding New Adapter Support

When a new USB/Thunderbolt adapter type needs to be supported:

1. Add adapter string to `SUPPORTED_ADAPTERS` in `wireless.sh` (pipe-delimited)
2. Update README "Multi-adapter Support" feature bullet and adapter list if present
3. Update `validate.yml` adapter grep if it tests specific adapter strings
4. Test manually: plug in adapter, run `networksetup -listnetworkserviceorder`, confirm new name appears and is matched

## Adding New macOS Version Support

No code change required — the OS version check was removed. The script works on any macOS with `networksetup`. Update only documentation (README badge, CHANGELOG) when confirming compatibility with a new release.

---

## Common Pitfalls

- **Bridge interfaces** — `get_wired_interfaces()` explicitly filters out `bridge` interfaces; preserve this filter when modifying
- **Self-assigned IPs** — `169.254.x.x` means no DHCP lease; the IP filter in `get_interface_ip()` must exclude these
- **Root requirement** — `networksetup -setairportpower` requires root; scripts must run via LaunchDaemon as root, not as user
- **LaunchDaemon restart loop** — the 10-second sleep at end of `wireless.sh` is intentional; do not remove it
- **Multiple WiFi interfaces** — `toggle_wifi()` iterates all interfaces returned by `get_wifi_interfaces()` via a `while IFS= read` loop; failures are accumulated so no interface is left in a split state
- **`actions/create-release@v1` deprecation** — `release.yml` uses this deprecated action; migrate to `gh release create` when updating
