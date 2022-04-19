#!/bin/bash

NETBASICS_PATH="/Library/Scripts/NetBasics"
LAUNCHDAEMONS_PATH="/Library/LaunchDaemons"

PS3='[Please enter your choice]: '
options=(
    "install (i): install mode"       # 1
    "uninstall (ui): uninstall mode" # 2
    "update (up): update mode"       # 3
    "quit: Exit from this menu"                        # 4
    )

function _sudo() {
    SUDO=''
    if [[ $(id -u) -ne 0 ]]; then
        SUDO='sudo'
    fi
}

function _mkdir() {
    if [! -d $NETBASICS_PATH ]; then
            $SUDO mkdir -p $NETBASICS_PATH;
    fi
    if [! -d $LAUNCHDAEMONS_PATH ]; then
            $SUDO mkdir -p $LAUNCHDAEMONS_PATH;
    fi
}

function _switch() {
    _reply="$1"

    case $_reply in
        ""|"i"|"install"|"1")
            _sudo
            _mkdir
            $SUDO cp wireless.sh $NETBASICS_PATH;
            $SUDO cp com.computernetworkbasics.wifionoff.plist $LAUNCHDAEMONS_PATH/com.computernetworkbasics.wifionoff.plist;
            $SUDO chmod 755 $NETBASICS_PATH/wireless.sh;
            $SUDO chown root:wheel $LAUNCHDAEMONS_PATH/com.computernetworkbasics.wifionoff.plist;
            ;;
        ""|"ui"|"uninstall"|"2")
            _sudo
            $SUDO rm -Rf $NETBASICS_PATH/wireless.sh;
            $SUDO rm -Rf $LAUNCHDAEMONS_PATH/com.computernetworkbasics.wifionoff.plist;
            ;;
        ""|"up"|"update"|"3")
            _sudo
            $SUDO cp wireless.sh $NETBASICS_PATH;
            $SUDO cp com.computernetworkbasics.wifionoff.plist $LAUNCHDAEMONS_PATH/com.computernetworkbasics.wifionoff.plist;
            $SUDO chmod 755 $NETBASICS_PATH/wireless.sh;
            $SUDO chown root:wheel $LAUNCHDAEMONS_PATH/com.computernetworkbasics.wifionoff.plist;
            exit
            ;;
        ""|"quit"|"4")
            echo "Goodbye!"
            exit
            ;;
        ""|"--help")
            echo "Available commands:"
            printf '%s\n' "${options[@]}"
            ;;
        *) echo "invalid option, use --help option for the commands list";;
    esac
}

while true
do
    # run option directly if specified in argument
    [ ! -z $1 ] && _switch $@
    [ ! -z $1 ] && exit 0

    echo "==== OPTIONS ===="
    select opt in "${options[@]}"
    do
        _switch $REPLY
        break
    done
done
