#!/bin/bash
#
# Drift check for macos-wireless-autoswitch maintenance-matrix rules.
# Run locally or in CI to catch silent desync between files.
#
# Checks:
#   1. LOOP_PREVENTION_DELAY (wireless.sh) must match ThrottleInterval (plist)
#   2. NETBASICS_PATH (install.sh) must appear in plist ProgramArguments
#
# Usage: bash scripts/check_drift.sh
#

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WIRELESS="$ROOT/wireless.sh"
INSTALL="$ROOT/install.sh"
PLIST="$ROOT/com.computernetworkbasics.wifionoff.plist"

failures=0

fail() {
    echo "DRIFT: $1" >&2
    failures=$((failures + 1))
}

# ── Check 1: LOOP_PREVENTION_DELAY matches ThrottleInterval ─────────────────
delay=$(grep -E '^readonly LOOP_PREVENTION_DELAY=' "$WIRELESS" | grep -oE '[0-9]+')
throttle=$(grep -A1 '<key>ThrottleInterval</key>' "$PLIST" | grep -oE '[0-9]+')

if [[ -z "$delay" ]]; then
    fail "Could not extract LOOP_PREVENTION_DELAY from wireless.sh"
elif [[ -z "$throttle" ]]; then
    fail "Could not extract ThrottleInterval from plist"
elif [[ "$throttle" -lt "$delay" ]]; then
    fail "ThrottleInterval ($throttle) < LOOP_PREVENTION_DELAY ($delay) — plist will restart the daemon before the sleep completes, causing a restart loop. See docs/failures/launchdaemon-restart-loop.md"
else
    echo "OK: LOOP_PREVENTION_DELAY=$delay, ThrottleInterval=$throttle"
fi

# ── Check 2: NETBASICS_PATH appears in plist ProgramArguments ────────────────
netbasics=$(grep -E '^readonly NETBASICS_PATH=' "$INSTALL" | grep -oE '"[^"]+"' | tr -d '"')

if [[ -z "$netbasics" ]]; then
    fail "Could not extract NETBASICS_PATH from install.sh"
elif ! grep -qF "$netbasics" "$PLIST"; then
    fail "NETBASICS_PATH ('$netbasics') not found in plist ProgramArguments — daemon will launch the wrong script path. See docs/failures/install-path-desync.md"
else
    echo "OK: NETBASICS_PATH='$netbasics' found in plist"
fi

# ── Result ───────────────────────────────────────────────────────────────────
if [[ $failures -gt 0 ]]; then
    echo ""
    echo "Drift check failed: $failures issue(s) found." >&2
    exit 1
fi

echo ""
echo "Drift check passed."
