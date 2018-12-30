#!/bin/ksh
# Stop Moonlight (by Davy Keppens on 04/10/2018)
# Enable/Disable debug by running confpieh_ph.sh -d stopmoon.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

typeset PH_RUNAPP="Moonlight"
typeset PH_PARAM="$1"
typeset PH_OPTION=""
typeset PH_RUNAPP_CMD=""
typeset PH_OLDOPTARG="$OPTARG"
typeset -l PH_RUNAPPL=`echo $PH_RUNAPP | cut -c1-4`
typeset -i PH_RUNAPP_TTY=0
typeset -i PH_OLDOPTIND=$OPTIND
OPTIND=1

while getopts h PH_OPTION 2>/dev/null
do
        case $PH_OPTION in *)
                >&2 printf "%s\n" "Usage : stopmoon.sh | -h"
                >&2 printf "\n"
                >&2 printf "%3s%s\n" "" "Where -h displays this usage"
                >&2 printf "%9s%s\n" "" "- Running this script without parameters will stop an instance of Moonlight running on it's allocated TTY"
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
printf "%8s%s\n" "" "--> Attempting to determine TTY for $PH_RUNAPP"
PH_RUNAPP_TTY=`ph_get_tty_for_app $PH_RUNAPP`
[[ $? -eq 1 && $PH_RUNAPP_TTY -ne 0 ]] && printf "%10s%s\n" "" "OK (TTY$PH_RUNAPP_TTY)" || \
		(printf "%10s%s\n" "" "Warning : Could not determine TTY for $PH_RUNAPP" ; printf "%2s%s\n" "" "SUCCESS" ; return 1) || \
		 exit 0
PH_RUNAPP_CMD=`nawk -v runapp=^"$PH_RUNAPP"$ 'BEGIN { ORS=" " } $1 ~ runapp { for (i=2;i<=NF;i++) { if (i==NF) { ORS="" ; print $i } else { print $i }}}' $PH_CONF_DIR/supported_apps`
PH_RUNAPP_CMD=`sed "s/PH_TTY/$PH_RUNAPP_TTY/" <<<$PH_RUNAPP_CMD`
printf "%8s%s\n" "" "--> Checking for $PH_RUNAPP"
[[ "$PH_RUNAPP" == "Bash" ]] && PH_RUNAPP_CMD="bash"
if pgrep -t tty$PH_RUNAPP_TTY -f "$PH_RUNAPP_CMD"  >/dev/null
then
	printf "%10s%s\n" "" "OK (Found)"
        [[ -z "$1" && `$PH_SUDO cat /proc/$PPID/comm` != @(start*sh|+(?)to+(?).sh|restart!($PH_RUNAPPL).sh) ]] && \
			PH_PARAM="force"
	ph_run_app_action stop "$PH_RUNAPP" $PH_PARAM
	case $? in 3)
		printf "%2s%s\n" "" "PARTIALLY FAILED"
		exit 1 ;;
		   1)
		printf "%2s%s\n" "" "FAILED"
		exit 1 ;;
	esac
else
	printf "%10s%s\n" "" "Warning : $PH_RUNAPP not running"
fi
printf "%2s%s\n" "" "SUCCESS"
exit 0
