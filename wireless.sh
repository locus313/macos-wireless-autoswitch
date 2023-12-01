#!/bin/bash
 
# Set toggle for found IP on an interface to FALSE to start
IPFOUND=
# Determine Current OS Version
OSVERSION=$(uname -a | awk '{print $3}' | awk 'BEGIN {FS = "."} ; {print $1}')
# Get list of possible wired ethernet interfaces
INTERFACES=$(networksetup -listnetworkserviceorder | grep "Hardware Port" | grep "Ethernet\|LAN\|Thunderbolt\|AX88179A" | awk -F ": " '{print $3}'  | sed 's/)//g')
# Get list of Wireless Interfaces
WIFIINTERFACES=$(networksetup -listallhardwareports | tr '\n' ' ' | sed -e 's/Hardware Port:/\'$'\n/g' | grep Wi-Fi | awk '{print $3}')
 
# Look for an IP on all Ethernet interfaces.  If found set variable IPFOUND to true.
for INTERFACE in $INTERFACES
do
  # Get Wired LAN IP (If there is one other then the loopback and the self assigned.)
  IPCHECK=$(ifconfig "$INTERFACE" | grep -E 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -E -v '127.0.0.1|169.254.' | awk '{print $2}')
  if [ "$IPCHECK" ]; then
    IPFOUND=true
  fi
done
 
# For Monterey (#21), Ventura (#22)
if [ "$OSVERSION" == "21" ] || [ "$OSVERSION" == "22" ]; then
  if [ $IPFOUND ]; then
    /usr/sbin/networksetup -setairportpower "$WIFIINTERFACES" off || exit 1
    echo "Turning OFF wireless on card $WIFIINTERFACES."
    logger "wireless.sh: turning off wireless card ($WIFIINTERFACES) because an IP was found on a wired card."
  else
    /usr/sbin/networksetup -setairportpower "$WIFIINTERFACES" on || exit 1
    echo "Turning ON wireless on card $WIFIINTERFACES."
    logger "wireless.sh: turning on wireless card ($WIFIINTERFACES) because NO IP was found on a wired card."
  fi
fi
 
# This sleep prevents LaunchDaemons from thinking the script failed and running it again.
sleep 10
