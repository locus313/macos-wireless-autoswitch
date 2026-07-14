#!/usr/bin/env bats
#
# Tests for wireless.sh — covers issues #43, #45, #46, #47, #48
#

WIRELESS_SH="$BATS_TEST_DIRNAME/../wireless.sh"

setup() {
    # Prepend helpers so unqualified commands (uname, ifconfig, logger) use stubs.
    # /usr/sbin/networksetup stub is installed separately by validate.yml.
    export PATH="$BATS_TEST_DIRNAME/helpers:$PATH"
    # shellcheck source=../wireless.sh
    source "$WIRELESS_SH"
    set +euo pipefail  # prevent sourced script's strict mode from breaking BATS assertions
}

# ── get_interface_ip (#45) ────────────────────────────────────────────────────

@test "get_interface_ip: returns valid IP" {
    export IFCONFIG_OUTPUT="inet 192.168.1.100 netmask 0xffffff00 broadcast 192.168.1.255"
    run get_interface_ip "en0"
    [ "$status" -eq 0 ]
    [ "$output" = "192.168.1.100" ]
}

@test "get_interface_ip: excludes loopback 127.0.0.1" {
    export IFCONFIG_OUTPUT="inet 127.0.0.1 netmask 0xff000000"
    run get_interface_ip "en0"
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "get_interface_ip: excludes self-assigned 169.254.x.x" {
    export IFCONFIG_OUTPUT="inet 169.254.1.5 netmask 0xffff0000"
    run get_interface_ip "en0"
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "get_interface_ip: returns empty when no inet line" {
    export IFCONFIG_OUTPUT="flags=8863<UP,BROADCAST> mtu 1500"
    run get_interface_ip "en0"
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "get_interface_ip: returns first valid IP when multiple present" {
    export IFCONFIG_OUTPUT="inet 192.168.1.100 netmask 0xffffff00
inet 10.0.0.1 netmask 0xffffff00"
    run get_interface_ip "en0"
    [ "$status" -eq 0 ]
    [ "$output" = "192.168.1.100" ]
}

# ── get_wired_interfaces (#46) ────────────────────────────────────────────────

@test "get_wired_interfaces: returns single Ethernet device" {
    export NETWORKSETUP_SERVICEORDER="(Hardware Port: Ethernet, Device: en0)"
    run get_wired_interfaces
    [ "$output" = "en0" ]
}

@test "get_wired_interfaces: returns Thunderbolt Ethernet and Ethernet" {
    export NETWORKSETUP_SERVICEORDER="(Hardware Port: Thunderbolt Ethernet Slot 1, Device: en1)
(Hardware Port: Ethernet, Device: en0)"
    run get_wired_interfaces
    [ "${#lines[@]}" -eq 2 ]
    [ "${lines[0]}" = "en1" ]
    [ "${lines[1]}" = "en0" ]
}

@test "get_wired_interfaces: returns AX88179A USB adapter" {
    export NETWORKSETUP_SERVICEORDER="(Hardware Port: AX88179A USB Ethernet, Device: en3)"
    run get_wired_interfaces
    [ "$output" = "en3" ]
}

@test "get_wired_interfaces: returns empty for Wi-Fi only" {
    export NETWORKSETUP_SERVICEORDER="(Hardware Port: Wi-Fi, Device: en1)"
    run get_wired_interfaces
    [ "$output" = "" ]
}

@test "get_wired_interfaces: excludes bridge interfaces" {
    export NETWORKSETUP_SERVICEORDER="(Hardware Port: Thunderbolt Bridge, Device: bridge0)"
    run get_wired_interfaces
    [ "$output" = "" ]
}

@test "get_wired_interfaces: returns empty when no adapters listed" {
    export NETWORKSETUP_SERVICEORDER=""
    run get_wired_interfaces
    [ "$output" = "" ]
}

# ── get_wifi_interfaces (#46) ─────────────────────────────────────────────────

@test "get_wifi_interfaces: returns single Wi-Fi device" {
    export NETWORKSETUP_HARDWAREPORTS="Hardware Port: Wi-Fi
Device: en0
Ethernet Address: aa:bb:cc:dd:ee:ff

Hardware Port: Bluetooth PAN
Device: en1
Ethernet Address: ff:ee:dd:cc:bb:aa"
    run get_wifi_interfaces
    [ "$status" -eq 0 ]
    [ "$output" = "en0" ]
}

@test "get_wifi_interfaces: returns both devices when two Wi-Fi adapters present" {
    export NETWORKSETUP_HARDWAREPORTS="Hardware Port: Wi-Fi
Device: en0
Ethernet Address: aa:bb:cc:dd:ee:ff

Hardware Port: Wi-Fi
Device: en2
Ethernet Address: 11:22:33:44:55:66"
    run get_wifi_interfaces
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 2 ]
    [ "${lines[0]}" = "en0" ]
    [ "${lines[1]}" = "en2" ]
}

@test "get_wifi_interfaces: returns empty when no Wi-Fi adapters" {
    export NETWORKSETUP_HARDWAREPORTS="Hardware Port: Bluetooth PAN
Device: en1
Ethernet Address: ff:ee:dd:cc:bb:aa"
    run get_wifi_interfaces
    [ "$output" = "" ]
}

# ── detect_wired_connection (#47) ─────────────────────────────────────────────

@test "detect_wired_connection: returns 1 when no wired interfaces" {
    export INTERFACES=""
    run detect_wired_connection
    [ "$status" -eq 1 ]
}

@test "detect_wired_connection: returns 1 when interface has no IP" {
    export INTERFACES="en0"
    export IFCONFIG_OUTPUT=""
    run detect_wired_connection
    [ "$status" -eq 1 ]
}

@test "detect_wired_connection: returns 0 when interface has valid IP" {
    export INTERFACES="en0"
    export IFCONFIG_OUTPUT="inet 192.168.1.100 netmask 0xffffff00"
    run detect_wired_connection
    [ "$status" -eq 0 ]
}

@test "detect_wired_connection: returns 0 when second interface has IP (first has none)" {
    export INTERFACES="en0
en1"
    export IFCONFIG_EN0_OUTPUT=""
    export IFCONFIG_EN1_OUTPUT="inet 10.0.0.5 netmask 0xffffff00"
    run detect_wired_connection
    [ "$status" -eq 0 ]
}

@test "detect_wired_connection: returns 1 when only self-assigned IP present" {
    export INTERFACES="en0"
    export IFCONFIG_OUTPUT="inet 169.254.1.5 netmask 0xffff0000"
    run detect_wired_connection
    [ "$status" -eq 1 ]
}

# ── toggle_wifi (#48) ─────────────────────────────────────────────────────────

@test "toggle_wifi off: exits 0 when networksetup succeeds" {
    export WIFIINTERFACES="en0"
    export NETWORKSETUP_SETAIRPORT_EXIT=0
    run toggle_wifi "off"
    [ "$status" -eq 0 ]
}

@test "toggle_wifi on: exits 0 when networksetup succeeds" {
    export WIFIINTERFACES="en0"
    export NETWORKSETUP_SETAIRPORT_EXIT=0
    run toggle_wifi "on"
    [ "$status" -eq 0 ]
}

@test "toggle_wifi: exits 1 for invalid state" {
    export WIFIINTERFACES="en0"
    run toggle_wifi "maybe"
    [ "$status" -eq 1 ]
}

@test "toggle_wifi: exits 0 and skips when no WiFi interfaces" {
    export WIFIINTERFACES=""
    run toggle_wifi "off"
    [ "$status" -eq 0 ]
}

@test "toggle_wifi: exits 1 after completing loop when one adapter fails" {
    export WIFIINTERFACES="en0
en1"
    export NETWORKSETUP_SETAIRPORT_EN0_EXIT=0
    export NETWORKSETUP_SETAIRPORT_EN1_EXIT=1
    run toggle_wifi "off"
    [ "$status" -eq 1 ]
}

@test "toggle_wifi: exits 0 when all adapters succeed" {
    export WIFIINTERFACES="en0
en1"
    export NETWORKSETUP_SETAIRPORT_EN0_EXIT=0
    export NETWORKSETUP_SETAIRPORT_EN1_EXIT=0
    run toggle_wifi "off"
    [ "$status" -eq 0 ]
}
