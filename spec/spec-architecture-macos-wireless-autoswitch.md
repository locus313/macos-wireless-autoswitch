---
title: Architecture Specification - macOS Wireless Auto-Switch Utility
version: 1.0
date_created: 2025-09-14
last_updated: 2025-09-14
owner: System Architecture Team
tags: [architecture, macos, networking, launchd, system-utility, automation]
---

# Introduction

This specification defines the architecture, requirements, and implementation guidelines for the macOS Wireless Auto-Switch utility - a system service that automatically manages WiFi connectivity based on wired network adapter status. The utility provides seamless network switching without user intervention, eliminating connection conflicts between wired and wireless interfaces.

## 1. Purpose & Scope

### Purpose
Define the complete architecture and requirements for a macOS system utility that automatically toggles WiFi connectivity based on the presence of active wired network connections.

### Scope
- **In Scope**: Network interface detection, WiFi state management, system service integration, installation/management tooling, macOS compatibility (Ventura 13.x, Sonoma 14.x, Sequoia 15.x)
- **Out of Scope**: GUI applications, network configuration management beyond WiFi toggle, third-party network managers, cross-platform support
- **Target Audience**: System administrators, developers maintaining macOS network automation tools, DevOps engineers
- **Assumptions**: Administrator privileges available, standard macOS networking stack, bash shell environment

## 2. Definitions

- **LaunchDaemon**: macOS system service that runs with root privileges and starts automatically at boot
- **NetworkSetup**: macOS command-line utility for network configuration management
- **Hardware Port**: Physical network interface identifier in macOS network configuration
- **Airport Power**: macOS WiFi radio state (on/off) controlled via networksetup command
- **System Configuration**: macOS framework for network and system state monitoring located at `/Library/Preferences/SystemConfiguration`
- **Self-Assigned Address**: IPv4 address in 169.254.x.x range assigned when DHCP fails
- **Wired Interface**: Ethernet, Thunderbolt, LAN, or USB-C network adapters with active IP assignment

## 3. Requirements, Constraints & Guidelines

### Functional Requirements
- **REQ-001**: System shall detect active wired network connections with valid IP addresses
- **REQ-002**: System shall automatically disable WiFi when wired connection is active
- **REQ-003**: System shall automatically enable WiFi when no wired connections are active
- **REQ-004**: System shall support multiple wired adapter types (Ethernet, Thunderbolt, LAN, AX88179A)
- **REQ-005**: System shall ignore loopback (127.0.0.1) and self-assigned (169.254.x.x) IP addresses
- **REQ-006**: System shall respond to network configuration changes in real-time
- **REQ-007**: System shall provide comprehensive installation and management tooling

### Performance Requirements
- **PERF-001**: Network state detection shall complete within 5 seconds
- **PERF-002**: WiFi toggle operations shall complete within 10 seconds
- **PERF-003**: System shall introduce maximum 10-second delay to prevent LaunchDaemon restart loops

### Security Requirements
- **SEC-001**: System shall require administrator privileges for installation and execution
- **SEC-002**: System shall use absolute paths for all system commands
- **SEC-003**: System shall validate input parameters and exit with appropriate error codes
- **SEC-004**: Scripts shall be owned by root with appropriate execution permissions

### Compatibility Requirements
- **COMP-001**: System shall support macOS Ventura (version 22.x), Sonoma (23.x), and Sequoia (24.x)
- **COMP-002**: System shall require Bash 4+ for proper array handling
- **COMP-003**: System shall integrate with standard macOS networking utilities

### Operational Constraints
- **CON-001**: System must run with root privileges for network configuration access
- **CON-002**: System files must be installed in standard macOS system directories
- **CON-003**: System shall not interfere with user manual network configuration
- **CON-004**: System shall provide logging integration with macOS system logs

### Development Guidelines
- **GUD-001**: Use explicit error handling with appropriate exit codes
- **GUD-002**: Implement comprehensive logging for debugging and monitoring
- **GUD-003**: Follow macOS system service best practices for LaunchDaemon configuration
- **GUD-004**: Maintain backward compatibility within supported macOS versions

### Architecture Patterns
- **PAT-001**: Use event-driven architecture with file system monitoring for network changes
- **PAT-002**: Implement idempotent operations for safe repeated execution
- **PAT-003**: Separate concerns between detection logic and configuration management
- **PAT-004**: Use declarative configuration for LaunchDaemon properties

## 4. Interfaces & Data Contracts

### Command Line Interface
```bash
# Installation script interface
./install.sh [i|up|ui]
# i  = install system components
# up = update existing installation  
# ui = uninstall system components
```

### System Integration Points
| Component | Interface | Purpose |
|-----------|-----------|---------|
| networksetup | `/usr/sbin/networksetup -listnetworkserviceorder` | Enumerate network interfaces |
| networksetup | `/usr/sbin/networksetup -listallhardwareports` | Get WiFi interface identifiers |
| networksetup | `/usr/sbin/networksetup -setairportpower <interface> <on\|off>` | Control WiFi state |
| ifconfig | `ifconfig <interface>` | Query interface IP configuration |
| logger | `logger <message>` | System log integration |
| launchctl | `launchctl load/unload <plist>` | Service lifecycle management |

### File System Layout
```
/Library/Scripts/NetBasics/
├── wireless.sh                    # Core detection and toggle logic
└── install.sh                     # Installation management script

/Library/LaunchDaemons/
└── com.computernetworkbasics.wifionoff.plist  # Service configuration

/var/log/system.log                 # System logging destination
```

### LaunchDaemon Configuration Schema
```xml
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.computernetworkbasics.wifionoff</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Library/Scripts/NetBasics/wireless.sh</string>
    </array>
    <key>WatchPaths</key>
    <array>
        <string>/Library/Preferences/SystemConfiguration</string>
    </array>
</dict>
</plist>
```

## 5. Acceptance Criteria

### Network Detection
- **AC-001**: Given multiple network interfaces, When wired interface has valid IP address, Then system shall detect active wired connection
- **AC-002**: Given wired interface with self-assigned IP (169.254.x.x), When evaluating connection status, Then system shall treat as inactive connection
- **AC-003**: Given no wired interfaces with valid IPs, When evaluating connection status, Then system shall detect no active wired connections

### WiFi State Management  
- **AC-004**: Given active wired connection detected, When WiFi is currently enabled, Then system shall disable WiFi and log action
- **AC-005**: Given no active wired connections, When WiFi is currently disabled, Then system shall enable WiFi and log action
- **AC-006**: Given WiFi state change command fails, When executing networksetup command, Then system shall exit with error code 1

### System Integration
- **AC-007**: Given network configuration changes, When SystemConfiguration directory is modified, Then LaunchDaemon shall trigger script execution within 5 seconds
- **AC-008**: Given script execution completes, When processing finishes, Then system shall sleep 10 seconds to prevent restart loops
- **AC-009**: Given system startup, When LaunchDaemon loads, Then service shall start automatically without user intervention

### Installation Process
- **AC-010**: Given installation command executed, When install script runs with 'i' parameter, Then all system files shall be copied and permissions set correctly
- **AC-011**: Given uninstall command executed, When install script runs with 'ui' parameter, Then all system files shall be removed and service stopped
- **AC-012**: Given update command executed, When install script runs with 'up' parameter, Then existing files shall be replaced and service restarted

## 6. Test Automation Strategy

### Test Levels
- **Unit Testing**: Shell script function validation using bash test framework
- **Integration Testing**: Network interface detection with mocked system commands
- **System Testing**: End-to-end validation on target macOS versions
- **Compatibility Testing**: Cross-version validation on Ventura, Sonoma, Sequoia

### Testing Frameworks
- **Shell Testing**: Bash Automated Testing System (BATS) for script validation
- **Mock Testing**: Custom mocking for networksetup and ifconfig commands
- **System Testing**: GitHub Actions with macOS runners for automated validation
- **Manual Testing**: Physical hardware validation with multiple adapter types

### Test Data Management
- **Network Mocking**: Predefined interface configurations for consistent testing
- **IP Address Scenarios**: Valid, invalid, self-assigned, and loopback address sets
- **Hardware Simulation**: Mock data for various adapter types and configurations

### CI/CD Integration
- **Automated Testing**: GitHub Actions workflow with macOS matrix builds
- **Syntax Validation**: ShellCheck integration for static analysis
- **Security Scanning**: Automated vulnerability assessment for shell scripts
- **Documentation Validation**: Automated README and specification consistency checks

### Coverage Requirements
- **Script Coverage**: 100% line coverage for core wireless.sh logic
- **Scenario Coverage**: All supported hardware adapter types and IP configurations
- **Error Handling**: All error conditions and exit codes validated
- **Integration Points**: All system command interactions tested with mocks

### Performance Testing
- **Response Time**: Network change detection and WiFi toggle performance measurement
- **Resource Usage**: Memory and CPU utilization monitoring during operation
- **Stress Testing**: Rapid network state changes and concurrent execution scenarios

## 7. Rationale & Context

### Architecture Decisions

#### LaunchDaemon vs LaunchAgent
**Decision**: Use LaunchDaemon for system-level network monitoring
**Rationale**: Requires root privileges for networksetup commands and must operate regardless of user login status

#### File System Monitoring vs Polling
**Decision**: Monitor `/Library/Preferences/SystemConfiguration` for network changes
**Rationale**: Event-driven approach provides real-time response without continuous polling overhead

#### Shell Script vs Compiled Binary
**Decision**: Implement core logic in Bash shell script
**Rationale**: Simplifies maintenance, leverages existing macOS command-line tools, and provides transparency for security auditing

#### Hardware Port Detection Strategy
**Decision**: Use `networksetup -listnetworkserviceorder` with hardware port filtering
**Rationale**: Provides reliable identification of physical interfaces across different macOS versions and hardware configurations

### Design Trade-offs

#### Performance vs Reliability
- **Trade-off**: 10-second sleep delay after execution
- **Rationale**: Prevents LaunchDaemon restart loops at cost of slight delay in rapid network changes

#### Flexibility vs Simplicity
- **Trade-off**: Hardcoded adapter type detection vs dynamic discovery
- **Rationale**: Explicit adapter type list (Ethernet, LAN, Thunderbolt, AX88179A) provides predictable behavior

#### Security vs Usability
- **Trade-off**: Requires sudo privileges for installation
- **Rationale**: System-level network control necessitates administrative access

## 8. Dependencies & External Integrations

### macOS System Dependencies
- **SYS-001**: macOS networksetup utility - Network interface configuration and control
- **SYS-002**: macOS ifconfig utility - Network interface status and IP address query
- **SYS-003**: macOS launchctl utility - Service lifecycle management
- **SYS-004**: macOS logger utility - System log integration
- **SYS-005**: Bash shell environment - Script execution runtime

### System Framework Dependencies
- **FWK-001**: SystemConfiguration framework - Network state change monitoring
- **FWK-002**: Airport/WiFi framework - Wireless interface control via networksetup
- **FWK-003**: LaunchDaemon framework - System service execution environment

### Hardware Dependencies
- **HW-001**: Network interfaces - Physical Ethernet, Thunderbolt, LAN, or USB-C adapters
- **HW-002**: WiFi capability - Wireless network interface for state management
- **HW-003**: Administrator access - User account with sudo privileges

### File System Dependencies
- **FS-001**: System directories - Write access to `/Library/Scripts/` and `/Library/LaunchDaemons/`
- **FS-002**: Configuration monitoring - Read access to `/Library/Preferences/SystemConfiguration`
- **FS-003**: System logging - Write access to system log facilities

### Network Dependencies
- **NET-001**: DHCP services - For valid IP address assignment to wired interfaces
- **NET-002**: Network infrastructure - Physical network connectivity for wired adapters

### Version Dependencies
- **VER-001**: macOS Ventura 13.x+ - Minimum supported operating system version
- **VER-002**: Bash 4.0+ - Required for proper array handling and script execution

## 9. Examples & Edge Cases

### Basic Network Detection Logic
```bash
# Detect wired interfaces with valid IP addresses
INTERFACES=$(networksetup -listnetworkserviceorder | \
    grep "Hardware Port" | \
    grep "Ethernet\|LAN\|Thunderbolt\|AX88179A" | \
    awk -F ": " '{print $3}' | sed 's/)//g')

for INTERFACE in $INTERFACES; do
    IPCHECK=$(ifconfig "$INTERFACE" | \
        grep -E 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | \
        grep -E -v '127.0.0.1|169.254.' | \
        awk '{print $2}')
    if [ "$IPCHECK" ]; then
        IPFOUND=true
        break
    fi
done
```

### WiFi State Management
```bash
# Get WiFi interface identifier
WIFIINTERFACES=$(networksetup -listallhardwareports | \
    tr '\n' ' ' | \
    sed -e 's/Hardware Port:/\'$'\n/g' | \
    grep Wi-Fi | awk '{print $3}')

# Toggle WiFi based on wired connection status
if [ $IPFOUND ]; then
    networksetup -setairportpower "$WIFIINTERFACES" off || exit 1
    logger "wireless.sh: turning off wireless card ($WIFIINTERFACES)"
else
    networksetup -setairportpower "$WIFIINTERFACES" on || exit 1
    logger "wireless.sh: turning on wireless card ($WIFIINTERFACES)"
fi
```

### Edge Cases

#### Multiple Wired Interfaces
- **Scenario**: System has both Ethernet and Thunderbolt adapters connected
- **Behavior**: Detection logic finds first interface with valid IP and enables wired mode
- **Handling**: Loop through all interfaces, set IPFOUND=true on first valid IP

#### Rapid Network Changes
- **Scenario**: User frequently connects/disconnects wired adapter
- **Behavior**: Each change triggers LaunchDaemon execution
- **Handling**: 10-second sleep prevents rapid cycling and system instability

#### No WiFi Interface
- **Scenario**: System has no wireless capability (desktop Mac Pro)
- **Behavior**: Script continues execution but WiFi commands fail silently
- **Handling**: Check for WiFi interface existence before state changes

#### Invalid IP Assignments
- **Scenario**: Wired interface gets self-assigned IP (169.254.x.x)
- **Behavior**: System treats as no valid wired connection
- **Handling**: Explicit exclusion of 169.254.x.x range in IP detection

#### Permission Failures
- **Scenario**: Script runs without sufficient privileges
- **Behavior**: networksetup commands fail with permission errors
- **Handling**: Exit with error code 1 to signal LaunchDaemon failure

## 10. Validation Criteria

### Functional Validation
- **VAL-001**: Script correctly identifies all supported wired adapter types on test hardware
- **VAL-002**: WiFi toggle operations complete successfully across all supported macOS versions
- **VAL-003**: IP address filtering excludes loopback and self-assigned addresses correctly
- **VAL-004**: LaunchDaemon responds to network configuration changes within specified timeframes

### Performance Validation
- **VAL-005**: Network detection completes within 5-second requirement under normal conditions
- **VAL-006**: System operates without memory leaks during extended operation periods
- **VAL-007**: CPU utilization remains minimal during monitoring and execution cycles

### Integration Validation
- **VAL-008**: Installation script successfully deploys all components with correct permissions
- **VAL-009**: System logging integration captures all significant events and errors
- **VAL-010**: Uninstallation completely removes all system components without residue

### Security Validation
- **VAL-011**: All system commands use absolute paths to prevent PATH injection attacks
- **VAL-012**: Script validation detects and prevents execution of malformed commands
- **VAL-013**: File permissions prevent unauthorized modification of system components

### Compatibility Validation
- **VAL-014**: Solution operates correctly across Ventura, Sonoma, and Sequoia macOS versions
- **VAL-015**: Hardware compatibility verified with various adapter types and configurations
- **VAL-016**: Script handles differences in command output formats across macOS versions

## 11. Related Specifications / Further Reading

- [CI/CD Workflow Specification - macOS Utility Validation](spec-process-cicd-macos-utility-validation.md)
- [Apple Developer Documentation - LaunchDaemon and LaunchAgent](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)
- [macOS Network Configuration Guide](https://support.apple.com/guide/mac-help/mchlp2439/mac)
- [Bash Scripting Best Practices for System Administration](https://google.github.io/styleguide/shellguide.html)
- [macOS Security and Privacy Guidelines](https://support.apple.com/guide/security/welcome/web)