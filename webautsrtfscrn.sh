#!/usr/bin/env bash

set -e

#
# Copyright (c) 2014, November 13, Are Hansen.
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without modification, are 
# permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice, this list of 
# conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of 
# conditions and the following disclaimer in the documentation and/or other materials 
# provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND AN EXPRESS 
# OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
# COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR 
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Version: 0.0.1
#

declare -rx Script="${0##*/}"
declare astart="/etc/xdg/lxsession/LXDE/autostart"
declare astartorg="/etc/xdg/lxsession/LXDE/autostart.ORG"


function backup_config()
{
if [ ! -e $astart ]
then
    echo "[ERROR:$LINENO]: Unable to locate the config file\!"
    exit 1
fi

echo '

Creating backup configuration file(s).
If the script fails, execute it with the REVERT argument.

'

sleep 1

cp $astart $astartorg
}


function make_autostart()
{
if [ ! -e $astartorg ]
then
    backup_config
fi

echo "
@xset s off
@xset -dpms
@xset s noblank
@midori -e Fullscreen -a $1
" > $astart
}


function restore_config()
{
if [ ! -e $astartorg ]
then
    echo "[ERROR:$LINENO]: Unable to locate the config file\!"
    exit 1
fi

echo '

Restoring the previous configuration files(s).

'
mv $astartorg $astart


if [ ! -e $astartorg ]
then
    echo 'Restore conplete. Logout or reboot to apply the changes.'
fi
}


function help_text()
{
clear

echo "

    USAGE: $Script

    Launch web browser at startup in fullscreen and set the start page.

        $Script ASTART http://google.com

    This will configure your system to launch the web browser in fullscreen and set the
    start page to http://google.com.

    Restore previous configuration (in case the scripts messes something up).

        $Script REVERT

    This will reset the configuration to the previous configuration.
"
}


if [ $# = 0 ]
then
    help_text
    exit 1
fi

if [[ $1 != 'REVERT' && $1 != 'ASTART' ]]
then
    help_text
    exit 1
fi


if [ $(id -u) != 0 ]
then
    echo "[ERROR:$LINENO]: You have to run this script as root"
    exit 1
fi

if [[ $1 = 'ASTART' && $# = 2 ]]
then
    make_autostart $2
fi

if [[ $1 = 'REVERT' && $# = 1 ]]
then
    restore_config
fi
