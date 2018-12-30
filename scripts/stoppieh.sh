#!/bin/ksh
# Stop PieHelper (by Davy Keppens on 04/10/2018)
# Enable/Disable debug by running confpieh_ph.sh -d stoppieh.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

typeset PH_RUNAPP="PieHelper"
typeset PH_PARAM="$1"
typeset PH_OPTION=""
typeset PH_INST=""
typeset PH_FLAG=""
typeset PH_i=""
typeset PH_OLDOPTARG="$OPTARG"
typeset -l PH_RUNAPPL=`echo $PH_RUNAPP | cut -c1-4`
typeset -i PH_RUNAPP_TTY=0
typeset -i PH_OLDOPTIND=$OPTIND
OPTIND=1

while getopts ph PH_OPTION 2>/dev/null
do
        case $PH_OPTION in p)
		PH_FLAG="pseudo" ;;
                           *)
                >&2 printf "%s\n" "Usage : stop$PH_RUNAPPL.sh '-p' | -h"
                >&2 printf "\n"
                >&2 printf "%3s%s\n" "" "Where -h displays this usage"
                >&2 printf "%9s%s\n" "" "-p allows setting the stop of $PH_RUNAPP to be executed on a pseudo-terminal instead of it's allocated TTY"
                >&2 printf "%12s%s\n" "" "- Specifying -p is optional"
                >&2 printf "%9s%s\n" "" "- Running this script without parameters will stop an instance of $PH_RUNAPP running on it's allocated TTY"
                >&2 printf "\n"
                OPTIND=$PH_OLDOPTIND ; OPTARG="$PH_OLDOPTARG" ; exit 1 ;;
        esac
done
OPTIND=$PH_OLDOPTIND
OPTARG="$PH_OLDOPTARG"

if [[ `$PH_SUDO cat /proc/$PPID/comm` != start*sh ]]
then
	ph_check_app_name -i -a "$PH_RUNAPP" || exit $?
fi
printf "%s\n" "- Disabling $PH_RUNAPP"
if [[ "$PH_FLAG" != "pseudo" ]]
then
	printf "%8s%s\n" "" "--> Attempting to determine TTY for $PH_RUNAPP"
	PH_RUNAPP_TTY=`ph_get_tty_for_app $PH_RUNAPP`
	if [[ $? -eq 1 && $PH_RUNAPP_TTY -ne 0 ]]
	then
		printf "%10s%s\n" "" "OK (Found)"
	else
		printf "%10s%s\n" "" "Warning : Could not determine TTY for $PH_RUNAPP"
		printf "%2s%s\n" "" "SUCCESS"
		exit 0
	fi
fi
printf "%8s%s\n" "" "--> Checking for $PH_RUNAPP"
PH_INST=`pgrep startpieh.sh | sed "s/^$PPID$//g" | paste -d" " -s`
[[ -z "$PH_INST" ]] && printf "%10s%s\n" "" "Warning : $PH_RUNAPP not running" && printf "%2s%s\n" "" "SUCCESS" && return 0
pgrep -t tty$PH_RUNAPP_TTY start$PH_RUNAPPL.sh >/dev/null
case $?_$PH_FLAG in 0_)
	printf "%10s%s\n" "" "OK (Found)"
        [[ -z "$1" && `$PH_SUDO cat /proc/$PPID/comm` != @(start*sh|+(?)to+(?).sh|restart!($PH_RUNAPPL).sh) ]] && \
                        PH_PARAM="force"
	[[ `tty` == "/dev/tty$PH_RUNAPP_TTY" ]] && PH_PARAM="force"
	ph_run_app_action stop "$PH_RUNAPP" $PH_PARAM || (printf "%2s%s\n" "" "FAILED" ; return 1) || exit $? ;;
		    1_)
	printf "%10s%s\n" "" "ERROR : $PH_RUNAPP currently running on a pseudo-terminal -> Use -p" && printf "%2s%s\n" "" "FAILED" && exit 1 ;;
	      0_pseudo)
	printf "%10s%s\n" "" "ERROR : $PH_RUNAPP currently running on it's allocated TTY -> Don't use -p" && printf "%2s%s\n" "" "FAILED" && exit 1 ;;
	      1_pseudo)
	printf "%10s%s\n" "" "OK (Found)"
	printf "%8s%s\n" "" "--> Stopping $PH_RUNAPP"
	for PH_i in $PH_INST
	do
		kill $PH_i
	done
	printf "%10s%s\n" "" "OK" ;;
esac
printf "%2s%s\n" "" "SUCCESS"
exit 0
