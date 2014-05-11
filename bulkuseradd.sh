#!/bin/bash

#
#	Author:		Are Hansen
#	Date:		2014, May 11
#
#	Usage:
#	This script is used to generate a file that can be passed to 'newusers'
#	that will generate new user accounts on a Ubuntu server.
#

clear

echo 'Whats the naming scheme of your users?'
echo '
Explanation: 
If you set the naming scheme to "sshuser", it will generate user accounts called:

	sshuser1
	sshuser2
	sshuser3
	sshuser4
	sshuser5
	...
	...
'
read -p 'Enter your naming scheme here: ' NAMESCH
read -p 'Number of user accounts to create: ' USRNUMB

Start="0"
Stop="$USRNUMB"

# Generate the list for the newusers application.
while [ "$Start" -lt "$Stop" ]
do
		if [ "$Start" -lt "10" ]
		then
			num="0$Start"
		else
			num="$Start"
		fi

		echo "Creating: $NAMESCH$num"
        echo "$NAMESCH$num:$NAMESCH$num:50$num:50$num:$NAMESCH$num:/home/$NAMESCH$num:/bin/bash"\
        | newusers

        echo "Force password change at first login: $NAMESCH$num"
        chage -d 0 $NAMESCH$num

        Start=$(( $Start + 1 ))
done

exit 0
