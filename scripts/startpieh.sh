#!/bin/ksh
# Start PieHelper (by Davy Keppens on 04/10/2018)
# Enable/Disable debug by running confpieh_ph.sh -d startpieh.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

typeset PH_RUNAPP="PieHelper"
typeset PH_EXCEPTION=""
typeset PH_OPTION=""
typeset PH_INST=""
typeset PH_FLAG=""
typeset PH_i=""
typeset PH_RUNAPP_CMD=""
typeset PH_OLDOPTARG="$OPTARG"
typeset -l PH_RUNAPPL=""
typeset -l PH_APPSL=""
typeset -u PH_RUNAPPU=""
typeset -i PH_RUNAPP_TTY=0
typeset -i PH_OLDOPTIND=$OPTIND
OPTIND=1

PH_RUNAPPL=`echo $PH_RUNAPP | cut -c1-4`
PH_RUNAPPU=`echo $PH_RUNAPP | cut -c1-4`
while getopts ph PH_OPTION 2>/dev/null
do
        case $PH_OPTION in p)
                [[ `tty` != /dev/pts/* ]] && printf "%s\n" "- Enabling $PH_RUNAPP" && printf "%2s%s\n" "" "FAILED : Not currently on a pseudoterminal" && \
						OPTIND=$PH_OLDOPTIND && OPTARG="$PH_OLDOPTARG" && exit 1
		PH_FLAG="pseudo" ;;
                           *)
                >&2 printf "%s\n" "Usage : start$PH_RUNAPPL.sh -h|-p"
                >&2 printf "\n"
                >&2 printf "%3s%s\n" "" "Where -h displays this usage"
                >&2 printf "%9s%s\n" "" "-p requests to attempt starting an instance of $PH_RUNAPP on a pseudo-terminal"
                >&2 printf "\n"
                OPTIND=$PH_OLDOPTIND ; OPTARG="$PH_OLDOPTARG" ; exit 1 ;;
        esac
done
OPTIND=$PH_OLDOPTIND
OPTARG="$PH_OLDOPTARG"
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
				printf "%10s%s\n" "" "Warning : $PH_i is active"
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
PH_INST=`pgrep start$PH_RUNAPPL.sh | sed "s/^$$$//g" | paste -d" " -s`
if [[ -n "$PH_INST" && `$PH_SUDO cat /proc/$PPID/comm` != "restart$PH_RUNAPPL.sh" ]]
then
	if [[ "$PH_FLAG" != "pseudo" ]]
	then
		if pgrep -t tty$PH_RUNAPP_TTY -f start$PH_RUNAPPL.sh >/dev/null
		then
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
        		printf "%10s%s\n" "" "OK (Found on pseudo-terminal) -> Stopping"
			printf "%2s%s\n" "" "SUCCESS"
			$PH_SCRIPTS_DIR/stop$PH_RUNAPPL.sh -p || exit $?
			printf "%s\n" "- Restarting $PH_RUNAPP on a TTY"
			ph_run_app_action start "$PH_RUNAPP"
			[[ $? -eq 0 ]] && printf "%2s%s\n" "" "SUCCESS" || (printf "%2s%s\n" "" "FAILED" ; return 1) || exit $?
		fi
	else
		if pgrep -t tty$PH_RUNAPP_TTY -f start$PH_RUNAPPL.sh >/dev/null
		then
        		printf "%10s%s\n" "" "OK (Found on TTY$PH_RUNAPP_TTY) -> Stopping"
			printf "%2s%s\n" "" "SUCCESS"
			$PH_SCRIPTS_DIR/stop$PH_RUNAPPL.sh force || exit $?
			printf "%s\n" "- Restarting $PH_RUNAPP on a pseudo-terminal"
			printf "%8s%s\n" "" "--> Starting $PH_RUNAPP"
			printf "%10s%s\n" "" "OK"
			printf "%2s%s\n" "" "SUCCESS"
			ph_show_menu Main
		else
			if [[ `eval echo "\\$PH_\$PH_RUNAPPU"_PERSISTENT` == "no" ]]
			then
				printf "%10s%s\n" "" "ERROR : $PH_RUNAPP already running on a pseudo-terminal"
				printf "%2s%s\n" "" "FAILED"
				exit 1
			else
				printf "%10s%s\n" "" "Warning : $PH_RUNAPP already persistent on a pseudo-terminal"
				printf "%2s%s\n" "" "SUCCESS"
			fi
		fi
	fi
else
        printf "%10s%s\n" "" "OK (Not found)"
	if [[ "$PH_FLAG" == "" ]]
	then
		ph_run_app_action start "$PH_RUNAPP"
		[[ $? -eq 0 ]] && printf "%2s%s\n" "" "SUCCESS" || (printf "%2s%s\n" "" "FAILED" ; return 1) || exit $?
	else
		printf "%8s%s\n" "" "--> Starting $PH_RUNAPP"
		printf "%10s%s\n" "" "OK"
		printf "%2s%s\n" "" "SUCCESS"
		ph_show_menu Main
	fi
fi
exit 0
