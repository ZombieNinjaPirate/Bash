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


declare -rx Script="${0##*/}"
declare -rx date="/bin/date"
declare -rx echo="/bin/echo"
declare -rx tcpd="/usr/sbin/tcpdump"


function failed()
{
    logger -p daemon.warn "$Script[$$]: ERROR: Failed to daemonize $1"
    exit 1
}


function ftp_capture()
{
    if [ -z "$1" ]
    then
        logger -p daemon.warn "$Script[$$]: ERROR: Did not receive any directory to save the files in. Exit 1"
        exit 1
    else
        if [ -d "$1" ]
        then
            pcap="$1/FTP_$(date +"%Y%m%d_%H%M%S").pcap"
            logger -p daemon.warn "$Script[$$]: Saving pcap files to $pcap"
        else
            logger -p daemon.warn "$Script[$$]: WARNING: $1 does not exist"
            mkdir -p $1
            logger -p daemon.warn "$Script[$$]: WARNING: $1 was created"
            pcap="$1/FTP_$(date +"%Y%m%d_%H%M%S").pcap"
            logger -p daemon.warn "$Script[$$]: Saving pcap files to $pcap"
        fi
    fi

    if [ -z "$2" ]
    then
        capif="eth0"
        logger -p daemon.warn "$Script[$$]: Capture interface was specified, using $capif"
    else
        capif="$2"
        logger -p daemon.warn "$Script[$$]: Capture interface specified, using $capif"
    fi

    snaplen="65535"
    rotate="14400"
    lognum="42"
    data="tcp portrange 20-21"

    logger -p daemon.warn "$Script[$$]: Attempting to daemonize $FUNCNAME"
    $tcpd -n -i $capif -s $snaplen -G $rotate -w $pcap -C $lognum $data &>/dev/null || failed $FUNCNAME &
    find_pid $FUNCNAME $pcap
}



function irc_capture()
{
    if [ -z "$1" ]
    then
        logger -p daemon.warn "$Script[$$]: ERROR: Did not receive any directory to save the files in. Exit 1"
        exit 1
    else
        if [ -d "$1" ]
        then
            pcap="$1/IRC_$(date +"%Y%m%d_%H%M%S").pcap"
            logger -p daemon.warn "$Script[$$]: Saving pcap files to $pcap"
        else
            logger -p daemon.warn "$Script[$$]: WARNING: $1 does not exist"
            mkdir -p $1
            logger -p daemon.warn "$Script[$$]: WARNING: $1 was created"
            pcap="$1/IRC_$(date +"%Y%m%d_%H%M%S").pcap"
            logger -p daemon.warn "$Script[$$]: Saving pcap files to $pcap"
        fi
    fi

    if [ -z "$2" ]
    then
        capif="eth0"
        logger -p daemon.warn "$Script[$$]: Capture interface was specified, using $capif"
    else
        capif="$2"
        logger -p daemon.warn "$Script[$$]: Capture interface specified, using $capif"
    fi

    snaplen="65535"
    rotate="14400"
    lognum="42"
    data="tcp portrange 6660-6669"

    logger -p daemon.warn "$Script[$$]: Attempting to daemonize $FUNCNAME"
    $tcpd -n -i $capif -s $snaplen -G $rotate -w $pcap -C $lognum $data &>/dev/null || failed $FUNCNAME &
    find_pid $FUNCNAME $pcap
}


function web_capture()
{
    if [ -z "$1" ]
    then
        logger -p daemon.warn "$Script[$$]: ERROR: Did not receive any directory to save the files in. Exit 1"
        exit 1
    else
        if [ -d "$1" ]
        then
            pcap="$1/WEB_$(date +"%Y%m%d_%H%M%S").pcap"
            logger -p daemon.warn "$Script[$$]: Saving pcap files to $pcap"
        else
            logger -p daemon.warn "$Script[$$]: WARNING: $1 does not exist"
            mkdir -p $1
            logger -p daemon.warn "$Script[$$]: WARNING: $1 was created"
            pcap="$1/WEB_$(date +"%Y%m%d_%H%M%S").pcap"
            logger -p daemon.warn "$Script[$$]: Saving pcap files to $pcap"
        fi
    fi

    if [ -z "$2" ]
    then
        capif="eth0"
        logger -p daemon.warn "$Script[$$]: Capture interface was specified, using $capif"
    else
        capif="$2"
        logger -p daemon.warn "$Script[$$]: Capture interface specified, using $capif"
    fi

    snaplen="65535"
    rotate="14400"
    lognum="42"
    data="tcp port 80"

    logger -p daemon.warn "$Script[$$]: Attempting to daemonize $FUNCNAME"
    $tcpd -n -i $capif -s $snaplen -G $rotate -w $pcap -C $lognum $data &>/dev/null || failed $FUNCNAME &
    find_pid $FUNCNAME $pcap
}


function find_pid()
{
    dpid="$(ps x | grep $2 | head -n1 | awk '{print $1}')"
    echo "$dpid" > /var/run/$1.$dpid
    logger -p daemon.warn "$Script[$$]: $1 is running as a daemon process with PID file /var/run/$1.$dpid"
}


function stop_capture()
{
    pfile="$(find /var/run/ -type f -name "$1.*" | wc -l)"

    if [ "$pfile" -ge 1 ]
    then
        for pid in $(find /var/run/ -type f -name "$1.*" | cut -d '.' -f2)
        do 
            echo "Killing $1 with pid $pid"
            rm /var/run/$1.$pid
            kill -15 $pid
            logger -p daemon.warn "$Script[$$]: Removing pid file /var/run/$1.$pid and killing pid $pid"
        done
    fi

    if [ "$pfile" = "0" ]
    then
        echo "No pid file for $1 found"
        exit 1
    fi
}


case "$1" in
    ftp)
        ftp_capture $2 $3
        ;;
    stop-ftp)
        stop_capture "ftp_capture"
        ;;
    irc)
        irc_capture $2 $3
        ;;
    stop-irc)
        stop_capture "irc_capture"
        ;;
    web)
        web_capture $2 $3
        ;;
    stop-web)
        stop_capture "web_capture"
        ;;
    *)
        logger -p daemon.warn "$Script[$$]: ERROR: \"$1\" is not a valid argument. Exit 1"
        exit 1
        ;;
esac


exit 0
