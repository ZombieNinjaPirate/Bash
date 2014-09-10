#!/usr/bin/env bash


#
#   Copyright (c) 2014, Are Hansen - Honeypot Development
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
#   BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
#   STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
#   THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#

set -e

declare AUTHOR='(c) 2014, Are Hansen - Honeypot Development'
declare DATE='2014, 9 September'
declare VERSION='0.0.6'

declare -rx Script="${0##*/}"
declare -rx chmod="/bin/chmod"
declare -rx chown="/bin/chown"
declare -rx clear="/usr/bin/clear"
declare -rx cp="/bin/cp"
declare -rx cut="/usr/bin/cut"
declare -rx date="/bin/date"
declare -rx du="/usr/bin/du"
declare -rx echo="/bin/echo"
declare -rx mkdir="/bin/mkdir"
declare -rx mkisofs="/usr/bin/mkisofs"
declare -rx mksquashfs="/usr/bin/mksquashfs"
declare -rx mv="/bin/mv"
declare -rx rm="/bin/rm"
declare -rx sleep="/bin/sleep"
declare -rx unsquashfs="/usr/bin/unsquashfs"


function helpinfo()
{
$echo "
	$AUTHOR - $DATE - $VERSION

	The $Script script is used when you are building and modifying the default
	file system thats been compressed in the Ubuntu ISO files. During such a
	process you would typically extract and decompress the filesystem.squashfs
	to make your own modifications to it then, compress it and replace the
	original file system and, finally, calculate the the size of the new files
	system. I'm pretty lazy so, i made this script to take care of most of these
	steps for you.

	The following examples assumes that you have extracted the contents of a ISO
	into a directory called ISODIR. The extracted file system will be extracted
	to a directory called squashfs-root.


	EXAMPLES:

	- Extract the compressed file system:

		$Script open ISODIR

	Copies the filesystem.squashfs from ISODIR/install/filesystem.squashfs
	to the current directory and decompresses it. This creates a new
	directory called squashfs-root that contains the file system. Once the
	squashfs-root directory has been created the script will delete the
	filesystem.squashfs.

	- Compress the modified file system:

		$Script close squashfs-root ISODIR

	Compresses the squashfs-root into filesystem.squashfs. Then checks for
	any existing filesystem.squashfs insode ISODIR/install/filesystem.squashfs
	and removes it if present. Moves the newly created filesystem.squashfs into 
	ISODIR/install and sets the correct premissions (0444).
	After the new filesystem.squashfs has been moved into place it will
	calculate the size of the new file system and writes that to the
	filesystem.size file before setting the permission on that file as well.

	- Create the ISO file from the ISODIR

		$Script build ISODIR NAME-OF-ISO USER-ID

	Creates the ISO file from the contents in the ISODIR directory. The
	resulting ISO file is created in a directory with the same name as the ISO. The
	USER-ID is the id for the user that is going to manage the ISO file after its
	built. The script must be executed as root but, you might want to set the permissions
	so that other users can use these ISO files as well.
	The name of the resulting ISO file will be created after the following scheme:

		NAME-OF-ISO_yymmddhhmm.iso

	If the script was executed with the following command:

		$Script build ISODIR MyDistro bob

	It would make a directory called MyDistro and create a ISO file that called
	MyDistro_1409092239.iso inside of it and the ownership would be given to bob.

"
}


function openfs()
{
    if [ ! -e squashfs-root ]
    then

    	if [ -e $1/install/filesystem.squashfs ]
    	then
    		$echo "Extracting the compressed file system..."
	    	$echo "- copying $1/install/filesystem.squashfs to current directory"
    		$cp $1/install/filesystem.squashfs . \
        	&& $unsquashfs filesystem.squashfs

        	if [ -e squashfs-root ]
        	then
        		$echo "- squashfs-root was created"
        	fi

        	if [ -e filesystem.squashfs ]
        	then
        		$rm -v filesystem.squashfs
        		$echo "- filesystem.squashfs was deleted"
        	fi

        else
        	$echo "ERROR: Unable to find $1/install/filesystem.squashfs"
        	exit 1
        fi
    
    else
        $echo 'ERROR: squashfs-root already exists in this directory'
        exit 1
    fi
}


function closefs()
{
    if [ -e $1 ]
    then
    	$echo "Starting compression of $1..."
        $mksquashfs $1 filesystem.squashfs -b 1048576 \

        if [ -e $2/install/filesystem.squashfs ]
        then
        	$echo "- removing old filesystem.squashfs"
        	$rm $2/install/filesystem.squashfs
        fi

        if [ -e filesystem.squashfs ]
        then
        	$echo "- adding new file system to $2/install/filesystem.squashfs"
        	$mv filesystem.squashfs $2/install/filesystem.squashfs \
        	&& $chmod 0444 $2/install/filesystem.squashfs
        fi

    	$chmod 0644 $2/install/filesystem.size \
        && $du -sx --block-size=1 $1 | $cut -f1 > $2/install/filesystem.size \
        && $chmod 0444 $2/install/filesystem.size

    else
        $echo 'ERROR: filesystem.squashfs already exists in this directory'
        exit 1
    fi
}


function createiso()
{
	if [ ! -d $1 ]
	then
		$echo "ERROR: $1 dont appear to exist"
		exit 1
	fi

	iso_name="$2.$($date +"%y%m%d%H%H").iso"

	if [ ! -d $2 ]
	then
		$mkdir $2
	fi

	$clear
	$echo "Starting to build $iso_name...."

	$mkisofs -J -l -b isolinux/isolinux.bin \
	-no-emul-boot -boot-load-size 4 \
	-boot-info-table -z -iso-level 4 \
	-c isolinux/isolinux.cat \
	-o $2/$iso_name \
	-joliet-long $1

	$echo 'Done! Setting permissions on the ISO file..'

	$sleep 1

	$chown -R $3:$3 $2

	$echo "Created $iso_name in $2 and ownership has been given to $3"
}


if [ $EUID != 0 ]
then
	$echo "ERROR: You must execute this script as root"
	exit 1
fi


if [ $# = 0 ]
then
	helpinfo
	exit 1
fi


if [[ -z $1 && "$1" != "open" && "$1" != "close" && "$1" != "help" ]]
then
	helpinfo
	exit 1
else
	if [ "$1" = "help" ] 
	then
		helpinfo
		exit 1
	fi

	if [ "$1" = "open" ]
	then
		if [ $# !=  2 ]
		then
			helpinfo
			exit 1
		else
			if [ -d $2 ]
			then
			    openfs $2
			else
				$echo "ERROR: $2 dont appear to be a directory"
				exit 1
			fi
		fi
	fi

	if [ "$1" = "close" ]
	then
		if [ $# !=  3 ]
		then
			helpinfo
			exit 1
		else
		    closefs $2 $3
		 fi
	fi

	if [ "$1" = "build" ]
	then
		if [ $# != 4 ]
		then
			helpinfo
			exit 1
		else
			createiso $2 $3 $4
		fi
	fi
fi


exit 0
