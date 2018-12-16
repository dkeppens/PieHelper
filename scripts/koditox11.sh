#!/bin/ksh
# Move from Kodi to X11 (by Davy Keppens on 04/10/2018)
# Enable/Disable debug by running confpieh_ph.sh -d koditox11.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

if [[ `fgconsole` -ne `ph_get_tty_for_app Kodi` ]]
then
	printf "%s\n" "- Disabling Kodi"
	printf "%2s%s\n" "" "FAILED : Kodi not currently on foreground"
	exit 1
fi
stopkodi.sh || exit $?
startx11.sh || exit $?
exit 0
