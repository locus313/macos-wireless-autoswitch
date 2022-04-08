#!/bin/bash

NETBASICS_PATH="/Library/Scripts/NetBasics"
LAUNCHDAEMONS_PATH="/Library/LaunchDaemons"

SUDO=''
if [[ $(id -u) -ne 0 ]]; then
    SUDO='sudo'
fi

$SUDO mkdir -p $NETBASICS_PATH

$SUDO cp wireless.sh $NETBASICS_PATH

$SUDO chmod 755 $NETBASICS_PATH/wireless.sh

$SUDO mkdir -p $LAUNCHDAEMONS_PATH

$SUDO cp com.computernetworkbasics.wifionoff.plist $LAUNCHDAEMONS_PATH/com.computernetworkbasics.wifionoff.plist

$SUDO chown root:wheel $LAUNCHDAEMONS_PATH/com.computernetworkbasics.wifionoff.plist
