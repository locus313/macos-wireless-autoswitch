# LaunchDaemon Restart Loop from Delay/Throttle Mismatch

## Summary

The LaunchDaemon enters a rapid restart loop when `LOOP_PREVENTION_DELAY` in `wireless.sh` exceeds `ThrottleInterval` in `com.computernetworkbasics.wifionoff.plist`. Each script run triggers another network-configuration event before the sleep completes, causing `launchd` to re-launch the script continuously. This burns CPU and floods system logs.

## Root Cause

`wireless.sh` ends with `sleep $LOOP_PREVENTION_DELAY` to dampen the event-triggered re-launch cycle. `launchd` enforces its own minimum interval between re-launches via `ThrottleInterval`. If `ThrottleInterval < LOOP_PREVENTION_DELAY`, the sleep in the script is the only guard — and any future change that reduces or removes the sleep will cause the loop.

The intended invariant: **`ThrottleInterval` must be ≥ `LOOP_PREVENTION_DELAY`** so both guards are active.

## Prevention

- `scripts/check_drift.sh` — fails CI if `ThrottleInterval` < `LOOP_PREVENTION_DELAY`.
- Maintenance matrix in `.github/copilot-instructions.md` — documents that changing `LOOP_PREVENTION_DELAY` requires updating `ThrottleInterval` to match or exceed it.

## Evidence

- `wireless.sh`: `readonly LOOP_PREVENTION_DELAY=10`
- `com.computernetworkbasics.wifionoff.plist`: `<key>ThrottleInterval</key><integer>10</integer>`
- Maintenance matrix row: `wireless.sh — LOOP_PREVENTION_DELAY → com.computernetworkbasics.wifionoff.plist ThrottleInterval (should match or exceed)`
