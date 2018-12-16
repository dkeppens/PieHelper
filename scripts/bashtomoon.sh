#!/bin/ksh
# Move from Bash to Moonlight (by Davy Keppens on 04/10/2018)
# Enable/Disable debug by running confpieh_ph.sh -d bashtomoon.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

if [[ `fgconsole` -ne `ph_get_tty_for_app Bash` ]]
then
	printf "%s\n" "- Disabling Bash"
	printf "%2s%s\n" "" "FAILED : Bash not currently on foreground"
	exit 1
fi
stopbash.sh || exit $?
startmoon.sh || exit $?
exit 0
