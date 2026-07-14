# Daemon Launch Failure from Install Path Desync

## Summary

The LaunchDaemon silently fails to execute after installation when `NETBASICS_PATH` in `install.sh` and the `ProgramArguments` path in `com.computernetworkbasics.wifionoff.plist` disagree. `launchd` loads the plist successfully (no XML errors) but attempts to run a path that does not exist, leaving WiFi unmanaged with no obvious error in the UI.

## Root Cause

The install path is defined in two separate places:

- `install.sh`: `readonly NETBASICS_PATH="/Library/Scripts/NetBasics"` — used when copying `wireless.sh` to the system.
- `com.computernetworkbasics.wifionoff.plist`: `<string>/Library/Scripts/NetBasics/wireless.sh</string>` — the path `launchd` launches.

If an agent updates one without the other (e.g., renames the install directory), `launchd` silently fails because the ProgramArguments path does not exist. The daemon appears loaded in `launchctl list` but never runs.

## Prevention

- `scripts/check_drift.sh` — fails CI if `NETBASICS_PATH` from `install.sh` is not found in the plist `ProgramArguments` string.
- `validate.yml` content check — verifies both `install.sh` and `plist` reference `/Library/Scripts/NetBasics`.
- Maintenance matrix row: `install.sh — install paths → com.computernetworkbasics.wifionoff.plist ProgramArguments, validate.yml path checks, AGENTS.md install locations`

## Evidence

- `install.sh`: `readonly NETBASICS_PATH="/Library/Scripts/NetBasics"`
- `com.computernetworkbasics.wifionoff.plist`: `<string>/Library/Scripts/NetBasics/wireless.sh</string>`
- `validate.yml` content check: `grep -q "/Library/Scripts/NetBasics/wireless.sh" com.computernetworkbasics.wifionoff.plist`
