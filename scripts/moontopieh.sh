#!/bin/ksh
# Move from Moonlight to PieHelper (by Davy Keppens on 04/10/2018)
# Enable/Disable debug by running confpieh_ph.sh -d moontopieh.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

if [[ `fgconsole` -ne `ph_get_tty_for_app Moonlight` ]]
then
	printf "%s\n" "- Disabling Moonlight"
	printf "%2s%s\n" "" "FAILED : Moonlight not currently on foreground"
	exit 1
fi
stopmoon.sh || exit $?
startpieh.sh || exit $?
exit 0
