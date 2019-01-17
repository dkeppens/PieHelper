#!/bin/ksh
# Start Bash (by Davy Keppens on 04/10/2018)
# Enable/Disable debug by running confpieh_ph.sh -p debug -m startbash.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

typeset PH_RUNAPP="Bash"
typeset PH_RUNAPP_CMD=""
typeset PH_EXCEPTION=""
typeset PH_OPTION=""
typeset PH_OLDOPTARG="$OPTARG"
typeset PH_i=""
typeset -l PH_APPSL=""
typeset -l PH_RUNAPPL=`echo $PH_RUNAPP | cut -c1-4`
typeset -u PH_RUNAPPU=`echo $PH_RUNAPP | cut -c1-4`
typeset -i PH_RUNAPP_TTY=0
typeset -i PH_OLDOPTIND=$OPTIND
OPTIND=1

while getopts h PH_OPTION 2>/dev/null
do
        case $PH_OPTION in *)
                >&2 printf "%s%s%s\n" "Usage : start" "$PH_RUNAPPL" ".sh | -h"
                >&2 printf "\n"
                >&2 printf "%3s%s\n" "" "Where -h displays this usage"
                >&2 printf "%9s%s\n" "" "- Running this script without parameters will start a new instance of $PH_RUNAPP on it's allocated TTY"
                >&2 printf "%12s%s\n" "" "- The first unallocated TTY will be automatically assigned to any application without a TTY that attempts to start"
                >&2 printf "%12s%s\n" "" "- A TTY is only deallocated when an application is removed from PieHelper"
                >&2 printf "%12s%s\n" "" "- If an application in need of a TTY attempts to start but all TTY's are already allocated, startup will fail"
                >&2 printf "%12s%s\n" "" "- At any application start, all other running applications marked non-persistent, will first be stopped"
                >&2 printf "%12s%s\n" "" "  Two exceptions to this rule exist :"
                >&2 printf "%15s%s\n" "" "- PieHelper starting on a pseudo-terminal will never stop running applications"
                >&2 printf "%15s%s\n" "" "- To avoid unnecessary actions for move scripts, stop actions performed directly by those will not be repeated"
                >&2 printf "%15s%s\n" "" "  A move script is defined as a script named 'xxxx'to'yyyy'.sh where 'xxxx' is the shortname of the application it will stop"
                >&2 printf "%15s%s\n" "" "  and 'yyyy' is the shortname of the application it will start"
                >&2 printf "%12s%s\n" "" "- Additionally, the following rules apply to the start of $PH_RUNAPP :"
                >&2 printf "%15s%s\n" "" "- If a persistent $PH_RUNAPP instance is already running on that TTY, that TTY will become the active TTY"
                >&2 printf "%15s%s\n" "" "- If a non-persistent $PH_RUNAPP instance is already running on that TTY, startup will fail"
                >&2 printf "\n"
                OPTIND=$PH_OLDOPTIND ; OPTARG="$PH_OLDOPTARG" ; exit 1 ;;
        esac
done
OPTIND=$PH_OLDOPTIND
OPTARG="$PH_OLDOPTARG"

if [[ `$PH_SUDO cat /proc/$PPID/comm` != restart*sh ]]
then
        ph_check_app_name -i -a "$PH_RUNAPP" || exit $?
fi
printf "%s\n" "- Checking for application presences"
[[ `$PH_SUDO cat /proc/$PPID/comm` == +(?)to+(?).sh ]] && PH_EXCEPTION=`nawk '$1 ~ /^stop.*\.sh$/ { print substr($1,5,length($1)-7) }' $PH_SCRIPTS_DIR/\`$PH_SUDO cat /proc/$PPID/comm\``
for PH_i in `cut -f1 $PH_CONF_DIR/installed_apps | egrep -v ^"$PH_RUNAPP"$ | paste -d" " -s`
do
	PH_RUNAPPL=`echo $PH_i | cut -c1-4`
	if [[ "$PH_EXCEPTION" != "$PH_RUNAPPL" ]]
	then
		printf "%8s%s\n" "" "--> Checking for $PH_i"
		PH_RUNAPP_TTY=`ph_get_tty_for_app $PH_i`
		PH_RUNAPP_CMD=`nawk -v runapp=^"$PH_i"$ 'BEGIN { ORS=" " } $1 ~ runapp { for (i=2;i<=NF;i++) { if (i==NF) { ORS="" ; print $i } else { print $i }}}' $PH_CONF_DIR/supported_apps`
		PH_RUNAPP_CMD=`sed "s/PH_TTY/$PH_RUNAPP_TTY/" <<<$PH_RUNAPP_CMD`
		[[ "$PH_i" == "Bash" ]] && PH_RUNAPP_CMD="bash"
		if pgrep -t tty$PH_RUNAPP_TTY -f "$PH_RUNAPP_CMD" >/dev/null
		then
			printf "%10s%s\n" "" "Warning : $PH_i is active -> Stopping"
			[[ -n "$PH_APPSL" ]] && PH_APPSL="$PH_APPSL $PH_RUNAPPL" || PH_APPSL="$PH_RUNAPPL"
		else
			[[ "$PH_i" == "PieHelper" ]] && printf "%10s%s\n" "" "OK (Not found or running on a pseudo-terminal)" || \
								printf "%10s%s\n" "" "OK (Not found)"
		fi
	fi
done
printf "%2s%s\n" "" "SUCCESS"
for PH_i in $PH_APPSL
do
	$PH_SCRIPTS_DIR/stop"$PH_i".sh || exit $?
done
printf "%s\n" "- Enabling $PH_RUNAPP"
PH_RUNAPPL=`echo $PH_RUNAPP | cut -c1-4`
PH_RUNAPPU=`echo $PH_RUNAPP | cut -c1-4`
printf "%8s%s\n" "" "--> Attempting to determine TTY for $PH_RUNAPP"
PH_RUNAPP_TTY=`ph_get_tty_for_app $PH_RUNAPP`
if [[ $? -eq 0 ]]
then
	printf "%10s%s\n" "" "OK"
	ph_setup_tty $PH_RUNAPP_TTY "$PH_RUNAPP"
else
	if [[ $PH_RUNAPP_TTY -eq 0 ]]
	then
		printf "%10s%s\n" "" "ERROR : All TTY's already allocated"
		printf "%2s%s\n" "" "FAILED"
		exit 1
	else
		printf "%10s%s\n" "" "OK"
	fi
fi
PH_RUNAPP_CMD=`nawk -v runapp=^"$PH_RUNAPP"$ 'BEGIN { ORS=" " } $1 ~ runapp { for (i=2;i<=NF;i++) { if (i==NF) { ORS="" ; print $i } else { print $i }}}' $PH_CONF_DIR/supported_apps`
PH_RUNAPP_CMD=`sed "s/PH_TTY/$PH_RUNAPP_TTY/" <<<$PH_RUNAPP_CMD`
printf "%8s%s\n" "" "--> Checking for $PH_RUNAPP"
[[ "$PH_RUNAPP" == "Bash" ]] && PH_RUNAPP_CMD="bash"
if pgrep -t tty$PH_RUNAPP_TTY -f "$PH_RUNAPP_CMD" >/dev/null
then
	if [[ "$PH_RUNAPP" == "Bash" ]]
	then
		if [[ -n `ps --ppid \`pgrep -t tty$PH_RUNAPP_TTY -f "$PH_RUNAPP_CMD"\` 2>/dev/null | tail -n +2` ]]
		then
			printf "%10s%s\n" "" "OK (Not found)"
			ph_run_app_action start "$PH_RUNAPP" || (printf "%2s%s\n" "" "FAILED" ; return 1) || exit $?
			exit 0
		fi
	fi
	if [[ `eval echo "\\$PH_\$PH_RUNAPPU"_PERSISTENT` == "no" ]]
	then
		printf "%10s%s\n" "" "ERROR : $PH_RUNAPP already running on TTY$PH_RUNAPP_TTY"
		printf "%2s%s\n" "" "FAILED"
		exit 1
	else
		printf "%10s%s\n" "" "Warning : $PH_RUNAPP already persistent on TTY$PH_RUNAPP_TTY"
		printf "%2s%s\n" "" "SUCCESS"
		$PH_SUDO chvt $PH_RUNAPP_TTY
	fi
else
	printf "%10s%s\n" "" "OK (Not found)"
	ph_run_app_action start "$PH_RUNAPP"
	if [[ $? -eq 0 ]]
	then
		[[ "$PH_RUNAPP" != "Bash" ]] && printf "%2s%s\n" "" "SUCCESS"
	else
		printf "%2s%s\n" "" "FAILED"
		exit 1
	fi
fi
exit 0
