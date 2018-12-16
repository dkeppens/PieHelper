#!/bin/ksh
# Move from X11 to Moonlight (by Davy Keppens on 04/10/2018)
# Enable/Disable debug by running confpieh_ph.sh -d x11tomoon.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

if [[ `fgconsole` -ne `ph_get_tty_for_app X11` ]]
then
	printf "%s\n" "- Disabling X11"
	printf "%2s%s\n" "" "FAILED : X11 not currently on foreground"
	exit 1
fi
stopx11.sh || exit $?
startmoon.sh || exit $?
exit 0
