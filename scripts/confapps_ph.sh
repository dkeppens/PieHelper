#!/bin/ksh
# Manage installed and supported applications (by Davy Keppens on 03/11/2018)
# Enable/Disable debug by running confpieh_ph.sh -d confapps_ph.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

typeset PH_ACTION=""
typeset PH_LISTMODE=""
typeset PH_APP=""
typeset PH_APP_CMD=""
typeset PH_STATE=""
typeset PH_APP_NEWTTY=""
typeset PH_OLDOPTARG="$OPTARG"
typeset -l PH_APPL=""
typeset -i PH_APP_TTY=0
typeset -i PH_COUNT=0
typeset -i PH_RET_CODE=0
typeset -i PH_OLDOPTIND=$OPTIND
OPTIND=1

while getopts hp:l:a:t: PH_OPTION 2>/dev/null
do
	case $PH_OPTION in p)
                ph_screen_input "$OPTARG" || exit $?
		[[ "$PH_LISTMODE" != @(int|supp|start|run|all|) ]] && (! confapps_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ "$OPTARG" != @(list|tty|int|rem|conf|move|start|state) ]] && (! confapps_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ -n "$PH_ACTION" ]] && (! confapps_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_ACTION="$OPTARG" ;;
			   l)
                ph_screen_input "$OPTARG" || exit $?
		[[ "$OPTARG" != @(int|supp|start|run|all) ]] && (! confapps_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ -n "$PH_LISTMODE" ]] && (! confapps_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_LISTMODE="$OPTARG" ;;
			   a)
                ! ph_screen_input "$OPTARG" && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ -n "$PH_APP" ]] && (! confapps_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_APP="$OPTARG" ;;
			   t)
                ! ph_screen_input "$OPTARG" && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit $?
		[[ -n "$PH_APP_NEWTTY" ]] && (! confapps_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ "$OPTARG" != @(+([[:digit:]])|prompt) ]] && (! confapps_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_APP_NEWTTY="$OPTARG" ;;
			   *)
		>&2 printf "%s\n" "Usage : confapps_ph.sh -h |"
		>&2 printf "%23s%s\n" "" "-p \"list\" -l [\"int\"|\"start\"|\"supp\"|\"run\"|\"all\"] |"
		>&2 printf "%23s%s\n" "" "-p \"tty\" -a [[ttyapp]|\"all\"] |"
		>&2 printf "%23s%s\n" "" "-p \"int\" -a [intapp] |"
		>&2 printf "%23s%s\n" "" "-p \"rem\" -a [remapp] |"
		>&2 printf "%23s%s\n" "" "-p \"conf\" -a [confapp] |"
		>&2 printf "%23s%s\n" "" "-p \"move\" -a [moveapp] '-t [[movetty]|\"prompt\"]' |"
		>&2 printf "%23s%s\n" "" "-p \"start\" -a [[startapp]|\"none\"|\"prompt\"] |"
		>&2 printf "%23s%s\n" "" "-p \"state\""
		>&2 printf "\n"
		>&2 printf "%3s%s\n" "" "Where -h displays this usage"
		>&2 printf "%9s%s\n" "" "-p specifies the action to take"
		>&2 printf "%12s%s\n" "" "\"list\" allows listing the application(s) selected with -l"
		>&2 printf "%15s%s\n" "" "-l \"int\" selects all applications currently integrated with PieHelper"
		>&2 printf "%15s%s\n" "" "-l \"start\" selects the application currently configured to start by default on system boot"
		>&2 printf "%15s%s\n" "" "-l \"supp\" selects all currently supported applications"
		>&2 printf "%18s%s\n" "" "- Applications supported by default are \"Moonlight\",\"X11\",\"Bash\",\"Kodi\",\"Emulationstation\" and \"PieHelper\""
		>&2 printf "%18s%s\n" "" "- Additional out-of-scope applications can be added as supported applications and integrated with PieHelper using confsupp_ph.sh or"
		>&2 printf "%20s%s\n" "" "the PieHelper menu on condition that a package exists for the application in question"
		>&2 printf "%15s%s\n" "" "-l \"run\" selects all applications currently running"
		>&2 printf "%18s%s\n" "" "- The currently allocated TTY will also be displayed for each running application"
		>&2 printf "%15s%s\n" "" "-l \"all\" selects all of the above"
		>&2 printf "%12s%s\n" "" "\"tty\" allows displaying the TTY currently allocated to application [ttyapp]"
		>&2 printf "%15s%s\n" "" "-a allows specifying an application name for [ttyapp]"
		>&2 printf "%18s%s\n" "" "- [ttyapp] must already be known to PieHelper as an integrated application"
		>&2 printf "%18s%s\n" "" "- The keyword \"all\" can be used to display the currently allocated TTY for every integrated application"
		>&2 printf "%12s%s\n" "" "\"int\" allows installing an application [intapp] and integrating it with PieHelper"
		>&2 printf "%15s%s\n" "" "-a allows specifying an application name for [intapp]"
		>&2 printf "%18s%s\n" "" "- [intapp] cannot be \"PieHelper\" (duh)"
		>&2 printf "%18s%s\n" "" "- [intapp] must already be known to PieHelper as a supported application"
		>&2 printf "%18s%s\n" "" "- Moonlight and Emulationstation will attempt a packageless install if the packagename is unset or cannot be found"
		>&2 printf "%18s%s\n" "" "- The appropriate configure function for an application will automatically be run after an application's installation"
		>&2 printf "%12s%s\n" "" "\"rem\" allows removing an application [remapp] from PieHelper and uninstalling it"
		>&2 printf "%15s%s\n" "" "-a allows specifying an application name for [remapp]"
		>&2 printf "%18s%s\n" "" "- [remapp] cannot be \"PieHelper\" which should be removed with confpieh_ph.sh -s"
		>&2 printf "%18s%s\n" "" "- [remapp] must already be known to PieHelper as an integrated application"
		>&2 printf "%18s%s\n" "" "- Moonlight and Emulationstation will attempt a packageless uninstall if the packagename is unset or cannot be found"
		>&2 printf "%12s%s\n" "" "\"conf\" allows configuring an application [confapp]"
		>&2 printf "%15s%s\n" "" "-a allows specifying an application name for [confapp]"
		>&2 printf "%18s%s\n" "" "- [confapp] should already be known to PieHelper as an integrated application"
		>&2 printf "%18s%s\n" "" "- [confapp] cannot be \"PieHelper\" which should be configured with confpieh_ph.sh -c"
		>&2 printf "%18s%s\n" "" "- Applications supported by default that require configuration are \"Moonlight\" and \"Emulationstation\"" 
		>&2 printf "%12s%s\n" "" "\"move\" allows moving an application [moveapp] from it's allocated TTY to TTY [movetty]"
		>&2 printf "%15s%s\n" "" "- Running applications being moved will first be stopped and automatically restarted after the operation completed successfully"
		>&2 printf "%15s%s\n" "" "-a allows specifying an application name for [moveapp]"
		>&2 printf "%18s%s\n" "" "- [moveapp] should already be known to PieHelper as an integrated application and have a TTY allocated"
		>&2 printf "%15s%s\n" "" "-t allows specifying a new number for [movetty]"
		>&2 printf "%18s%s\n" "" "- Specifying a new TTY number is optional"
		>&2 printf "%18s%s\n" "" "  If no new number is specified the first available TTY will be used"
		>&2 printf "%18s%s\n" "" "- The keyword \"prompt\" will make confapps_ph.sh behave interactively when it comes to new TTY number selection"
		>&2 printf "%21s%s\n" "" "- The following info will be prompted for during interactive TTY moves :"
		>&2 printf "%24s%s\n" "" "- TTY number to move [moveapp] to"
		>&2 printf "%27s%s\n" "" "- Entering a new TTY number is optional"
		>&2 printf "%27s%s\n" "" "  If no new TTY number is entered the first available TTY will be used"
		>&2 printf "%12s%s\n" "" "\"start\" allows configuring an application [startapp] to start by default on system boot"
		>&2 printf "%15s%s\n" "" "-a allows specifying an application name for [startapp]"
		>&2 printf "%18s%s\n" "" "- [startapp] should already be known to PieHelper as an integrated application"
		>&2 printf "%18s%s\n" "" "- The keyword \"none\" can be used to remove the current configuration for starting an application by default on system boot"
		>&2 printf "%18s%s\n" "" "- The keyword \"prompt\" will make confapps_ph.sh behave interactively when it comes to startapp selection"
		>&2 printf "%21s%s\n" "" "- The following info will be prompted for during interactive [startapp] selection :"
		>&2 printf "%24s%s\n" "" "- Any integrated application name (required)"
		>&2 printf "%12s%s\n" "" "\"state\" allows discovering supporting applications installed on the system"
		>&2 printf "%20s%s\n" "" "and attempts to integrate them into PieHelper when found"
		>&2 printf "\n"
		OPTARG="$PH_OLDOPTARG"
		OPTIND=$PH_OLDOPTIND
		exit 1 ;;
	esac
done
OPTARG="$PH_OLDOPTARG"
OPTIND=$PH_OLDOPTIND

[[ "$PH_ACTION" == "list" && -n "$PH_APP" ]] && (! confapps_ph.sh -h) && exit 1
[[ "$PH_ACTION" == "list" && -z "$PH_LISTMODE" ]] && (! confapps_ph.sh -h) && exit 1
[[ "$PH_ACTION" != "tty" && "$PH_APP" == "all" ]] && (! confapps_ph.sh -h) && exit 1
[[ "$PH_ACTION" == @(tty|int|rem|conf|move|start) && -z "$PH_APP" ]] && (! confapps_ph.sh -h) && exit 1
if [[ "$PH_ACTION" == "start" && "$PH_APP" != @(none|prompt) ]]
then
	! ph_check_app_name -i -a "$PH_APP" && printf "\n" && exit 1
fi
[[ "$PH_APP" == "PieHelper" && "$PH_ACTION" == "rem" ]] && printf "%s\n" "- Removing $PH_APP" && \
			printf "%2s%s\n\n" "" "FAILED : Invalid argument \"$PH_APP\" -> $PH_APP should be removed with 'confpieh_ph.sh -s'" && \
			exit 1
[[ "$PH_APP" == "PieHelper" && "$PH_ACTION" == "conf" ]] && printf "%s\n" "- Configuring $PH_APP" && \
			printf "%2s%s\n\n" "" "FAILED : Invalid argument \"$PH_APP\" -> $PH_APP should be configured with 'confpieh_ph.sh -c'" && \
			exit 1
[[ "$PH_APP" == "PieHelper" && "$PH_ACTION" == "int" ]] && printf "%s\n" "- Installing $PH_APP" && \
			printf "%2s%s\n\n" "" "FAILED : Invalid argument \"$PH_APP\" -> $PH_APP is already integrated into PieHelper" && \
			exit 1
case $PH_ACTION in list)
	case $PH_LISTMODE in int)
		printf "%s\n" "- Listing applications currently integrated with PieHelper"
		nawk '{ printf "%8s%s\n", "", $1 }' $PH_CONF_DIR/installed_apps
		printf "%2s%s\n\n" "" "SUCCESS" ;;
			     supp)
		printf "%s\n" "- Listing currently supported applications"
		nawk '{ printf "%8s%s\n", "", $1 }' $PH_CONF_DIR/supported_apps
		printf "%2s%s\n\n" "" "SUCCESS" ;;
			    start)
		printf "%s\n" "- Listing application currently configured to start by default on system boot"
		printf "%8s%s\n" "" "$PH_PIEH_STARTAPP"
		printf "%2s%s\n\n" "" "SUCCESS" ;;
			      run)
		printf "%s\n" "- Listing applications currently running"
		for PH_APP in `nawk 'BEGIN { ORS = " " } { print $1 }' $PH_CONF_DIR/installed_apps`
		do
			PH_APP_TTY=`ph_get_tty_for_app $PH_APP`
			if [[ $? -eq 1 && $PH_APP_TTY -ne 0 ]]
			then
				if [[ "$PH_APP" == "Bash" ]]
				then
					PH_APP_CMD="bash"
				else
					PH_APP_CMD=`nawk -v app=^"$PH_APP"$ 'BEGIN { ORS=" " } $1 ~ app { for (i=2;i<=NF;i++) { if (i==NF) { ORS="" ; print $i } else { print $i }}}' $PH_CONF_DIR/supported_apps`
					PH_APP_CMD=`sed "s/PH_TTY/$PH_APP_TTY/" <<<$PH_APP_CMD`
				fi
				if pgrep -t tty$PH_APP_TTY -f "$PH_APP_CMD" >/dev/null
				then
					printf "%8s%s\n" "" "$PH_APP (TTY$PH_APP_TTY)"
					((PH_COUNT++))
				else
					if (([[ "$PH_APP" == "PieHelper" ]]) && (pgrep -f 'startpieh.sh -p' >/dev/null))
					then
						printf "%8s%s\n" "" "$PH_APP (Running on a pseudo-terminal)"
						((PH_COUNT++))
					fi
				fi
			fi
		done
		[[ $PH_COUNT -eq 0 ]] && printf "%8s%s\n" "" "\"none\""
		PH_COUNT=0
		printf "%2s%s\n\n" "" "SUCCESS" ;;
		              all)
		confapps_ph.sh -p list -l int
		confapps_ph.sh -p list -l supp
		confapps_ph.sh -p list -l run
		confapps_ph.sh -p list -l start ;;
	esac
	exit 0 ;;
		   int)
	! ph_check_app_name -s -a "$PH_APP" && printf "\n" && exit 1
	ph_install_app "$PH_APP"
	exit $? ;;
		    tty)
	if [[ "$PH_APP" != "all" ]]
	then
		! ph_check_app_name -i -a "$PH_APP" && printf "\n" && exit 1
		printf "%s\n" "- Displaying TTY currently allocated to $PH_APP"
		PH_APP_TTY=`nawk -v app=^"$PH_APP"$ '$1 ~ app { if ($4!~/^-$/) { print $4 } else { print 0 }}' $PH_CONF_DIR/installed_apps`
		if [[ $PH_APP_TTY -ne 0 ]]
		then
			printf "%2s%s\n" "" "\"$PH_APP_TTY\""
		else
			printf "%2s%s\n" "" "\"none\""
		fi
		printf "%2s%s\n\n" "" "SUCCESS"
	else
		for PH_APP in `nawk 'BEGIN { ORS = " " } { print $1 }' $PH_CONF_DIR/installed_apps`
		do
			confapps_ph.sh -p tty -a "$PH_APP"
		done
	fi
	exit 0 ;;
		    rem)
	! ph_check_app_name -i -a "$PH_APP" && printf "\n" && exit 1
	ph_remove_app "$PH_APP"
	exit $? ;;
	      	   conf)
	! ph_check_app_name -i -a "$PH_APP" && printf "\n" && exit 1
	PH_APPL=`echo $PH_APP | cut -c1-4`
	eval ph_configure_$PH_APPL
	exit $? ;;
		   move)
	! ph_check_app_name -i -a "$PH_APP" && printf "\n" && exit 1
	PH_APP_TTY=`ph_get_tty_for_app $PH_APP`
	if [[ $? -eq 0 || $PH_APP_TTY -eq 0 ]]
	then
		printf "%s\n" "- Executing TTY move for $PH_APP"
		printf "%2s%s\n\n" "" "FAILED : No TTY currently allocated to $PH_APP"
		exit 1
	fi
	PH_APP_CMD=`nawk -v app=^"$PH_APP"$ 'BEGIN { ORS=" " } $1 ~ app { for (i=2;i<=NF;i++) { if (i==NF) { ORS="" ; print $i } else { print $i }}}' $PH_CONF_DIR/supported_apps`
	PH_APP_CMD=`sed "s/PH_TTY/$PH_APP_TTY/" <<<$PH_APP_CMD`
	pgrep -t tty$PH_APP_TTY -f "$PH_APP_CMD" >/dev/null && PH_STATE="running"
	PH_APPL=`echo $PH_APP | cut -c1-4`
	if [[ -n "$PH_STATE" ]]
	then
		$PH_SCRIPTS_DIR/stop"$PH_APPL".sh || exit $?
	fi
	printf "%s\n" "- Executing TTY move for $PH_APP"
	case $PH_APP_NEWTTY in +([[:digit:]]))
		if [[ $PH_APP_NEWTTY -le 1 || $PH_APP_NEWTTY -gt $PH_PIEH_MAX_TTYS || `cut -f4 $PH_CONF_DIR/installed_apps | grep ^$PH_APP_NEWTTY$` ]]
		then
			printf "%2s%s\n\n" "" "FAILED : Invalid or allocated TTY given"
			exit 1
		fi ;;
			               prompt)
		PH_APP_NEWTTY="0"
		while [[ ($PH_APP_NEWTTY -le 1 || $PH_APP_NEWTTY -gt $PH_PIEH_MAX_TTYS || `cut -f4 $PH_CONF_DIR/installed_apps | grep ^$PH_APP_NEWTTY$`) ]]
		do
			[[ $PH_COUNT -gt 0 ]] && printf "\n%10s%s\n\n" "" "ERROR : Invalid or allocated TTY given"
			printf "%8s%s" "" "--> Please enter a new TTY for $PH_APP (Press Enter for the default of the first available TTY): "
			read PH_APP_NEWTTY 2>/dev/null
			ph_screen_input $PH_APP_NEWTTY || exit $?
			[[ "$PH_APP_NEWTTY" == "" ]] && break
			[[ "$PH_APP_NEWTTY" != +([[:digit:]]) ]] && PH_APP_NEWTTY="0"
			((PH_COUNT++))
		done
		printf "%10s%s\n" "" "OK" ;;
			       		    *)
                PH_APP_NEWTTY=`ph_get_tty_for_app none`
                printf "%8s%s\n" "" "--> Attempting to determine TTY for $PH_APP"
                if [[ $? -eq 1 && $PH_APP_NEWTTY -eq 0 ]]
                then
                        printf "%10s%s\n" "" "ERROR : All TTY's already allocated"
                        printf "%2s%s\n\n" "" "FAILED"
			exit 1
		else
                        printf "%10s%s\n" "" "OK"
		fi ;;
	esac
	if [[ "$PH_APP_NEWTTY" == "" ]]
	then
		PH_APP_NEWTTY=`ph_get_tty_for_app none`
                printf "%8s%s\n" "" "--> Attempting to determine TTY for $PH_APP"
                if [[ $? -eq 1 && $PH_APP_NEWTTY -eq 0 ]]
                then
                        printf "%10s%s\n" "" "ERROR : All TTY's already allocated"
                        printf "%2s%s\n\n" "" "FAILED"
			exit 1
		else
                        printf "%10s%s\n" "" "OK"
		fi
	fi
	ph_change_app_tty $PH_APP_NEWTTY "$PH_APP"
	[[ $? -eq 1 ]] && printf "\n" && exit 1
	if [[ -n "$PH_STATE" ]]
	then
		$PH_SCRIPTS_DIR/start"$PH_APPL".sh
		PH_RET_CODE=$?
	fi
	printf "\n"
	exit $PH_RET_CODE ;;
		  start)
	if [[ "$PH_APP" == "prompt" ]]
	then
		ph_set_app_for_start
		PH_RET_CODE=$?
	else
		ph_set_app_for_start "$PH_APP"
		PH_RET_CODE=$?
	fi
	printf "\n"
	exit $PH_RET_CODE ;;
		  state)
	ph_generate_installed_apps
	PH_RET_CODE=$?
	printf "\n"
	exit $PH_RET_CODE ;;
esac
confapps_ph.sh -h || exit $?
