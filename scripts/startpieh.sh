#!/bin/ksh
# Start PieHelper (by Davy Keppens on 04/10/2018)
# Enable/Disable debug by running confpieh_ph.sh -p debug -m startpieh.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

typeset PH_RUNAPP="PieHelper"
typeset PH_EXCEPTION=""
typeset PH_OPTION=""
typeset PH_OLDOPTARG="$OPTARG"
typeset PH_INST=""
typeset PH_FLAG=""
typeset PH_i=""
typeset PH_RUNAPP_CMD=""
typeset -l PH_RUNAPPL=`echo $PH_RUNAPP | cut -c1-4`
typeset -l PH_APPSL=""
typeset -u PH_RUNAPPU=`echo $PH_RUNAPP | cut -c1-4`
typeset -i PH_RUNAPP_TTY=0
typeset -i PH_OLDOPTIND=$OPTIND
OPTIND=1
export PH_LAST_RETURN_GLOB="yes"

while getopts phm: PH_OPTION 2>/dev/null
do
        case $PH_OPTION in p)
                [[ `tty` != /dev/pts/* ]] && printf "%s\n" "- Enabling $PH_RUNAPP" && printf "%2s%s\n\n" "" "FAILED : Not currently on a pseudo-terminal" && \
						OPTIND=$PH_OLDOPTIND && OPTARG="$PH_OLDOPTARG" && exit 1
		PH_FLAG="pseudo" ;;
			   m)
		if ! ph_screen_input "$OPTARG"
		then
			OPTIND=$PH_OLDOPTIND
			OPTARG="$PH_OLDOPTARG"
			exit 1
		fi
		if [[ "$OPTARG" != @(Main|Controllers|Apps|Advanced|Settings|PS3|PS4|XBOX360|AppManagement|OS|OSdefaults|`nawk 'BEGIN { ORS = "|" } { print $1 }' $PH_CONF_DIR/supported_apps`) ]]
		then
			if ! startpieh.sh -h
			then
				OPTIND=$PH_OLDOPTIND
				OPTARG="$PH_OLDOPTARG"
				exit 1
			fi
		fi
		if [[ -n "$OPTARG" && "$PH_PIEH_CMD_OPTS" != "$OPTARG" ]]
		then
			$PH_SCRIPTS_DIR/confopts_ph.sh -p set -a PieHelper -o PH_PIEH_CMD_OPTS="$OPTARG"
			export PH_PIEH_CMD_OPTS="$OPTARG"
		fi ;;
                           *)
                >&2 printf "%s%s%s\n" "Usage : start" "$PH_RUNAPPL.sh" " '-m ['menu']' '-p' | -h"
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
                >&2 printf "%15s%s\n" "" "- $PH_RUNAPP will always activate persistence for itself before starting on a TTY"
                >&2 printf "%15s%s\n" "" "- $PH_RUNAPP will always terminate after any other application startup completes fully"
                >&2 printf "%15s%s\n" "" "- If a $PH_RUNAPP instance is already running on a pseudo-terminal, that instance will be replaced by the new instance on it's allocated TTY"
                >&2 printf "%9s%s\n" "" "-p allows setting the start of $PH_RUNAPP to be executed on a pseudo-terminal instead of it's allocated TTY"
                >&2 printf "%12s%s\n" "" "- Specifying -p is optional"
                >&2 printf "%12s%s\n" "" "- The following rules replace these for a normal start :" 
                >&2 printf "%15s%s\n" "" "- As mentioned above, PieHelper will not stop any other running applications when starting in this mode" 
                >&2 printf "%15s%s\n" "" "- If a persistent $PH_RUNAPP pseudo-terminal instance is already running, startup will be skipped but succeed with a warning" 
                >&2 printf "%15s%s\n" "" "- If a non-persistent $PH_RUNAPP pseudo-terminal instance is already running, startup will fail"
                >&2 printf "%15s%s\n" "" "- If a $PH_RUNAPP instance is already running on it's allocated TTY, that instance will be replaced by the new pseudo-terminal instance"
                >&2 printf "%9s%s\n" "" "-m allows starting $PH_RUNAPP directly in menu [menu] instead of the default Main menu"
                >&2 printf "%12s%s\n" "" "- Specifying -m is optional"
                >&2 printf "%12s%s\n" "" "- Allowed values for [menu] are \"Main\", \"Controllers\", \"Apps\", \"Advanced\", \"Settings\", \"PS3\", \"PS4\", \"XBOX360\", \"AppManagement\","
                >&2 printf "%12s%s\n" "" "  or the name of any supported application"
                >&2 printf "%15s%s\n" "" "- By default, the current value of option PH_PIEH_CMD_OPTS will be used"
                >&2 printf "%18s%s\n" "" "- If PH_PIEH_CMD_OPTS has no value, it will be set to 'Main'"
                >&2 printf "%15s%s\n" "" "- If an empty string is specified for [menu], the default will be used"
                >&2 printf "%12s%s\n" "" "- This setting will be ignored if a persistent instance of $PH_RUNAPP is already active"
                >&2 printf "\n"
                OPTIND=$PH_OLDOPTIND ; OPTARG="$PH_OLDOPTARG" ; exit 1 ;;
        esac
done
OPTIND=$PH_OLDOPTIND
OPTARG="$PH_OLDOPTARG"

if [[ -z "$PH_PIEH_CMD_OPTS" ]]
then
	$PH_SCRIPTS_DIR/confopts_ph.sh -p set -a PieHelper -o PH_PIEH_CMD_OPTS="Main" && export PH_PIEH_CMD_OPTS="Main"
fi
if [[ `$PH_SUDO cat /proc/$PPID/comm` != restart*sh ]]
then
        ph_check_app_name -i -a "$PH_RUNAPP" || exit $?
fi
if [[ "$PH_FLAG" != "pseudo" ]]
then
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
				printf "%10s%s\n" "" "OK (Not found)"
			fi
		fi
	done
	printf "%2s%s\n" "" "SUCCESS"
	for PH_i in $PH_APPSL
	do
		$PH_SCRIPTS_DIR/stop"$PH_i".sh || exit $?
	done
	PH_RUNAPPL=`echo $PH_RUNAPP | cut -c1-4`
fi
printf "%s\n" "- Enabling $PH_RUNAPP"
printf "%8s%s\n" "" "--> Attempting to determine TTY for $PH_RUNAPP"
PH_RUNAPP_TTY=`ph_get_tty_for_app $PH_RUNAPP`
printf "%10s%s\n" "" "OK (Found)"
printf "%8s%s\n" "" "--> Checking for $PH_RUNAPP"
PH_INST=`pgrep start"$PH_RUNAPPL".sh | sed "s/^$$$//g" | paste -d" " -s`
if [[ -n "$PH_INST" && `$PH_SUDO cat /proc/$PPID/comm` != "restart$PH_RUNAPPL.sh" ]]
then
	if [[ "$PH_FLAG" != "pseudo" ]]
	then
		if pgrep -t tty$PH_RUNAPP_TTY -f start"$PH_RUNAPPL".sh >/dev/null
		then
			printf "%10s%s\n" "" "Warning : $PH_RUNAPP already persistent on TTY$PH_RUNAPP_TTY"
			printf "%2s%s\n\n" "" "SUCCESS"
			$PH_SUDO chvt $PH_RUNAPP_TTY
		else
        		printf "%10s%s\n" "" "OK (Found on pseudo-terminal) -> Stopping"
			printf "%2s%s\n" "" "SUCCESS"
			$PH_SCRIPTS_DIR/stop"$PH_RUNAPPL".sh -p || exit $?
			printf "%s\n" "- Restarting $PH_RUNAPP on a TTY"
			ph_set_option PieHelper -r PH_PIEH_PERSISTENT='yes' || (printf "%2s%s\n\n" "" "FAILED" ; return 1) || exit $?
			ph_run_app_action start "$PH_RUNAPP"
			[[ $? -eq 0 ]] && printf "%2s%s\n\n" "" "SUCCESS" || (printf "%2s%s\n\n" "" "FAILED" ; return 1) || exit $?
		fi
	else
		if pgrep -t tty$PH_RUNAPP_TTY -f start"$PH_RUNAPPL".sh >/dev/null
		then
        		printf "%10s%s\n" "" "OK (Found on TTY$PH_RUNAPP_TTY) -> Stopping"
			printf "%2s%s\n" "" "SUCCESS"
			$PH_SCRIPTS_DIR/stop"$PH_RUNAPPL".sh force || exit $?
			printf "%s\n" "- Restarting $PH_RUNAPP on a pseudo-terminal"
			printf "%8s%s\n" "" "--> Starting $PH_RUNAPP"
			printf "%10s%s\n" "" "OK"
			printf "%2s%s\n\n" "" "SUCCESS"
			ph_show_menu "$PH_PIEH_CMD_OPTS"
		else
			if [[ `eval echo "\\$PH_\$PH_RUNAPPU"_PERSISTENT` == "no" ]]
			then
				printf "%10s%s\n" "" "ERROR : $PH_RUNAPP already running on a pseudo-terminal"
				printf "%2s%s\n\n" "" "FAILED"
				exit 1
			else
				printf "%10s%s\n" "" "Warning : $PH_RUNAPP already persistent on a pseudo-terminal"
				printf "%2s%s\n\n" "" "SUCCESS"
			fi
		fi
	fi
else
        printf "%10s%s\n" "" "OK (Not found)"
	if [[ "$PH_FLAG" == "" ]]
	then
		ph_set_option PieHelper -r PH_PIEH_PERSISTENT='yes' || (printf "%2s%s\n\n" "" "FAILED" ; return 1) || exit $?
		ph_run_app_action start "$PH_RUNAPP"
		[[ $? -eq 0 ]] && printf "%2s%s\n\n" "" "SUCCESS" || (printf "%2s%s\n\n" "" "FAILED" ; return 1) || exit $?
	else
		printf "%8s%s\n" "" "--> Starting $PH_RUNAPP"
		printf "%10s%s\n" "" "OK"
		printf "%2s%s\n\n" "" "SUCCESS"
		ph_show_menu "$PH_PIEH_CMD_OPTS"
	fi
fi
exit 0
