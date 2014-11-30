#!/usr/bin/env bash


#
#   Copyright (c) 2014, Are Hansen - Honeypot Development.
# 
#   All rights reserved.
# 
#   Redistribution and use in source and binary forms, with or without modification, are
#   permitted provided that the following conditions are met:
#
#   1. Redistributions of source code must retain the above copyright notice, this list
#   of conditions and the following disclaimer.
# 
#   2. Redistributions in binary form must reproduce the above copyright notice, this
#   list of conditions and the following disclaimer in the documentation and/or other
#   materials provided with the distribution.
# 
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND AN
#   EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
#   OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
#   SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
#   INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
#   TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
#   BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
#   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY 
#   WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#   Version:    0.1.0
#   Date:       2014, November 29
#   Info:       Creates a backround instance of tcpdump that will capture traffic on a
#               certain port(s) to a file thats rotated after a set number of seconds.
#


set -e


# Capturing interface (default: eth0)
declare capif="eth0"

# Snaplen (default: 65535)
declare snaplen="65535"

# Number of seconds between log file rotation (default: 14400 (4 hours))
declare rotate="14400"

# Maximim number of log files (default: 48)
declare lognum="42"

# Output pcap file
declare pcap="$1/HTTP_%Y%m%d_%H%M%S.pcap"

# Port(s) and protocol to capture (default: tcp portrange 6660-6669)
declare data="tcp port 80"

# Log file (default: /var/log/syslog)
declare syslog="/var/log/syslog"


######## UNLESS YOU KNOW WHAT YOU ARE DOING, DONT CHANGE ANYTHING BELOW THIS LINE ########


declare -rx Script="${0##*/}"
declare -rx date="/bin/date"
declare -rx echo="/bin/echo"
declare -rx tcpd="/usr/sbin/tcpdump"


function check_sanity()
{
    if [ $# != 1 ]
    then
        $echo -e "\n$($date +"%b %d %T") $HOSTNAME $Script: Error $LINENO - Missing argument" >> $syslog
        exit 1
    fi

    if [ ! -e $1 ]
    then
        $echo -e "\n$($date +"%b %d %T") $HOSTNAME $Script: Error $LINENO - File object not found" >> $syslog
        exit 1
    fi

    if [ ! -d $1 ]
    then
        $echo -e "\n$($date +"%b %d %T") $HOSTNAME $Script: Error $LINENO - File object not a directory" >> $syslog
        exit 1
    fi

    if [ $EUID != 0 ]
    then
        $echo -e "\n$($date +"%b %d %T") $HOSTNAME $Script: Error $LINENO - EUID was $EUID, should have been 0" >> $syslog
        exit 1
    fi
}


function failed()
{
    $echo "$($date +"%b %d %T") $HOSTNAME $Script: Error $LINENO - $Script failed to daemonize packet capture" >> $syslog

    exit 1
}


function daemon_capture()
{
    $echo -e "\n$($date +"%b %d %T") $HOSTNAME $Script: Daemonizing packet capture" >> $syslog

    $tcpd -n -i $capif -s $snaplen -G $rotate -w $pcap -C $lognum $data || failed &

    $echo "$($date +"%b %d %T") $HOSTNAME $Script: Packet capture was started with pid $!" >> $syslog
}


function execd()
{
    check_sanity $1

    daemon_capture
}


execd $1


exit 0
