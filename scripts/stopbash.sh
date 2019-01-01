#!/bin/ksh
# Stop Bash (by Davy Keppens on 04/10/2018)
# Enable/Disable debug by running confpieh_ph.sh -d stopbash.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

typeset PH_STOPAPP="Bash"
typeset PH_PARAM="$1"
typeset PH_OPTION=""
typeset PH_STOPAPP_CMD=""
typeset PH_OLDOPTARG="$OPTARG"
typeset -l PH_STOPAPPL=`echo $PH_STOPAPP | cut -c1-4`
typeset -i PH_STOPAPP_TTY=0
typeset -i PH_OLDOPTIND=$OPTIND
OPTIND=1

while getopts h PH_OPTION 2>/dev/null
do
        case $PH_OPTION in *)
                >&2 printf "%s%s%s\n" "Usage : stop" "$PH_STOPAPPL" ".sh | -h"
                >&2 printf "\n"
                >&2 printf "%3s%s\n" "" "Where -h displays this usage"
                >&2 printf "%9s%s\n" "" "- Running this script without parameters will stop an instance of $PH_STOPAPP running on it's allocated TTY"
                >&2 printf "%12s%s\n" "" "- A TTY is only deallocated when an application is removed from PieHelper"
                >&2 printf "%12s%s\n" "" "- Additionally, the following rules apply to the stop of $PH_STOPAPP :"
                >&2 printf "%15s%s\n" "" "- If no active instance of $PH_STOPAPP can be found on it's allocated TTY or"
                >&2 printf "%15s%s\n" "" "  the TTY for $PH_STOPAPP cannot be determined, stop will be skipped but succeed with a warning"
                >&2 printf "\n"
                OPTIND=$PH_OLDOPTIND ; OPTARG="$PH_OLDOPTARG" ; exit 1 ;;
        esac
done
OPTIND=$PH_OLDOPTIND
OPTARG="$PH_OLDOPTARG"

if [[ `$PH_SUDO cat /proc/$PPID/comm` != start*sh ]]
then
	ph_check_app_name -i -a "$PH_STOPAPP" || exit $?
fi
printf "%s\n" "- Disabling $PH_STOPAPP"
printf "%8s%s\n" "" "--> Attempting to determine TTY for $PH_STOPAPP"
PH_STOPAPP_TTY=`ph_get_tty_for_app $PH_STOPAPP`
[[ $? -eq 1 && $PH_STOPAPP_TTY -ne 0 ]] && printf "%10s%s\n" "" "OK (TTY$PH_STOPAPP_TTY)" || \
		(printf "%10s%s\n" "" "Warning : Could not determine TTY for $PH_STOPAPP" ; printf "%2s%s\n" "" "SUCCESS" ; return 1) || \
		 exit 0
PH_STOPAPP_CMD=`nawk -v runapp=^"$PH_STOPAPP"$ 'BEGIN { ORS=" " } $1 ~ runapp { for (i=2;i<=NF;i++) { if (i==NF) { ORS="" ; print $i } else { print $i }}}' $PH_CONF_DIR/supported_apps`
PH_STOPAPP_CMD=`sed "s/PH_TTY/$PH_STOPAPP_TTY/" <<<$PH_STOPAPP_CMD`
printf "%8s%s\n" "" "--> Checking for $PH_STOPAPP"
[[ "$PH_STOPAPP" == "Bash" ]] && PH_STOPAPP_CMD="bash"
if pgrep -t tty$PH_STOPAPP_TTY -f "$PH_STOPAPP_CMD"  >/dev/null
then
	printf "%10s%s\n" "" "OK (Found)"
        [[ -z "$1" && `$PH_SUDO cat /proc/$PPID/comm` != @(start*sh|+(?)to+(?).sh|restart!($PH_STOPAPPL).sh) ]] && \
			PH_PARAM="force"
	ph_run_app_action stop "$PH_STOPAPP" $PH_PARAM
	case $? in 3)
		printf "%2s%s\n" "" "PARTIALLY FAILED"
		exit 1 ;;
		   1)
		printf "%2s%s\n" "" "FAILED"
		exit 1 ;;
	esac
else
	printf "%10s%s\n" "" "Warning : $PH_STOPAPP not running"
fi
printf "%2s%s\n" "" "SUCCESS"
exit 0
