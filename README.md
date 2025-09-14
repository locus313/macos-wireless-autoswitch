# macOS Wireless Auto-Switch

*Automatically manage WiFi connections when wired network is available*

[![macOS](https://img.shields.io/badge/macOS-Ventura%20%7C%20Sonoma%20%7C%20Sequoia-blue)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/Bash-4%2B-green)](https://www.gnu.org/software/bash/)

[Features](#features) • [Installation](#installation) • [Usage](#usage) • [How it works](#how-it-works) • [Troubleshooting](#troubleshooting)

A lightweight macOS utility that automatically toggles WiFi off when a wired Ethernet connection is detected, and back on when disconnected. No more manually switching networks or dealing with connection conflicts between wired and wireless interfaces.

## Features

- **🔄 Automatic WiFi Toggle** - Seamlessly switches WiFi off/on based on wired connection status
- **⚡ Real-time Detection** - Uses macOS LaunchDaemon for instant network state monitoring
- **🔌 Multi-adapter Support** - Works with Ethernet, Thunderbolt, LAN, and USB-C adapters (including AX88179A)
- **🛡️ System Integration** - Runs as a system service with proper permissions and logging
- **📊 Smart IP Detection** - Ignores loopback and self-assigned addresses for accurate detection
- **🖥️ Modern macOS Support** - Compatible with Ventura (13.x), Sonoma (14.x), and Sequoia (15.x)

## Installation

### Prerequisites

- macOS Ventura (13.x) or later
- Administrator privileges
- Bash 4+ (recommended)

### Quick Install

1. Clone or download this repository:
   ```bash
   git clone https://github.com/locus313/macos-wireless-autoswitch.git
   cd macos-wireless-autoswitch
   ```

2. Run the installation script:
   ```bash
   ./install.sh i
   ```

The installer will:
- Copy scripts to `/Library/Scripts/NetBasics/`
- Install the LaunchDaemon configuration
- Set proper permissions and ownership
- Start monitoring network changes immediately

> [!NOTE]
> The script requires `sudo` privileges to install system-level components.

## Usage

### Management Commands

The `install.sh` script provides an interactive menu or can be used with direct commands:

```bash
# Install the service
./install.sh i

# Update to latest version
./install.sh up

# Uninstall completely
./install.sh ui

# Interactive menu (default)
./install.sh
```

### Verification

After installation, you can verify the service is running:

```bash
# Check if LaunchDaemon is loaded
sudo launchctl list | grep com.computernetworkbasics.wifionoff

# View recent log entries
log show --predicate 'subsystem == "com.apple.console"' --info --last 1h | grep wireless.sh
```

## How it works

The system consists of three main components:

### 1. Network Detection (`wireless.sh`)
- Scans for wired network interfaces (Ethernet, LAN, Thunderbolt, AX88179A)
- Checks for valid IP addresses (excluding loopback and self-assigned)
- Controls WiFi state using `networksetup -setairportpower`

### 2. System Monitoring (`com.computernetworkbasics.wifionoff.plist`)
- LaunchDaemon watches `/Library/Preferences/SystemConfiguration` for changes
- Triggers the wireless script whenever network configuration changes
- Runs with root privileges for system-level network control

### 3. Management Interface (`install.sh`)
- Interactive installation, update, and removal
- Proper permission setting and system integration
- Sudo privilege detection and handling

### Network Detection Logic

```bash
# Example: Check what interfaces are detected
networksetup -listnetworkserviceorder | grep "Hardware Port" | grep "Ethernet\|LAN\|Thunderbolt\|AX88179A"

# Example: View current WiFi status
networksetup -getairportpower Wi-Fi
```

## Troubleshooting

### Common Issues

**WiFi not switching automatically:**
```bash
# Check if LaunchDaemon is running
sudo launchctl list | grep wifionoff

# Restart the service
sudo launchctl unload /Library/LaunchDaemons/com.computernetworkbasics.wifionoff.plist
sudo launchctl load /Library/LaunchDaemons/com.computernetworkbasics.wifionoff.plist
```

**Script not detecting wired connection:**
```bash
# Test interface detection manually
./wireless.sh

# Check system logs for errors
log show --predicate 'process == "wireless.sh"' --info --last 1h
```

**Permission errors:**
```bash
# Verify file permissions
ls -la /Library/Scripts/NetBasics/wireless.sh
ls -la /Library/LaunchDaemons/com.computernetworkbasics.wifionoff.plist
```

### Supported Adapters

The script automatically detects these adapter types:
- Built-in Ethernet ports
- Thunderbolt Ethernet adapters
- USB-C Ethernet adapters (including AX88179A chipset)
- Any interface with "LAN" in the hardware port name

### Manual Testing

You can test the core functionality manually:

```bash
# Run the detection script directly
sudo /Library/Scripts/NetBasics/wireless.sh

# Check what network interfaces are available
networksetup -listallhardwareports
```

## Uninstallation

To completely remove the service:

```bash
./install.sh ui
```

This will:
- Stop and unload the LaunchDaemon
- Remove all installed files
- Clean up system configurations

## Authors & Contributors

- **Ryan Lininger** - Original script author - [Source](https://web.archive.org/web/20180508004545/www.computernetworkbasics.com/2012/12/automatically-turn-off-wireless-in-osx-including-mountain-lion/)
- **locus313** - Maintenance and modern macOS compatibility

## License

This project is open source and available under the MIT License.