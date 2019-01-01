#!/bin/ksh
# Manage application options and controller settings (by Davy Keppens on 06/11/2018)
# Enable/Disable debug by running confpieh_ph.sh -d confopts_ph.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

typeset PH_ACTION=""
typeset PH_OPT_TYPE="read-write"
typeset PH_I_ACTION=""
typeset PH_APP=""
typeset PH_VALUE=""
typeset PH_OPT=""
typeset PH_i=""
typeset PH_OPTION=""
typeset PH_RESOLVE=""
typeset PH_RESULT="SUCCESS"
typeset PH_TYPE=""
typeset PH_USE_WORD=""
typeset PH_OLDOPTARG="$OPTARG"
typeset -i PH_ANSWER=0
typeset -i PH_COUNT=0
typeset -i PH_COUNT2=0
typeset -i PH_RET_CODE=0
typeset -i PH_OLDOPTIND=$OPTIND
set -A OPTAR
set -A VALAR
OPTIND=1

while getopts a:o:p:hgsdrmn PH_OPTION 2>/dev/null
do
	case $PH_OPTION in a)
		ph_screen_input "$OPTARG" || exit $?
		[[ -n "$PH_APP" ]] && (! confopts_ph.sh -h) && exit 1
		PH_APP="$OPTARG"
		[[ "$PH_APP" == "Ctrls" ]] && PH_USE_WORD="setting" || PH_USE_WORD="option" ;;
			   p)
		ph_screen_input "$OPTARG" || exit $?
		[[ "$OPTARG" != @(set|get|help|prompt|list) ]] && (! confopts_ph.sh -h) && exit 1
		[[ -n "$PH_ACTION" ]] && (! confopts_ph.sh -h) && exit 1
		[[ -n "$PH_I_ACTION" && "$OPTARG" != "prompt" ]] && (! confopts_ph.sh -h) && exit 1
		PH_ACTION="$OPTARG" ;;
			   o)
		[[ -n "$PH_I_ACTION" ]] && (! confopts_ph.sh -h) && exit 1
		[[ -z "${OPTARG%%=*}" ]] && (! confopts_ph.sh -h) && exit 1
		if [[ "${OPTARG%%=*}" == "all" && $PH_ACTION == "set" ]]
		then
			printf "%s\n" "- Changing value for option ${OPTARG%%=*}"
			printf "%2s%s\n" "" "FAILED : Unknown option"
			exit 1	
		fi
		if [[ -n "$PH_OPT" ]]
		then
			PH_OPT="$PH_OPT"':'"${OPTARG%%=*}"
			PH_VALUE="$PH_VALUE"':'"${OPTARG##*=}"
		else
			PH_OPT="${OPTARG%%=*}"
			PH_VALUE="${OPTARG##*=}"
		fi ;;
                          g)
                [[ "$PH_ACTION" != @(prompt|) ]] && (! confopts_ph.sh -h) && exit 1
		[[ -n "$PH_I_ACTION" ]] && (! confopts_ph.sh -h) && exit 1
                PH_I_ACTION="get" ;;
                          s)
                [[ "$PH_ACTION" != @(prompt|) ]] && (! confopts_ph.sh -h) && exit 1
		[[ -n "$PH_I_ACTION" ]] && (! confopts_ph.sh -h) && exit 1
                PH_I_ACTION="set" ;;
                          d)
                [[ "$PH_ACTION" != @(prompt|) ]] && (! confopts_ph.sh -h) && exit 1
		[[ -n "$PH_I_ACTION" ]] && (! confopts_ph.sh -h) && exit 1
                PH_I_ACTION="help" ;;
                          r)
                [[ "$PH_ACTION" != @(get|prompt|set|) ]] && (! confopts_ph.sh -h) && exit 1
		[[ -n "$PH_RESOLVE" ]] && (! confopts_ph.sh -h) && exit 1
                PH_RESOLVE="yes" ;;
			  m)
		[[ "$PH_ACTION" != @(set|prompt|) ]] && (! confopts_ph.sh -h) && exit 1
		[[ "$PH_I_ACTION" != @(set|) ]] && (! confopts_ph.sh -h) && exit 1
		[[ -n "$PH_TYPE" ]] && (! confopts_ph.sh -h) && exit 1
                PH_TYPE="r" ;;
			  n)
		[[ "$PH_ACTION" != @(set|prompt|) ]] && (! confopts_ph.sh -h) && exit 1
		[[ "$PH_I_ACTION" != @(set|) ]] && (! confopts_ph.sh -h) && exit 1
		[[ -n "$PH_TYPE" ]] && (! confopts_ph.sh -h) && exit 1
                PH_TYPE="o" ;;
			   *)
		>&2 printf "%s\n" "Usage : confopts_ph.sh -h |"
		>&2 printf "%23s%s\n" "" "-p \"get\" -a [[getapp]|\"Ctrls\"] -o [[getopt]|\"all\"] '-r' |"
		>&2 printf "%23s%s\n" "" "-p \"list\" -a [[listapp]|\"Ctrls\"] |"
		>&2 printf "%23s%s\n" "" "-p \"help\" -a [[helpapp]|\"Ctrls\"] -o [[helpopt]|\"all\"] |"
		>&2 printf "%23s%s\n" "" "-p \"set\" -a [[setapp]|\"Ctrls\"] -o [setopt]='[value]' -o [setopt]='[value]' -o ... '[-m|-n]' |"
		>&2 printf "%23s%s\n" "" "-p \"prompt\" -a [[promptapp]|\"Ctrls\"] '-r' [-g|-s '[-m|-n]'|-d]"
		>&2 printf "\n"
		>&2 printf "%3s%s\n" "" "Where -h displays this usage"
		>&2 printf "%9s%s\n" "" "-p specifies the action to take"
		>&2 printf "%12s%s\n" "" "\"get\" allows displaying the value of the option(s) [getopt] of an application [getapp] or the controller settings"
		>&2 printf "%15s%s\n" "" "- Variables in option values will automatically be expanded when displaying"
		>&2 printf "%15s%s\n" "" "-a allows specifying an application name for [getapp]"
		>&2 printf "%15s%s\n" "" "-o allows specifying an optionname for [getopt]"
		>&2 printf "%18s%s\n" "" "- The keyword \"all\" can be used to request displaying the value of all options of [getapp]"
		>&2 printf "%15s%s\n" "" "-r allows requesting expansion of all variables present in the value for option [getopt]"
		>&2 printf "%18s%s\n" "" "- Specifying -r is optional"
		>&2 printf "%18s%s\n" "" "- Variables are not expanded by default"
		>&2 printf "%12s%s\n" "" "\"list\" allows listing all existing options of application [listapp] or all existing controller settings"
		>&2 printf "%12s%s\n" "" "\"help\" allows displaying information about the option(s) [helpopt] of an application [helpapp] or the controller settings"
		>&2 printf "%15s%s\n" "" "-a allows specifying an application name for [helpapp]"
		>&2 printf "%18s%s\n" "" "- The keyword \"Ctrls\" can be used to operate on the controller settings instead"
		>&2 printf "%15s%s\n" "" "-o allows specifying an optionname for [helpopt]"
		>&2 printf "%18s%s\n" "" "- The keyword \"all\" can be used to request displaying information about all options of [helpapp]"
		>&2 printf "%12s%s\n" "" "\"set\" allows changing the value of an option [setopt] of an application [setapp] or a read-write controller setting to [value]"
		>&2 printf "%15s%s\n" "" "- The value of a read-only option cannot be changed"
		>&2 printf "%15s%s\n" "" "-a allows specifying an application name for [setapp]"
		>&2 printf "%15s%s\n" "" "-o allows specifying an optionname for [setopt] and it's new value"
		>&2 printf "%18s%s\n" "" "- Multiple instances of -o are allowed"
		>&2 printf "%18s%s\n" "" "- Surround [value] with single quotes whenever possible in the form option='[value]'"
		>&2 printf "%18s%s\n" "" "- Composite strings (containing spaces) in [value] should be surrounded with double quotes"
		>&2 printf "%18s%s\n" "" "- Any controller device id references in [value] should have the numeric id replaced by the string 'PH_CTRL#' where '#' is '1' for controller 1, '2' for controller 2, etc"
		>&2 printf "%18s%s\n" "" "- Changes to an option that sets the controller amount for an application will automatically be reflected to"
		>&2 printf "%18s%s\n" "" "  the application's command line options if event-based input devices are present as command-line parameters, and vice versa"
		>&2 printf "%15s%s\n" "" "-m allows marking the operation as mandatory"
		>&2 printf "%18s%s\n" "" "- Mandatory operations will return an error when they fail"
		>&2 printf "%18s%s\n" "" "- Specifying -m is optional"
		>&2 printf "%18s%s\n" "" "- Operations are by default marked as mandatory"
		>&2 printf "%15s%s\n" "" "-n allows marking the operation as non-mandatory"
		>&2 printf "%18s%s\n" "" "- Specifying -n is optional"
		>&2 printf "%18s%s\n" "" "- Non-mandatory operations will return a warning when they fail"
		>&2 printf "%12s%s\n" "" "\"prompt\" makes confopts_ph.sh behave interactively when it comes to passing an optionname when acting on application [promptapp] or the controller settings"
		>&2 printf "%15s%s\n" "" "-a allows specifying an application name for [promptapp]"
		>&2 printf "%15s%s\n" "" "-g specifies a get action in interactive mode"
		>&2 printf "%15s%s\n" "" "-s specifies a set action in interactive mode"
		>&2 printf "%18s%s\n" "" "- Set actions will fail on read-only options"
		>&2 printf "%18s%s\n" "" "- No quotes are required for [value] in interactive mode"
		>&2 printf "%18s%s\n" "" "- Composite strings (containing spaces) in [value] should still be surrounded with double quotes"
		>&2 printf "%18s%s\n" "" "-m allows marking the operation as mandatory"
		>&2 printf "%21s%s\n" "" "- Mandatory operations will return an error when they fail"
		>&2 printf "%21s%s\n" "" "- Specifying -m is optional"
		>&2 printf "%21s%s\n" "" "- Operations are by default marked as mandatory"
		>&2 printf "%18s%s\n" "" "-n allows marking the operation as non-mandatory"
		>&2 printf "%21s%s\n" "" "- Non-mandatory operations will return a warning when they fail"
		>&2 printf "%21s%s\n" "" "- Specifying -n is optional"
		>&2 printf "%15s%s\n" "" "-d specifies a display help action in interactive mode"
		>&2 printf "%15s%s\n" "" "-r allows requesting expansion of all variables present in all option values displayed"
		>&2 printf "%18s%s\n" "" "- Specifying -r is optional"
		>&2 printf "%18s%s\n" "" "- Variables are not expanded by default"
		>&2 printf "\n"
		OPTARG="$PH_OLDOPTARG"
		OPTIND=$PH_OLDOPTIND
		exit 1 ;;
	esac
done
OPTARG="$PH_OLDOPTARG"
OPTIND=$PH_OLDOPTIND

[[ -n "$PH_RESOLVE" && "$PH_ACTION" != @(get|prompt) ]] && (! confopts_ph.sh -h) && exit 1
[[ -z "$PH_RESOLVE" ]] && PH_RESOLVE="no"
(([[ -z "$PH_TYPE" ]]) && ([[ "$PH_ACTION" == "set" || "$PH_I_ACTION" == "set" ]])) && PH_TYPE="r"
(([[ -n "$PH_TYPE" ]]) && ([[ "$PH_ACTION" == @(help|get|list) || "$PH_I_ACTION" == @(get|help) ]])) && (! confopts_ph.sh -h) && exit 1
(([[ -z "$PH_ACTION" || -z "$PH_APP" ]]) || ([[ "$PH_ACTION" != @(prompt|list) && -z "$PH_OPT" ]])) && (! confopts_ph.sh -h) && exit 1
[[ -n "$PH_OPT" && "$PH_ACTION" == @(prompt|list) ]] && (! confopts_ph.sh -h) && exit 1
[[ "$PH_ACTION" == "prompt" && -z "$PH_I_ACTION" ]] && (! confopts_ph.sh -h) && exit 1
if [[ `$PH_SUDO cat /proc/$PPID/comm` != "confopts_ph.sh" ]]
then
	if [[ "$PH_APP" != "Ctrls" ]]
	then
		ph_check_app_name -s -a "$PH_APP" || exit $?
	fi
fi
if [[ "$PH_ACTION" == @(set|get|help) ]]
then
	OPTAR+=(`echo -n $PH_OPT | sed 's/:/ /g'`)
	for PH_COUNT in {1..`echo $PH_VALUE | nawk -F':' '{ next } END { print NF }'`}
	do
		VALAR+=("`echo $PH_VALUE | cut -d':' -f$PH_COUNT`")
	done
	for PH_COUNT in {0..`echo $((${#OPTAR[@]}-1))`}
	do
		[[ "${OPTAR[$PH_COUNT]}" == "PH_PIEH_DEBUG" ]] && (printf "%s\n" "- Changing value for $PH_USE_WORD ${OPTAR[$PH_COUNT]}" ; \
				printf "%2s%s\n" "" "FAILED : Module debug should be handled by confpieh_ph.sh" ; return 0) && exit 1 
		[[ "${OPTAR[$PH_COUNT]}" == "PH_PIEH_STARTAPP" ]] && (printf "%s\n" "- Changing value for $PH_USE_WORD ${OPTAR[$PH_COUNT]}" ; \
				printf "%2s%s\n" "" "FAILED : The application to start by default on system boot should be handled by confapps_ph.sh -p start" ; return 0) && exit 1 
		while ((! grep ^"${OPTAR[$PH_COUNT]}=" $PH_CONF_DIR/$PH_APP.conf >/dev/null 2>&1) && ([[ "${OPTAR[$PH_COUNT]}" != "all" && "$PH_ACTION" != @(prompt|list) ]]))
		do
			for PH_i in `nawk 'BEGIN { ORS = " " } $0 ~ / typeset / { for (i=1;i<=NF;i++) { if ($i~/^PH_/) { print $i }}}' $PH_CONF_DIR/$PH_APP.conf`
			do
				PH_i="${PH_i%%=*}"
				[[ "$PH_i" == "${OPTAR[$PH_COUNT]}" ]] && PH_OPT_TYPE="read-only" && break 2
			done
			case $PH_ACTION in get)
				printf "%s\n" "- Displaying value for $PH_USE_WORD ${OPTAR[$PH_COUNT]}" ;;
					   set)
				printf "%s\n" "- Changing value for $PH_USE_WORD ${OPTAR[$PH_COUNT]}" ;;
					  help)
				printf "%s\n" "- Displaying help for $PH_USE_WORD ${OPTAR[$PH_COUNT]}" ;;
			esac
			printf "%2s%s\n" "" "FAILED : Unknown $PH_USE_WORD"
			exit 1
		done
	done
fi
PH_COUNT=0
case $PH_ACTION in get)
		if [[ "$PH_OPT" == "all" ]]
		then
			for PH_OPT in `grep ^"PH_" $PH_CONF_DIR/$PH_APP.conf | cut -d'=' -f1 | paste -d" " -s`
			do
				[[ "$PH_RESOLVE" == "yes" ]] && confopts_ph.sh -p get -a "$PH_APP" -o "$PH_OPT" -r || \
					confopts_ph.sh -p get -a "$PH_APP" -o "$PH_OPT"
			done
			for PH_OPT in `nawk 'BEGIN { ORS = " " } $0 ~ / typeset / { for (i=1;i<=NF;i++) { if ($i~/^PH_/) { print $i }}}' $PH_CONF_DIR/$PH_APP.conf`
			do
				[[ "$PH_RESOLVE" == "yes" ]] && confopts_ph.sh -p get -a "$PH_APP" -o "$PH_OPT" -r || \
					confopts_ph.sh -p get -a "$PH_APP" -o "$PH_OPT"
			done
		else
			printf "%s\n" "- Displaying value for $PH_OPT_TYPE $PH_USE_WORD $PH_OPT"
			typeset -n PH_OPTVAL="$PH_OPT"
			if [[ "$PH_RESOLVE" == "yes" ]]
			then
				printf "%2s%s\n" "" "'$(echo $PH_OPTVAL | sed 's/"/\\\"/g' | eval echo `cat`)'"
			else
				printf "%2s%s\n" "" "'$PH_OPTVAL'"
			fi
			printf "%2s%s\n" "" "$PH_RESULT"
			unset -n PH_OPTVAL
		fi
		unset OPTAR VALAR
		exit 0 ;;
		  list)
		printf "%s%s\n" "- Listing all available read-only $PH_USE_WORD" "s for $PH_APP"
		if [[ -z `nawk 'BEGIN { ORS = " " } $0 ~ / typeset / { for (i=1;i<=NF;i++) { if ($i~/^PH_/) { print $i }}}' $PH_CONF_DIR/$PH_APP.conf` ]]
		then
			printf "%8s%s\n" "" "\"none\"" 
		else
			for PH_OPT in `nawk 'BEGIN { ORS = " " } $0 ~ / typeset / { for (i=1;i<=NF;i++) { if ($i~/^PH_/) { print $i }}}' $PH_CONF_DIR/$PH_APP.conf`
			do
				printf "%8s%s\n" "" "${PH_OPT%%=*}"
			done
		fi
		printf "%2s%s\n" "" "$PH_RESULT"
		printf "%s%s\n" "- Listing all available read-write $PH_USE_WORD" "s for $PH_APP"
		for PH_OPT in `nawk -F'=' '$1 ~ /^PH_/ { print $1 ; next } { next }' $PH_CONF_DIR/$PH_APP.conf | paste -d" " -s`
		do
			printf "%8s%s\n" "" "$PH_OPT"
		done
		printf "%2s%s\n" "" "$PH_RESULT"
		unset OPTAR VALAR
		exit 0 ;;
		  help)
		if [[ "$PH_OPT" == "all" ]]
		then
			for PH_OPT in `grep ^"PH_" $PH_CONF_DIR/$PH_APP.conf | cut -d'=' -f1 | paste -d" " -s`
			do
				confopts_ph.sh -p help -a "$PH_APP" -o "$PH_OPT"
			done
			for PH_OPT in `nawk 'BEGIN { ORS = " " } $0 ~ / typeset / { for (i=1;i<=NF;i++) { if ($i~/^PH_/) { print $i }}}' $PH_CONF_DIR/$PH_APP.conf`
			do
				confopts_ph.sh -p help -a "$PH_APP" -o "$PH_OPT"
			done
		else
			printf "%s\n" "- Displaying help for $PH_OPT_TYPE $PH_USE_WORD $PH_OPT"
			printf "%2s%s\n" "" "$PH_RESULT"
			printf "\n"
			ph_print_bannerline
			printf "\n"
			if [[ "$PH_OPT_TYPE" == "read-write" ]]
			then
				nawk -F'#' -v opt=^"$PH_OPT=" '$1 ~ opt { print $2 ; getline ; while ($1!~/^PH_/ && $0!~/^$/) { print $2 ; getline } ; exit }' $PH_CONF_DIR/$PH_APP.conf 
			else
				nawk -F'#' -v opt=" typeset .* $PH_OPT=" '$1 ~ opt { print $2 ; getline ; while ($1!~/^PH_|^\[\[/ && $0!~/^$/) { print $2 ; getline } ; exit }' $PH_CONF_DIR/$PH_APP.conf
			fi
			printf "\n"
			ph_print_bannerline
			printf "\n"
		fi
		unset OPTAR VALAR
		exit 0 ;;
		   set)
		printf "%s%s%s\n" "- Changing value for $PH_USE_WORD" "s" " $(for PH_COUNT in {0..`echo $((${#OPTAR[@]}-1))`};do;echo -n "${OPTAR[$PH_COUNT]} ";done)"
		for PH_COUNT in {0..`echo $((${#OPTAR[@]}-1))`}
		do
			[[ "${OPTAR[$PH_COUNT]}" == "PH_PIEH_DEBUG" ]] && printf "%2s%s\n" "" "FAILED : Module debug should be handled by confpieh_ph.sh" && exit 1 
			[[ "${OPTAR[$PH_COUNT]}" == "PH_PIEH_STARTAPP" ]] && printf "%2s%s\n" "" "FAILED : The application to start by default on system boot should be handled by confapps_ph.sh -p start" && exit 1 
		done
		eval ph_set_option "$PH_APP" `echo -n "$(for PH_COUNT in {0..\`echo -n $((${#OPTAR[@]}-1))\`};do;eval echo -en -$PH_TYPE ${OPTAR[$PH_COUNT]}='\"\\${VALAR[$PH_COUNT]}\"'\" \";done)"`
		PH_RET_CODE=$?
		if [[ $PH_RET_CODE -ne 0 ]]
		then
			[[ $PH_RET_CODE -eq ${#OPTAR[@]} ]] && PH_RESULT="FAILED" || PH_RESULT="PARTIALLY FAILED"
		fi
		printf "%2s%s\n" "" "$PH_RESULT"
		unset OPTAR VALAR
		exit $PH_RET_CODE ;;
		  prompt)
		printf "%s\n" "- Using interactive mode"
		case $PH_I_ACTION in get)
			printf "%8s%s\n\n" "" "--> Which $PH_USE_WORD do you want to view the value of ?"
                	while [[ $PH_ANSWER -eq 0 || $PH_ANSWER -gt $((PH_COUNT)) ]]
                	do
				[[ $PH_COUNT -gt 0 ]] && printf "\n%10s%s\n\n" "" "ERROR : Invalid response"
				PH_COUNT=1
				for PH_i in `grep ^"PH_" $PH_CONF_DIR/$PH_APP.conf | nawk -F'=' '{ print $1 }'`
				do
					printf "%8s%s%s%s\n" "" "$((PH_COUNT))" ". " "$PH_i"
					((PH_COUNT++))
				done
				PH_COUNT2=$PH_COUNT
				for PH_i in `nawk 'BEGIN { ORS = " " } $0 ~ / typeset / { for (i=1;i<=NF;i++) { if ($i~/^PH_/) { print $i }}}' $PH_CONF_DIR/$PH_APP.conf`
				do
					printf "%8s%s%s%s\n" "" "$((PH_COUNT))" ". " "${PH_i%%=*}"
					((PH_COUNT++))
				done
				printf "%8s%s%s%s\n" "" "$((PH_COUNT))" ". " "All"
				printf "\n%8s%s" "" "Your choice ? "
				read PH_ANSWER 2>/dev/null
			done
			printf "%10s%s\n" "" "OK"
			printf "%2s%s\n" "" "SUCCESS"
			if [[ $PH_ANSWER -eq $((PH_COUNT)) ]]
			then
				PH_OPT="all"
			else
				if [[ $PH_ANSWER -le $((PH_COUNT2-1)) ]]
				then
					PH_OPT=`grep ^"PH_" $PH_CONF_DIR/$PH_APP.conf | nawk -F'=' -v choice=$PH_ANSWER 'NR == choice { print $1 }'`
				else
					PH_OPT=$(grep ' typeset ' $PH_CONF_DIR/$PH_APP.conf | \
						nawk -v choice=$((PH_ANSWER-$((PH_COUNT2-1)))) 'NR == choice { for (i=1;i<=NF;i++) { if ($i~/^PH_/) { print $i }}}')
				fi

			fi
			[[ "$PH_RESOLVE" == "yes" ]] && confopts_ph.sh -p get -a "$PH_APP" -o "${PH_OPT%%=*}" -r || \
					confopts_ph.sh -p get -a "$PH_APP" -o "${PH_OPT%%=*}"
			unset OPTAR VALAR
			exit 0 ;;
				     set)
			printf "%8s%s\n\n" "" "--> Which $PH_USE_WORD do you want to change the value of ?"
                	while [[ $PH_ANSWER -eq 0 || $PH_ANSWER -gt $PH_COUNT ]]
                	do
				[[ $PH_COUNT -gt 0 ]] && printf "\n%10s%s\n\n" "" "ERROR : Invalid response"
				if [[ "$PH_RESOLVE" == "yes" ]]
				then
					PH_COUNT=0
					for PH_i in `nawk -F'=' '$1 ~ /^PH_/ && $1 !~ /^PH_PIEH_DEBUG=/ && $1 !~ /^PH_PIEH_STARTAPP=/ { print $1 }' $PH_CONF_DIR/$PH_APP.conf`
					do
						typeset -n PH_OPTVAL="$PH_i"
						PH_OPTVAL=`echo $PH_OPTVAL | sed 's/"/\\\"/g'`
						printf "%8s%s%s%s%s%s\n" "" "$((PH_COUNT+1))" ". " "$PH_i" "=" "'`eval echo $PH_OPTVAL`'"
						PH_OPTVAL=`echo $PH_OPTVAL | sed 's/\\\"/"/g'`
						((PH_COUNT++))
						unset -n PH_OPTVAL
					done
				else
					nawk -F'\t' 'BEGIN { count = 1 } $1 ~ /^PH_/ && $1 !~ /^PH_PIEH_DEBUG=/ && $1 !~ /^PH_PIEH_STARTAPP=/ { printf "%8s%s%s\n", "", count ". ", $1 ; count++ ; next }' \
												$PH_CONF_DIR/$PH_APP.conf
					PH_COUNT=`nawk -F'\t' 'BEGIN { count = 0 } $1 ~ /^PH_/ && $1 !~ /^PH_PIEH_DEBUG=/ && $1 !~ /^PH_PIEH_STARTAPP=/ { count++ } END { print count }' $PH_CONF_DIR/$PH_APP.conf`
				fi
				printf "\n%8s%s" "" "Your choice ? "
				read PH_ANSWER 2>/dev/null
			done
			printf "%10s%s\n" "" "OK"
			PH_OPT=`grep ^"PH_" $PH_CONF_DIR/$PH_APP.conf | egrep -v ^"PH_PIEH_DEBUG=|PH_PIEH_STARTAPP=" | nawk -F"=" -v choice=$PH_ANSWER 'NR==choice { print $1 }'`
			printf "%8s%s" "" "--> Please enter the new value for read-write $PH_USE_WORD $PH_OPT : "
			read PH_VALUE 2>/dev/null
			printf "%10s%s\n" "" "OK"
			printf "%2s%s\n" "" "SUCCESS"
			[[ "$PH_TYPE" == "o" ]] && PH_TYPE="n" || PH_TYPE="m"
			confopts_ph.sh -p set -a "$PH_APP" -"$PH_TYPE" -o "$PH_OPT"="$PH_VALUE"
			unset OPTAR VALAR
			exit $? ;;
				    help)
			printf "%8s%s\n\n" "" "--> Which $PH_USE_WORD do you want to display help for ?"
                	while [[ $PH_ANSWER -eq 0 || $PH_ANSWER -gt $PH_COUNT ]]
                	do
				[[ $PH_COUNT -gt 0 ]] && printf "\n%10s%s\n\n" "" "ERROR : Invalid response"
				PH_COUNT=1
				PH_COUNT2=$PH_COUNT
				if [[ "$PH_RESOLVE" == "yes" ]]
				then
					for PH_i in `nawk -F'=' '$1 ~ /^PH_/ && $1 !~ /^PH_PIEH_DEBUG=/ && $1 !~ /^PH_PIEH_STARTAPP=/ { print $1 }' $PH_CONF_DIR/$PH_APP.conf`
					do
						typeset -n PH_OPTVAL="$PH_i"
						PH_OPTVAL=`echo $PH_OPTVAL | sed 's/"/\\\"/g'`
						printf "%8s%s%s%s%s%s\n" "" "$((PH_COUNT))" ". " "$PH_i" "=" "'`eval echo $PH_OPTVAL`'"
						PH_OPTVAL=`echo $PH_OPTVAL | sed 's/\\\"/"/g'`
						((PH_COUNT++))
						unset -n PH_OPTVAL
					done
					((PH_COUNT--))
					PH_COUNT2=$PH_COUNT
					for PH_i in `nawk 'BEGIN { ORS = " " } $0 ~ / typeset / { for (i=1;i<=NF;i++) { if ($i~/^PH_/) { print $i }}}' $PH_CONF_DIR/$PH_APP.conf`
					do
						typeset -n PH_OPTVAL="${PH_i%%=*}"
						printf "%8s%s%s%s%s%s\n" "" "$((PH_COUNT+1))" ". " "${PH_i%%=*}" "=" "'$(echo $PH_OPTVAL | sed 's/"/\\\"/g' | eval echo `cat`)'" 
						((PH_COUNT++))
						unset -n PH_OPTVAL
					done
				else
					nawk -F'\t' 'BEGIN { count = 1 } $1 ~ /^PH_/ && $1 !~ /^PH_PIEH_DEBUG=/ && $1 !~ /^PH_PIEH_STARTAPP=/ { printf "%8s%s%s\n", "", count ". ", $1 ; count++ ; next } \
														{ next }' $PH_CONF_DIR/$PH_APP.conf
					PH_COUNT=`nawk -F'\t' 'BEGIN { count = 0 } $1 ~ /^PH_/ && $1 !~ /^PH_PIEH_DEBUG=/ && $1 !~ /^PH_PIEH_STARTAPP=/ { count++ } END { print count }' $PH_CONF_DIR/$PH_APP.conf`
					PH_COUNT2=$PH_COUNT
					nawk -v count=$((PH_COUNT+1)) '$0 ~ / typeset / { for (i=1;i<=NF;i++) { if ($i~/^PH_/) { printf "%8s%s%s\n", "", count ". ", $i }} ; count++ ; next }' $PH_CONF_DIR/$PH_APP.conf
					PH_COUNT=$((PH_COUNT+`nawk 'BEGIN { count = 0 } $0 ~ / typeset / { for (i=1;i<=NF;i++) { if ($i~/^PH_/) { count++ }}} END { print count }' $PH_CONF_DIR/$PH_APP.conf`))
				fi
				((PH_COUNT++))
				printf "%8s%s%s\n" "" "$PH_COUNT. " "All"
				printf "\n%8s%s" "" "Your choice ? "
				read PH_ANSWER 2>/dev/null
			done
			printf "%10s%s\n" "" "OK"
			printf "%2s%s\n" "" "SUCCESS"
			if [[ $PH_ANSWER -eq $PH_COUNT ]]
			then
				PH_OPT="all"
			else
				if [[ $PH_ANSWER -le $PH_COUNT2 ]]
				then
					PH_OPT=`grep ^"PH_" $PH_CONF_DIR/$PH_APP.conf | egrep -v ^"PH_PIEH_STARTAPP|PH_PIEH_DEBUG" | nawk -F'=' -v choice=$PH_ANSWER 'NR==choice { print $1 }'`
				else
					PH_OPT=$(grep ' typeset ' $PH_CONF_DIR/$PH_APP.conf | \
						nawk -v choice=$((PH_ANSWER-$PH_COUNT2)) 'NR == choice { for (i=1;i<=NF;i++) { if ($i~/^PH_/) { print $i }}}')
					PH_OPT="${PH_OPT%%=*}" 
				fi
			fi
			confopts_ph.sh -p help -a "$PH_APP" -o "$PH_OPT"
			unset OPTAR VALAR
			exit $? ;;
		esac ;;
esac
confopts_ph.sh -h || exit $?
