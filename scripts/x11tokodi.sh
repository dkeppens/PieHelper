#!/bin/ksh
# Move from X11 to Kodi (by Davy Keppens on 04/10/2018)
# Enable/Disable debug by running confpieh_ph.sh -p debug -m x11tokodi.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

typeset PH_RUNAPP="Kodi"
typeset PH_STOPAPP="X11"
typeset PH_OPTION=""
typeset PH_OLDOPTARG="$OPTARG"
typeset -i PH_OLDOPTIND=$OPTIND
typeset -l PH_RUNAPPL=`echo $PH_RUNAPP | cut -c1-4`
typeset -l PH_STOPAPPL=`echo $PH_STOPAPP | cut -c1-4`
OPTIND=1

while getopts h PH_OPTION 2>/dev/null
do
        case $PH_OPTION in *)
                >&2 printf "%s%s%s%s\n" "Usage : $PH_STOPAPPL" "to" "$PH_RUNAPPL" ".sh | -h"
                >&2 printf "\n"
                >&2 printf "%3s%s\n" "" "Where -h displays this usage"
                >&2 printf "%9s%s\n" "" "- Running this script without parameters will stop an instance of $PH_STOPAPP running on it's allocated TTY if"
		>&2 printf "%9s%s\n" ""	"  the currently active TTY is the TTY allocated to $PH_STOPAPP"
		>&2 printf "%9s%s\n" "" "  If successful, a new instance of $PH_RUNAPP will be started on it's allocated TTY"
                >&2 printf "%12s%s\n" "" "- The first unallocated TTY will be automatically assigned to any application without a TTY that attempts to start"
                >&2 printf "%12s%s\n" "" "- A TTY is only deallocated when an application is removed from PieHelper"
                >&2 printf "%12s%s\n" "" "- If an application in need of a TTY attempts to start but all TTY's are already allocated, startup will fail"
                >&2 printf "%12s%s\n" "" "- Persistence will be taken into account when stopping $PH_STOPAPP since the stop command is being issued indirectly"
                >&2 printf "%12s%s\n" "" "- At any application start, all other running applications marked non-persistent, will first be stopped"
                >&2 printf "%12s%s\n" "" "  Two exceptions to this rule exist :"
                >&2 printf "%15s%s\n" "" "- PieHelper starting on a pseudo-terminal will never stop running applications"
                >&2 printf "%15s%s\n" "" "- To avoid unnecessary actions for move scripts, stop actions performed directly by those will not be repeated"
		>&2 printf "%15s%s\n" "" "  A move script is defined as a script named 'xxxx'to'yyyy'.sh where 'xxxx' is the shortname of the application it will stop"
		>&2 printf "%15s%s\n" "" "  and 'yyyy' is the shortname of the application it will start"
                >&2 printf "%12s%s\n" "" "- Additionally, the following rules apply to the stop of $PH_STOPAPP :"
                >&2 printf "%15s%s\n" "" "- If no active instance of $PH_STOPAPP can be found on it's allocated TTY or"
                >&2 printf "%15s%s\n" "" "  the TTY for $PH_STOPAPP cannot be determined, stop will be skipped but succeed with a warning"
                >&2 printf "%12s%s\n" "" "- Additionally, the following rules apply to the start of $PH_RUNAPP :"
		>&2 printf "%15s%s\n" "" "- If a persistent $PH_RUNAPP instance is already running on that TTY, that TTY will become the active TTY"
                >&2 printf "%15s%s\n" "" "- If a non-persistent $PH_RUNAPP instance is already running on that TTY, startup will fail"
                >&2 printf "\n"
                OPTIND=$PH_OLDOPTIND ; OPTARG="$PH_OLDOPTARG" ; exit 1 ;;
        esac
done
OPTIND=$PH_OLDOPTIND
OPTARG="$PH_OLDOPTARG"

if [[ `$PH_SUDO fgconsole` -ne `ph_get_tty_for_app $PH_STOPAPP` ]]
then
	printf "%s\n" "- Disabling $PH_STOPAPP"
	printf "%2s%s\n" "" "FAILED : $PH_STOPAPP not currently on foreground"
	exit 1
fi
stop"$PH_STOPAPPL".sh || exit $?
start"$PH_RUNAPPL".sh || exit $?
exit 0
