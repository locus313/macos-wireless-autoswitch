#!/bin/bash

#
# macOS Wireless Auto-Switch Utility
# Automatically toggles WiFi off when wired Ethernet connection is detected
# and back on when disconnected. Supports Ventura, Sonoma, and Sequoia.
#
# Requirements: Root privileges, macOS 13+, Bash 4+
# Usage: Executed automatically by LaunchDaemon on network configuration changes
#

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# Constants
readonly SCRIPT_NAME="wireless.sh"
readonly SUPPORTED_ADAPTERS="Ethernet|LAN|Thunderbolt|AX88179A"
readonly SUPPORTED_OS_VERSIONS="22|23|24"  # Ventura, Sonoma, Sequoia
readonly LOOP_PREVENTION_DELAY=10

# Global variables
IPFOUND=""
OSVERSION=""
INTERFACES=""
WIFIINTERFACES=""

#
# Log message to system log with script context
# Arguments: $1 - log message
#
log_message() {
    local message="$1"
    logger "${SCRIPT_NAME}: ${message}"
    echo "${SCRIPT_NAME}: ${message}"
}

#
# Get the current macOS version number
# Returns: OS version number (22, 23, 24, etc.)
#
get_os_version() {
    uname -a | awk '{print $3}' | awk 'BEGIN {FS = "."} ; {print $1}'
}

#
# Get list of wired ethernet interfaces by hardware port type
# Returns: Space-separated list of interface names
#
get_wired_interfaces() {
    /usr/sbin/networksetup -listnetworkserviceorder | \
        grep "Hardware Port" | \
        grep -E "${SUPPORTED_ADAPTERS}" | \
        awk -F ": " '{print $3}' | \
        sed 's/)//g' | \
        grep -v "bridge" | \
        tr '\n' ' ' | \
        sed 's/[[:space:]]*$//'
}

#
# Get list of WiFi interfaces
# Returns: Space-separated list of WiFi interface names  
#
get_wifi_interfaces() {
    /usr/sbin/networksetup -listallhardwareports | \
        tr '\n' ' ' | \
        sed -e 's/Hardware Port:/\n/g' | \
        grep Wi-Fi | \
        awk '{print $3}'
}

#
# Check if a network interface has a valid IP address
# Arguments: $1 - interface name
# Returns: IP address if valid, empty string otherwise
#
get_interface_ip() {
    local interface="$1"
    
    if [[ -z "$interface" ]]; then
        return 1
    fi
    
    # Get IP address, excluding loopback and self-assigned addresses
    local ip_result
    ip_result=$(ifconfig "$interface" 2>/dev/null | \
        grep -E 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | \
        grep -E -v '127\.0\.0\.1|169\.254\.' | \
        awk '{print $2}' | \
        head -1 2>/dev/null)
    
    echo "$ip_result"
}

#
# Check if any wired interface has a valid IP address
# Sets global IPFOUND variable to "true" if found
#
detect_wired_connection() {
    IPFOUND=""
    
    log_message "Starting wired connection detection..."
    
    if [[ -z "$INTERFACES" ]]; then
        log_message "No wired interfaces detected"
        return 0
    fi
    
    log_message "Checking interfaces: $INTERFACES"
    
    for interface in $INTERFACES; do
        log_message "Checking interface: $interface"
        local ip_address
        ip_address=$(get_interface_ip "$interface")
        
        if [[ -n "$ip_address" ]]; then
            IPFOUND="true"
            log_message "Active wired connection detected on interface $interface with IP $ip_address"
            break
        else
            log_message "No IP found on interface $interface"
        fi
    done
    
    if [[ -z "$IPFOUND" ]]; then
        log_message "No active wired connections detected"
    fi
}

#
# Toggle WiFi state based on wired connection status
# Arguments: $1 - desired state ("on" or "off")
#
toggle_wifi() {
    local desired_state="$1"
    
    if [[ -z "$WIFIINTERFACES" ]]; then
        log_message "No WiFi interfaces found - skipping WiFi toggle"
        return 0
    fi
    
    if [[ "$desired_state" != "on" && "$desired_state" != "off" ]]; then
        log_message "ERROR: Invalid WiFi state '$desired_state'. Must be 'on' or 'off'"
        exit 1
    fi
    
    # Execute WiFi toggle command
    if ! /usr/sbin/networksetup -setairportpower "$WIFIINTERFACES" "$desired_state"; then
        log_message "ERROR: Failed to set WiFi power to $desired_state on interface $WIFIINTERFACES"
        exit 1
    fi
    
    log_message "Successfully turned $desired_state WiFi on interface $WIFIINTERFACES"
}

#
# Main execution logic
#
main() {
    log_message "Starting network detection and WiFi management"
    
    # Get system information
    OSVERSION=$(get_os_version)
    log_message "Detected macOS version: $OSVERSION"
    
    # Validate OS compatibility
    if [[ ! "$OSVERSION" =~ ^($SUPPORTED_OS_VERSIONS)$ ]]; then
        log_message "WARNING: Unsupported macOS version $OSVERSION. Supported versions: Ventura (22), Sonoma (23), Sequoia (24)"
        exit 1
    fi
    
    # Get network interfaces
    INTERFACES=$(get_wired_interfaces)
    WIFIINTERFACES=$(get_wifi_interfaces)
    
    log_message "Detected wired interfaces: ${INTERFACES:-none}"
    log_message "Detected WiFi interfaces: ${WIFIINTERFACES:-none}"
    
    # Detect wired connection status
    detect_wired_connection
    
    # Manage WiFi state based on wired connection
    if [[ -n "$IPFOUND" ]]; then
        toggle_wifi "off"
        log_message "WiFi disabled due to active wired connection"
    else
        toggle_wifi "on"
        log_message "WiFi enabled due to no active wired connections"
    fi
    
    # Prevent LaunchDaemon restart loops
    log_message "Sleeping ${LOOP_PREVENTION_DELAY} seconds to prevent restart loops"
    sleep "$LOOP_PREVENTION_DELAY"
    
    log_message "Network detection and WiFi management completed successfully"
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
