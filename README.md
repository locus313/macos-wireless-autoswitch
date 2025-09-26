# macOS Wireless Auto-Switch

[![macOS](https://img.shields.io/badge/macOS-Sonoma%20|%20Sequoia%20|%20Tahoe-blue?style=flat-square)](https://www.apple.com/macos/)
[![Bash](https://img.shields.io/badge/Bash-4+-green?style=flat-square)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)](LICENSE)

⭐ If you like this project, star it on GitHub — it helps a lot!

[Features](#features) • [Installation](#installation) • [Usage](#usage) • [How it works](#how-it-works) • [Troubleshooting](#troubleshooting)

A lightweight macOS utility that automatically toggles WiFi off when a wired Ethernet connection is detected, and back on when disconnected. Perfect for eliminating network conflicts and ensuring optimal connection performance without manual intervention.

## Features

- **Automatic WiFi Management** - Seamlessly switches WiFi off/on based on wired connection status
- **Real-time Network Monitoring** - Uses macOS LaunchDaemon for instant network state detection
- **Multi-adapter Support** - Works with Ethernet, Thunderbolt, LAN, and USB-C adapters (including AX88179A)
- **System Integration** - Runs as a native macOS system service with proper logging
- **Smart IP Detection** - Ignores loopback and self-assigned addresses for accurate connection status
- **Modern macOS Support** - Compatible with Sonoma (14.x), Sequoia (15.x), and Tahoe (16.x)

## Installation

### Prerequisites

- macOS Sonoma (14.x) or later
- Administrator privileges for system installation
- Bash 4+ (included with modern macOS)

### Quick Start

1. Clone the repository:
   ```bash
   git clone https://github.com/locus313/macos-wireless-autoswitch.git
   cd macos-wireless-autoswitch
   ```

2. Install the service:
   ```bash
   ./install.sh i
   ```

The installer automatically:
- Copies scripts to `/Library/Scripts/NetBasics/`
- Installs the LaunchDaemon configuration
- Sets proper permissions and ownership
- Starts monitoring network changes immediately

> [!NOTE]
> Installation requires `sudo` privileges to create system-level components.

## Usage

### Management Commands

Use the `install.sh` script for all management operations:

```bash
# Install the service
./install.sh i

# Update to latest version  
./install.sh up

# Uninstall completely
./install.sh ui

# Interactive menu
./install.sh
```

### Verification

After installation, verify the service is working:

```bash
# Check LaunchDaemon status
sudo launchctl list | grep com.computernetworkbasics.wifionoff

# View logs
log show --predicate 'subsystem == "com.apple.console"' --info --last 1h | grep wireless.sh
```

## How it works

The system consists of three components working together:

### Network Detection Engine (`wireless.sh`)
- Automatically scans for wired network interfaces using hardware port detection
- Validates active connections by checking for legitimate IP addresses
- Controls WiFi state using `networksetup -setairportpower` commands
- Implements smart filtering to exclude loopback and self-assigned addresses

### System Monitoring (`com.computernetworkbasics.wifionoff.plist`)
- LaunchDaemon watches `/Library/Preferences/SystemConfiguration` for network changes
- Triggers the wireless script whenever network configuration is modified
- Runs with root privileges for system-level network control
- Uses throttling to prevent excessive execution during rapid network changes

### Management Interface (`install.sh`)
- Provides interactive installation, update, and removal capabilities
- Handles proper permission setting and system integration
- Includes sudo privilege detection and validation
- Offers both command-line and menu-driven operation modes

### Supported Network Adapters

The utility automatically detects and works with:
- Built-in Ethernet ports
- Thunderbolt Ethernet adapters
- USB-C Ethernet adapters (including AX88179A chipset)
- Any interface with "LAN" designation

## Troubleshooting

### Common Issues

**WiFi not switching automatically:**
```bash
# Restart the service
sudo launchctl unload /Library/LaunchDaemons/com.computernetworkbasics.wifionoff.plist
sudo launchctl load /Library/LaunchDaemons/com.computernetworkbasics.wifionoff.plist
```

**Script not detecting wired connection:**
```bash
# Test detection manually
sudo /Library/Scripts/NetBasics/wireless.sh

# Check available interfaces
networksetup -listallhardwareports
```

**Permission errors:**
```bash
# Verify file permissions
ls -la /Library/Scripts/NetBasics/wireless.sh
ls -la /Library/LaunchDaemons/com.computernetworkbasics.wifionoff.plist
```

### Manual Testing

Test the core functionality directly:

```bash
# Run detection script manually
sudo /Library/Scripts/NetBasics/wireless.sh

# Check current WiFi status
networksetup -getairportpower Wi-Fi

# List detected wired interfaces
networksetup -listnetworkserviceorder | grep "Hardware Port" | grep "Ethernet\|LAN\|Thunderbolt\|AX88179A"
```

### System Requirements

- **macOS Version**: Sonoma (14.x), Sequoia (15.x), or Tahoe (16.x)
- **Shell**: Bash 4+ (included with macOS)
- **Privileges**: Administrator access for installation
- **Network Stack**: Standard macOS networking components

## Authors

- **Ryan Lininger** - Original script concept and implementation
- **locus313** - Modern macOS compatibility, architecture improvements, and maintenance

## Resources

- [macOS LaunchDaemon Documentation](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)
- [NetworkSetup Command Reference](https://ss64.com/osx/networksetup.html)
- [Original Implementation](https://web.archive.org/web/20180508004545/www.computernetworkbasics.com/2012/12/automatically-turn-off-wireless-in-osx-including-mountain-lion/)