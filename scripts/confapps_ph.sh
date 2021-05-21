#!/bin/bash
# Run application management routines (by Davy Keppens on 03/11/2018)
# Enable/Disable debug by running 'confpieh_ph.sh -p debug -m confapps_ph.sh'

if [[ -f "$(dirname "$0" 2>/dev/null)/app/main.sh" && -r "$(dirname "$0" 2>/dev/null)/app/main.sh" ]]
then
	source "$(dirname "$0" 2>/dev/null)/app/main.sh"
	set +x
else
	printf "\n%2s\033[1;31m%s\033[0;0m\n\n" "" "ABORT : Reinstallation of PieHelper is required (Missing or unreadable critical codebase file '$(dirname "$0" 2>/dev/null)/app/main.sh'"
	exit 1
fi

#set -x

declare PH_i=""
declare PH_ACTION=""
declare PH_APP=""
declare PH_LIST=""
declare PH_KEYWORD=""
declare PH_DISP_HELP=""
declare PH_ROUTINE_OPTS=""
declare PH_APP_SCOPE=""
declare PH_APP_STR_TTY=""
declare PH_OLDOPTARG="$OPTARG"
declare -i PH_OLDOPTIND="$OPTIND"
declare -i PH_ALL_FLAG="1"
declare -i PH_RET_CODE="0"

OPTIND="1"
declare -ix PH_ROUTINE_DEPTH="0"
declare -ix PH_SKIP_DEPTH_MEMBERS="0"
declare -ix PH_ROUTINE_FLAG="1"

while getopts p:k:a:t:s:l:o:dh PH_OPTION 2>/dev/null
do
	case "$PH_OPTION" in p)
		[[ -n "$PH_ACTION" ]] && (! confapps_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND="$PH_OLDOPTIND" && exit 1
		[[ "$OPTARG" != @(list|tty|info|sup|unsup|int|unint|inst|uninst|conf|update|move|start|mk_conf|mk_defaults|mk_alloweds|mk_menus|mk_scripts|mk_dir|mk_all|rm_conf|rm_defaults|rm_alloweds|rm_menus|rm_scripts|rm_dir|rm_all) ]] && \
			(! confapps_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND="$PH_OLDOPTIND" && exit 1
		PH_ACTION="$OPTARG" ;;
			   k)
		[[ -n "$PH_KEYWORD" ]] && (! confapps_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND="$PH_OLDOPTIND" && exit 1
		[[ "$OPTARG" != @(def|sup|int|halt|run|start|all) ]] && (! confapps_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND="$PH_OLDOPTIND" && exit 1
		PH_KEYWORD="$OPTARG" ;;
			   l)
		[[ -n "$PH_LIST" ]] && (! confapps_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND="$PH_OLDOPTIND" && exit 1
		for PH_i in $(sed 's/,/ /g' <<<"$OPTARG")
		do
			[[ "$PH_i" != @(def|sup|int|halt|run|start|all) ]] && (! confapps_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND="$PH_OLDOPTIND" && exit 1
			[[ "$PH_i" == "all" ]] && PH_ALL_FLAG="0"
		done
		PH_LIST="$OPTARG" ;;
			   d)
		[[ -n "$PH_DISP_HELP" ]] && (! confapps_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND="$PH_OLDOPTIND" && exit 1
		PH_DISP_HELP="yes" ;;
			   o)
		[[ -n "$PH_ROUTINE_OPTS" ]] && (! confapps_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND="$PH_OLDOPTIND" && exit 1
		PH_ROUTINE_OPTS="$OPTARG" ;;
			   s)
		[[ -n "$PH_APP_SCOPE" ]] && (! confapps_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND="$PH_OLDOPTIND" && exit 1
		[[ "$OPTARG" != @(def|oos|all) ]] && (! confapps_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND="$PH_OLDOPTIND" && exit 1
		PH_APP_SCOPE="$OPTARG" ;;
			   a)
		[[ -n "$PH_APP" ]] && (! confapps_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND="$PH_OLDOPTIND" && exit 1
		PH_APP="$OPTARG" ;;
			   t)
                ! ph_screen_input "$OPTARG" && OPTARG="$PH_OLDOPTARG" && OPTIND="$PH_OLDOPTIND" && exit 1
		[[ -n "$PH_APP_STR_TTY" ]] && (! confapps_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND="$PH_OLDOPTIND" && exit 1
		[[ "$OPTARG" != @(+([[:digit:]])|prompt) ]] && (! confapps_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND="$PH_OLDOPTIND" && exit 1
		PH_APP_STR_TTY="$OPTARG" ;;
			   *)
		>&2 printf "\n"
		>&2 printf "\033[36m%s\033[0m\n" "Usage : confapps_ph.sh -h |"
		>&2 printf "%23s\033[36m%s\033[0m\n" "" "-p [\"list\"|\"tty\"|\"info\"|\"sup\"|\"unsup\"|\"int\"|\"unint\"|\"inst\"|\"uninst\"|\"conf\"|\"update\"|\"move\"] \\"
		>&2 printf "%23s\033[36m%s\033[0m\n" "" "   ['-s [\"def\"|\"oos\"|\"all\"]'[-k [keyword]|-l [[keyword],[keyword],...]|-a [appname]] '-o [\"'\"[option1] [option2] ...\"'\"]'|-d] |"
		>&2 printf "%23s\033[36m%s\033[0m\n" "" "-p [\"mk_conf\"|\"mk_defaults\"|\"mk_alloweds\"|\"mk_menus\"|\"mk_scripts\"|\"mk_dir\"|\"mk_all\"|\"rm_conf\"|\"rm_defaults\"|\"rm_alloweds\"|\"rm_menus\"|\"rm_scripts\"|\"rm_dir\"|\"rm_all\"] \\"
		>&2 printf "%23s\033[36m%s\033[0m\n" "" "   ['-s [\"def\"|\"oos\"|\"all\"]' [-k [keyword]|-l [[keyword],[keyword],...]|-a [appname]|\"Ctrls\"]] '-o [\"'\"[option1] [option2] ...\"'\"]'|-d] |"
		>&2 printf "%23s\033[36m%s\033[0m\n" "" "-p [\"start\"] ['-s [\"def\"|\"oos\"|\"all\"]' [-k [keyword]|-l [[keyword],[keyword],...]|-a [appname|\"none\"|\"prompt\"]] '-o [\"'\"[option1] [option2] ...\"'\"]'|-d]"
		>&2 printf "\n"
		>&2 printf "%3s%s\n" "" "Where -h displays this usage"
		>&2 printf "%9s%s\n" "" "- Applications can be selected by one of the following options :"
		>&2 printf "%12s%s\n" "" "-a allows selecting an application named [appname]"
		>&2 printf "%15s%s\n" "" "- Routines starting with either 'mk_' or 'rm_' can use keyword 'Ctrls' to select the items for controller settings"
		>&2 printf "%15s%s\n" "" "- Routine 'start' can use keyword 'prompt' or keyword 'none' to respectively make the routine behave interactively or remove the current 'StartApp' configuration"
		>&2 printf "%12s%s\n" "" "-k allows the use of supported keywords to select a single application or application groups"
		>&2 printf "%15s%s\n" "" "- Overall supported keywords are :"
		>&2 printf "%18s%s\n" "" "\"sup\" selects all applications supported by PieHelper"
		>&2 printf "%21s%s\n" "" "\"int\" selects all applications integrated with PieHelper"
		>&2 printf "%24s%s\n" "" "- An 'Integrated' application is always 'Supported'"
		>&2 printf "%21s%s\n" "" "\"def\" selects all 'Default' applications"
		>&2 printf "%21s%s\n" "" "\"halt\" selects all non-active integrated applications that have an allocated TTY"
		>&2 printf "%24s%s\n" "" "- A 'Halted' application is always 'Supported' and 'Integrated' and has an allocated TTY"
		>&2 printf "%21s%s\n" "" "\"run\" selects all active integrated applications that have an allocated TTY"
		>&2 printf "%24s%s\n" "" "- A 'Running' application is always 'Supported' and 'Integrated' and has an allocated TTY"
		>&2 printf "%21s%s\n" "" "\"start\" selects the application currently configured as 'StartApp'"
		>&2 printf "%24s%s\n" "" "- The 'StartApp' is always 'Supported' and 'Integrated'"
		>&2 printf "%21s%s\n" "" "\"all\" is equivalent to '-l \"def sup int halt run start\"'"
		>&2 printf "%18s%s\n" "" "- Any applications in a state not selected by any of the above keywords are in state 'Unknown'"
		>&2 printf "%12s%s\n" "" "-l allows specifying a comma-separated list of multiple supported keywords"
		>&2 printf "%15s%s\n" "" "- Keyword 'all' cannot be combined with other keywords when using lists"
		>&2 printf "%12s%s\n" "" "- Options '-a', '-k' and '-l' are mutually exclusive"
		>&2 printf "%12s%s\n" "" "- Applications can be selected more than once"
		>&2 printf "%9s%s\n" "" "-s allows applying an additional scope filter when selecting applications"
		>&2 printf "%12s%s\n" "" "- Applying a scope filter is optional"
		>&2 printf "%12s%s\n" "" "- Not applying a scope filter will use default scope 'all'"
		>&2 printf "%12s%s\n" "" "\"def\" allows applying a filter of 'Default' applications"
		>&2 printf "%15s%s\n" "" "- 'Default' applications are applications with additional support and features embedded in the PieHelper framework"
		>&2 printf "%12s%s\n" "" "\"oos\" allows applying a filter of 'Out-of-scope' applications"
		>&2 printf "%15s%s\n" "" "- 'Out-of-scope' applications are all applications which are not 'Default'"
		>&2 printf "%12s%s\n" "" "\"all\" allows applying a filter of 'all' applications"
		>&2 printf "%15s%s\n" "" "- Both 'Out-of-scope' and 'Default' applications will be selected"
		>&2 printf "%9s%s\n" "" "-p specifies the application routine to run for each selection made"
		>&2 printf "%12s%s\n" "" "\"list\" allows listing all selections"
		>&2 printf "%15s%s\n" "" "- Selected applications with state 'Unknown' will be skipped"
		>&2 printf "%15s%s\n" "" "- The install state will be displayed for all selections except when selected by keyword 'def'"
		>&2 printf "%12s%s\n" "" "\"tty\" allows displaying the allocated TTY of all selections"
		>&2 printf "%15s%s\n" "" "- Selected applications with state 'Unknown', 'Supported' or 'Integrated' will be skipped"
		>&2 printf "%12s%s\n" "" "\"info\" allows displaying information for all selections"
		>&2 printf "%15s%s\n" "" "- Selected applications with state 'Unknown' will be skipped"
		>&2 printf "%12s%s\n" "" "\"sup\" allows adding support for all selections"
		>&2 printf "%15s%s\n" "" "- Selected applications with state 'Supported', 'Integrated', 'Halted' or 'Running' will be skipped"
		>&2 printf "%15s%s\n" "" "- Empty configuration routines for end-user development will be created in '$PH_MAIN_DIR/functions.user' for selected 'Out-of-scope' applications"
		>&2 printf "%12s%s\n" "" "\"unsup\" allows removing support for all selections"
		>&2 printf "%15s%s\n" "" "- Selected applications with state 'Unknown', 'Integrated', 'Halted' or 'Running' will be skipped"
		>&2 printf "%15s%s\n" "" "- 'PieHelper' will always be skipped and should be unsupported using 'confpieh_ph.sh -u'"
		>&2 printf "%15s%s\n" "" "- Empty configuration routines for selected 'Out-of-scope' applications in '$PH_MAIN_DIR/functions.update' will be removed"
		>&2 printf "%12s%s\n" "" "\"int\" allows adding integration for all selections"
		>&2 printf "%15s%s\n" "" "- Selected applications with state 'Unknown', 'Integrated', 'Halted' or 'Running' will be skipped"
		>&2 printf "%12s%s\n" "" "\"unint\" allows removing integration for all selections"
		>&2 printf "%15s%s\n" "" "- Selected applications with state 'Unknown', 'Supported', or 'Running' will be skipped"
		>&2 printf "%15s%s\n" "" "- 'PieHelper' will always be skipped and should be unintegrated using 'confpieh_ph.sh -u'"
		>&2 printf "%12s%s\n" "" "\"inst\" allows installing all selections"
		>&2 printf "%15s%s\n" "" "- Selected applications with state 'Supported', 'Integrated', 'Halted' or 'Running' will be skipped"
		>&2 printf "%15s%s\n" "" "- 'Moonlight' and 'Emulationstation' will attempt Packageless installation if the packagename is unset or invalid"
		>&2 printf "%12s%s\n" "" "\"uninst\" allows uninstalling all selections"
		>&2 printf "%15s%s\n" "" "- Selected applications with state 'Supported', 'Integrated', 'Halted' or 'Running' will be skipped"
		>&2 printf "%15s%s\n" "" "- 'Moonlight' and 'Emulationstation' will attempt Packageless uninstallation if the packagename is unset or invalid"
		>&2 printf "%12s%s\n" "" "\"update\" allows updating all selections"
		>&2 printf "%15s%s\n" "" "- Selected applications with state 'Unknown' or 'Running' will be skipped"
		>&2 printf "%12s%s\n" "" "\"conf\" allows configuring all selections"
		>&2 printf "%15s%s\n" "" "- When selected, applications with state 'Running' and applications with state 'Unknown' other than 'PieHelper' will be skipped"
		>&2 printf "%15s%s\n" "" "- Configuration routines for selected 'Out-of-scope' applications require end-user development to operate"
		>&2 printf "%12s%s\n" "" "\"move\" allows moving all selections from their allocated TTY to another available TTY"
		>&2 printf "%15s%s\n" "" "- Selected applications with state 'Unknown', 'Supported' or 'Integrated' will be skipped"
		>&2 printf "%15s%s\n" "" "- 'PieHelper' will always be skipped"
		>&2 printf "%15s%s\n" "" "- Selected applications with state 'Running' will first be stopped and automatically be restarted after a successful move operation"
		>&2 printf "%15s%s\n" "" "-t allows specifying a numeric TTY value for [movetty]"
		>&2 printf "%18s%s\n" "" "- Specifying a new TTY number is optional"
		>&2 printf "%18s%s\n" "" "- Not specifying a value will use the first available TTY"
		>&2 printf "%18s%s\n" "" "- Using the keyword 'prompt' will make 'confapps_ph.sh' behave interactively when it comes to new TTY number selection"
		>&2 printf "%21s%s\n" "" "- The following info will be prompted for during interactive TTY number selection :"
		>&2 printf "%24s%s\n" "" "- The numeric TTY value for [movetty]"
		>&2 printf "%12s%s\n" "" "\"start\" allows configuring selections as 'StartApp'"
		>&2 printf "%15s%s\n" "" "- Selected applications with state 'Unknown' or 'Supported' will be skipped"
		>&2 printf "%15s%s\n" "" "- The 'StartApp' is the application to start at system boot"
		>&2 printf "%12s%s\n" "" "\"mk_conf\" allows creating a new default config file for all selections"
		>&2 printf "%15s%s\n" "" "- Selected applications with state 'Running' will be skipped"
		>&2 printf "%15s%s\n" "" "- Configuration files will be saved in '$PH_CONF_DIR' as '[appname].conf'"
		>&2 printf "%15s%s\n" "" "- Existing configuration files will be overwritten"
		>&2 printf "%12s%s\n" "" "\"mk_defaults\" allows creating default entries for default option values for all selections"
		>&2 printf "%15s%s\n" "" "- Selected applications with state 'Running' will be skipped"
		>&2 printf "%15s%s\n" "" "- Entries for [appname] will be created in '$PH_CONF_DIR/options.defaults'"
		>&2 printf "%15s%s\n" "" "- Existing entries will be removed before new items are created"
		>&2 printf "%12s%s\n" "" "\"mk_alloweds\" allows creating default entries for allowed option values for all selections"
		>&2 printf "%15s%s\n" "" "- Selected applications with state 'Running' will be skipped"
		>&2 printf "%15s%s\n" "" "- Entries for [appname] will be created in '$PH_CONF_DIR/options.defaults'"
		>&2 printf "%15s%s\n" "" "- Existing entries will be removed before new items are created"
		>&2 printf "%12s%s\n" "" "\"mk_menus\" allows creating default menu items for all selections"
		>&2 printf "%15s%s\n" "" "- Selected applications with state 'Running' will be skipped"
		>&2 printf "%15s%s\n" "" "- Menu items for [appname] will be created in '$PH_MENUS_DIR'"
		>&2 printf "%15s%s\n" "" "- Existing menu items will be overwritten"
		>&2 printf "%15s%s\n" "" "- 'PieHelper' will always be skipped"
		>&2 printf "%12s%s\n" "" "\"mk_scripts\" allows creating default management scripts for all selections"
		>&2 printf "%15s%s\n" "" "- Selected applications with state 'Unknown' or 'Running' will be skipped"
		>&2 printf "%15s%s\n" "" "- Management scripts for [appname] will be created in '$PH_SCRIPTS_DIR'"
		>&2 printf "%15s%s\n" "" "- Existing management scripts for [appname] will be overwritten"
		>&2 printf "%12s%s\n" "" "\"mk_dir\" allows creating the CIFS mountpoint directory for all selections"
		>&2 printf "%15s%s\n" "" "- Selected applications with state 'Unknown' or 'Running' will be skipped"
		>&2 printf "%15s%s\n" "" "- Selected applications with a non-default CIFS mountpoint configured will be skipped"
		>&2 printf "%15s%s\n" "" "- Default CIFS mountpoints will be created in '$PH_MNT_DIR'"
		>&2 printf "%15s%s\n" "" "- In case the mountpoint already exists, it will first be removed"
		>&2 printf "%12s%s\n" "" "\"mk_all\" is equivalent to running this script multiple times for each selection successively using"
		>&2 printf "%15s%s\n" "" "- one of the following options in the order specified below for 'Integrated' applications :"
		>&2 printf "%18s%s\n" "" "- \"mk_conf\", \"mk_alloweds\", \"mk_defaults\", \"mk_menus\", \"mk_scripts\" or \"mk_dir\""
		>&2 printf "%15s%s\n" "" "- one of the following options in the order specified below for non-'Integrated' applications :"
		>&2 printf "%18s%s\n" "" "- \"mk_conf\", \"mk_alloweds\", \"mk_defaults\" or \"mk_menus\""
		>&2 printf "%12s%s\n" "" "\"rm_conf\" allows removing the configuration file for all selections"
		>&2 printf "%15s%s\n" "" "- Selected applications with state 'Unknown' or 'Running' will be skipped"
		>&2 printf "%15s%s\n" "" "- Configuration file '[appname].conf' will be removed from '$PH_CONF_DIR'"
		>&2 printf "%15s%s\n" "" "- This will automatically disable PieHelper sanity checks"
		>&2 printf "%12s%s\n" "" "\"rm_defaults\" allows removing entries for default option values for all selections"
		>&2 printf "%15s%s\n" "" "- Selected applications with state 'Unknown' or 'Running' will be skipped"
		>&2 printf "%15s%s\n" "" "- Entries for [appname] will be removed from '$PH_CONF_DIR/options.defaults'"
		>&2 printf "%15s%s\n" "" "- This will automatically disable PieHelper sanity checks"
		>&2 printf "%12s%s\n" "" "\"rm_alloweds\" allows removing entries for allowed option values for all selections"
		>&2 printf "%15s%s\n" "" "- Selected applications with state 'Unknown' or 'Running' will be skipped"
		>&2 printf "%15s%s\n" "" "- Entries for [appname] will be removed from '$PH_CONF_DIR/options.defaults'"
		>&2 printf "%15s%s\n" "" "- This will automatically disable PieHelper sanity checks"
		>&2 printf "%12s%s\n" "" "\"rm_menus\" allows removing default menu items for all selections"
		>&2 printf "%15s%s\n" "" "- Selected applications with state 'Unknown' or 'Running' will be skipped"
		>&2 printf "%15s%s\n" "" "- Menu items for [appname] will be removed from '$PH_MENUS_DIR'"
		>&2 printf "%15s%s\n" "" "- 'PieHelper' will always be skipped"
		>&2 printf "%15s%s\n" "" "- This will automatically disable PieHelper sanity checks"
		>&2 printf "%12s%s\n" "" "\"rm_scripts\" allows removing default management scripts for all selections"
		>&2 printf "%15s%s\n" "" "- Selected applications with state 'Unknown', 'Supported' or 'Running' will be skipped"
		>&2 printf "%15s%s\n" "" "- Management scripts for [appname] will be removed from '$PH_SCRIPTS_DIR'"
		>&2 printf "%15s%s\n" "" "- This will automatically disable PieHelper sanity checks"
		>&2 printf "%12s%s\n" "" "\"rm_dir\" allows removing the CIFS mountpoint directory for all selections"
		>&2 printf "%15s%s\n" "" "- Selected applications with state 'Unknown', 'Supported' or 'Running' will be skipped"
		>&2 printf "%15s%s\n" "" "- Selected applications with a non-default CIFS mountpoint configured will be skipped"
		>&2 printf "%15s%s\n" "" "- Default CIFS mountpoints will be removed from '$PH_MNT_DIR'"
		>&2 printf "%15s%s\n" "" "- This will automatically disable PieHelper sanity checks"
		>&2 printf "%12s%s\n" "" "\"rm_all\" is equivalent to running this script multiple times for each selection successively using"
		>&2 printf "%15s%s\n" "" "- one of the following options in the order specified below for 'Integrated' applications :"
		>&2 printf "%18s%s\n" "" "- \"rm_dir\", \"rm_scripts\", \"rm_menus\", \"rm_defaults\", \"rm_alloweds\" or \"rm_conf\""
		>&2 printf "%15s%s\n" "" "- one of the following options in the order specified below for non-'Integrated' applications :"
		>&2 printf "%18s%s\n" "" "- \"rm_menus\", \"rm_defaults\", \"rm_alloweds\" or \"rm_conf\""
		>&2 printf "%9s%s\n" "" "-o allows passing a single-quoted list of space-separated options to pass to a specific routine"
		>&2 printf "%12s%s\n" "" "- Passing a routine option list is optional"
		>&2 printf "%9s%s\n" "" "-d allows displaying a list of all possible options that can be passed to a specific routine using '-o'"
		>&2 printf "\n"
		OPTARG="$PH_OLDOPTARG"
		OPTIND="$PH_OLDOPTIND"
		exit 1 ;;
	esac
done
OPTARG="$PH_OLDOPTARG"
OPTIND="$PH_OLDOPTIND"

[[ -z "$PH_ACTION" ]] && (! confapps_ph.sh -h) && exit 1
if [[ -n "$PH_DISP_HELP" ]] && [[ -n "$PH_LIST" || -n "$PH_KEYWORD" || -n "$PH_APP" || -n "$PH_APP_SCOPE" || -n "$PH_ROUTINE_OPTS" ]]
then
	confapps_ph.sh -h
	exit 1
fi
if [[ -n "$PH_LIST" ]] && [[ -n "$PH_KEYWORD" || -n "$PH_APP" ]]
then
	confapps_ph.sh -h
	exit 1
fi
[[ -n "$PH_KEYWORD" && -n "$PH_APP" ]] && (! confapps_ph.sh -h) && exit 1
[[ "$PH_ALL_FLAG" -eq "0" && "$(echo -n "$PH_LIST" | nawk -F',' 'END { printf NF }')" -gt "1" ]] && (! confapps_ph.sh -h) && exit 1
if [[ "$PH_ACTION" == "list" && "$PH_KEYWORD" == "def" ]] && [[ -n "$PH_APP_SCOPE" && "$PH_APP_SCOPE" != "all" ]]
then
	PH_APP_SCOPE="all"
fi
[[ "$PH_ACTION" == "start" && "$PH_KEYWORD" == "start" ]] && (! confapps_ph.sh -h) && exit 1
[[ "$PH_ACTION" != @(mk_|rm_)* && "$PH_APP" == "Ctrls" ]] && (! confapps_ph.sh -h) && exit 1
[[ "$PH_ACTION" != "move" && -n "$PH_APP_STR_TTY" ]] && (! confapps_ph.sh -h) && exit 1
[[ "$PH_ACTION" != "start" && "$PH_APP" == @(none|prompt) ]] && (! confapps_ph.sh -h) && exit 1
[[ "$PH_LIST" == "all" || "$PH_KEYWORD" == "all" ]] && PH_LIST="def,sup,int,run,halt,start" && PH_KEYWORD=""
if [[ -n "$PH_APP" ]]
then
	case "$PH_ACTION" in list|info|unsup|int|uninst|update|mk_scripts|mk_dir|rm_conf|rm_defaults|rm_alloweds|rm_menus|rm_all)
			PH_KEYWORD="sup" ;;
		  	     tty|unint|conf|move|start|rm_scripts|rm_dir)
			PH_KEYWORD="int" ;;
		  	     sup|inst|mk_conf|mk_defaults|mk_alloweds|mk_menus|mk_all)
			PH_KEYWORD="unk" ;;
	esac
fi
printf "\n"
if [[ -n "$PH_ROUTINE_OPTS" ]]
then
	case "$PH_ACTION" in list|info|conf|update|start|tty|mk_*|rm_*|inst|uninst)
					PH_RET_CODE="1" ;;
			     sup)
					for PH_i in $(echo -n "$PH_ROUTINE_OPTS")
					do
						[[ "$PH_i" != -* ]] && continue
						[[ "$PH_i" != @(-c|-s|-p) ]] && PH_RET_CODE="1"
					done ;;
			     unsup)
					for PH_i in $(echo -n "$PH_ROUTINE_OPTS")
					do
						[[ "$PH_i" != -* ]] && continue
						[[ "$PH_i" != @(-c|-s) ]] && PH_RET_CODE="1"
					done ;;
			     int)
					for PH_i in $(echo -n "$PH_ROUTINE_OPTS")
					do
						[[ "$PH_i" != -* ]] && continue
						[[ "$PH_i" != @(-u|-t) ]] && PH_RET_CODE="1"
					done ;;
			     unint)
					for PH_i in $(echo -n "$PH_ROUTINE_OPTS")
					do
						[[ "$PH_i" != -* ]] && continue
						[[ "$PH_i" != @(-u|-s|-t) ]] && PH_RET_CODE="1"
					done ;;
			     move)
					for PH_i in $(echo -n "$PH_ROUTINE_OPTS")
					do
						[[ "$PH_i" != -* ]] && continue
						[[ "$PH_i" != "-t" ]] && PH_RET_CODE="1"
					done ;;
	esac
	if [[ "$PH_RET_CODE" -eq "1" ]]
	then
		printf "\033[36m%s\033[0m\n" "- Executing '$PH_ACTION' routine"
		ph_set_result -r "$PH_RET_CODE" -m "Unsupported option passed to routine '$PH_ACTION'"
		ph_show_result
		exit "$?"
	fi
fi
[[ -z "$PH_APP_SCOPE" ]] && PH_APP_SCOPE="all"
[[ "$PH_APP_SCOPE" == "oos" ]] && PH_APP_SCOPE="Out-of-scope"
[[ "$PH_APP_SCOPE" == "def" ]] && PH_APP_SCOPE="Default"
if [[ -n "$PH_ACTION" ]]
then
	if [[ -n "$PH_DISP_HELP" ]]
	then
		printf "\033[36m%s\033[0m\n\n" "- Displaying '$PH_ACTION' routine allowed option(s)"
		case "$PH_ACTION" in list|info|conf|update|start|tty|mk_*|rm_*|inst|uninst)
						printf "%4s%s\n" "" "None" ;;
				     sup)
						printf "%4s%-35s%s\n" "" "-c \"application start command\" " ": double-quoted complete start command for the application"
						ph_set_result -r "$?"
						printf "%4s%-35s%s\n" "" "-s [\"Packaged\"|\"Packageless\"] " ": application install state"
						ph_set_result -r "$?"
						printf "%4s%-35s%s\n" "" "-p \"application package\" " ": application package name" ;;
				     unsup)
						printf "%4s%-35s%s\n" "" "-c \"application start command\" " ": double-quoted complete start command for the application"
						ph_set_result -r "$?"
						printf "%4s%-35s%s\n" "" "-s [\"Packaged\"|\"Packageless\"] " ": application install state" ;;
				     int)
						printf "%4s%-35s%s\n" "" "-u \"application run account\" " ": account the application should run as"
						ph_set_result -r "$?"
						printf "%4s%-35s%s\n" "" "-t \"application tty\" " ": tty number to allocate to the application" ;;
				     unint)
						printf "%4s%-35s%s\n" "" "-u \"application run account\" " ": account the application runs as"
						ph_set_result -r "$?"
						printf "%4s%-35s%s\n" "" "-s [\"Packaged\"|\"Packageless\"] " ": application install state"
						ph_set_result -r "$?"
						printf "%4s%-35s%s\n" "" "-t \"application tty\" " ": tty number allocated to the application" ;;
				     move)
						printf "%4s%-35s%s\n" "" "-t \"new application tty\" " ": new tty number to allocate to the application" ;;
		esac
		ph_set_result -r "$?"
		ph_show_result
		exit "$?"
	else
		if [[ "$PH_ACTION" == rm_* && "$PH_PIEH_SANITY" == "yes" ]]
		then
			confopts_ph.sh -p set -a PieHelper -o PH_PIEH_SANITY='no' || exit "$?"
			ph_set_result -t -r "$?"
		fi
		if [[ "$PH_ACTION" == @(rm_conf|mk_conf) ]]
		then
			printf "\033[36m%s\033[0m\n\n" "- Storing current option values"
			if ! ph_store_all_options_value
			then
				ph_set_result -r 1 -m "An error occurred storing current option values" 
				ph_show_result
				ph_set_result -t -r "$?"
				ph_show_result -t
				exit "$?"
			else
				ph_set_result -r 0
				ph_show_result
				ph_set_result -t -r "$?"
			fi
		fi
		if [[ -n "$PH_LIST" ]]
		then
			ph_do_app_routine -p "$PH_ACTION" -l "$PH_LIST" -s "$PH_APP_SCOPE"
		else
			if [[ -z "$PH_APP" ]]
			then
				ph_do_app_routine -p "$PH_ACTION" -k "$PH_KEYWORD" -s "$PH_APP_SCOPE" -o "$PH_ROUTINE_OPTS"
			else
				ph_do_app_routine -p "$PH_ACTION" -a "$PH_APP" -k "$PH_KEYWORD" -s "$PH_APP_SCOPE" -o "$PH_ROUTINE_OPTS"
			fi
		fi
		PH_RET_CODE="$?"
		if [[ "$PH_ACTION" == "mk_conf" && "$PH_RET_CODE" -eq "0" ]]
		then
			if ! ph_restore_all_options_value
			then
				printf "\033[36m%s\033[0m\n\n" "- Restoring option values"
				ph_set_result -r 1 -m "An error occurred resstoring option values"
				ph_show_result
				PH_RET_CODE="$?"
			fi
		fi
		exit "$PH_RET_CODE"
	fi
fi
confapps_ph.sh -h || exit "$?"
