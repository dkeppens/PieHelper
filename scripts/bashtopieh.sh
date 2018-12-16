#!/bin/ksh
# Move from Bash to PieHelper (by Davy Keppens on 04/10/2018)
# Enable/Disable debug by running confpieh_ph.sh -d bashtopieh.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

if [[ `fgconsole` -ne `ph_get_tty_for_app Bash` ]]
then
	printf "%s\n" "- Disabling Bash"
	printf "%2s%s\n" "" "FAILED : Bash not currently on foreground"
	exit 1
fi
stopbash.sh || exit $?
startpieh.sh || exit $?
exit 0
