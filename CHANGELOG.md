# Changelog

All notable changes to macOS Wireless Auto-Switch are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/locus313/macos-wireless-autoswitch/compare/v1.0.6...HEAD
[1.0.6]: https://github.com/locus313/macos-wireless-autoswitch/compare/v1.0.5...v1.0.6
[1.0.5]: https://github.com/locus313/macos-wireless-autoswitch/compare/v1.0.4...v1.0.5
[1.0.4]: https://github.com/locus313/macos-wireless-autoswitch/compare/v1.0.3...v1.0.4
[1.0.3]: https://github.com/locus313/macos-wireless-autoswitch/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/locus313/macos-wireless-autoswitch/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/locus313/macos-wireless-autoswitch/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/locus313/macos-wireless-autoswitch/releases/tag/v1.0.0
