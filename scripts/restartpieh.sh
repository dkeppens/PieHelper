#!/bin/ksh
# Restart PieHelper (by Davy Keppens on 04/10/2018)
# Enable/Disable debug by running confpieh_ph.sh -p debug -m restartpieh.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

typeset PH_RUNAPP="PieHelper"
typeset PH_OPTION=""
typeset PH_MENU=""
typeset PH_FLAG=""
typeset PH_OLDOPTARG="$OPTARG"
typeset -l PH_RUNAPPL=`echo $PH_RUNAPP | cut -c1-4`
typeset -i PH_OLDOPTIND=$OPTIND
OPTIND=1

while getopts phm: PH_OPTION
do
	case $PH_OPTION in p)
		[[ `tty` != /dev/pts/* ]] && printf "%s\n" "- Restarting $PH_RUNAPP" && printf "%2s%s\n" "" "FAILED : Not currently on a pseudo-terminal" && \
						OPTIND=$PH_OLDOPTIND && OPTARG="$PH_OLDOPTARG" && exit 1
		PH_FLAG="pseudo" ;;
			   m)
		if ! ph_screen_input "$OPTARG"
		then
			OPTARG="$PH_OLDOPTARG"
			OPTIND=$PH_OLDOPTIND
			exit 1
		fi
		PH_MENU="$OPTARG" ;;
			   *)
                >&2 printf "%s%s%s\n" "Usage : restart" "$PH_RUNAPPL" ".sh '-p' '-m ['menu']' | -h"
                >&2 printf "\n"
                >&2 printf "%3s%s\n" "" "Where -h displays this usage"
                >&2 printf "%9s%s\n" "" "- Running this script without parameters will stop an instance of $PH_RUNAPP running on it's allocated TTY"
                >&2 printf "%9s%s\n" "" "  If successful, $PH_RUNAPP will be restarted on the same TTY"
                >&2 printf "%12s%s\n" "" "- The first unallocated TTY will be automatically assigned to any application without a TTY that attempts to start"
                >&2 printf "%12s%s\n" "" "- A TTY is only deallocated when an application is removed from PieHelper"
                >&2 printf "%12s%s\n" "" "- If an application in need of a TTY attempts to start but all TTY's are already allocated, startup will fail"
                >&2 printf "%12s%s\n" "" "- Persistence will be ignored when stopping $PH_RUNAPP since the stop command is being issued by a restart"
                >&2 printf "%12s%s\n" "" "- At any application start, all other running applications marked non-persistent, will first be stopped"
                >&2 printf "%12s%s\n" "" "  Two exceptions to this rule exist :"
                >&2 printf "%15s%s\n" "" "- PieHelper starting on a pseudo-terminal will never stop running applications"
                >&2 printf "%15s%s\n" "" "- To avoid unnecessary actions for move scripts, stop actions performed directly by those will not be repeated"
                >&2 printf "%15s%s\n" "" "  A move script is defined as a script named 'xxxx'to'yyyy'.sh where 'xxxx' is the shortname of the application it will stop"
                >&2 printf "%15s%s\n" "" "  and 'yyyy' is the shortname of the application it will start"
                >&2 printf "%12s%s\n" "" "- Additionally, the following rules apply to the stop of $PH_RUNAPP :"
                >&2 printf "%15s%s\n" "" "- If a $PH_RUNAPP instance is running on a pseudo-terminal, stop will fail"
                >&2 printf "%15s%s\n" "" "- If no active instance of $PH_RUNAPP can be found on it's allocated TTY or"
                >&2 printf "%15s%s\n" "" "  the TTY for $PH_RUNAPP cannot be determined, stop will be skipped but succeed with a warning"
                >&2 printf "%9s%s\n" "" "-p allows setting both the stop and restart of $PH_RUNAPP to be executed on a pseudo-terminal instead of it's allocated TTY"
                >&2 printf "%12s%s\n" "" "- Specifying -p is optional"
                >&2 printf "%12s%s\n" "" "- The following rules replace these for a normal stop :"
                >&2 printf "%15s%s\n" "" "- If a $PH_RUNAPP instance is running on it's allocated TTY, stop will fail"
                >&2 printf "%15s%s\n" "" "- If no active instance of $PH_RUNAPP can be found on a pseudo-terminal, stop will be skipped but succeed with a warning"
                >&2 printf "%12s%s\n" "" "- Additionally, the following rules apply to the start of $PH_RUNAPP :"
		>&2 printf "%15s%s\n" "" "- As mentioned above, $PH_RUNAPP will not stop any other running applications when starting in this mode"
                >&2 printf "%9s%s\n" "" "-m allows starting $PH_RUNAPP directly in menu [menu] instead of the default Main menu"
                >&2 printf "%12s%s\n" "" "- Specifying -m is optional"
                >&2 printf "%12s%s\n" "" "- Allowed values for [menu] are \"Main\", \"Controllers\", \"Apps\", \"Advanced\", \"Settings\", \"PS3\", \"PS4\", \"XBOX360\", \"AppManagement\","
                >&2 printf "%12s%s\n" "" "  or the name of any supported application"
                >&2 printf "%15s%s\n" "" "- By default, the current value of option PH_PIEH_CMD_OPTS will be used"
                >&2 printf "%18s%s\n" "" "- If PH_PIEH_CMD_OPTS has no value, it will be set to 'Main'"
                >&2 printf "%15s%s\n" "" "- If an empty string is specified for [menu], the default will be used"
                >&2 printf "\n"
		OPTIND=$PH_OLDOPTIND
		OPTARG="$PH_OLDOPTARG"
                exit 1 ;;
	esac
done
OPTIND=$PH_OLDOPTIND
OPTARG="$PH_OLDOPTARG"

if [[ -z "$PH_FLAG" ]]
then
	$PH_SCRIPTS_DIR/stop"$PH_RUNAPPL".sh force || exit $?
	$PH_SCRIPTS_DIR/start"$PH_RUNAPPL".sh -m "$PH_MENU" || exit $?
else
	$PH_SCRIPTS_DIR/stop"$PH_RUNAPPL".sh -p || exit $?
	$PH_SCRIPTS_DIR/start"$PH_RUNAPPL".sh -p -m "$PH_MENU" || exit $?
fi
exit 0
