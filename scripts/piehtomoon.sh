#!/bin/ksh
# Move from PieHelper to Moonlight (by Davy Keppens on 04/10/2018)
# Enable/Disable debug by running confpieh_ph.sh -d piehtomoon.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

if [[ `fgconsole` -ne `ph_get_tty_for_app PieHelper` ]]
then
	printf "%s\n" "- Disabling PieHelper"
	printf "%2s%s\n" "" "FAILED : PieHelper not currently on foreground"
	exit 1
fi
stoppieh.sh || exit $?
startmoon.sh || exit $?
exit 0
