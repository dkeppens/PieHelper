#!/bin/bash
# Run application management routines (by Davy Keppens on 03/11/2018)
# Enable/Disable debug by running 'confpieh_ph.sh -p debug -m confapps_ph.sh'

if [[ -f "$(dirname "${0}" 2>/dev/null)/app/main.sh" && -r "$(dirname "${0}" 2>/dev/null)/app/main.sh" ]]
then
	source "$(dirname "${0}" 2>/dev/null)/app/main.sh"
	set +x
else
	printf "\n%2s\033[1;31m%s\033[0;0m\n\n" "" "ABORT : Reinstallation of PieHelper is required (Missing or unreadable critical codebase file '$(dirname "${0}" 2>/dev/null)/app/main.sh'"
	exit 1
fi

#set -x

declare PH_i
declare PH_APP
declare PH_APP_SCOPE
declare PH_APP_STR_TTY
declare PH_ACTION
declare PH_LIST
declare PH_KEYWORD
declare PH_DISP_HELP
declare PH_ROUTINE_OPTS
declare PH_OPTION
declare PH_OLDOPTARG
declare -i PH_OLDOPTIND
declare -i PH_RET_CODE

declare -ix PH_ROUTINE_DEPTH
declare -ix PH_SKIP_DEPTH_MEMBERS
declare -ix PH_ROUTINE_FLAG

PH_OLDOPTARG="${OPTARG}"
PH_OLDOPTIND="${OPTIND}"
PH_i=""
PH_APP=""
PH_APP_SCOPE=""
PH_APP_STR_TTY=""
PH_ACTION=""
PH_LIST=""
PH_KEYWORD=""
PH_DISP_HELP=""
PH_ROUTINE_OPTS=""
PH_OPTION=""
PH_RET_CODE="0"

OPTIND="1"
PH_ROUTINE_DEPTH="0"
PH_SKIP_DEPTH_MEMBERS="0"
PH_ROUTINE_FLAG="1"

while getopts :p:k:a:t:s:l:o:dh PH_OPTION
do
	case "${PH_OPTION}" in p)
		[[ -n "${PH_ACTION}" || ( "${OPTARG}" != @(inst|uninst|sup|unsup|int|unint|conf|unconf|start|unstart|update|move|list|info|tty) && \
			"${OPTARG}" != @(mk|rm)_@(conf|defaults|alloweds|menus|scripts|cifs_mpt|all) ) ]] && \
			(! confapps_ph.sh -h) && \
			OPTARG="${PH_OLDOPTARG}" && \
			OPTIND="${PH_OLDOPTIND}" && \
			exit 1
		PH_ACTION="${OPTARG}" ;;
			   k)
		[[ -n "${PH_KEYWORD}" || "${OPTARG}" != @(def|sup|int|hal|run|str|all) ]] && \
			(! confapps_ph.sh -h) && \
			OPTARG="${PH_OLDOPTARG}" && \
			OPTIND="${PH_OLDOPTIND}" && \
			exit 1
		PH_KEYWORD="${OPTARG}" ;;
			   a)
		[[ -n "${PH_APP}" || -z "${OPTARG}" ]] && \
			(! confapps_ph.sh -h) && \
			OPTARG="${PH_OLDOPTARG}" && \
			OPTIND="${PH_OLDOPTIND}" && \
			exit 1
		PH_APP="${OPTARG}" ;;
			   t)
		[[ -n "${PH_APP_STR_TTY}" || "${OPTARG}" != @(+([[:digit:]])|prompt) ]] && \
			(! confapps_ph.sh -h) && \
			OPTARG="${PH_OLDOPTARG}" && \
			OPTIND="${PH_OLDOPTIND}" && \
			exit 1
		PH_APP_STR_TTY="${OPTARG}" ;;
			   s)
		[[ -n "${PH_APP_SCOPE}" || "${OPTARG}" != @(oos|def|inst|uninst|pkg|unpkg|PI|PU|UI|UU) ]] && \
			(! confapps_ph.sh -h) && \
			OPTARG="${PH_OLDOPTARG}" && \
			OPTIND="${PH_OLDOPTIND}" && \
			exit 1
		PH_APP_SCOPE="${OPTARG}" ;;
			   l)
		[[ -n "${PH_LIST}" || -z "${OPTARG}" ]] && \
			(! confapps_ph.sh -h) && \
			OPTARG="${PH_OLDOPTARG}" && \
			OPTIND="${PH_OLDOPTIND}" && \
			exit 1
		for PH_i in ${OPTARG//,/ }
		do
			if [[ "${PH_i}" != @(def|sup|int|hal|run|str|all) ]]
			then
				(! confapps_ph.sh -h)
				OPTARG="${PH_OLDOPTARG}"
				OPTIND="${PH_OLDOPTIND}"
				exit 1
			fi
		done
		PH_LIST="${OPTARG}" ;;
			   o)
		[[ -n "${PH_ROUTINE_OPTS}" || -z "${OPTARG}" ]] && \
			(! confapps_ph.sh -h) && \
			OPTARG="${PH_OLDOPTARG}" && \
			OPTIND="${PH_OLDOPTIND}" && \
			exit 1
		PH_ROUTINE_OPTS="${OPTARG}" ;;
			   d)
		[[ -n "${PH_DISP_HELP}" ]] && \
			(! confapps_ph.sh -h) && \
			OPTARG="${PH_OLDOPTARG}" && \
			OPTIND="${PH_OLDOPTIND}" && \
			exit 1
		PH_DISP_HELP="yes" ;;
			   *)
		>&2 printf "\n"
		>&2 printf "\033[1;36m%s\033[0;0m\n" "Usage : Options when [routine] is \"nostart\" :"
		>&2 printf "%23s\033[1;37m%s\033[0;0m\n" "" "-p \"nostart\""
		>&2 printf "%8s\033[1;36m%s\033[0;0m\n" "" "Options when [routine] is \"move\" :"
		>&2 printf "%23s\033[1;37m%s\033[0;0m\n" "" "-p \"move\" [-a [[appname]|\"prompt\"]|-k [keyword]|-l [[keyword],[keyword],...] '-s [scope]' '-t [[newtty]|\"prompt\"]' |"
		>&2 printf "%8s\033[1;36m%s\033[0;0m\n" "" "Options for all other routines :"
		>&2 printf "%23s\033[1;37m%s\033[0;0m\n" "" "-p [routine] [-a [[appname]|\"prompt\"]|-k [keyword]|-l [[keyword],[keyword],...] '-s [scope]' '-o \"[[option1] [option2] ...]\"' |"
		>&2 printf "%23s\033[1;37m%s\n" "" "-p [routine] -d |"
		>&2 printf "%23s%s\n" "" "-h"
		>&2 printf "\n"
		>&2 printf "%3sm%s\n" "" "Run a specified application routine successively on a selection of applications"
		>&2 printf "%9s%s\n" "" "- Valid applications are :"
		>&2 printf "%12s%s\n" "" "- Any alphabetic string" 
		>&2 printf "%12s%s\n" "" "- 'Controllers' which refers to the controller settings"
		>&2 printf "%9s%s\n" "" "- Applications can be selected by one of the following mutually exclusive methods :"
		>&2 printf "%12s%s\n" "" "-a allows selecting an application named [appname]"
		>&2 printf "%15s%s\n" "" "- [appname] 'prompt' allows prompting for the name instead"
		>&2 printf "%12s%s\n" "" "-k allows using [keyword] to select applications by application state"
		>&2 printf "%15s%s\n" "" "- Supported keywords are :"
		>&2 printf "%18s%s\n" "" "- \"oos\" selects all Out-of-scope applications"
		>&2 printf "%21s%s\n" "" "- Out-of-scope applications are applications for which PieHelper has no built-in support requirements"
		>&2 printf "%18s%s\n" "" "- \"def\" selects all Default applications"
		>&2 printf "%21s%s\n" "" "- Default applications are applications for which PieHelper has built-in support requirements"
		>&2 printf "%18s%s\n" "" "- \"sup\" selects all applications with a minimum state of 'Supported'"
		>&2 printf "%21s%s\n" "" "- Supported applications are Out-of-scope or Default applications for which a configuration file and menu items exist"
		>&2 printf "%18s%s\n" "" "- \"int\" selects all applications with a minimum state of 'Integrated'"
		>&2 printf "%21s%s\n" "" "- Integrated applications are Supported applications for which management scripts exist"
		>&2 printf "%18s%s\n" "" "- \"hal\" selects all Halted applications"
		>&2 printf "%21s%s\n" "" "- Halted applications are inactive Integrated applications with an allocated tty"
		>&2 printf "%18s%s\n" "" "- \"run\" selects all Running applications"
		>&2 printf "%21s%s\n" "" "- Running applications are active Integrated applications with an allocated tty"
		>&2 printf "%18s%s\n" "" "- \"str\" selects the current Start application"
		>&2 printf "%21s%s\n" "" "- The Start application is a Supported application set to start automatically on system boot"
		>&2 printf "%21s%s\n" "" "- The Start application can be set by changing PieHelper option 'PH_PIEH_STARTAPP'"
		>&2 printf "%18s%s\n" "" "- \"all\" is equivalent to using '-l def,sup'"
		>&2 printf "%12s%s\n" "" "-l allows using a comma-separated list of [keyword] instances and returns all applications selected by any of the keywords"
		>&2 printf "%15s%s\n" "" "- Mentions of application state 'Unused' refer to Out-of-scope or Default applications that are as yet unsupported by PieHelper"
		>&2 printf "%9s%s\n" "" "-s allows applying an additional scope filter when selecting applications"
		>&2 printf "%12s%s\n" "" "- Supported scope filters are :"
		>&2 printf "%15s%s\n" "" "- \"oos\" additionally filters selections by application state and returns only those which are also Out-of-scope"
		>&2 printf "%15s%s\n" "" "- \"def\" additionally filters selections by application state and returns only those which are also Default"
		>&2 printf "%15s%s\n" "" "- \"inst\" additionally filters selections by installation state and returns only those which are currently installed"
		>&2 printf "%15s%s\n" "" "- \"uninst\" additionally filters selections by installation state and returns only those which are currently not installed"
		>&2 printf "%15s%s\n" "" "- \"pkg\" additionally filters selections by installation state and returns only those which are packaged"
		>&2 printf "%15s%s\n" "" "- \"unpkg\" additionally filters selections by installation state and returns only those which are unpackaged"
		>&2 printf "%15s%s\n" "" "- \"PI\" additionally filters selections by installation state and returns only those which are packaged and currently installed"
		>&2 printf "%15s%s\n" "" "- \"PU\" additionally filters selections by installation state and returns only those which are packaged and not currently installed"
		>&2 printf "%15s%s\n" "" "- \"UI\" additionally filters selections by installation state and returns only those which are unpackaged and currently installed"
		>&2 printf "%15s%s\n" "" "- \"UU\" additionally filters selections by installation state and returns only those which are unpackaged and not currently installed"
		>&2 printf "%12s%s\n" "" "- Applying a scope filter is optional"
		>&2 printf "%12s%s\n" "" "- Selections will not be filtered by default"
		>&2 printf "%9s%s\n" "" "-p allows specifying an application routine to run for each selected application, in the order they were selected"
		>&2 printf "%12s%s\n" "" "- For applications selected more than once, the specified routine will run only for the first instance selected"
		>&2 printf "%12s%s\n" "" "- Routines that remove application items will disable sanity checks by setting PieHelper option 'PH_PIEH_SANITY' to 'no'"
		>&2 printf "%12s%s\n" "" "- Routines that create application items will replace all existing items of the same type for the selected application"
		>&2 printf "%12s%s\n" "" "- PieHelper will always be skipped by the following routines :"
		>&2 printf "%15s%s\n" "" "- 'conf' and 'unconf'"
		>&2 printf "%15s%s\n" "" "- 'sup' and 'unsup'"
		>&2 printf "%15s%s\n" "" "- 'int' and 'unint'"
		>&2 printf "%15s%s\n" "" "- 'inst' and 'uninst'"
		>&2 printf "%15s%s\n" "" "- 'move'"
		>&2 printf "%12s%s\n" "" "- Controllers will always be skipped except by the following routines :"
		>&2 printf "%15s%s\n" "" "- 'list' and 'info'"
		>&2 printf "%15s%s\n" "" "- 'sup' and 'unsup'"
		>&2 printf "%15s%s\n" "" "- 'mk_conf' and 'rm_conf'"
		>&2 printf "%15s%s\n" "" "- 'mk_menus' and 'rm_menus'"
		>&2 printf "%15s%s\n" "" "- 'mk_all' and 'rm_all'"
		>&2 printf "%12s%s\n" "" "- Unused Out-of-scope applications will always be skipped except by 'sup'"
		>&2 printf "%12s%s\n" "" "- Supported routines are :"
		>&2 printf "%15s%s\n" "" "- \"inst\" will install selected applications"
		>&2 printf "%18s%s\n" "" "- Applications that are currently installed will be skipped"
		>&2 printf "%15s%s\n" "" "- \"uninst\" will uninstall selected applications"
		>&2 printf "%18s%s\n" "" "- Applications with state 'Running' will be skipped"
		>&2 printf "%18s%s\n" "" "- Applications that are not currently installed will be skipped"
		>&2 printf "%15s%s\n" "" "- \"sup\" will support selected applications"
		>&2 printf "%18s%s\n" "" "- Applications with state 'Supported', 'Integrated', 'Halted' or 'Running' will be skipped"
		>&2 printf "%18s%s\n" "" "- When supporting Out-of-scope applications, related routines that allow for end-user development will be created in '${PH_FUNCS_DIR}/functions.user'"
		>&2 printf "%15s%s\n" "" "- \"unsup\" will unsupport selected applications"
		>&2 printf "%18s%s\n" "" "- Applications with state 'Unused', 'Integrated', 'Halted' or 'Running' will be skipped"
		>&2 printf "%18s%s\n" "" "- When unsupporting Out-of-scope applications, related routines allowing for end-user development will be removed from '${PH_FUNCS_DIR}/functions.user'"
		>&2 printf "%15s%s\n" "" "- \"int\" will integrate selected applications"
		>&2 printf "%18s%s\n" "" "- Applications with state 'Unused', 'Integrated', 'Halted' or 'Running' will be skipped"
		>&2 printf "%15s%s\n" "" "- \"unint\" will unintegrate selected applications"
		>&2 printf "%18s%s\n" "" "- Applications with state 'Unused', 'Supported', or 'Running' will be skipped"
		>&2 printf "%15s%s\n" "" "- \"conf\" will attempt to do application-specific configuration"
		>&2 printf "%18s%s\n" "" "- Applications with state 'Unused' or 'Running' will be skipped"
		>&2 printf "%18s%s\n" "" "- Applications that are not currently installed will be skipped"
		>&2 printf "%18s%s\n" "" "- Out-of-scope application-specific configuration routines require prior end-user development"
		>&2 printf "%15s%s\n" "" "- \"unconf\" will attempt to undo application-specific configuration"
		>&2 printf "%18s%s\n" "" "- Applications with state 'Unused' or 'Running' will be skipped"
		>&2 printf "%18s%s\n" "" "- Applications that are not currently installed will be skipped"
		>&2 printf "%18s%s\n" "" "- Out-of-scope application-specific unconfiguration routines require prior end-user development"
		>&2 printf "%15s%s\n" "" "- \"start\" will configure selected applications as the Start application"
		>&2 printf "%18s%s\n" "" "- Applications with state 'Unused' will be skipped"
		>&2 printf "%18s%s\n" "" "- Applications that are not currently installed will be skipped"
		>&2 printf "%15s%s\n" "" "- \"unstart\" will remove the Start application if one is set"
		>&2 printf "%15s%s\n" "" "- \"update\" will check for available updates of selected applications and apply them when found"
		>&2 printf "%18s%s\n" "" "- Applications with state 'Unused' or 'Running' will be skipped"
		>&2 printf "%15s%s\n" "" "- \"move\" will change the allocated tty of a single selected application to another tty"
		>&2 printf "%18s%s\n" "" "- Applications with state 'Unused', 'Supported' or 'Integrated' will be skipped"
		>&2 printf "%15s%s\n" "" "- \"list\" will list the name of selected applications"
		>&2 printf "%15s%s\n" "" "- \"info\" will display the name and general information"
		>&2 printf "%15s%s\n" "" "- \"tty\" will display the name and tty allocation of selected applications"
		>&2 printf "%18s%s\n" "" "- Applications with state 'Unused', 'Supported' or 'Integrated' will be skipped"
		>&2 printf "%15s%s\n" "" "- \"mk_conf\" will create the configuration file for selected applications"
		>&2 printf "%18s%s\n" "" "- Applications with state 'Unused' or 'Running' will be skipped"
		>&2 printf "%18s%s\n" "" "- Configuration files are created as '${PH_CONF_DIR}/[appname].conf'"
		>&2 printf "%15s%s\n" "" "- \"mk_defaults\" will create entries for default option values of selected applications"
		>&2 printf "%18s%s\n" "" "- Applications with state 'Unused' or 'Running' will be skipped"
		>&2 printf "%18s%s\n" "" "- Entries will be added to '${PH_CONF_DIR}/options.defaults'"
		>&2 printf "%15s%s\n" "" "- \"mk_alloweds\" will create entries for allowed option values of selected applications"
		>&2 printf "%18s%s\n" "" "- Applications with state 'Unused' or 'Running' will be skipped"
		>&2 printf "%18s%s\n" "" "- Entries will be added to '${PH_CONF_DIR}/options.defaults'"
		>&2 printf "%15s%s\n" "" "- \"mk_menus\" will create the menu items for selected applications"
		>&2 printf "%18s%s\n" "" "- Applications with state 'Unused' or 'Running' will be skipped"
		>&2 printf "%18s%s\n" "" "- Menu items will be created in '${PH_MENUS_DIR}'"
		>&2 printf "%15s%s\n" "" "- \"mk_scripts\" will create the management scripts for selected applications"
		>&2 printf "%18s%s\n" "" "- Applications with state 'Unused', 'Supported' or 'Running' will be skipped"
		>&2 printf "%18s%s\n" "" "- Controller settings will be skipped"
		>&2 printf "%18s%s\n" "" "- Management scripts will be created in '${PH_SCRIPTS_DIR}'"
		>&2 printf "%15s%s\n" "" "- \"mk_cifs_mpt\" will create the CIFS mountpoint for selected applications if one is defined"
		>&2 printf "%18s%s\n" "" "- Applications with state 'Unused' or 'Supported' or applications with an active mounpoint will be skipped"
		>&2 printf "%18s%s\n" "" "- Controller settings will be skipped"
		>&2 printf "%18s%s\n" "" "- The mountpoint is defined by the value of option 'PH_[APPU]_CIFS_MPT' where [APPU] is"
		>&2 printf "%18s%s\n" "" "  the first four characters of the selected application's name in uppercase"
		>&2 printf "%15s%s\n" "" "- \"mk_all\" is equivalent to running this script successively using the following options in order for :"
		>&2 printf "%18s%s\n" "" "- Applications with an exact state of 'Supported':"
		>&2 printf "%21s%s\n" "" "- \"mk_conf\", \"mk_alloweds\", \"mk_defaults\", \"mk_menus\""
		>&2 printf "%18s%s\n" "" "- All other applications :"
		>&2 printf "%21s%s\n" "" "- \"mk_conf\", \"mk_alloweds\", \"mk_defaults\", \"mk_menus\", \"mk_scripts\", \"mk_cifs_mpt\""
		>&2 printf "%15s%s\n" "" "- \"rm_conf\" will remove the configuration file of selected applications"
		>&2 printf "%18s%s\n" "" "- Applications with state 'Unused' or 'Running' will be skipped"
		>&2 printf "%18s%s\n" "" "- Configuration files will be removed as '${PH_CONF_DIR}/[appname].conf'"
		>&2 printf "%15s%s\n" "" "- \"rm_defaults\" will remove default option value entries of selected applications"
		>&2 printf "%18s%s\n" "" "- Applications with state 'Unused' or 'Running' will be skipped"
		>&2 printf "%18s%s\n" "" "- Entries will be removed from '${PH_CONF_DIR}/options.defaults'"
		>&2 printf "%15s%s\n" "" "- \"rm_alloweds\" will remove allowed option value entries of selected applications"
		>&2 printf "%18s%s\n" "" "- Applications with state 'Unused' or 'Running' will be skipped"
		>&2 printf "%18s%s\n" "" "- Entries will be removed from '${PH_CONF_DIR}/options.alloweds'"
		>&2 printf "%15s%s\n" "" "- \"rm_menus\" will remove the menu items of selected applications"
		>&2 printf "%18s%s\n" "" "- Applications with state 'Unused' or 'Running' will be skipped"
		>&2 printf "%18s%s\n" "" "- Menu items will be removed from '${PH_MENUS_DIR}'"
		>&2 printf "%15s%s\n" "" "- \"rm_scripts\" will remove the management scripts of selected applications"
		>&2 printf "%18s%s\n" "" "- Applications with state 'Unused', 'Supported' or 'Running' will be skipped"
		>&2 printf "%18s%s\n" "" "- Controller settings will be skipped"
		>&2 printf "%18s%s\n" "" "- Management scripts will be removed from '${PH_SCRIPTS_DIR}'"
		>&2 printf "%15s%s\n" "" "- \"rm_cifs_mpt\" will remove the CIFS mountpoint of selected applications if one is defined"
		>&2 printf "%18s%s\n" "" "- Applications with state 'Unused' or 'Supported' or applications with an active mountpoint will be skipped"
		>&2 printf "%18s%s\n" "" "- Controller settings will be skipped"
		>&2 printf "%18s%s\n" "" "- The mountpoint is defined by the value of option 'PH_[APPU]_CIFS_MPT' where [APPU] is"
		>&2 printf "%18s%s\n" "" "  the first four characters of the selected application's name in uppercase"
		>&2 printf "%15s%s\n" "" "- \"rm_all\" is equivalent to running this script successively using the following options in order for"
		>&2 printf "%18s%s\n" "" "- Applications with an exact state of 'Supported':"
		>&2 printf "%21s%s\n" "" "- \"rm_menus\", \"rm_defaults\", \"rm_alloweds\", \"rm_conf\""
		>&2 printf "%18s%s\n" "" "- All other applications :"
		>&2 printf "%21s%s\n" "" "- \"rm_cifs_mpt\", \"rm_scripts\", \"rm_menus\", \"rm_defaults\", \"rm_alloweds\", \"rm_conf\""
		>&2 printf "%9s%s\n" "" "-t allows specifying the tty to move an application to as [newtty]"
		>&2 printf "%12s%s\n" "" "- [newtty] can be :"
		>&2 printf "%15s%s\n" "" "- A numeric value from '3' up to and including the value of PieHelper option 'PH_PIEH_MAX_TTYS'"
		>&2 printf "%15s%s\n" "" "- Keyword 'prompt' which will prompt for the value to use"
		>&2 printf "%18s%s\n" "" "- If multiple applications were selected :"
		>&2 printf "%21s%s\n" "" "- And a tty number was passed, it will only be used for the first application selected"
		>&2 printf "%21s%s\n" "" "  All remaining selections will fall back to the default"
		>&2 printf "%21s%s\n" "" "- And 'prompt' was passed, the user will be prompted for the new tty of each application selected"
		>&2 printf "%12s%s\n" "" "- Running applications will first be stopped and restart on their new tty after a successful move"
		>&2 printf "%12s%s\n" "" "- Passing a value is optional"
		>&2 printf "%12s%s\n" "" "- By default, moves will be performed to the lowest unallocated tty within range"
		>&2 printf "%9s%s\n" "" "-o allows passing a double-quoted and space-separated list of supported routine options to a specified routine"
		>&2 printf "%12s%s\n" "" "- Passing options to a routine is optional"
		>&2 printf "%12s%s\n" "" "- No routine options are passed by default"
		>&2 printf "%9s%s\033[0;0m\n" "" "-d will list all the options supported by a specified routine"
		>&2 printf "\n"
		OPTARG="${PH_OLDOPTARG}"
		OPTIND="${PH_OLDOPTIND}"
		exit 1 ;;
	esac
done
OPTARG="${PH_OLDOPTARG}"
OPTIND="${PH_OLDOPTIND}"

[[ -z "${PH_ACTION}" || \
	( -n "${PH_DISP_HELP}" && ( -n "${PH_LIST}" || -n "${PH_KEYWORD}" || -n "${PH_APP}" || -n "${PH_APP_SCOPE}" || -n "${PH_ROUTINE_OPTS}" )) || \
	( -n "${PH_LIST}" && ( -n "${PH_KEYWORD}" || -n "${PH_APP}" )) || \
	( -n "${PH_KEYWORD}" && -n "${PH_APP}" ) || \
	( "${PH_ACTION}" == "start" && "${PH_KEYWORD}" == "str" ) || \
	( "${PH_ACTION}" != @(mk|rm)_* && "${PH_APP}" == "Ctrls" ) || \
	( "${PH_ACTION}" != "move" && -n "${PH_APP_STR_TTY}" ) || \
	( "${PH_ACTION}" != "start" && "${PH_APP}" == @(none|prompt) ) ]] && \
	(! confapps_ph.sh -h) && \
	exit 1
if [[ "${PH_LIST}" == "all" || "${PH_KEYWORD}" == "all" ]]
then
	PH_LIST="def,sup,int,run,hal,str"
	PH_KEYWORD=""
fi
if [[ -n "${PH_APP}" ]]
then
	case "${PH_ACTION}" in info|unsup|int|uninst|update|mk_scripts|mk_cifs_mpt|rm_conf|rm_defaults|rm_alloweds|rm_menus|rm_all)
		PH_KEYWORD="sup" ;;
		  	     list)
		PH_KEYWORD="unu" ;;
		  	     inst)
		PH_LIST="oos,def,sup,int,halt"
		PH_APP_SCOPE="uninst" ;;
		  	     uninst)
		PH_LIST="def,sup,int,halt"
		PH_APP_SCOPE="inst" ;;
		  	     conf|unconf)
		PH_LIST="def,sup"
		PH_APP_SCOPE="inst" ;;
		  	     tty|unint|move|start|rm_scripts|rm_cifs_mpt)
		PH_KEYWORD="unu" ;;
		  	     sup|inst|mk_conf|mk_defaults|mk_alloweds|mk_menus|mk_all)
		PH_KEYWORD="unu" ;;
	esac
fi
printf "\n"
if [[ -n "${PH_ROUTINE_OPTS}" ]]
then
	case "${PH_ACTION}" in list|info|conf|update|start|tty|mk_*|rm_*|inst|uninst)
		PH_RET_CODE="1" ;;
			sup)
		for PH_i in ${PH_ROUTINE_OPTS}
		do
			[[ "${PH_i}" != -* ]] && \
				continue
			[[ "${PH_i}" != @(-c|-s|-p) ]] && \
				PH_RET_CODE="1"
		done ;;
			unsup)
		for PH_i in ${PH_ROUTINE_OPTS}
		do
			[[ "${PH_i}" != -* ]] && \
				continue
			[[ "${PH_i}" != @(-c|-s) ]] && \
				PH_RET_CODE="1"
		done ;;
			int)
		for PH_i in ${PH_ROUTINE_OPTS}
		do
			[[ "${PH_i}" != -* ]] && \
				continue
			[[ "${PH_i}" != @(-u|-t) ]] && \
				PH_RET_CODE="1"
		done ;;
			unint)
		for PH_i in ${PH_ROUTINE_OPTS}
		do
			[[ "${PH_i}" != -* ]] && \
				continue
			[[ "${PH_i}" != @(-u|-s|-t) ]] && \
				PH_RET_CODE="1"
		done ;;
			move)
		for PH_i in ${PH_ROUTINE_OPTS}
		do
			[[ "${PH_i}" != -* ]] && \
				continue
			[[ "${PH_i}" != "-t" ]] && \
				PH_RET_CODE="1"
		done ;;
	esac
	if [[ "${PH_RET_CODE}" -eq "1" ]]
	then
		(! confapps_ph.sh -h) && \
			exit 1
	fi
fi
case "${PH_APP_SCOPE}" in oos)
	PH_APP_SCOPE="Out-of-scope" ;;
			  def)
	PH_APP_SCOPE="Default" ;;
			  pkg)
	PH_APP_SCOPE='P*' ;;
			  unpkg)
	PH_APP_SCOPE='U*' ;;
			  *)
	: ;;
esac
if [[ -n "${PH_ACTION}" ]]
then
	if [[ -n "${PH_DISP_HELP}" ]]
	then
		printf "\033[1;36m%s\033[0;0m\n\n" "- Displaying supported '${PH_ACTION}' routine options"
		case "${PH_ACTION}" in sup)
			if printf "%4s\033[1;37m%-35s\033[1;33m%s\033[0;0m\n" "" "The start command for the application : " "-c \"start command\""
			then
				if printf "%4s\033[1;37m%-35s\033[1;33m%s\033[0;0m\n" "" "The user account for the application : " "-u \"user\""
				then
					printf "%4s\033[1;37m%-35s\033[1;33m%s\033[0;0m\n" "" "The package name for packaged applications or empty otherwise : " "-p \"package\""
				fi
			fi ;;
				inst)
			if printf "%4s\033[1;37m%-35s\033[1;33m%s\033[0;0m\n" "" "The user account for the application : " "-u \"user\""
			then
				printf "%4s\033[1;37m%-35s\033[1;33m%s\033[0;0m\n" "" "The package name for packaged applications or an empty value otherwise : " "-p \"package\"" 
			fi ;;
				uninst)
			if printf "%4s\033[1;37m%-35s\033[1;33m%s\033[0;0m\n" "" "The current user account of the application : " "-u \"user\""
			then
				printf "%4s\033[1;37m%-35s\033[1;33m%s\033[0;0m\n" "" "The current package name of the application : " "-p \"package\""
			fi ;;
				move)
			printf "%4s\033[1;37m%-35s\033[1;33m%s\033[0;0m\n" "" "The new tty for the application : " "-t \"tty\"" ;;
				*)
			printf "%4s\033[1;37m%-35s\033[0;0m\n" "" "No options supported" ;;
		esac
		ph_set_result -r "${?}"
		ph_show_result
		exit "${?}"
	else
		printf "\033[1;36m%s\033[0;0m\n\n" "- Running routine '${PH_ACTION}'"
		if [[ "${PH_ACTION}" == rm_* && "${PH_PIEH_SANITY}" == "yes" ]]
		then
			if ! ph_run_with_rollback -c "ph_set_option_to_value PieHelper -r \"PH_PIEH_SANITY'no\""
			then
				ph_show_result
				exit "${?}"
			fi
		fi
		if [[ "${PH_ACTION}" == @(rm|mk)_conf ]]
		then
			if ! ph_store_all_options_value
			then
				ph_show_result
				exit "${?}"
			fi
		fi
		if [[ -n "${PH_LIST}" ]]
		then
			ph_do_app_routine -p "${PH_ACTION}" -l "${PH_LIST}" -s "${PH_APP_SCOPE}"
		else
			if [[ -z "${PH_APP}" ]]
			then
				ph_do_app_routine -p "${PH_ACTION}" -k "${PH_KEYWORD}" -s "${PH_APP_SCOPE}" -o "${PH_ROUTINE_OPTS}"
			else
				ph_do_app_routine -p "${PH_ACTION}" -a "${PH_APP}" -k "${PH_KEYWORD}" -s "${PH_APP_SCOPE}" -o "${PH_ROUTINE_OPTS}"
			fi
		fi
		if [[ "${?}" -eq "0" && "${PH_ACTION}" == @(rm|mk)_conf ]]
		then
			ph_restore_all_options_value
		fi
		ph_show_result
		exit "${?}"
	fi
fi
confapps_ph.sh -h || \
	exit 1
