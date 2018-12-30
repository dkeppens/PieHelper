#!/bin/ksh
# Move from Emulationstation to Kodi (by Davy Keppens on 04/10/2018)
# Enable/Disable debug by running confpieh_ph.sh -d emultokodi.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

typeset PH_OPTION=""
typeset PH_OLDOPTARG="$OPTARG"
typeset -i PH_OLDOPTIND=$OPTIND

while getopts h PH_OPTION 2>/dev/null
do
        case $PH_OPTION in *)
                >&2 printf "%s\n" "Usage : emultokodi.sh |-h"
                >&2 printf "\n"
                >&2 printf "%3s%s\n" "" "Where -h displays this usage"
                >&2 printf "\n"
                >&2 printf "%9s%s\n" "" "Running this script without parameters will stop a running instance of Emulationstation if"
                >&2 printf "%9s%s\n" "" "the currently active TTY is the TTY allocated to Emulationstation"
                >&2 printf "%9s%s\n" "" "If successful, a new instance of Kodi will be started if one is not already running"
                >&2 printf "\n"
                OPTIND=$PH_OLDOPTIND ; OPTARG="$PH_OLDOPTARG" ; exit 1 ;;
        esac
done
OPTIND=$PH_OLDOPTIND
OPTARG="$PH_OLDOPTARG"

if [[ `fgconsole` -ne `ph_get_tty_for_app Emulationstation` ]]
then
	printf "%s\n" "- Disabling Emulationstation"
	printf "%2s%s\n" "" "FAILED : Emulationstation not currently on foreground"
	exit 1
fi
stopemul.sh || exit $?
startkodi.sh || exit $?
exit 0
