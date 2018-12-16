#!/bin/ksh
# Move from Kodi to Bash (by Davy Keppens on 04/10/2018)
# Enable/Disable debug by running confpieh_ph.sh -d koditobash.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

if [[ `fgconsole` -ne `ph_get_tty_for_app Kodi` ]]
then
	printf "%s\n" "- Disabling Kodi"
	printf "%2s%s\n" "" "FAILED : Kodi not currently on foreground"
	exit 1
fi
stopkodi.sh || exit $?
startbash.sh || exit $?
exit 0
