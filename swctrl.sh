#!/usr/bin/env bash
#
#   Shortcut script that preforms tedious system tasks. 
#   Platform: Debian/Ubuntu
#
#   Author: Are Hansen
#   Date: 2015, Oct 17
#   Version: 0.0.2
#
set -e


declare -rx Script="${0##*/}"
declare -rx aptget="/usr/bin/apt-get"


function check_uid()
{
    if [ "$(id -u)" != "0" ]
    then
        echo "[FAIL] - You have to run $Script as root. Try: sudo $Script [argument]"
        exit 1
    fi
}


function clear_boot()
{
    echo 'NOT IMPLEMENTED YET - Removing obsolete files in /boot'
}


function full_sw_up()
{
    $aptget update \
    && $aptget upgrade -y \
    && $aptget dist-upgrade -y \
    && $aptget autoremove -y \
    && $aptget autoclean \
    && echo "[OKAY] - You might consider rebooting $(hostname -f) now."
}


function sw_up()
{
    $aptget update \
    && $aptget upgrade -y \
    && $aptget autoremove -y \
    && $aptget autoclean \
    && echo "[OKAY] - Update of $(hostname -f) has completed."
}


function script_usage()
{
echo "
    Usage: $Script [argument]

    $Script clear-boot
    - Removes any obsolete files in /boot

    $Script full
    - Runs update, upgrade, dist-upgrade, autoremove and autoclean

    $Script update
    - Runs update, upgrade, autoremove and autoclean
"
}


case "$1" in
    clear-boot)
        check_uid
        clear_boot
        ;;
    full)
        check_uid
        full_sw_up
        ;;
    update)
        check_uid
        sw_up
        ;;
    *)
        script_usage
        exit 1
        ;;
esac

exit 0