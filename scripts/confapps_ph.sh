#!/bin/bash
# Run application management routines (by Davy Keppens on 03/11/2018)
# Enable/Disable debug by running 'confpieh_ph.sh -p debug -m confapps_ph.sh'

if [[ -e "$(dirname "${0}" 2>/dev/null)/app/main.sh" && -r "$(dirname "${0}" 2>/dev/null)/app/main.sh" ]]
then
	if ! source "$(dirname "${0}" 2>/dev/null)/app/main.sh"
	then
		set +x
		printf "\n%2s\033[1;31m%s\033[0m\n\n" "" "ABORT : Reinstallation of PieHelper is required (Corrupted critical codebase file '$(dirname "${0}" 2>/dev/null)/app/main.sh'"
		exit 1
	fi
	set +x
else
	printf "\n%2s\033[1;31m%s\033[0m\n\n" "" "ABORT : Reinstallation of PieHelper is required (Missing or unreadable critical codebase file '$(dirname "${0}" 2>/dev/null)/app/main.sh'"
	exit 1
fi

#set -x

declare PH_i
declare PH_APP
declare PH_APP_CMD
declare PH_APP_USER
declare PH_APP_PKG
declare PH_APP_SCOPE
declare PH_CMD
declare PH_HEADER
declare PH_ROUTINE
declare PH_LIST
declare PH_DISP_HELP
declare PH_OLD_PIEH_SANITY_EXTENDED
declare PH_OPTION
declare PH_OLDOPTARG
declare -i PH_OLDOPTIND

declare -ix PH_ROUTINE_DEPTH
declare -ix PH_SKIP_DEPTH_MEMBERS
declare -ix PH_ROUTINE_FLAG

PH_OLDOPTARG="${OPTARG}"
PH_OLDOPTIND="${OPTIND}"
PH_i=""
PH_APP=""
PH_APP_CMD=""
PH_APP_USER=""
PH_APP_PKG=""
PH_APP_SCOPE=""
PH_CMD=""
PH_HEADER="Run a specified routine successively on selected applications"
PH_ROUTINE=""
PH_LIST=""
PH_DISP_HELP=""
PH_OLD_PIEH_SANITY_EXTENDED="${PH_PIEH_SANITY_EXTENDED}"
PH_OPTION=""

OPTIND="1"
PH_ROUTINE_DEPTH="0"
PH_SKIP_DEPTH_MEMBERS="0"
PH_ROUTINE_FLAG="1"

while getopts :r:a:l:s:c:u:p:dh PH_OPTION
do
	case "${PH_OPTION}" in r)
		[[ -n "${PH_ROUTINE}" || ( "${OPTARG}" != @(inst|uninst|sup|unsup|int|unint|conf|unconf|start|unstart|update|list|info|tty) && \
			"${OPTARG}" != @(mk|rm)_@(conf_file|defaults|alloweds|menus|scripts|cifs_mpt|all) ) ]] && \
			(! confapps_ph.sh -h) && \
			OPTARG="${PH_OLDOPTARG}" && \
			OPTIND="${PH_OLDOPTIND}" && \
			exit 1
		PH_ROUTINE="${OPTARG}" ;;
			   a)
		[[ -n "${PH_APP}" || -z "${OPTARG}" ]] && \
			(! confapps_ph.sh -h) && \
			OPTARG="${PH_OLDOPTARG}" && \
			OPTIND="${PH_OLDOPTIND}" && \
			exit 1
		PH_APP="${OPTARG}" ;;
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
			   s)
		[[ -n "${PH_APP_SCOPE}" || "${OPTARG}" != @(oos|def|inst|uninst|pkg|unpkg|PI|PU|UI|UU) ]] && \
			(! confapps_ph.sh -h) && \
			OPTARG="${PH_OLDOPTARG}" && \
			OPTIND="${PH_OLDOPTIND}" && \
			exit 1
		PH_APP_SCOPE="${OPTARG}" ;;
			   c)
		[[ -n "${PH_APP_CMD}" || -z "${OPTARG}" ]] && \
			(! confapps_ph.sh -h) && \
			OPTARG="${PH_OLDOPTARG}" && \
			OPTIND="${PH_OLDOPTIND}" && \
			exit 1
		PH_APP_CMD="${OPTARG}" ;;
			   u)
		[[ -n "${PH_APP_USER}" || -z "${OPTARG}" ]] && \
			(! confapps_ph.sh -h) && \
			OPTARG="${PH_OLDOPTARG}" && \
			OPTIND="${PH_OLDOPTIND}" && \
			exit 1
		PH_APP_USER="${OPTARG}" ;;
			   p)
		[[ -n "${PH_APP_PKG}" || -z "${OPTARG}" ]] && \
			(! confapps_ph.sh -h) && \
			OPTARG="${PH_OLDOPTARG}" && \
			OPTIND="${PH_OLDOPTIND}" && \
			exit 1
		PH_APP_PKG="${OPTARG}" ;;
			   d)
		[[ -n "${PH_DISP_HELP}" ]] && \
			(! confapps_ph.sh -h) && \
			OPTARG="${PH_OLDOPTARG}" && \
			OPTIND="${PH_OLDOPTIND}" && \
			exit 1
		PH_DISP_HELP="yes" ;;
			   *)
		>&2 printf "\n\n"
		>&2 printf "%2s\033[1;36m%s%s\033[1;4;35m%s\033[0m\n" "" "Applications" " : " "${PH_HEADER}"
		>&2 printf "\n\n"
		>&2 printf "%4s\033[1;5;33m%s\033[0m\n" "" "General options"
		>&2 printf "\n\n"
		>&2 printf "%6s\033[1;36m%s\033[1;37m%s\n" "" "$(basename "${0}" 2>/dev/null) : " "-r [routine] [[-a [[app]|\"prompt\"|\"Controllers\"]|-l [[keyword],[keyword],...]] '-s [scope]' |"
		>&2 printf "%23s%s\n" "" "-r [routine] -d |"
		>&2 printf "%23s%s\n" "" "-h"
		>&2 printf "\n"
		>&2 printf "%15s\033[0m\033[1;37m%s\n" "" "Where : - The PieHelper framework manages applications by their regular state and their install state"
		>&2 printf "%27s%s\n" "" "- To manage the install state of applications (installing, uninstalling, updates, etc), they must be supported by the framework"
		>&2 printf "%27s%s\n" "" "- To manage the state of applications (start, stop, etc), they must also be integrated with the framework"
		>&2 printf "%25s%s\n" "" "- Application states are separated into two groups :"
		>&2 printf "%27s%s\n" "" "- Unused applications refers to all applications for which support has not been added yet"
		>&2 printf "%27s%s\n" "" "- Used applications refers to all applications for which support has been added"
		>&2 printf "%23s%s\n" "" "-l allows selecting one or more applications by state if it is matched exactly by any one of a comma-separated [keyword] list"
		>&2 printf "%25s%s\n" "" "- Supported keywords are :"
		>&2 printf "%27s%s\n" "" "- \"oos\" refers to Unused applications that are Out-of-scope"
		>&2 printf "%29s%s\n" "" "- Since Out-of-scope applications are applications for which the framework has no built-in knowledge of"
		>&2 printf "%29s%s\n" "" "  the data required for support, these are equivalent to unknown applications"
		>&2 printf "%27s%s\n" "" "- \"def\" selects Unused applications that are Default"
		>&2 printf "%29s%s\n" "" "- Since Default applications are applications for which the framework has built-in knowledge of"
		>&2 printf "%29s%s\n" "" "  the data required for support, these applications are still known"
		>&2 printf "%27s%s\n" "" "- \"sup\" selects applications in state Supported"
		>&2 printf "%29s%s\n" "" "- Supported applications are Default or Out-of-scope applications for which a configuration file, option configuration and menu items exist as well"
		>&2 printf "%27s%s\n" "" "- \"int\" selects applications in state Integrated"
		>&2 printf "%29s%s\n" "" "- Integrated applications are Supported applications without a tty for which management scripts and, in case one is defined, a mounpoint exist as well"
		>&2 printf "%27s%s\n" "" "- \"hal\" selects applications in state Halted"
		>&2 printf "%29s%s\n" "" "- Halted applications are inactive Integrated applications with an allocated tty"
		>&2 printf "%27s%s\n" "" "- \"run\" selects applications in state Running"
		>&2 printf "%29s%s\n" "" "- Running applications are active Integrated applications with an allocated tty"
		>&2 printf "%27s%s\n" "" "- \"str\" selects the current Start application"
		>&2 printf "%29s%s\n" "" "- The Start application, if set, is either a Halted or Running application, set to start automatically on system boot"
		>&2 printf "%27s%s\n" "" "- \"all\" is equivalent to using '-l def,sup,int,hal,run'"
		>&2 printf "%23s%s\n" "" "-a allows selecting a single application by an identifier [app]"
		>&2 printf "%25s%s\n" "" "- Supported values for [app] are :"
		>&2 printf "%27s%s\n" "" "- An application name"
		>&2 printf "%27s%s\n" "" "- Reserved keyword 'Controllers' which is a special Supported application for controller management"
		>&2 printf "%27s%s\n" "" "- Reserved keyword 'prompt' for specifying the name interactively"
		>&2 printf "%25s%s\n" "" "- This option is mandatory to select Unused Out-of-scope applications"
		>&2 printf "%23s%s\n" "" "-s allows applying an additional scope filter when selecting applications"
		>&2 printf "%25s%s\n" "" "- Supported scope filters are :"
		>&2 printf "%27s%s\n" "" "- \"oos\" additionally filters selections by state and returns only Out-of-scope applications (Used and Unused)"
		>&2 printf "%27s%s\n" "" "- \"def\" additionally filters selections by state and returns only Default applications (Used and Unused)"
		>&2 printf "%27s%s\n" "" "- \"inst\" additionally filters selections by install state and returns only those currently installed"
		>&2 printf "%27s%s\n" "" "- \"uninst\" additionally filters selections by install state and returns only those not currently installed"
		>&2 printf "%27s%s\n" "" "- \"pkg\" additionally filters selections by install state and returns only those which are packaged"
		>&2 printf "%27s%s\n" "" "- \"unpkg\" additionally filters selections by install state and returns only those which are unpackaged"
		>&2 printf "%27s%s\n" "" "- \"PI\" additionally filters selections by install state and returns only those which are both packaged and currently installed"
		>&2 printf "%27s%s\n" "" "- \"PU\" additionally filters selections by install state and returns only those which are both packaged and not currently installed"
		>&2 printf "%27s%s\n" "" "- \"UI\" additionally filters selections by install state and returns only those which are both unpackaged and currently installed"
		>&2 printf "%27s%s\n" "" "- \"UU\" additionally filters selections by install state and returns only those which are both unpackaged and not currently installed"
		>&2 printf "%25s%s\n" "" "- Applying a scope filter is optional"
		>&2 printf "%25s%s\n" "" "- Selections will not be filtered by default"
		>&2 printf "%23s%s\n" "" "-r allows specifying an application routine to run for each selected application, in the order they were selected"
		>&2 printf "%25s%s\n" "" "- For applications selected more than once, the routine will run only once, for the first instance selected"
		>&2 printf "%25s%s\n" "" "- Routines that remove application items will :"
		>&2 printf "%27s%s\n" "" "- Disable extended sanity checks by setting PieHelper option 'PH_PIEH_SANITY_EXTENDED' to no"
		>&2 printf "%27s%s\n" "" "- Remove all existing items for that routine and for each selection"
		>&2 printf "%27s%s\n" "" "- Re-enable extended sanity checks, if at first disabled, by setting PieHelper option 'PH_PIEH_SANITY_EXTENDED' back to yes"
		>&2 printf "%25s%s\n" "" "- Routines that create application items will :"
		>&2 printf "%27s%s\n" "" "- Disable extended sanity checks by setting PieHelper option 'PH_PIEH_SANITY_EXTENDED' to no"
		>&2 printf "%27s%s\n" "" "- Remove and re-create all existing items for that routine and for each selection"
		>&2 printf "%27s%s\n" "" "- Re-enable extended sanity checks, if at first disabled, by setting PieHelper option 'PH_PIEH_SANITY_EXTENDED' back to yes"
		>&2 printf "%25s%s\n" "" "- Application PieHelper will always be skipped by the following routines :"
		>&2 printf "%27s%s\n" "" "- 'conf' and 'unconf'"
		>&2 printf "%27s%s\n" "" "- 'sup' and 'unsup'"
		>&2 printf "%27s%s\n" "" "- 'int' and 'unint'"
		>&2 printf "%27s%s\n" "" "- 'inst' and 'uninst'"
		>&2 printf "%25s%s\n" "" "- Application Controllers will always be skipped except by the following routines :"
		>&2 printf "%27s%s\n" "" "- 'list' and 'info'"
		>&2 printf "%27s%s\n" "" "- 'sup' and 'unsup'"
		>&2 printf "%27s%s\n" "" "- 'mk_conf_file' and 'rm_conf_file'"
		>&2 printf "%27s%s\n" "" "- 'mk_menus' and 'rm_menus'"
		>&2 printf "%27s%s\n" "" "- 'mk_all' and 'rm_all'"
		>&2 printf "%25s%s\n" "" "- Supported routines are :"
		>&2 printf "%27s%s\n" "" "- \"inst\" will install all selected applications"
		>&2 printf "%29s%s\n" "" "- Running and installed applications will be skipped"
		>&2 printf "%27s%s\n" "" "- \"uninst\" will uninstall selected applications"
		>&2 printf "%29s%s\n" "" "- Running and uninstalled applications will be skipped"
		>&2 printf "%27s%s\n" "" "- \"sup\" will support selected applications in the PieHelper framework"
		>&2 printf "%29s%s\n" "" "- Adding support will create a configuration file, option configuration and menu items"
		>&2 printf "%31s%s\n" "" "- When supporting Out-of-scope applications, related routines that allow for end-user"
		>&2 printf "%31s%s\n" "" "  development will also be created, in '${PH_FUNCS_DIR}/functions.user'"
		>&2 printf "%29s%s\n" "" "- Applications with state Supported or higher will be skipped"
		>&2 printf "%27s%s\n" "" "- \"unsup\" will unsupport selected applications from the PieHelper framework"
		>&2 printf "%29s%s\n" "" "- Removing support will remove the configuration file, option configuration and menu items"
		>&2 printf "%31s%s\n" "" "- When unsupporting Out-of-scope applications, related routines allowing for end-user"
		>&2 printf "%31s%s\n" "" "  development will also be removed, from '${PH_FUNCS_DIR}/functions.user'"
		>&2 printf "%29s%s\n" "" "- Unused applications or applications with state Integrated or higher will be skipped"
		>&2 printf "%27s%s\n" "" "- \"int\" will integrate selected applications into the PieHelper framework"
		>&2 printf "%29s%s\n" "" "- Integration will create management scripts and, in case a default mountpoint is defined, the mountpoint"
		>&2 printf "%29s%s\n" "" "- Unused applications or applications with state Integrated or higher will be skipped"
		>&2 printf "%27s%s\n" "" "- \"unint\" will unintegrate selected applications from the PieHelper framework"
		>&2 printf "%29s%s\n" "" "- Unintegration will remove any tty allocation, management scripts and, in case a default CIFS mountpoint is used, the mountpoint"
		>&2 printf "%29s%s\n" "" "- Unused, Supported, and Running applications will be skipped"
		>&2 printf "%27s%s\n" "" "- \"conf\" will attempt to do application-specific configuration"
		>&2 printf "%29s%s\n" "" "- Out-of-scope application-specific configuration routines require prior end-user development"
		>&2 printf "%29s%s\n" "" "- Unused and Running applications and applications not currently installed will be skipped"
		>&2 printf "%27s%s\n" "" "- \"unconf\" will attempt to undo application-specific configuration"
		>&2 printf "%29s%s\n" "" "- Out-of-scope application-specific unconfiguration routines require prior end-user development"
		>&2 printf "%29s%s\n" "" "- Unused, Running applications and uninstalled applications will be skipped"
		>&2 printf "%27s%s\n" "" "- \"start\" will configure selected applications as the Start application"
		>&2 printf "%29s%s\n" "" "- Unused and uninstalled applications will be skipped"
		>&2 printf "%27s%s\n" "" "- \"unstart\" will unconfigure the current Start application"
		>&2 printf "%29s%s\n" "" "- Applications that are not the current Start application and uninstalled applications will be skipped"
		>&2 printf "%27s%s\n" "" "- \"update\" will check for available updates of selected applications and apply them when found"
		>&2 printf "%29s%s\n" "" "- Unused and Running applications will be skipped"
		>&2 printf "%27s%s\n" "" "- \"list\" will list the name of selected applications"
		>&2 printf "%27s%s\n" "" "- \"info\" will display the name and general information of selected applications"
		>&2 printf "%27s%s\n" "" "- \"tty\" will display the name and tty allocation of selected applications"
		>&2 printf "%29s%s\n" "" "- Applications with a maximum state of Integrated will be skipped"
		>&2 printf "%27s%s\n" "" "- \"mk_conf_file\" will create the configuration file for selected applications"
		>&2 printf "%29s%s\n" "" "- Configuration files are created as '${PH_CONF_DIR}/[app].conf'"
		>&2 printf "%29s%s\n" "" "- Unused and Running applications will be skipped"
		>&2 printf "%27s%s\n" "" "- \"mk_defaults\" will create configuration for default option values of selected applications"
		>&2 printf "%29s%s\n" "" "- Configuration will be added to '${PH_CONF_DIR}/options.defaults'"
		>&2 printf "%29s%s\n" "" "- Unused and Running applications will be skipped"
		>&2 printf "%27s%s\n" "" "- \"mk_alloweds\" will create configuration for allowed option values of selected applications"
		>&2 printf "%29s%s\n" "" "- Configuration will be added to '${PH_CONF_DIR}/options.defaults'"
		>&2 printf "%29s%s\n" "" "- Unused and Running applications will be skipped"
		>&2 printf "%27s%s\n" "" "- \"mk_menus\" will create the menu items for selected applications"
		>&2 printf "%29s%s\n" "" "- Menu items will be created in '${PH_MENUS_DIR}'"
		>&2 printf "%29s%s\n" "" "- Unused and Running applications will be skipped"
		>&2 printf "%27s%s\n" "" "- \"mk_scripts\" will create the management scripts for selected applications"
		>&2 printf "%29s%s\n" "" "- Management scripts will be created in '${PH_SCRIPTS_DIR}'"
		>&2 printf "%29s%s\n" "" "- Unused and Running applications will be skipped"
		>&2 printf "%27s%s\n" "" "- \"mk_cifs_mpt\" will create the CIFS mountpoint for selected applications if one is defined"
		>&2 printf "%29s%s\n" "" "- The mountpoint is defined by the value of option 'PH_[APPU]_CIFS_MPT' where [APPU] is"
		>&2 printf "%29s%s\n" "" "  the first four characters of the selected application's name in uppercase"
		>&2 printf "%29s%s\n" "" "- Applications with a maximum state of Supported or applications with an active mounpoint will be skipped"
		>&2 printf "%27s%s\n" "" "- \"mk_all\" is equivalent to running this script successively using the following options in order :"
		>&2 printf "%29s%s\n" "" "- For Supported applications :"
		>&2 printf "%31s%s\n" "" "- \"mk_conf_file\", \"mk_alloweds\", \"mk_defaults\", \"mk_menus\""
		>&2 printf "%29s%s\n" "" "- For Integrated and Halted applications :"
		>&2 printf "%31s%s\n" "" "- \"mk_conf_file\", \"mk_alloweds\", \"mk_defaults\", \"mk_menus\", \"mk_scripts\", \"mk_cifs_mpt\""
		>&2 printf "%29s%s\n" "" "- Unused and Running applications will be skipped"
		>&2 printf "%27s%s\n" "" "- \"rm_conf_file\" will remove the configuration file of selected applications"
		>&2 printf "%29s%s\n" "" "- Configuration files will be removed as '${PH_CONF_DIR}/[app].conf'"
		>&2 printf "%29s%s\n" "" "- Unused and Running applications will be skipped"
		>&2 printf "%27s%s\n" "" "- \"rm_defaults\" will remove default option value configuration of selected applications"
		>&2 printf "%29s%s\n" "" "- Configuration will be removed from '${PH_CONF_DIR}/options.defaults'"
		>&2 printf "%29s%s\n" "" "- Unused and Running applications will be skipped"
		>&2 printf "%27s%s\n" "" "- \"rm_alloweds\" will remove allowed option value configuration of selected applications"
		>&2 printf "%29s%s\n" "" "- Configuration will be removed from '${PH_CONF_DIR}/options.alloweds'"
		>&2 printf "%29s%s\n" "" "- Unused and Running applications will be skipped"
		>&2 printf "%27s%s\n" "" "- \"rm_menus\" will remove the menu items of selected applications"
		>&2 printf "%29s%s\n" "" "- Menu items will be removed from '${PH_MENUS_DIR}'"
		>&2 printf "%29s%s\n" "" "- Unused and Running applications will be skipped"
		>&2 printf "%27s%s\n" "" "- \"rm_scripts\" will remove the management scripts of selected applications"
		>&2 printf "%29s%s\n" "" "- Management scripts will be removed from '${PH_SCRIPTS_DIR}'"
		>&2 printf "%29s%s\n" "" "- Unused and Running applications will be skipped"
		>&2 printf "%27s%s\n" "" "- \"rm_cifs_mpt\" will remove the CIFS mountpoint of selected applications if one is defined"
		>&2 printf "%29s%s\n" "" "- The mountpoint is defined by the value of option 'PH_[APPU]_CIFS_MPT' where [APPU] is"
		>&2 printf "%29s%s\n" "" "  the first four characters of the selected application's name in uppercase"
		>&2 printf "%29s%s\n" "" "- Applications with a maximum state of Supported or applications with an active mountpoint will be skipped"
		>&2 printf "%27s%s\n" "" "- \"rm_all\" is equivalent to running this script successively using the following options in order :"
		>&2 printf "%29s%s\n" "" "- For Supported applications :"
		>&2 printf "%31s%s\n" "" "- \"rm_menus\", \"rm_defaults\", \"rm_alloweds\", \"rm_conf_file\""
		>&2 printf "%29s%s\n" "" "- For Integrated and Halted applications :"
		>&2 printf "%31s%s\n" "" "- \"rm_cifs_mpt\", \"rm_scripts\", \"rm_menus\", \"rm_defaults\", \"rm_alloweds\", \"rm_conf_file\""
		>&2 printf "%29s%s\n" "" "- Unused and Running applications will be skipped"
		>&2 printf "%23s%s\n" "" "-d will list the options supported by a specified routine [routine]"
		>&2 printf "%23s%s\033[0m\n" "" "-h displays this usage"
		>&2 printf "\n"
		>&2 printf "%4s\033[1;5;33m%s\033[0m\n" "" "Routine-specific options"
		>&2 printf "\n"
		>&2 printf "%6s\033[1;36m%s\033[1;5;33m%s\033[0;1;37m%s\n" "" "$(basename "${0}" 2>/dev/null) : " "-a [app] -r [\"sup\"|\"inst\"|\"uninst\"] '-s [scope]'" " '-c [[cmd]|\"prompt\"]' |"
		>&2 printf "%72s%s\n" "" "'-u [[user]|\"prompt\"]' |"
		>&2 printf "%72s%s\n" "" "'-p [[pkg]|\"prompt\"|\"none\"]'"
		>&2 printf "\n"
		>&2 printf "%15s\033[0m\033[1;37m%s\n" "" "Where : - Routine options are only required when supporting, installing or"
		>&2 printf "%23s%s\n" "" "  uninstalling Unused Out-of-scope applications"
		>&2 printf "%23s%s\n" "" "-u allows passing a username value [user] to a routine"
		>&2 printf "%25s%s\n" "" "- [user] can be :"
		>&2 printf "%27s%s\n" "" "- A valid username for [app]"
		>&2 printf "%27s%s\n" "" "- Reserved keyword 'prompt' which allows for specifying the value interactively"
		>&2 printf "%25s%s\n" "" "- This argument is optional"
		>&2 printf "%23s%s\n" "" "-p allows passing a packagename value [pkg] to a routine"
		>&2 printf "%25s%s\n" "" "- [pkg] can be :"
		>&2 printf "%27s%s\n" "" "- A valid packagename if [app] is a packaged application"
		>&2 printf "%27s%s\n" "" "- Reserved keyword 'none' if [app] is an unpackaged application"
		>&2 printf "%27s%s\n" "" "- Reserved keyword 'prompt' which allows for specifying the value interactively"
		>&2 printf "%25s%s\n" "" "- This argument is optional"
		>&2 printf "%23s%s\n" "" "-c allows passing a start command value [cmd] to a routine"
		>&2 printf "%25s%s\n" "" "- [cmd] can be :"
		>&2 printf "%27s%s\n" "" "- A valid start command for [app]"
		>&2 printf "%27s%s\n" "" "- Reserved keyword 'prompt' which allows for specifying the value interactively"
		>&2 printf "%25s%s\033[0m\n" "" "- This argument is optional"
		>&2 printf "\n"
		OPTARG="${PH_OLDOPTARG}"
		OPTIND="${PH_OLDOPTIND}"
		exit 1 ;;
	esac
done
OPTARG="${PH_OLDOPTARG}"
OPTIND="${PH_OLDOPTIND}"

[[ -z "${PH_ROUTINE}" || \
	( -n "${PH_DISP_HELP}" && ( -n "${PH_LIST}" || -n "${PH_APP}" || -n "${PH_APP_SCOPE}" || \
	-n "${PH_APP_CMD}" || -n "${PH_APP_USER}" || -n "${PH_APP_PKG}" )) || \
	( -n "${PH_LIST}" && -n "${PH_APP}" ) || \
	(( "${PH_ROUTINE}" != "sup" || -n "${PH_LIST}" || \
	"$(ph_check_app_state_validity -a "${PH_APP}" -q -o; echo "${?}")" -ne "0" ) && \
	( -n "${PH_APP_CMD}" || -n "${PH_APP_USER}" )) ||  \
	(( "${PH_ROUTINE}" != @(sup|inst|uninst) || -n "${PH_LIST}" || \
	"$(ph_check_app_state_validity -a "${PH_APP}" -q -o; echo "${?}")" -ne "0" ) && \
	-n "${PH_APP_PKG}" ) ]] &&  \
	(! confapps_ph.sh -h) && \
	exit 1
if [[ -n "${PH_LIST}" ]]
then
	declare -a PH_KEYWORDS
	for PH_i in ${PH_LIST//,/ }
	do
		[[ "${PH_i}" == "all" ]] && \
			PH_i="def,sup,int,hal,run"
		PH_KEYWORDS+=("${PH_i}")
	done
	PH_LIST="$(printf "%s\n" "${PH_KEYWORDS[@]}" | sort -u | nawk 'BEGIN { \
			ORS = " " \
		} { \
			print \
		}')"
	unset PH_KEYWORDS
else
	if [[ -n "${PH_APP}" ]]
	then
		case "${PH_ROUTINE}" in mk_cifs_mpt|rm_cifs_mpt)
			PH_LIST="int,hal,run" ;;
			  	     inst)
			PH_LIST="oos,def,sup,int,hal"
			if [[ -n "${PH_APP_SCOPE}" && "${PH_APP_SCOPE}" != "uninst" ]]
			then
				case "${PH_APP_SCOPE}" in oos|def)
					PH_LIST="${PH_APP_SCOPE}" ;;
						pkg|PU)
					PH_APP_SCOPE="PU" ;;
						unpkg|UU)
					PH_APP_SCOPE="UU" ;;
						*I|inst)
					PH_APP_SCOPE="oos"
					PH_LIST="def" ;;
				esac
			else
				PH_APP_SCOPE="uninst"
			fi ;;
			  	     uninst)
			PH_LIST="oos,def,sup,int,hal"
			if [[ -n "${PH_APP_SCOPE}" && "${PH_APP_SCOPE}" != "inst" ]]
			then
				case "${PH_APP_SCOPE}" in oos|def)
					PH_LIST="${PH_APP_SCOPE}" ;;
						pkg|PI)
					PH_APP_SCOPE="PI" ;;
						unpkg|UI)
					PH_APP_SCOPE="UI" ;;
						*U|uninst)
					PH_APP_SCOPE="oos"
					PH_LIST="def" ;;
				esac
			else
				PH_APP_SCOPE="inst"
			fi ;;
			  	     sup)
			PH_LIST="oos,def" ;;
			  	     unsup|int)
			PH_LIST="sup" ;;
			  	     unint)
			PH_LIST="hal" ;;
			  	     conf|unconf)
			PH_LIST="sup,int,hal"
			if [[ -n "${PH_APP_SCOPE}" && "${PH_APP_SCOPE}" != "inst" ]]
			then
				case "${PH_APP_SCOPE}" in oos|def)
					PH_LIST="${PH_APP_SCOPE}" ;;
						pkg|PI)
					PH_APP_SCOPE="PI" ;;
						unpkg|UI)
					PH_APP_SCOPE="UI" ;;
						*U|uninst)
					PH_APP_SCOPE="oos"
					PH_LIST="def" ;;
				esac
			else
				PH_APP_SCOPE="inst"
			fi ;;
			  	     start)
			PH_LIST="sup,int,hal,run"
			if [[ -n "${PH_APP_SCOPE}" && "${PH_APP_SCOPE}" != "inst" ]]
			then
				case "${PH_APP_SCOPE}" in oos|def)
					PH_LIST="${PH_APP_SCOPE}" ;;
						pkg|PI)
					PH_APP_SCOPE="PI" ;;
						unpkg|UI)
					PH_APP_SCOPE="UI" ;;
						*U|uninst)
					PH_APP_SCOPE="oos"
					PH_LIST="def" ;;
				esac
			else
				PH_APP_SCOPE="inst"
			fi ;;
			  	     unstart)
			PH_LIST="str"
			if [[ -n "${PH_APP_SCOPE}" && "${PH_APP_SCOPE}" != "inst" ]]
			then
				case "${PH_APP_SCOPE}" in oos|def)
					PH_LIST="${PH_APP_SCOPE}" ;;
						pkg|PI)
					PH_APP_SCOPE="PI" ;;
						unpkg|UI)
					PH_APP_SCOPE="UI" ;;
						*U|uninst)
					PH_APP_SCOPE="oos"
					PH_LIST="def" ;;
				esac
			else
				PH_APP_SCOPE="inst"
			fi ;;
			  	     update|mk_conf_file|mk_defaults|mk_alloweds|mk_menus|mk_scripts|rm_conf_file|rm_defaults|rm_alloweds|rm_menus|rm_scripts)
			PH_LIST="sup,int,hal" ;;
			  	     tty)
			PH_LIST="hal,run" ;;
			  	     list|info)
			PH_LIST="oos,def,sup,int,hal,run" ;;
			  	     *)
			: ;;
		esac
	fi
fi
printf "\n"
case "${PH_APP_SCOPE}" in oos)
	PH_APP_SCOPE="Out-of-scope" ;;
			  def)
	PH_APP_SCOPE="Default" ;;
			  pkg)
	PH_APP_SCOPE='P*' ;;
			  unpkg)
	PH_APP_SCOPE='U*' ;;
			  inst)
	PH_APP_SCOPE='*I' ;;
			  uninst)
	PH_APP_SCOPE='*U' ;;
			  *)
	: ;;
esac
if [[ -n "${PH_DISP_HELP}" ]]
then
	printf "\033[1;36m%s\033[0;0m\n\n" "- Displaying supported routine options"
	printf "%8s%s\033[1;33m%s\033[0;0m\n\n" "" "--> Listing supported options for routine " "'${PH_ROUTINE}'"
	case "${PH_ROUTINE}" in sup)
		if printf "%12s\033[1;37m%-73s%-5s\033[1;33m%s\033[0;0m\n" "" "- The start command for the application " ":" " -c \"start command\""
		then
			if printf "%12s\033[1;37m%-73s%-5s\033[1;33m%s\033[0;0m\n" "" "- The user account for the application " ":" " -u \"user\""
			then
				printf "%12s\033[1;37m%-73s%-5s\033[1;33m%s\033[0;0m\n" "" "- A package name for packaged applications or empty string otherwise " ":" " -p \"package\""
			fi
		fi ;;
			inst|uninst)
		printf "%12s\033[1;37m%-73s%-5s\033[1;33m%s\033[0;0m\n" "" "- The package name for packaged applications or an empty string otherwise " ":" "-p \"package\"" ;;
			*)
		printf "%12s\033[1;37m%-73s\033[0;0m\n" "" "- No options supported" ;;
	esac
	if [[ "${?}" -eq "0" ]]
	then
		printf "\n"
		ph_run_with_rollback -c true
	else
		ph_set_result -m "An error occurred trying to list the supported options of routine '${PH_ROUTINE}'"
		ph_run_with_rollback -c false -m "Could not list"
	fi
else
	printf "\033[1;36m%s\033[0;0m\n\n" "- Running routine '${PH_ROUTINE}'"
	if [[ "${PH_ROUTINE}" == @(rm|mk)_conf_file ]]
	then
		if ! ph_store_all_options_value
		then
			ph_show_result
			exit "${?}"
		fi
	fi
	if [[ "${PH_ROUTINE}" == rm_* && "${PH_PIEH_SANITY_EXTENDED}" == "yes" ]]
	then
		if ! ph_run_with_rollback -c "ph_set_option_to_value PieHelper -r \"PH_PIEH_SANITY_EXTENDED'no\""
		then
			ph_show_result
			exit "${?}"
		fi
	fi
	declare -a PH_ROUTINE_OPTS
	for PH_i in APP LIST APP_SCOPE APP_USER APP_PKG APP_CMD
	do
		declare -n PH_PARAM
		PH_PARAM="PH_${PH_i}"
		if [[ "${PH_i}" == @(APP|LIST) ]]
		then
			PH_ROUTINE_OPTS+=("-$(cut -c1<<<"${PH_i}" | tr '[:upper:]' '[:lower:]')" "'${PH_PARAM}'")
		else
			PH_ROUTINE_OPTS+=("-$(cut -c5<<<"${PH_i}" | tr '[:upper:]' '[:lower:]')" "'${PH_PARAM}'")
		fi
		unset -n PH_PARAM
	done
	PH_CMD="ph_do_app_routine -r '${PH_ROUTINE}' ${PH_ROUTINE_OPTS[*]}"
	unset PH_ROUTINE_OPTS
	if eval "${PH_CMD}"
	then
		if [[ "${PH_ROUTINE}" == @(rm|mk)_conf_file ]]
		then
			if ! ph_restore_all_options_value
			then
				ph_show_result
				exit "${?}"
			fi
		fi
		if [[ "${PH_ROUTINE}" == rm_* && "${PH_ROUTINE}" != "rm_conf" && "${PH_OLD_PIEH_SANITY_EXTENDED}" != "${PH_PIEH_SANITY_EXTENDED}" ]]
		then
			if ! ph_run_with_rollback -c "ph_set_option_to_value PieHelper -r \"PH_PIEH_SANITY_EXTENDED'yes\""
			then
				ph_show_result
				exit "${?}"
			fi
		fi
	fi
fi
ph_show_result
exit "${?}"
