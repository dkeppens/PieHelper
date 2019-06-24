#!/bin/ksh
# Stop PieHelper (by Davy Keppens on 04/10/2018)
# Enable/Disable debug by running 'confpieh_ph.sh -p debug -m stoppieh.sh'

. $(dirname "$0")/../main/main.sh || exit "$?" && set +x

#set -x

typeset PH_STOPAPP="PieHelper"
typeset PH_PARAM="$1"
typeset PH_OPTION=""
typeset PH_INST=""
typeset PH_FLAG=""
typeset PH_i=""
typeset PH_OLDOPTARG="$OPTARG"
typeset -l PH_STOPAPPL=`echo "$PH_STOPAPP" | cut -c1-4`
typeset -i PH_STOPAPP_TTY="0"
typeset -i PH_OLDOPTIND="$OPTIND"
OPTIND="1"

while getopts ph PH_OPTION 2>/dev/null
do
        case "$PH_OPTION" in p)
		PH_FLAG="pseudo" ;;
                             *)
                >&2 printf "%s%s%s\n" "Usage : stop" "$PH_STOPAPPL.sh" " '-p' | -h"
                >&2 printf "\n"
                >&2 printf "%3s%s\n" "" "Where -h displays this usage"
                >&2 printf "%9s%s\n" "" "- Running this script without parameters will stop an instance of '$PH_STOPAPP' running on it's allocated TTY"
                >&2 printf "%12s%s\n" "" "- A TTY is only deallocated when an application is removed from PieHelper"
                >&2 printf "%12s%s\n" "" "- Additionally, the following rules apply to the stop of '$PH_STOPAPP' :"
                >&2 printf "%15s%s\n" "" "- If a '$PH_RUNAPP' instance is running on a pseudo-terminal, stop will fail"
                >&2 printf "%15s%s\n" "" "- If no active instance of '$PH_RUNAPP' can be found on it's allocated TTY or"
                >&2 printf "%15s%s\n" "" "  the TTY for '$PH_RUNAPP' cannot be determined, stop will be skipped but succeed with a warning"
                >&2 printf "%9s%s\n" "" "-p allows setting the stop of '$PH_STOPAPP' to be executed on a pseudo-terminal instead of it's allocated TTY"
                >&2 printf "%12s%s\n" "" "- Specifying -p is optional"
                >&2 printf "%12s%s\n" "" "- The following rules replace these for a normal stop :"
                >&2 printf "%15s%s\n" "" "- If a '$PH_STOPAPP' instance is running on it's allocated TTY, stop will fail"
                >&2 printf "%15s%s\n" "" "- If no active instance of '$PH_STOPAPP' can be found on a pseudo-terminal, stop will be skipped but succeed with a warning"
                >&2 printf "\n"
                OPTIND="$PH_OLDOPTIND" ; OPTARG="$PH_OLDOPTARG" ; exit 1 ;;
        esac
done
OPTIND="$PH_OLDOPTIND"
OPTARG="$PH_OLDOPTARG"

if [[ `"$PH_SUDO" cat /proc/"$PPID"/comm 2>/dev/null` != "confsupp_ph.sh" ]]
then
	ph_check_app_name -i -a "$PH_STOPAPP" || exit "$?"
fi
printf "\033[36m%s\033[0m\n" "- Disabling '$PH_STOPAPP'"
if [[ "$PH_FLAG" != "pseudo" ]]
then
	printf "%8s%s\n" "" "--> Attempting to determine TTY for '$PH_STOPAPP'"
	PH_STOPAPP_TTY=`ph_get_tty_for_app "$PH_STOPAPP"`
	if [[ "$?" -eq 1 && "$PH_STOPAPP_TTY" -ne 0 ]]
	then
		printf "%10s\033[32m%s\033[0m\n" "" "OK (Found)"
	else
		printf "%10s%s\n" "" "Warning : Could not determine TTY for '$PH_STOPAPP'"
		printf "%2s\033[32m%s\033[0m\n\n" "" "SUCCESS"
		exit 0
	fi
fi
printf "%8s%s\n" "" "--> Checking for '$PH_STOPAPP'"
PH_INST=`pgrep startpieh.sh | sed "s/^$PPID$//g" | paste -d" " -s`
[[ -z "$PH_INST" ]] && printf "%10s%s\n" "" "Warning : '$PH_STOPAPP' not running" && printf "%2s\033[32m%s\033[0m\n\n" "" "SUCCESS" && return 0
pgrep -t tty"$PH_STOPAPP_TTY" -f start"$PH_STOPAPPL".sh >/dev/null
case "$?"_"$PH_FLAG" in 0_)
	printf "%10s\033[32m%s\033[0m\n" "" "OK (Found)"
        [[ -z "$1" && `"$PH_SUDO" cat /proc/"$PPID"/comm` != @(start*sh|+(?)to+(?).sh|restart!("$PH_STOPAPPL").sh) ]] && \
                        PH_PARAM="force"
	ph_run_app_action stop "$PH_STOPAPP" "$PH_PARAM" || (printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" ; return 1) || exit "$?" ;;
		    1_)
	printf "%10s\033[31m%s\033[0m\n" "" "ERROR : '$PH_STOPAPP' currently running on a pseudo-terminal -> Use -p" && printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" && exit 1 ;;
	      0_pseudo)
	printf "%10s\033[31m%s\033[0m\n" "" "ERROR : '$PH_STOPAPP' currently running on it's allocated TTY -> Don't use -p" && printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" && exit 1 ;;
	      1_pseudo)
	printf "%10s\033[32m%s\033[0m\n" "" "OK (Found)"
	printf "%8s%s\n" "" "--> Stopping '$PH_STOPAPP'"
	for PH_i in `echo -n "$PH_INST"`
	do
		kill "$PH_i"
	done
	printf "%10s\033[32m%s\033[0m\n" "" "OK" ;;
esac
printf "%2s\033[32m%s\033[0m\n\n" "" "SUCCESS"
exit 0
