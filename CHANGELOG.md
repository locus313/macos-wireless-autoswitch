# Changelog

All notable changes to macOS Wireless Auto-Switch are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- `wireless.sh`: stale "Sonoma, Sequoia, Tahoe" header comment updated to "macOS 14+" (fixes #56)
- `install.sh`: `show_help` requirements updated to "macOS 14+"; `launchctl load/unload` replaced with `launchctl bootstrap/bootout` (fixes #56, #57)
- `wireless.sh`: `get_wired_interfaces()` now returns newline-separated output (dropped `tr`/`sed` trim); `detect_wired_connection()` iterates with `while IFS= read -r` to match `toggle_wifi` (fixes #58)
- `wireless.sh`: removed dead `2>/dev/null` from `head -1` in `get_interface_ip()` (fixes #62)
- `com.computernetworkbasics.wifionoff.plist`: `ThrottleInterval` bumped from 5 to 10 to match `LOOP_PREVENTION_DELAY` (fixes #61)
- `release.yml`: added `CHANGELOG.md` to release archive (fixes #59)
- `validate.yml`: standardised `actions/checkout` to `@v7` to match `release.yml` (fixes #60)

### Fixed
- `release.yml`: CHANGELOG.md was never updated on release; workflow now promotes `[Unreleased]` to a versioned entry, updates the comparison link, and commits before tagging (fixes #54)

### Changed
- `CHANGELOG.md`: backfilled missing comparison links for v1.0.7–v1.0.10

### Removed
- `wireless.sh`: removed `get_os_version()`, `SUPPORTED_OS_VERSIONS` constant, and the runtime OS version check from `main()` — the check was a killswitch that would block future macOS versions despite `networksetup` still working (fixes #52)

### Changed
- `test/wireless.bats`: removed 6 now-obsolete OS version tests
- `validate.yml`: removed `uname -r` and `23|24|25` content checks
- `AGENTS.md`: updated flow diagram, constants list, and "Adding New macOS Version Support" section

### Added
- BATS test suite (`test/wireless.bats`, `test/install.bats`) with 51 tests covering all core functions (fixes #42–#50)
- `test/helpers/` stubs for `uname`, `ifconfig`, `logger`, `id`, and `networksetup`
- CI: `validate.yml` now installs bats, deploys the `networksetup` stub to `/usr/sbin/`, and runs the full test suite; also triggers on `test/**` path changes

### Changed
- `wireless.sh`: `SCRIPT_NAME` now uses `$(basename "$0")` instead of a hardcoded string (fixes #39)
- `wireless.sh`: `get_os_version` simplified from double-awk to `uname -r | cut -d. -f1` (fixes #36)
- `wireless.sh`: removed unreachable empty-interface guard in `get_interface_ip` (fixes #37)
- `wireless.sh`: `detect_wired_connection` now returns exit code (0=found, 1=not found) instead of setting `IPFOUND` global; removed `IPFOUND`/`OSVERSION` module-level globals (fixes #38)
- `install.sh`: `SCRIPT_NAME` now uses `$(basename "$0")` instead of a hardcoded string (fixes #39)
- `install.sh`: `validate_source_files` simplified from 13-line array accumulator to 2-line guards (fixes #41)
- `install.sh`: extracted `_deploy_files` helper to eliminate ~20-line duplication between `install_components` and `update_components` (fixes #40)

### Added
- `.github/skills/sync-docs`: new Copilot skill that audits `AGENTS.md` and `.github/copilot-instructions.md` against the live source, patches stale values, updates `CHANGELOG.md [Unreleased]`, then commits and pushes

### Fixed
- `wireless.sh`: `toggle_wifi` mid-loop `exit 1` left multi-adapter Macs in a split WiFi state; loop now completes all interfaces before exiting non-zero (fixes #32)
- `com.computernetworkbasics.wifionoff.plist`: `RunAtLoad: false` meant booting with Ethernet already connected never triggered the daemon; changed to `true` (fixes #31)
- `install.sh`: bare filenames resolved against `$PWD` caused "Missing required files" when not run from the repo directory; `main()` now `cd`s to script directory first (fixes #30)

### Fixed
- `wireless.sh`: `set -e` + empty grep silently killed the script before WiFi could be re-enabled; bare assignments now use `|| INTERFACES=""` / `|| WIFIINTERFACES=""` guards (fixes #27)
- `wireless.sh`: `toggle_wifi` passed multi-line `$WIFIINTERFACES` as one argument, failing on Macs with multiple WiFi adapters; now iterates per interface (fixes #28)
- `install.sh`: missing `chmod 644` on installed plist caused `launchctl` to silently refuse loading on systems with a restrictive umask; added to both `install_components` and `update_components` (fixes #26)

## [1.0.6] – 2025

### Added
- Copilot agents, instructions, and skills for AI-assisted development
- Migrated from legacy chatmodes/prompts to current agents/skills format

## [1.0.5] – 2025

### Added
- macOS Tahoe (16.x / kernel 25) support
- Removed macOS Ventura support (EOL)

## [1.0.4] – 2025

### Changed
- Improved wired connection detection: exclude bridge interfaces
- Enhanced `get_interface_ip()` with cleaner error handling
- Added detailed logging throughout `detect_wired_connection()`

## [1.0.3] – 2025

### Fixed
- Release workflow: simplified release name to version number only

## [1.0.2] – 2025

### Changed
- `install.sh` fully rewritten: robust error handling, modular functions, interactive + CLI modes
- `README.md` major update: clearer installation steps, expanded troubleshooting, badges

### Added
- `validate.yml` CI workflow: shellcheck + xmllint + compatibility checks
- `release.yml` CI workflow: auto-release on merged PR

## [1.0.1] – 2024

### Added
- macOS Sonoma (14.x / kernel 23) support
- MIT License
- `.github/copilot-instructions.md`

## [1.0.0] – 2024

### Added
- Initial release: `wireless.sh` core logic, `install.sh`, LaunchDaemon plist
- Supports Ethernet, Thunderbolt, LAN, and AX88179A (USB-C) adapters

[Unreleased]: https://github.com/locus313/macos-wireless-autoswitch/compare/v1.0.10...HEAD
[1.0.10]: https://github.com/locus313/macos-wireless-autoswitch/compare/v1.0.9...v1.0.10
[1.0.9]: https://github.com/locus313/macos-wireless-autoswitch/compare/v1.0.8...v1.0.9
[1.0.8]: https://github.com/locus313/macos-wireless-autoswitch/compare/v1.0.7...v1.0.8
[1.0.7]: https://github.com/locus313/macos-wireless-autoswitch/compare/v1.0.6...v1.0.7
[1.0.6]: https://github.com/locus313/macos-wireless-autoswitch/compare/v1.0.5...v1.0.6
[1.0.5]: https://github.com/locus313/macos-wireless-autoswitch/compare/v1.0.4...v1.0.5
[1.0.4]: https://github.com/locus313/macos-wireless-autoswitch/compare/v1.0.3...v1.0.4
[1.0.3]: https://github.com/locus313/macos-wireless-autoswitch/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/locus313/macos-wireless-autoswitch/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/locus313/macos-wireless-autoswitch/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/locus313/macos-wireless-autoswitch/releases/tag/v1.0.0
