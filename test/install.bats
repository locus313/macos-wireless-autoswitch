#!/usr/bin/env bats
#
# Tests for install.sh — covers issues #49, #50
#

INSTALL_SH="$BATS_TEST_DIRNAME/../install.sh"

setup() {
    export PATH="$BATS_TEST_DIRNAME/helpers:$PATH"
    # shellcheck source=../install.sh
    source "$INSTALL_SH"
    set +euo pipefail
}

# ── validate_source_files (#50) ───────────────────────────────────────────────
# Run in a fresh bash -c subshell with a temp dir so the relative-path constants
# (WIRELESS_SCRIPT="wireless.sh", DAEMON_PLIST="...plist") resolve correctly.

@test "validate_source_files: passes when both files present" {
    local d; d=$(mktemp -d)
    touch "$d/wireless.sh" "$d/com.computernetworkbasics.wifionoff.plist"
    run bash -c "cd '$d' && source '$INSTALL_SH' && validate_source_files"
    rm -rf "$d"
    [ "$status" -eq 0 ]
}

@test "validate_source_files: fails and names file when wireless.sh missing" {
    local d; d=$(mktemp -d)
    touch "$d/com.computernetworkbasics.wifionoff.plist"
    run bash -c "cd '$d' && source '$INSTALL_SH' && validate_source_files"
    rm -rf "$d"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "wireless.sh" ]]
}

@test "validate_source_files: fails and names file when plist missing" {
    local d; d=$(mktemp -d)
    touch "$d/wireless.sh"
    run bash -c "cd '$d' && source '$INSTALL_SH' && validate_source_files"
    rm -rf "$d"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "wifionoff.plist" ]]
}

@test "validate_source_files: fails when both files missing" {
    local d; d=$(mktemp -d)
    run bash -c "cd '$d' && source '$INSTALL_SH' && validate_source_files"
    rm -rf "$d"
    [ "$status" -eq 1 ]
}

# ── configure_sudo (#50) ──────────────────────────────────────────────────────

@test "configure_sudo: SUDO is empty when uid is 0 (root)" {
    export ID_OUTPUT=0
    configure_sudo
    [ "$SUDO" = "" ]
}

@test "configure_sudo: SUDO is 'sudo' for non-root user" {
    export ID_OUTPUT=501
    configure_sudo
    [ "$SUDO" = "sudo" ]
}

# ── process_command (#49) ─────────────────────────────────────────────────────

@test "process_command 'i' calls install_components" {
    install_components() { echo "install_called"; }
    run process_command "i"
    [ "$status" -eq 0 ]
    [ "$output" = "install_called" ]
}

@test "process_command 'install' calls install_components" {
    install_components() { echo "install_called"; }
    run process_command "install"
    [ "$status" -eq 0 ]
    [ "$output" = "install_called" ]
}

@test "process_command '1' calls install_components" {
    install_components() { echo "install_called"; }
    run process_command "1"
    [ "$status" -eq 0 ]
    [ "$output" = "install_called" ]
}

@test "process_command 'ui' calls uninstall_components" {
    uninstall_components() { echo "uninstall_called"; }
    run process_command "ui"
    [ "$status" -eq 0 ]
    [ "$output" = "uninstall_called" ]
}

@test "process_command 'uninstall' calls uninstall_components" {
    uninstall_components() { echo "uninstall_called"; }
    run process_command "uninstall"
    [ "$status" -eq 0 ]
    [ "$output" = "uninstall_called" ]
}

@test "process_command '2' calls uninstall_components" {
    uninstall_components() { echo "uninstall_called"; }
    run process_command "2"
    [ "$status" -eq 0 ]
    [ "$output" = "uninstall_called" ]
}

@test "process_command 'up' calls update_components" {
    update_components() { echo "update_called"; }
    run process_command "up"
    [ "$status" -eq 0 ]
    [ "$output" = "update_called" ]
}

@test "process_command 'update' calls update_components" {
    update_components() { echo "update_called"; }
    run process_command "update"
    [ "$status" -eq 0 ]
    [ "$output" = "update_called" ]
}

@test "process_command '3' calls update_components" {
    update_components() { echo "update_called"; }
    run process_command "3"
    [ "$status" -eq 0 ]
    [ "$output" = "update_called" ]
}

@test "process_command 'quit' exits 0" {
    run process_command "quit"
    [ "$status" -eq 0 ]
}

@test "process_command '4' exits 0" {
    run process_command "4"
    [ "$status" -eq 0 ]
}

@test "process_command '--help' shows usage without exiting" {
    run process_command "--help"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage" ]]
}

@test "process_command returns 1 for unknown input" {
    run process_command "garbage"
    [ "$status" -eq 1 ]
}

@test "process_command returns 1 for empty input" {
    run process_command ""
    [ "$status" -eq 1 ]
}
