#!/bin/bash

#
# macOS Wireless Auto-Switch Installation Script
# Manages installation, update, and removal of the wireless auto-switch utility
#
# Usage: ./install.sh [i|up|ui|--help]
#   i  - Install system components
#   up - Update existing installation
#   ui - Uninstall system components
#
# Requirements: Administrator privileges for system directory access
#

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# Constants
readonly SCRIPT_NAME="install.sh"
readonly NETBASICS_PATH="/Library/Scripts/NetBasics"
readonly LAUNCHDAEMONS_PATH="/Library/LaunchDaemons"
readonly DAEMON_NAME="com.computernetworkbasics.wifionoff"
readonly DAEMON_PLIST="${DAEMON_NAME}.plist"
readonly WIRELESS_SCRIPT="wireless.sh"

# Global variables
SUDO=""

# Menu options for interactive mode
readonly PS3='[Please enter your choice]: '
readonly -a OPTIONS=(
    "install (i): install mode"
    "uninstall (ui): uninstall mode"
    "update (up): update mode"
    "quit: Exit from this menu"
)

#
# Log message with script context
# Arguments: $1 - log message
#
log_message() {
    local message="$1"
    echo "${SCRIPT_NAME}: ${message}"
}

#
# Log error message and exit
# Arguments: $1 - error message, $2 - exit code (optional, defaults to 1)
#
log_error_and_exit() {
    local error_message="$1"
    local exit_code="${2:-1}"
    echo "ERROR: ${SCRIPT_NAME}: ${error_message}" >&2
    exit "$exit_code"
}

#
# Check if running as root, set SUDO variable accordingly
#
configure_sudo() {
    if [[ $(id -u) -eq 0 ]]; then
        SUDO=""
        log_message "Running as root"
    else
        SUDO="sudo"
        log_message "Running as non-root user, will use sudo for privileged operations"
    fi
}

#
# Create required system directories
#
create_directories() {
    log_message "Creating system directories..."
    
    if [[ ! -d "$NETBASICS_PATH" ]]; then
        if ! $SUDO mkdir -p "$NETBASICS_PATH"; then
            log_error_and_exit "Failed to create directory $NETBASICS_PATH"
        fi
        log_message "Created directory: $NETBASICS_PATH"
    else
        log_message "Directory already exists: $NETBASICS_PATH"
    fi
    
    if [[ ! -d "$LAUNCHDAEMONS_PATH" ]]; then
        if ! $SUDO mkdir -p "$LAUNCHDAEMONS_PATH"; then
            log_error_and_exit "Failed to create directory $LAUNCHDAEMONS_PATH"
        fi
        log_message "Created directory: $LAUNCHDAEMONS_PATH"
    else
        log_message "Directory already exists: $LAUNCHDAEMONS_PATH"
    fi
}

#
# Validate that required source files exist
#
validate_source_files() {
    local missing_files=()
    
    if [[ ! -f "$WIRELESS_SCRIPT" ]]; then
        missing_files+=("$WIRELESS_SCRIPT")
    fi
    
    if [[ ! -f "$DAEMON_PLIST" ]]; then
        missing_files+=("$DAEMON_PLIST")
    fi
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        log_error_and_exit "Missing required files: ${missing_files[*]}"
    fi
}

#
# Stop and unload the LaunchDaemon if it's running
#
stop_daemon() {
    local daemon_path="${LAUNCHDAEMONS_PATH}/${DAEMON_PLIST}"
    
    if [[ -f "$daemon_path" ]]; then
        log_message "Stopping LaunchDaemon..."
        if $SUDO launchctl unload "$daemon_path" 2>/dev/null; then
            log_message "LaunchDaemon stopped successfully"
        else
            log_message "LaunchDaemon was not running or failed to stop (this is normal)"
        fi
    fi
}

#
# Load and start the LaunchDaemon
#
start_daemon() {
    local daemon_path="${LAUNCHDAEMONS_PATH}/${DAEMON_PLIST}"
    
    if [[ -f "$daemon_path" ]]; then
        log_message "Starting LaunchDaemon..."
        if $SUDO launchctl load "$daemon_path"; then
            log_message "LaunchDaemon started successfully"
        else
            log_error_and_exit "Failed to start LaunchDaemon"
        fi
    else
        log_error_and_exit "LaunchDaemon plist file not found: $daemon_path"
    fi
}

#
# Install system components
#
install_components() {
    log_message "Starting installation..."
    
    configure_sudo
    validate_source_files
    create_directories
    stop_daemon
    
    # Copy wireless script
    local wireless_dest="${NETBASICS_PATH}/${WIRELESS_SCRIPT}"
    if ! $SUDO cp "$WIRELESS_SCRIPT" "$wireless_dest"; then
        log_error_and_exit "Failed to copy $WIRELESS_SCRIPT to $wireless_dest"
    fi
    log_message "Copied: $WIRELESS_SCRIPT -> $wireless_dest"
    
    # Set script permissions
    if ! $SUDO chmod 755 "$wireless_dest"; then
        log_error_and_exit "Failed to set permissions on $wireless_dest"
    fi
    log_message "Set execute permissions on: $wireless_dest"
    
    # Copy LaunchDaemon plist
    local daemon_dest="${LAUNCHDAEMONS_PATH}/${DAEMON_PLIST}"
    if ! $SUDO cp "$DAEMON_PLIST" "$daemon_dest"; then
        log_error_and_exit "Failed to copy $DAEMON_PLIST to $daemon_dest"
    fi
    log_message "Copied: $DAEMON_PLIST -> $daemon_dest"
    
    # Set plist ownership
    if ! $SUDO chown root:wheel "$daemon_dest"; then
        log_error_and_exit "Failed to set ownership on $daemon_dest"
    fi
    log_message "Set ownership (root:wheel) on: $daemon_dest"
    
    start_daemon
    log_message "Installation completed successfully"
}

#
# Uninstall system components
#
uninstall_components() {
    log_message "Starting uninstallation..."
    
    configure_sudo
    stop_daemon
    
    # Remove wireless script
    local wireless_dest="${NETBASICS_PATH}/${WIRELESS_SCRIPT}"
    if [[ -f "$wireless_dest" ]]; then
        if ! $SUDO rm -f "$wireless_dest"; then
            log_error_and_exit "Failed to remove $wireless_dest"
        fi
        log_message "Removed: $wireless_dest"
    else
        log_message "File not found (already removed): $wireless_dest"
    fi
    
    # Remove LaunchDaemon plist
    local daemon_dest="${LAUNCHDAEMONS_PATH}/${DAEMON_PLIST}"
    if [[ -f "$daemon_dest" ]]; then
        if ! $SUDO rm -f "$daemon_dest"; then
            log_error_and_exit "Failed to remove $daemon_dest"
        fi
        log_message "Removed: $daemon_dest"
    else
        log_message "File not found (already removed): $daemon_dest"
    fi
    
    # Remove directory if empty
    if [[ -d "$NETBASICS_PATH" ]] && [[ -z "$(ls -A "$NETBASICS_PATH")" ]]; then
        if ! $SUDO rmdir "$NETBASICS_PATH"; then
            log_message "Warning: Failed to remove empty directory $NETBASICS_PATH"
        else
            log_message "Removed empty directory: $NETBASICS_PATH"
        fi
    fi
    
    log_message "Uninstallation completed successfully"
}

#
# Update existing installation
#
update_components() {
    log_message "Starting update..."
    
    configure_sudo
    validate_source_files
    stop_daemon
    
    # Update wireless script
    local wireless_dest="${NETBASICS_PATH}/${WIRELESS_SCRIPT}"
    if ! $SUDO cp "$WIRELESS_SCRIPT" "$wireless_dest"; then
        log_error_and_exit "Failed to update $wireless_dest"
    fi
    log_message "Updated: $wireless_dest"
    
    # Set script permissions
    if ! $SUDO chmod 755 "$wireless_dest"; then
        log_error_and_exit "Failed to set permissions on $wireless_dest"
    fi
    
    # Update LaunchDaemon plist
    local daemon_dest="${LAUNCHDAEMONS_PATH}/${DAEMON_PLIST}"
    if ! $SUDO cp "$DAEMON_PLIST" "$daemon_dest"; then
        log_error_and_exit "Failed to update $daemon_dest"
    fi
    log_message "Updated: $daemon_dest"
    
    # Set plist ownership
    if ! $SUDO chown root:wheel "$daemon_dest"; then
        log_error_and_exit "Failed to set ownership on $daemon_dest"
    fi
    
    start_daemon
    log_message "Update completed successfully"
}

#
# Display help information
#
show_help() {
    cat << EOF
macOS Wireless Auto-Switch Installation Script

Usage: $0 [COMMAND]

Commands:
  i, install    Install the wireless auto-switch utility
  up, update    Update the existing installation
  ui, uninstall Remove the wireless auto-switch utility
  --help        Show this help message

Interactive Mode:
  Run without arguments to enter interactive menu mode

Examples:
  $0 i          # Install the utility
  $0 up         # Update existing installation
  $0 ui         # Uninstall the utility

Requirements:
  - Administrator privileges (sudo access)
  - macOS Sonoma (14.x), Sequoia (15.x), or Tahoe (16.x)
  - Source files: $WIRELESS_SCRIPT, $DAEMON_PLIST

For more information, see the project documentation.
EOF
}

#
# Process command line arguments or interactive menu selection
# Arguments: $1 - command/reply
#
process_command() {
    local reply="$1"
    
    case "$reply" in
        "i"|"install"|"1")
            install_components
            ;;
        "ui"|"uninstall"|"2")
            uninstall_components
            ;;
        "up"|"update"|"3")
            update_components
            ;;
        "quit"|"4")
            log_message "Goodbye!"
            exit 0
            ;;
        "--help")
            show_help
            ;;
        "")
            # Empty input in interactive mode - do nothing, continue loop
            return 1
            ;;
        *)
            echo "Invalid option: $reply"
            echo "Use --help for available commands"
            return 1
            ;;
    esac
}

#
# Main execution function
#
main() {
    # Process command line arguments if provided
    if [[ $# -gt 0 ]]; then
        process_command "$1"
        exit $?
    fi
    
    # Interactive menu mode
    log_message "Starting interactive installation menu"
    
    while true; do
        echo
        echo "==== macOS Wireless Auto-Switch Installation Menu ===="
        
        select _ in "${OPTIONS[@]}"; do
            if process_command "$REPLY"; then
                break
            fi
        done
    done
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
