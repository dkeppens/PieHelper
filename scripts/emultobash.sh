#!/bin/ksh
# Move from Emulationstation to Bash (by Davy Keppens on 04/10/2018)
# Enable/Disable debug by running confpieh_ph.sh -d emultobash.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

if [[ `fgconsole` -ne `ph_get_tty_for_app Emulationstation` ]]
then
	printf "%s\n" "- Disabling Emulationstation"
	printf "%2s%s\n" "" "FAILED : Emulationstation not currently on foreground"
	exit 1
fi
stopemul.sh || exit $?
startbash.sh || exit $?
exit 0
