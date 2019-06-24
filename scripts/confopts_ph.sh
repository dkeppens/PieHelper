#!/bin/ksh
# Manage application options and controllers settings (by Davy Keppens on 06/11/2018)
# Enable/Disable debug by running confpieh_ph.sh -p debug -m confopts_ph.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

typeset PH_ACTION=""
typeset PH_OPT_TYPE="read-write"
typeset PH_I_ACTION=""
typeset PH_APP=""
typeset PH_VALUE=""
typeset PH_OPT=""
typeset PH_i=""
typeset PH_j=""
typeset PH_OPTION=""
typeset PH_RESOLVE=""
typeset PH_RESULT="SUCCESS"
typeset PH_TYPE=""
typeset PH_DISP_TYPE=""
typeset PH_USE_WORD=""
typeset PH_ALLOW_VAL=""
typeset PH_OLDOPTARG="$OPTARG"
typeset -i PH_ANSWER=0
typeset -i PH_COUNT=0
typeset -i PH_COUNT2=0
typeset -i PH_RET_CODE=0
typeset -i PH_OLDOPTIND=$OPTIND
set -A PH_OPTAR
set -A PH_VALAR
OPTIND=1

while getopts a:o:p:t:hgsdrmn PH_OPTION 2>/dev/null
do
	case $PH_OPTION in a)
		! ph_screen_input "$OPTARG" && unset PH_OPTAR PH_VALAR && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ -n "$PH_APP" ]] && (! confopts_ph.sh -h) && unset PH_OPTAR PH_VALAR && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_APP="$OPTARG"
		[[ "$PH_APP" == "Ctrls" ]] && PH_USE_WORD="setting" || PH_USE_WORD="option" ;;
			   p)
		! ph_screen_input "$OPTARG" && unset PH_OPTAR PH_VALAR && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ "$OPTARG" != @(set|get|help|prompt|list) ]] && (! confopts_ph.sh -h) && unset PH_OPTAR PH_VALAR && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ -n "$PH_ACTION" ]] && (! confopts_ph.sh -h) && unset PH_OPTAR PH_VALAR && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ -n "$PH_I_ACTION" && "$OPTARG" != "prompt" ]] && (! confopts_ph.sh -h) && unset PH_OPTAR PH_VALAR && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_ACTION="$OPTARG" ;;
			   o)
		[[ -n "$PH_I_ACTION" ]] && (! confopts_ph.sh -h) && unset PH_OPTAR PH_VALAR && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ -z "${OPTARG%%=*}" ]] && (! confopts_ph.sh -h) && unset PH_OPTAR PH_VALAR && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		if [[ "${OPTARG%%=*}" == "all" && $PH_ACTION == "set" ]]
		then
			printf "%s\033[36m%s\033[0m\033[32m%s\033[0m\n" "- " "Changing value of option " "'${OPTARG%%=*}'"
			printf "%2s\033[31m%s\033[0m%s\n\n" "" "FAILED" " : Unknown option"
			unset PH_OPTAR PH_VALAR
			OPTARG="$PH_OLDOPTARG"
			OPTIND=$PH_OLDOPTIND
			exit 1	
		fi
		if [[ -n "$PH_OPT" ]]
		then
			PH_OPT="$PH_OPT'${OPTARG%%=*}"
			if (echo -n "$OPTARG" | grep '=' >/dev/null 2>&1)
			then
				if [[ "${OPTARG##*=}" == "N/A" ]]
				then
					printf "%s\033[36m%s\033[0m\033[32m%s\033[0m\n" "- " "Changing value of " "'${OPTARG%%=*}'"
					printf "%2s\033[31m%s\033[0m%s\033[32m%s\033[0m%s\n\n" "" "FAILED" " : Cannot accept " "'N/A'" " as a value (Reserved string)"
					unset PH_OPTAR PH_VALAR
					OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
				fi
				PH_VALUE="$PH_VALUE'${OPTARG##*=}"
			else
				PH_VALUE="$PH_VALUE'N/A"
			fi
		else
			PH_OPT="${OPTARG%%=*}"
			if (echo -n "$OPTARG" | grep '=' >/dev/null 2>&1)
			then
				if [[ "${OPTARG##*=}" == "N/A" ]]
				then
					printf "%s\033[36m%s\033[0m\033[32m%s\033[0m\n" "- " "Changing value of " "'${OPTARG%%=*}'"
					printf "%2s\033[31m%s\033[0m%s\033[32m%s\033[0m%s\n\n" "- " "FAILED" " : Cannot accept " "'N/A'" " as a value (Reserved string)"
					unset PH_OPTAR PH_VALAR
					OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
				fi
				PH_VALUE="${OPTARG##*=}"
			else
				PH_VALUE="N/A"
			fi
		fi ;;
                          g)
                [[ "$PH_ACTION" != @(prompt|) ]] && (! confopts_ph.sh -h) && unset PH_OPTAR PH_VALAR && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ -n "$PH_I_ACTION" ]] && (! confopts_ph.sh -h) && unset PH_OPTAR PH_VALAR && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
                PH_I_ACTION="get" ;;
                          s)
                [[ "$PH_ACTION" != @(prompt|) ]] && (! confopts_ph.sh -h) && unset PH_OPTAR PH_VALAR && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ -n "$PH_I_ACTION" ]] && (! confopts_ph.sh -h) && unset PH_OPTAR PH_VALAR && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
                PH_I_ACTION="set" ;;
                          d)
                [[ "$PH_ACTION" != @(prompt|) ]] && (! confopts_ph.sh -h) && unset PH_OPTAR PH_VALAR && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ -n "$PH_I_ACTION" ]] && (! confopts_ph.sh -h) && unset PH_OPTAR PH_VALAR && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
                PH_I_ACTION="help" ;;
                          r)
                [[ "$PH_ACTION" != @(get|prompt|set|) ]] && (! confopts_ph.sh -h) && unset PH_OPTAR PH_VALAR && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ -n "$PH_RESOLVE" ]] && (! confopts_ph.sh -h) && unset PH_OPTAR PH_VALAR && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
                PH_RESOLVE="yes" ;;
			  m)
		[[ "$PH_ACTION" != @(set|prompt|) ]] && (! confopts_ph.sh -h) && unset PH_OPTAR PH_VALAR && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ "$PH_I_ACTION" != @(set|) ]] && (! confopts_ph.sh -h) && unset PH_OPTAR PH_VALAR && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ -n "$PH_TYPE" ]] && (! confopts_ph.sh -h) && unset PH_OPTAR PH_VALAR && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
                PH_TYPE="r" ;;
			  n)
		[[ "$PH_ACTION" != @(set|prompt|) ]] && (! confopts_ph.sh -h) && unset PH_OPTAR PH_VALAR && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ "$PH_I_ACTION" != @(set|) ]] && (! confopts_ph.sh -h) && unset PH_OPTAR PH_VALAR && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ -n "$PH_TYPE" ]] && (! confopts_ph.sh -h) && unset PH_OPTAR PH_VALAR && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
                PH_TYPE="o" ;;
			  t)
		[[ "$OPTARG" != @(rw|ro) ]] && (! confopts_ph.sh -h) && unset PH_OPTAR PH_VALAR && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ -n "$PH_DISP_TYPE" ]] && (! confopts_ph.sh -h) && unset PH_OPTAR PH_VALAR && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
                PH_DISP_TYPE="$OPTARG" ;;
			   *)
		>&2 printf "%s\n" "Usage : confopts_ph.sh -h |"
		>&2 printf "%23s%s\n" "" "-p \"get\" -a [[getapp]|\"Ctrls\"] [-o [getopt] -o [getopt] ... |-o \"all\" '-t [\"rw\"|\"ro\"]'] '-r' |"
		>&2 printf "%23s%s\n" "" "-p \"list\" -a [[listapp]|\"Ctrls\"] '-t [\"rw\"|\"ro\"]' |"
		>&2 printf "%23s%s\n" "" "-p \"help\" -a [[helpapp]|\"Ctrls\"] [-o [helpopt] -o [helpopt] ...|-o \"all\" '-t [\"rw\"|\"ro\"]'] |"
		>&2 printf "%23s%s\n" "" "-p \"set\" -a [[setapp]|\"Ctrls\"] -o [setopt]='[value]' -o [setopt]='[value]' -o ... '[-m|-n]' |"
		>&2 printf "%23s%s\n" "" "-p \"prompt\" -a [[promptapp]|\"Ctrls\"] '-r' [-d '-t [\"rw\"|\"ro\"]'|-g '-t [\"rw\"|\"ro\"]'|-s '[-m|-n]']"
		>&2 printf "\n"
		>&2 printf "%3s%s\n" "" "Where -h displays this usage"
		>&2 printf "%9s%s\n" "" "-p specifies the action to take"
		>&2 printf "%12s%s\n" "" "\"get\" allows displaying the value of an option [getopt] of an application [getapp] or the value of a controllers setting"
		>&2 printf "%15s%s\n" "" "-a allows specifying an application name for [getapp]"
		>&2 printf "%18s%s\n" "" "- The keyword 'Ctrls' can be used to operate on controllers settings"
		>&2 printf "%15s%s\n" "" "-o allows specifying the name of an option or a controllers setting for [getopt]"
		>&2 printf "%18s%s\n" "" "- Multiple instances of -o are allowed"
		>&2 printf "%18s%s\n" "" "- The keyword \"all\" can be used to request displaying the value of all options of [getapp]"
		>&2 printf "%21s%s\n" "" "- The keyword \"all\" is unsupported when using multiple instances of -o"
		>&2 printf "%21s%s\n" "" "-t allows specifying one of two possible types to restrict the returned results to"
		>&2 printf "%24s%s\n" "" "- Possible types to filter on are \"rw\" (read-write) and \"ro\" (read-only)"
		>&2 printf "%24s%s\n" "" "- Specifying '-t' is optional"
		>&2 printf "%24s%s\n" "" "  If not specified, the default is to return results of both types" 
		>&2 printf "%15s%s\n" "" "-r allows requesting expansion of all variables present in the value for option [getopt]"
		>&2 printf "%18s%s\n" "" "- Specifying -r is optional"
		>&2 printf "%18s%s\n" "" "- Variables are not expanded by default"
		>&2 printf "%12s%s\n" "" "\"help\" allows displaying information about the option(s) [helpopt] of an application [helpapp] or the controllers settings"
		>&2 printf "%15s%s\n" "" "-a allows specifying an application name for [helpapp]"
		>&2 printf "%18s%s\n" "" "- The keyword 'Ctrls' can be used to operate on controllers settings"
		>&2 printf "%15s%s\n" "" "-o allows specifying the name of an option or a controllers setting for [helpopt]"
		>&2 printf "%18s%s\n" "" "- Multiple instances of -o are allowed"
		>&2 printf "%18s%s\n" "" "- The keyword \"all\" can be used to request displaying information about all options of [helpapp]"
		>&2 printf "%21s%s\n" "" "- The keyword \"all\" is unsupported when using multiple instances of -o"
		>&2 printf "%21s%s\n" "" "-t allows specifying one of two possible types to restrict the returned results to"
		>&2 printf "%24s%s\n" "" "- Possible types to filter on are \"rw\" (read-write) and \"ro\" (read-only)"
		>&2 printf "%24s%s\n" "" "- Specifying '-t' is optional"
		>&2 printf "%24s%s\n" "" "  If not specified, the default is to return results of both types" 
		>&2 printf "%12s%s\n" "" "\"list\" allows listing all existing options of application [listapp] or all existing controllers settings"
		>&2 printf "%15s%s\n" "" "-a allows specifying an application name for [listapp]"
		>&2 printf "%18s%s\n" "" "- The keyword 'Ctrls' can be used to operate on controllers settings"
		>&2 printf "%15s%s\n" "" "-t allows specifying one of two possible types to restrict the returned results to"
		>&2 printf "%18s%s\n" "" "- Possible types to filter on are \"rw\" (read-write) and \"ro\" (read-only)"
		>&2 printf "%18s%s\n" "" "- Specifying '-t' is optional"
		>&2 printf "%18s%s\n" "" "  If not specified, the default is to return results of both types" 
		>&2 printf "%12s%s\n" "" "\"set\" allows changing the value of an option [setopt] of an application [setapp] or a read-write controllers setting to [value]"
		>&2 printf "%15s%s\n" "" "- Set actions will fail on read-only options"
		>&2 printf "%15s%s\n" "" "-a allows specifying an application name for [setapp]"
		>&2 printf "%18s%s\n" "" "- The keyword 'Ctrls' can be used to operate on controllers settings"
		>&2 printf "%15s%s\n" "" "-o allows specifying the name of an option or a controllers setting [setopt] and it's new value [value]"
		>&2 printf "%18s%s\n" "" "- Multiple instances of -o are allowed"
		>&2 printf "%18s%s\n" "" "- [value] cannot be the reserved string 'N/A'"
		>&2 printf "%18s%s\n" "" "- Always surround [value] with single quotes in the form option='[value]' when [value] contains variables that should not be expanded by the current shell"
		>&2 printf "%18s%s\n" "" "  Use double quotes to surround [value] in the form option="[value]" in all other cases"
		>&2 printf "%18s%s\n" "" "- Composite strings (containing spaces) and variables within [value] should be surrounded with double quotes"
		>&2 printf "%18s%s\n" "" "- Using single quotes within [value] is not permitted due to being a POSIX limitation"
		>&2 printf "%18s%s\n" "" "- Any event-based input device id references in [value] for an option holding an application's command line options should have the"
		>&2 printf "%18s%s\n" "" "  numeric id replaced by the string 'PH_CTRL%' where '%' is '1' for controller 1, '2' for controller 2, etc"
		>&2 printf "%18s%s\n" "" "- Changes to an option that sets the controller amount for an application will automatically be reflected to"
		>&2 printf "%18s%s\n" "" "  the option holding an application's command line options if event-based input devices are present as command-line parameters"
		>&2 printf "%18s%s\n" "" "- Changes to an option holding an application's command line options where event-based input devices are present will automatically be reflected to"
		>&2 printf "%18s%s\n" "" "  the application's option determining the controller amount unless all event device parameters are being removed"
		>&2 printf "%15s%s\n" "" "-m allows marking the operation as mandatory"
		>&2 printf "%18s%s\n" "" "- Mandatory operations will return an error when they fail"
		>&2 printf "%18s%s\n" "" "- Specifying -m is optional"
		>&2 printf "%18s%s\n" "" "- Operations are marked mandatory by default"
		>&2 printf "%15s%s\n" "" "-n allows marking the operation as non-mandatory"
		>&2 printf "%18s%s\n" "" "- Specifying -n is optional"
		>&2 printf "%18s%s\n" "" "- Non-mandatory operations will return a warning when they fail"
		>&2 printf "%12s%s\n" "" "\"prompt\" makes confopts_ph.sh behave interactively when it comes to passing an optionname of application [promptapp] or passing the name of a controllers setting"
		>&2 printf "%15s%s\n" "" "-a allows specifying an application name for [promptapp]"
		>&2 printf "%18s%s\n" "" "- The keyword 'Ctrls' can be used to operate on controllers settings"
		>&2 printf "%15s%s\n" "" "-g specifies a get action in interactive mode"
		>&2 printf "%18s%s\n" "" "-t allows specifying one of two possible types to restrict the listed results in the interactive menu to"
		>&2 printf "%21s%s\n" "" "- Possible types to filter on are \"rw\" (read-write) and \"ro\" (read-only)"
		>&2 printf "%21s%s\n" "" "- Specifying '-t' is optional"
		>&2 printf "%21s%s\n" "" "  If not specified, the default is to list results of both types" 
		>&2 printf "%15s%s\n" "" "-s specifies a set action in interactive mode"
		>&2 printf "%18s%s\n" "" "- [value] cannot be the reserved string 'N/A'"
		>&2 printf "%18s%s\n" "" "- Set actions will fail on read-only options"
		>&2 printf "%18s%s\n" "" "- No surrounding quotes are required when entering the new value in interactive mode"
		>&2 printf "%18s%s\n" "" "- Composite strings (containing spaces) and variables within [value] should be surrounded with double quotes"
		>&2 printf "%18s%s\n" "" "- Using single quotes within the new value entered is not permitted due to being a POSIX limitation"
		>&2 printf "%18s%s\n" "" "- Any event-based input device id references in the new value entered for an option holding an application's command line options should have the"
		>&2 printf "%18s%s\n" "" "  numeric id replaced by the string 'PH_CTRL%' where '%' is '1' for controller 1, '2' for controller 2, etc"
		>&2 printf "%18s%s\n" "" "- Changes to an option that sets the controller amount for an application will automatically be reflected to"
		>&2 printf "%18s%s\n" "" "  the option holding that application's command line options if event-based input devices are present as command-line parameters"
		>&2 printf "%18s%s\n" "" "- Changes to an option holding an application's command line options where event-based input devices are present will automatically be reflected to"
		>&2 printf "%18s%s\n" "" "  the application's option determining the controller amount unless all event device parameters are being removed"
		>&2 printf "%18s%s\n" "" "-m allows marking the operation as mandatory"
		>&2 printf "%21s%s\n" "" "- Mandatory operations will return an error when they fail"
		>&2 printf "%21s%s\n" "" "- Specifying -m is optional"
		>&2 printf "%21s%s\n" "" "- Operations are by default marked as mandatory"
		>&2 printf "%18s%s\n" "" "-n allows marking the operation as non-mandatory"
		>&2 printf "%21s%s\n" "" "- Non-mandatory operations will return a warning when they fail"
		>&2 printf "%21s%s\n" "" "- Specifying -n is optional"
		>&2 printf "%15s%s\n" "" "-d specifies a display help action in interactive mode"
		>&2 printf "%18s%s\n" "" "-t allows specifying one of two possible types to restrict the listed results in the interactive menu to"
		>&2 printf "%21s%s\n" "" "- Possible types to filter on are \"rw\" (read-write) and \"ro\" (read-only)"
		>&2 printf "%21s%s\n" "" "- Specifying '-t' is optional"
		>&2 printf "%21s%s\n" "" "  If not specified, the default is to list results of both types" 
		>&2 printf "%15s%s\n" "" "-r allows requesting expansion of all variables present in all option values displayed in any interactive mode"
		>&2 printf "%18s%s\n" "" "- Specifying -r is optional"
		>&2 printf "%18s%s\n" "" "- Variables are not expanded by default"
		>&2 printf "\n"
		OPTARG="$PH_OLDOPTARG"
		OPTIND=$PH_OLDOPTIND
		unset PH_OPTAR PH_VALAR
		exit 1 ;;
	esac
done
OPTARG="$PH_OLDOPTARG"
OPTIND=$PH_OLDOPTIND

(([[ -n "$PH_DISP_TYPE" && "$PH_OPT" != "all" ]]) && ([[ "$PH_ACTION" == @(get|help) ]])) && (! confopts_ph.sh -h) && unset PH_OPTAR PH_VALAR && exit 1
(([[ -n "$PH_DISP_TYPE" ]]) && ([[ "$PH_ACTION" == "set" || "$PH_I_ACTION" == "set" ]])) && (! confopts_ph.sh -h) && unset PH_OPTAR PH_VALAR && exit 1
(([[ -z "$PH_DISP_TYPE" && "$PH_OPT" == "all" ]]) && ([[ "$PH_ACTION" == @(get|help) ]])) && PH_DISP_TYPE="all"
(([[ -z "$PH_DISP_TYPE" ]]) && ([[ "$PH_I_ACTION" == @(get|help) || "$PH_ACTION" == "list" ]])) && PH_DISP_TYPE="all"
[[ -n "$PH_RESOLVE" && "$PH_ACTION" != @(get|prompt) ]] && (! confopts_ph.sh -h) && unset PH_OPTAR PH_VALAR && exit 1
[[ -z "$PH_RESOLVE" ]] && PH_RESOLVE="no"
(([[ -z "$PH_TYPE" ]]) && ([[ "$PH_ACTION" == "set" || "$PH_I_ACTION" == "set" ]])) && PH_TYPE="r"
(([[ -n "$PH_TYPE" ]]) && ([[ "$PH_ACTION" == @(help|get|list) || "$PH_I_ACTION" == @(get|help) ]])) && (! confopts_ph.sh -h) && unset PH_OPTAR PH_VALAR && exit 1
(([[ -z "$PH_ACTION" || -z "$PH_APP" ]]) || ([[ "$PH_ACTION" != @(prompt|list) && -z "$PH_OPT" ]])) && (! confopts_ph.sh -h) && unset PH_OPTAR PH_VALAR && exit 1
[[ -n "$PH_OPT" && "$PH_ACTION" == @(prompt|list) ]] && (! confopts_ph.sh -h) && unset PH_OPTAR PH_VALAR && exit 1
[[ "$PH_ACTION" == "prompt" && -z "$PH_I_ACTION" ]] && (! confopts_ph.sh -h) && unset PH_OPTAR PH_VALAR && exit 1
if [[ `$PH_SUDO cat /proc/$PPID/comm` != "confopts_ph.sh" ]]
then
	if [[ "$PH_APP" != "Ctrls" ]]
	then
		! ph_check_app_name -s -a "$PH_APP" && printf "\n" && unset PH_OPTAR PH_VALAR && exit 1
	fi
fi
if [[ "$PH_ACTION" == @(set|get|help) ]]
then
	PH_OPTAR+=(`echo -n "$PH_OPT" | sed "s/'/ /g"`)
	for PH_COUNT in {1..${#PH_OPTAR[@]}}
	do
		PH_VALAR+=("`echo $PH_VALUE | cut -d\' -f$PH_COUNT`")
	done
	for PH_COUNT in {0..`echo $((${#PH_OPTAR[@]}-1))`}
	do
		if (([[ "${PH_OPTAR[$PH_COUNT]}" == "all" && ${#PH_OPTAR[@]} -gt 1 ]]) && ([[ "$PH_ACTION" == "get" ]]))
		then
			printf "%s\033[36m%s\033[0m\033[32m%s\033[0m\n" "- " "Displaying value of $PH_USE_WORD " "'${PH_OPTAR[0]}'"
			printf "%2s\033[31m%s\033[0m%s\n\n" "" "FAILED" " : Unsupported use of the keyword 'all'"
			exit 1
		fi
		if (([[ "${PH_OPTAR[$PH_COUNT]}" == "all" && ${#PH_OPTAR[@]} -gt 1 ]]) && ([[ "$PH_ACTION" == "help" ]]))
		then
			printf "%s\033[36m%s\033[0m\033[32m%s\033[0m\n" "- " "Displaying help of $PH_USE_WORD " "'${PH_OPTAR[0]}'"
			printf "%2s\033[31m%s\033[0m%s\n\n" "" "FAILED" " : Unsupported use of the keyword 'all'"
			exit 1
		fi
		[[ "$PH_ACTION" == "set" && "${PH_VALAR[$PH_COUNT]}" == "N/A" ]] && \
				(printf "%s\033[36m%s\033[0m\033[32m%s\033[0m\n" "- " "Changing value of $PH_USE_WORD " "'${PH_OPTAR[$PH_COUNT]}'" ; \
				printf "%2s\033[31m%s\033[0m%s\n\n" "" "FAILED" " : No value passed" ; return 0) && unset PH_OPTAR PH_VALAR && exit 1
		[[ "${PH_OPTAR[$PH_COUNT]}" == "PH_PIEH_DEBUG" && "$PH_ACTION" == "set" ]] && \
				(printf "%s\033[36m%s\033[0m\033[32m%s\033[0m\n" "- " "Changing value of $PH_USE_WORD " "'${PH_OPTAR[$PH_COUNT]}'" ; \
				printf "%2s\033[31m%s\033[0m%s\n\n" "" "FAILED" " : Module debug should be handled by 'confpieh_ph.sh' or the PieHelper menu" ; return 0) && unset PH_OPTAR PH_VALAR && exit 1 
		[[ "${PH_OPTAR[$PH_COUNT]}" == "PH_PIEH_STARTAPP" && "$PH_ACTION" == "set" ]] && \
				(printf "%s\033[36m%s\033[0m\033[32m%s\033[0m\n" "- " "Changing value of $PH_USE_WORD " "'${PH_OPTAR[$PH_COUNT]}'" ; \
				printf "%2s\033[31m%s\033[0m%s\n\n" "" "FAILED" " : The application to start by default on system boot should be handled by 'confapps_ph.sh -p start' or the PieHelper menu" ; return 0) && \
					unset PH_OPTAR PH_VALAR && exit 1 
		while ((! grep ^"${PH_OPTAR[$PH_COUNT]}=" $PH_CONF_DIR/$PH_APP.conf >/dev/null 2>&1) && ([[ "${PH_OPTAR[$PH_COUNT]}" != "all" && "$PH_ACTION" != @(prompt|list) ]]))
		do
			for PH_i in `nawk 'BEGIN { ORS = " " } $6 ~ /^typeset$/ && $7 ~ /^-r$/ && $8 ~ /^PH_/ { print substr($8,0,index($8,"=")) }' $PH_CONF_DIR/$PH_APP.conf`
			do
				[[ "$PH_i" == "${PH_OPTAR[$PH_COUNT]}" ]] && break 2
			done
			case $PH_ACTION in get)
				printf "%s\033[36m%s\033[0m\033[32m%s\033[0m\n" "- " "Displaying value of $PH_USE_WORD " "'${PH_OPTAR[$PH_COUNT]}'" ;;
					   set)
				printf "%s\033[36m%s\033[0m\033[32m%s\033[0m\n" "- " "Changing value of $PH_USE_WORD " "'${PH_OPTAR[$PH_COUNT]}'" ;;
					  help)
				printf "%s\033[36m%s\033[0m\033[32m%s\033[0m\n" "- " "Displaying help of $PH_USE_WORD " "'${PH_OPTAR[$PH_COUNT]}'" ;;
			esac
			printf "%2s\033[31m%s\033[0m%s\n\n" "" "FAILED" " : Unknown $PH_USE_WORD"
			unset PH_OPTAR PH_VALAR
			exit 1
		done
	done
fi
PH_COUNT=0
case $PH_ACTION in get)
		for PH_COUNT in {0..$((${#PH_OPTAR[@]}-1))}
		do
			PH_OPT="${PH_OPTAR[$PH_COUNT]}"
			if [[ "$PH_OPT" == "all" ]]
			then
				(if [[ "$PH_DISP_TYPE" == @(rw|all) ]]
				then
					for PH_OPT in `grep ^"PH_" $PH_CONF_DIR/$PH_APP.conf | cut -d'=' -f1 | paste -d" " -s`
					do
						[[ "$PH_RESOLVE" == "yes" ]] && confopts_ph.sh -p get -a "$PH_APP" -o "$PH_OPT" -r || \
							confopts_ph.sh -p get -a "$PH_APP" -o "$PH_OPT"
					done
				fi
				if [[ "$PH_DISP_TYPE" == @(ro|all) ]]
				then
					for PH_OPT in `nawk 'BEGIN { ORS = " " } $6 ~ /^typeset$/ && $7 ~ /^-r$/ && $8 ~ /^PH_/ { print substr($8,0,index($8,"=")) }' $PH_CONF_DIR/$PH_APP.conf`
					do
						[[ "$PH_RESOLVE" == "yes" ]] && confopts_ph.sh -p get -a "$PH_APP" -o "$PH_OPT" -r || \
							confopts_ph.sh -p get -a "$PH_APP" -o "$PH_OPT"
					done
				fi) | more
			else
				grep ^"$PH_OPT=" "$PH_CONF_DIR"/"$PH_APP".conf >/dev/null 2>&1 && PH_OPT_TYPE="read-write" || PH_OPT_TYPE="read-only"
				([[ "$PH_RESOLVE" == "yes" ]] && printf "%s\033[36m%s\033[0m\033[32m%s\033[0m\033[36m%s\033[0m\n" "- " "Displaying value of $PH_OPT_TYPE $PH_USE_WORD " "'$PH_OPT'" " (Variable expansion enabled)" || \
								printf "%s\033[36m%s\033[0m\033[32m%s\033[0m\n" "- " "Displaying value of $PH_OPT_TYPE $PH_USE_WORD " "'$PH_OPT'"
				printf "\033[32m"
				typeset -n PH_OPTVAL="$PH_OPT"
				if [[ "$PH_RESOLVE" == "yes" ]]
				then
					printf "%2s%s\n" "" "'$(echo $PH_OPTVAL | sed 's/"/\\\"/g' | eval echo `cat`)'"
				else
					printf "%2s%s\n" "" "'$PH_OPTVAL'"
				fi
				printf "\033[0m"
				[[ "$PH_RESULT" == "SUCCESS" ]] && printf "%2s%s\n\n" "" "$PH_RESULT" || printf "%2s\033[31m%s\033[0m\n\n" "" "$PH_RESULT"
				unset -n PH_OPTVAL) | more
			fi
		done
		unset PH_OPTAR PH_VALAR
		exit 0 ;;
		  list)
		if [[ "$PH_DISP_TYPE" == @(ro|all) ]]
		then
			printf "%s\033[36m%s%s\033[0m\033[32m%s\033[0m\n" "- " "Listing all available read-only $PH_USE_WORD" "s for " "'$PH_APP'"
			printf "\033[32m"
			if [[ -z `nawk 'BEGIN { ORS = " " } $6 ~ /^typeset$/ && $7 ~ /^-r$/ && $8 ~ /^PH_/ { print substr($8,0,index($8,"=")) }' $PH_CONF_DIR/$PH_APP.conf 2>/dev/null` ]]
			then
				printf "%8s%s\n" "" "\"No read-only options found\"" 
			else
				for PH_OPT in `nawk 'BEGIN { ORS = " " } $6 ~ /^typeset$/ && $7 ~ /^-r$/ && $8 ~ /^PH_/ { print substr($8,0,index($8,"=")) }' $PH_CONF_DIR/$PH_APP.conf`
				do
					printf "%8s%s\n" "" "$PH_OPT"
				done
			fi
			printf "\033[0m"
			[[ "$PH_RESULT" == "SUCCESS" ]] && printf "%2s%s\n\n" "" "$PH_RESULT" || printf "%2s\033[31m%s\033[0m\n\n" "" "$PH_RESULT"
		fi
		if [[ "$PH_DISP_TYPE" == @(rw|all) ]]
		then
			printf "%s\033[36m%s%s\033[0m\033[32m%s\033[0m\n" "- " "Listing all available read-write $PH_USE_WORD" "s for " "'$PH_APP'"
			printf "\033[32m"
			for PH_OPT in `nawk -F'=' '$1 ~ /^PH_/ { print $1 ; next } { next }' $PH_CONF_DIR/$PH_APP.conf | paste -d" " -s`
			do
				printf "%8s%s\n" "" "$PH_OPT"
			done
			printf "\033[0m"
			[[ "$PH_RESULT" == "SUCCESS" ]] && printf "%2s%s\n\n" "" "$PH_RESULT" || printf "%2s\033[31m%s\033[0m\n\n" "" "$PH_RESULT"
		fi
		unset PH_OPTAR PH_VALAR
		exit 0 ;;
		  help)
		for PH_COUNT in {0..$((${#PH_OPTAR[@]}-1))}
		do
			PH_OPT="${PH_OPTAR[$PH_COUNT]}"
			if [[ "$PH_OPT" == "all" ]]
			then
				(if [[ "$PH_DISP_TYPE" == @(rw|all) ]]
				then
					for PH_OPT in `grep ^"PH_" $PH_CONF_DIR/$PH_APP.conf | cut -d'=' -f1 | paste -d" " -s`
					do
						confopts_ph.sh -p help -a "$PH_APP" -o "$PH_OPT"
					done
				fi
				if [[ "$PH_DISP_TYPE" == @(ro|all) ]]
				then
					for PH_OPT in `nawk 'BEGIN { ORS = " " } $6 ~ /^typeset$/ && $7 ~ /^-r$/ && $8 ~ /^PH_/ { print substr($8,0,index($8,"=")) }' $PH_CONF_DIR/$PH_APP.conf`
					do
						confopts_ph.sh -p help -a "$PH_APP" -o "$PH_OPT"
					done
				fi) | more
			else
				grep ^"$PH_OPT=" "$PH_CONF_DIR"/"$PH_APP".conf >/dev/null 2>&1 && PH_OPT_TYPE="read-write" || PH_OPT_TYPE="read-only"
				(printf "%s\033[36m%s\033[0m\033[32m%s\033[0m\n" "- " "Displaying help for $PH_OPT_TYPE $PH_USE_WORD " "'$PH_OPT'"
				printf "\033[36m%s\033[0m\033[32m\n\n" "  ___________________________________________________________"
				if [[ "$PH_OPT_TYPE" == "read-write" ]]
				then
					nawk -F'#' -v opt=^"$PH_OPT=" '$1 ~ opt { print $2 ; getline ; while ($1!~/^PH_/ && $0!~/^$/) { print $2 ; getline } ; exit }' "$PH_CONF_DIR"/"$PH_APP".conf 2>/dev/null
					[[ $? -eq 0 ]] && PH_RESULT="SUCCESS" || PH_RESULT="FAILED"
				else
					nawk -F'#' -v opt=" typeset .* $PH_OPT=" '$1 ~ opt { print $2 ; getline ; while ($1!~/^PH_|^\[\[/ && $0!~/^$/) { print $2 ; getline } ; exit }' "$PH_CONF_DIR"/"$PH_APP".conf 2>/dev/null
					[[ $? -eq 0 ]] && PH_RESULT="SUCCESS" || PH_RESULT="FAILED"
				fi
				printf "\033[0m"
				[[ "$PH_RESULT" == "SUCCESS" ]] && printf "%2s%s\n\n" "" "$PH_RESULT" || printf "%2s\033[31m%s\033[0m\n\n" "" "$PH_RESULT") | more
			fi
		done
		unset PH_OPTAR PH_VALAR
		exit 0 ;;
		   set)
		printf "%s\033[36m%s%s\033[0m\033[32m%s\033[0m\n" "- " "Changing value of $PH_USE_WORD" "(s)" " $(for PH_COUNT in {0..`echo $((${#PH_OPTAR[@]}-1))`};do;echo -n "'${PH_OPTAR[$PH_COUNT]}' ";done)"
		for PH_COUNT in {0..`echo $((${#PH_OPTAR[@]}-1))`}
		do
			if [[ "${PH_OPTAR[$PH_COUNT]}" == *_CIFS_SHARE ]]
			then
				for PH_i in `nawk 'BEGIN { ORS = " " } { print $1 }' $PH_CONF_DIR/installed_apps`
				do
					[[ `echo "$PH_i" | cut -c1-4 | tr '[:lower:]' '[:upper:]'` == `echo "${PH_OPTAR[$PH_COUNT]}" | cut -d'_' -f2` ]] && PH_j="$PH_i"
				done
				if [[ -n "$PH_j" ]]
				then
					if mount | nawk '{ for (i=0;i<NF;i++) { if ($i == "type") { print $(i-1) }}}' | grep ^"${PH_SCRIPTS_DIR%/*}/mnt/$PH_j"$ >/dev/null 2>&1
					then
						printf "%2s\033[31m%s\033[0m%s\n\n" "" "FAILED" " : Cannot change value for ${PH_OPTAR[$PH_COUNT]} while CIFS mount is active on default mountpoint"
						exit 1
					fi
				fi
			fi
			[[ "${PH_OPTAR[$PH_COUNT]}" == "PH_PIEH_DEBUG" ]] && printf "%2s\033[31m%s\033[0m%s\n\n" "" "FAILED" " : Module debug should be handled by confpieh_ph.sh" && unset PH_OPTAR PH_VALAR && exit 1 
			[[ "${PH_OPTAR[$PH_COUNT]}" == "PH_PIEH_STARTAPP" ]] && printf "%2s\033[31m%s\033[0m%s\n\n" "" "FAILED" " : The application to start by default on system boot should be handled by confapps_ph.sh -p start" && \
											unset PH_OPTAR PH_VALAR && exit 1 
		done
		eval ph_set_option "$PH_APP" `echo -n "$(for PH_COUNT in {0..\`echo -n $((${#PH_OPTAR[@]}-1))\`};do;eval echo -en -$PH_TYPE ${PH_OPTAR[$PH_COUNT]}='\"\\${PH_VALAR[$PH_COUNT]}\"'\" \";done)"`
		PH_RET_CODE=$?
		if [[ $PH_RET_CODE -ne 0 ]]
		then
			[[ $PH_RET_CODE -eq ${#PH_OPTAR[@]} ]] && PH_RESULT="FAILED" || PH_RESULT="PARTIALLY FAILED"
		fi
		[[ "$PH_RESULT" == "SUCCESS" ]] && printf "%2s%s\n\n" "" "$PH_RESULT" || printf "%2s\033[31m%s\033[0m\n\n" "" "$PH_RESULT"
		unset PH_OPTAR PH_VALAR
		exit $PH_RET_CODE ;;
		  prompt)
		case $PH_I_ACTION in get)
			while true
			do
				printf "%s\033[36m%s\033[0m\n" "- " "Displaying value(s) using interactive mode"
				[[ "$PH_RESOLVE" == "yes" ]] && printf "%8s%s\n\n" "" "--> Which $PH_USE_WORD do you want to view the value of ? (Variable expansion enabled)" || \
							printf "%8s%s\n\n" "" "--> Which $PH_USE_WORD do you want to view the value of ?"
                		while [[ $PH_ANSWER -eq 0 || $PH_ANSWER -gt $((PH_COUNT+1)) ]]
                		do
					[[ $PH_COUNT -gt 0 ]] && printf "\n%10s\033[31m%s\033[0m%s\n\n" "" "ERROR" " : Invalid response"
					PH_COUNT=1
					if [[ "$PH_DISP_TYPE" == @(rw|all) ]]
					then
						for PH_i in `grep ^"PH_" $PH_CONF_DIR/$PH_APP.conf | nawk -F'=' '{ print $1 }'`
						do
							printf "%2s%-13s%4s%2s%s\033[32m%s\033[0m\n" "" "(read-write)" "" "$((PH_COUNT))" ". " "$PH_i"
							((PH_COUNT++))
						done
					fi
					PH_COUNT2=$PH_COUNT
					if [[ "$PH_DISP_TYPE" == @(ro|all) ]]
					then
						for PH_i in `nawk 'BEGIN { ORS = " " } $6 ~ /^typeset$/ && $7 ~ /^-r$/ && $8 ~ /^PH_/ { print substr($8,0,index($8,"=")) }' $PH_CONF_DIR/$PH_APP.conf`
						do
							printf "%2s%-13s%4s%2s%s\033[32m%s\033[0m\n" "" "(read-only)" "" "$((PH_COUNT))" ". " "$PH_i"
							((PH_COUNT++))
						done
					fi
					printf "%23s\033[32m%s\033[0m\n" "$PH_COUNT. " "All"
					[[ `ps -p $PPID -o comm | tail -n +2` == "startpieh.sh" ]] && printf "%23s\033[32m%s\033[0m\n" "$((PH_COUNT+1)). " "Return to PieHelper menu" || \
								printf "%23s\033[32m%s\033[0m\n" "$((PH_COUNT+1)). " "Exit"
					printf "\n%8s%s" "" "Your choice ? "
					read PH_ANSWER 2>/dev/null
				done
				printf "%10s%s\n" "" "OK"
				printf "%2s%s\n\n" "" "SUCCESS"
				[[ $PH_ANSWER -eq $((PH_COUNT+1)) ]] && unset PH_OPTAR PH_VALAR && exit 0
				if [[ $PH_ANSWER -eq $((PH_COUNT)) ]]
				then
					PH_OPT="all"
				else
					if [[ $PH_ANSWER -le $((PH_COUNT2-1)) ]]
					then
						PH_OPT=`grep ^"PH_" $PH_CONF_DIR/$PH_APP.conf | nawk -F'=' -v choice=$PH_ANSWER 'NR == choice { print $1 }'`
					else
						PH_OPT=$(grep ' typeset -' $PH_CONF_DIR/$PH_APP.conf | \
							nawk -v choice=$((PH_ANSWER-$((PH_COUNT2-1)))) 'NR == choice { print substr($8,0,index($8,"=")) }')
					fi
				fi
				[[ "$PH_RESOLVE" == "yes" ]] && confopts_ph.sh -p get -a "$PH_APP" -o "$PH_OPT" -r || \
					confopts_ph.sh -p get -a "$PH_APP" -o "$PH_OPT"
				printf "\n"
				PH_ANSWER=0
				PH_COUNT=0
				PH_COUNT2=0
			done ;;
				     set)
			while true
			do
				printf "%s\033[36m%s\033[0m\n" "- " "Changing value(s) using interactive mode"
				[[ "$PH_RESOLVE" == "yes" ]] && printf "%8s%s\n\n" "" "--> Which read-write $PH_USE_WORD do you want to change the value of ? (Variable expansion enabled)" || \
							printf "%8s%s\n\n" "" "--> Which read-write $PH_USE_WORD do you want to change the value of ?"
                		while [[ $PH_ANSWER -eq 0 || $PH_ANSWER -gt $((PH_COUNT+1)) ]]
                		do
					[[ $PH_COUNT -gt 0 ]] && printf "\n%70s\033[31m%s\033[0m%s\n\n" "" "ERROR" " : Invalid response"
					PH_COUNT=0
					for PH_i in `nawk -F'=' -v xcpt1=^"PH_PIEH_DEBUG"$ -v xcpt2=^"PH_PIEH_STARTAPP"$ ' \
								$1 ~ /^PH_/ && $1 !~ xcpt1 && $1 !~ xcpt2 { print $1 } { next }' $PH_CONF_DIR/$PH_APP.conf`
					do
						typeset -n PH_OPTVAL="$PH_i"
						PH_ALLOW_VAL="`nawk -F':' -v opt=^\"$PH_i\"$ '$1 ~ opt { print $2 }' $PH_FILES_DIR/options.allowed`"
						[[ -n "$PH_ALLOW_VAL" ]] && PH_ALLOW_VAL="(Allowed values are \"$PH_ALLOW_VAL\")"
						if [[ "$PH_RESOLVE" == "yes" ]]
						then
							PH_OPTVAL=`echo "$PH_OPTVAL" | sed 's/"/\\\"/g'`
							printf "%23s\033[32m%s\033[0m%-100s%s\n" "$((PH_COUNT+1)). " "$PH_i" "='`eval echo -n $PH_OPTVAL`'" "$PH_ALLOW_VAL"
							PH_OPTVAL=`echo "$PH_OPTVAL" | sed 's/\\\"/"/g'`
						else
							printf "%23s\033[32m%s\033[0m%-100s%s\n" "$((PH_COUNT+1)). " "$PH_i" "='`echo -n $PH_OPTVAL`'" "$PH_ALLOW_VAL"
						fi
						((PH_COUNT++))
						unset -n PH_OPTVAL
						PH_ALLOW_VAL=""
					done
					[[ `ps -p $PPID -o comm | tail -n +2` == "startpieh.sh" ]] && printf "%23s\033[32m%s\033[0m\n" "$((PH_COUNT+1)). " "Return to PieHelper menu" || \
								printf "%23s\033[32m%s\033[0m\n" "$((PH_COUNT+1)). " "Exit"
					printf "\n%8s%s" "" "Your choice ? "
					read PH_ANSWER 2>/dev/null
				done
				printf "%10s%s\n" "" "OK"
				[[ $PH_ANSWER -eq $((PH_COUNT+1)) ]] && printf "%2s%s\n\n" "" "SUCCESS" && unset PH_OPTAR PH_VALAR && exit 0
				PH_OPT=`grep ^"PH_" $PH_CONF_DIR/$PH_APP.conf | egrep -v ^"PH_PIEH_DEBUG=|PH_PIEH_STARTAPP=" | nawk -F"=" -v choice=$PH_ANSWER 'NR == choice { print $1 }'`
				[[ "$PH_OPT" == *_NUM_CTRL ]] && (printf "%8s%s\n" "" "--> Displaying additional info for read-write $PH_USE_WORD $PH_OPT : " ; \
							  printf "%10s%s\n\n" "" "OK" ; \
							  ph_print_bannerline ; \
							  printf "\n" ; \
							  printf "%12s%s\n" "" "- Changes to an option that sets the controller amount for an application will automatically be reflected to" ; \
							  printf "%12s%s\n\n" "" "  the option holding that application's command line options if event-based input devices are present as command-line parameters" ; \
							  printf "\n" ; \
							  ph_print_bannerline ; \
							  printf "\n")
				[[ "$PH_OPT" == *_CMD_OPTS ]] && (printf "%8s%s\n" "" "--> Displaying additional info for read-write $PH_USE_WORD $PH_OPT : " ; \
							  printf "%10s%s\n\n" "" "OK" ; \
							  ph_print_bannerline ; \
							  printf "\n" ; \
							  printf "%12s%s\n" "" "- Changes to an option holding an application's command line options where event-based input devices are present will automatically be reflected to" ; \
							  printf "%12s%s\n" "" "  the application's option determining the controller amount unless all event device parameters are being removed")
				[[ "$PH_OPT" == "PH_MOON_CMD_OPTS" ]] && printf "%12s%s\n" "" "  For Moonlight, the number of event-based input devices cannot be zero"
				[[ "$PH_OPT" == *_CMD_OPTS ]] && (printf "%12s%s\n" "" "- Any event-based input device id references in the new value entered for an option holding an application's command line options should have" ; \
							  printf "%12s%s\n\n" "" "  the numeric id replaced by the string 'PH_CTRL%' where '%' is '1' for controller 1, '2' for controller 2, etc" ; \
							  printf "\n" ; \
							  ph_print_bannerline ; \
							  printf "\n")
				printf "%8s%s\033[32m%s\033[0m\n" "" "--> Please enter the new value for read-write $PH_USE_WORD " "'$PH_OPT'"
				printf "%12s%s" "" "('N/A' is a reserved string and cannot be used) : "
				read PH_VALUE 2>/dev/null
				if [[ "$PH_VALUE" == 'N/A' ]]
				then
					printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Cannot accept 'N/A' as a value" 
					printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" && PH_ANSWER=0 && PH_COUNT=0
				else
					printf "%10s%s\n" "" "OK"
					printf "%2s%s\n\n" "" "SUCCESS"
					[[ "$PH_TYPE" == "o" ]] && PH_TYPE="n" || PH_TYPE="m"
					confopts_ph.sh -p set -a "$PH_APP" -"$PH_TYPE" -o "$PH_OPT"="$PH_VALUE" && export "$PH_OPT"="$PH_VALUE"
				fi
				PH_ANSWER=0
				PH_COUNT=0
			done ;;
				    help)
			while true
			do
				printf "%s\033[36m%s\033[0m\n" "- " "Displaying help(s) using interactive mode"
				[[ "$PH_RESOLVE" == "yes" ]] && printf "%8s%s\n\n" "" "--> Which $PH_USE_WORD do you want to display help for ? (Variable expansion enabled)" || \
							printf "%8s%s\n\n" "" "--> Which $PH_USE_WORD do you want to display help for ?"
                		while [[ $PH_ANSWER -eq 0 || $PH_ANSWER -gt $((PH_COUNT+1)) ]]
                		do
					[[ $PH_COUNT -gt 0 ]] && printf "\n%10s\033[31m%s\033[0m%s\n\n" "" "ERROR" " : Invalid response"
					PH_COUNT=1
					PH_COUNT2=$PH_COUNT
					if [[ "$PH_RESOLVE" == "yes" ]]
					then
						if [[ "$PH_DISP_TYPE" == @(rw|all) ]]
						then
							for PH_i in `nawk -F'=' '$1 ~ /^PH_/ { print $1 }' $PH_CONF_DIR/$PH_APP.conf`
							do
								typeset -n PH_OPTVAL="$PH_i"
								PH_OPTVAL=`echo $PH_OPTVAL | sed 's/"/\\\"/g'`
								printf "%2s%-13s%4s%2s%s\033[32m%s\033[0m%s%s\n" "" "(read-write)" "" "$((PH_COUNT))" ". " "$PH_i" "=" "'`eval echo $PH_OPTVAL`'"
								PH_OPTVAL=`echo $PH_OPTVAL | sed 's/\\\"/"/g'`
								((PH_COUNT++))
								unset -n PH_OPTVAL
							done
							((PH_COUNT--))
						fi
						PH_COUNT2=$PH_COUNT
						if [[ "$PH_DISP_TYPE" == @(ro|all) ]]
						then
							[[ "$PH_DISP_TYPE" == "ro" ]] && ((PH_COUNT--))
							for PH_i in `nawk 'BEGIN { ORS = " " } $6 ~ /^typeset$/ && $7 ~ /^-r$/ && $8 ~ /^PH_/ { print substr($8,0,index($8,"=")) }' $PH_CONF_DIR/$PH_APP.conf`
							do
								typeset -n PH_OPTVAL="$PH_i"
								printf "%2s%-13s%4s%2s%s\033[32m%s\033[0m%s%s\n" "" "(read-only)" "" "$((PH_COUNT+1))" ". " "$PH_i" "=" "'$(echo $PH_OPTVAL | sed 's/"/\\\"/g' | eval echo `cat`)'" 
								((PH_COUNT++))
								unset -n PH_OPTVAL
							done
						fi
					else
						if [[ "$PH_DISP_TYPE" == @(rw|all) ]]
						then
							nawk -F'\t' 'BEGIN { count = 1 } $1 ~ /^PH_/ { printf "%2s%-13s%4s%4s\033[32m", "", "(read-write)", "", count ". " ; printf "%s\033[0m", substr($1,0,index($1,"=")) ; print substr($1,index($1,"=")) ; count++ ; next } \
															{ next }' $PH_CONF_DIR/$PH_APP.conf
							PH_COUNT=`nawk -F'\t' 'BEGIN { count = 0 } $1 ~ /^PH_/ { count++ } END { print count }' $PH_CONF_DIR/$PH_APP.conf`
						fi
						PH_COUNT2=$PH_COUNT
						if [[ "$PH_DISP_TYPE" == @(ro|all) ]]
						then
							[[ "$PH_DISP_TYPE" == "ro" ]] && ((PH_COUNT--))
							nawk -v count=$((PH_COUNT+1)) '$6 ~ /^typeset$/ && $7 ~ /^-r$/ && $8 ~ /^PH_/ { printf "%2s%-13s%4s%4s\033[32m", "", "(read-only)", "", count ". " ; printf "%s\033[0m", substr($8,0,index($8,"=")) ; print substr($8,index($8,"=")) ; count++ ; next }' $PH_CONF_DIR/$PH_APP.conf
							PH_COUNT=$((PH_COUNT+`nawk 'BEGIN { count = 0 } $6 ~ /^typeset$/ && $7 ~ /^-r$/ && $8 ~ /^PH_/ { count++ } END { print count }' $PH_CONF_DIR/$PH_APP.conf`))
						fi
					fi
					((PH_COUNT++))
					printf "%23s\033[32m%s\033[0m\n" "$PH_COUNT. " "All"
					[[ `ps -p $PPID -o comm | tail -n +2` == "startpieh.sh" ]] && printf "%23s\033[32m%s\033[0m\n" "$((PH_COUNT+1)). " "Return to PieHelper menu" || \
								printf "%23s\033[32m%s\033[0m\n" "$((PH_COUNT+1)). " "Exit"
					printf "\n%8s%s" "" "Your choice ? "
					read PH_ANSWER 2>/dev/null
				done
				printf "%10s%s\n" "" "OK"
				printf "%2s%s\n\n" "" "SUCCESS"
				[[ $PH_ANSWER -eq $((PH_COUNT+1)) ]] && unset PH_OPTAR PH_VALAR && exit 0
				if [[ $PH_ANSWER -eq $PH_COUNT ]]
				then
					PH_OPT="all"
					[[ "$PH_DISP_TYPE" == "all" ]] && confopts_ph.sh -p help -a "$PH_APP" -o "$PH_OPT" || confopts_ph.sh -p help -a "$PH_APP" -o "$PH_OPT" -t "$PH_DISP_TYPE"
				else
					if [[ $PH_ANSWER -le $PH_COUNT2 ]]
					then
						PH_OPT=`grep ^"PH_" $PH_CONF_DIR/$PH_APP.conf | nawk -F'=' -v choice=$PH_ANSWER 'NR==choice { print $1 }'`
					else
						PH_OPT=$(if [[ "$PH_DISP_TYPE" == "all" ]]
							 then
							 	grep ' typeset -' $PH_CONF_DIR/$PH_APP.conf | \
								nawk -v choice=$((PH_ANSWER-$PH_COUNT2)) 'NR == choice { print substr($8,0,index($8,"=")) }'
							 else
							 	grep ' typeset -' $PH_CONF_DIR/$PH_APP.conf | \
								nawk -v choice=$PH_ANSWER 'NR == choice { print substr($8,0,index($8,"=")) }'
							fi)
					fi
					confopts_ph.sh -p help -a "$PH_APP" -o "$PH_OPT"
				fi
				PH_ANSWER=0
				PH_COUNT=0
				PH_COUNT2=0
			done ;;
		esac ;;
esac
(! confopts_ph.sh -h) && unset PH_OPTAR PH_VALAR && exit 1
