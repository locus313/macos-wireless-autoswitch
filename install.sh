#!/bin/bash

sudo mkdir -p /Library/Scripts/NetBasics/

sudo mv wireless.sh /Library/Scripts/NetBasics/

sudo chmod 755 /Library/Scripts/NetBasics/wireless.sh

sudo mkdir -p /Library/LaunchDaemons/

sudo mv com.computernetworkbasics.wifionoff.plist /Library/LaunchDaemons/com.computernetworkbasics.wifionoff.plist

sudo chown root:wheel /Library/LaunchDaemons/com.computernetworkbasics.wifionoff.plist
