#!/bin/bash
# Run 'PieHelper' start action (by Davy Keppens on 04/10/2018)
# Enable/Disable debug by running 'confpieh_ph.sh -p debug -m startpieh.sh'

if [[ -r "$(dirname "${0}" 2>/dev/null)/main/main.sh" ]]
then
	if ! source "$(dirname "${0}" 2>/dev/null)/main/main.sh"
	then
		set +x
		>&2 printf "\n%2s\033[1;31m%s\033[0m\n\n" "" "ABORT : Reinstallation of PieHelper is required (Corrupted critical codebase file '$(dirname "${0}" 2>/dev/null)/main/main.sh'"
		exit 1
	fi
	set +x
else
	>&2 printf "\n%2s\033[1;31m%s\033[0m\n\n" "" "ABORT : Reinstallation of PieHelper is required (Missing or unreadable critical codebase file '$(dirname "${0}" 2>/dev/null)/main/main.sh'"
	exit 1
fi

#set -x

declare PH_i
declare PH_RUNAPP
declare PH_RUNAPP_STATE
declare PH_RUNAPP_STR_TTY
declare PH_EXCEPTION
declare PH_MODE
declare PH_OPTION
declare PH_OLDOPTARG
declare -i PH_OLDOPTIND
declare -i PH_FG_CONSOLE
declare -i PH_SUBPID
declare -i PH_RECVD_FLAG
declare -l PH_RUNAPPL
declare -u PH_RUNAPPU

declare -x PH_LAST_RETURN_GLOB

PH_OLDOPTARG="${OPTARG}"
PH_OLDOPTIND="${OPTIND}"
PH_i=""
PH_RUNAPP="PieHelper"
PH_RUNAPP_STATE=""
PH_RUNAPP_STR_TTY=""
PH_EXCEPTION=""
PH_MODE=""
PH_OPTION=""
PH_FG_CONSOLE="$("${PH_SUDO}" fgconsole 2>/dev/null)"
PH_SUBPID="0"
PH_RECVD_FLAG="1"
PH_RUNAPPL="${PH_RUNAPP:0:4}"
PH_RUNAPPU="${PH_RUNAPP:0:4}"

PH_LAST_RETURN_GLOB="yes"
OPTIND="1"

while getopts :m:ph PH_OPTION
do
	case "${PH_OPTION}" in p)
		[[ -n "${PH_MODE}" ]] && \
			(! "start${PH_RUNAPPL}.sh" -h) && \
			OPTIND="${PH_OLDOPTIND}" && \
			OPTARG="${PH_OLDOPTARG}" && \
			exit 1
		if [[ "$(tty 2>/dev/null)" != /dev/pts/* ]]
		then
			OPTIND="${PH_OLDOPTIND}"
			OPTARG="${PH_OLDOPTARG}"
			ph_set_result -a -m "Option '-p' can only be used when issuing the command from a pseudo-terminal"
			exit "${?}"
		fi
		PH_MODE="pts" ;;
			   m)
		[[ "${PH_RECVD_FLAG}" -eq "0" || \
			"${OPTARG}" != @(Main|@(Controller|Application)s|PS@(3|4)|XBOX@(360|SX)|@(Status|Options|TTY)Management@(|_*)|Support) && \
			"${OPTARG}" != @(Supported|Integrated|Halted|Running|Default|Out-of-scope) && \
			"${OPTARG}" != @(System@(|Interactive|Retained@(|s))|$(ph_get_app_list_by_state -s Unused -t minimum | sed "s/ /|/g")) ]] && \
			(! "start${PH_RUNAPPL}.sh" -h) && \
			OPTIND="${PH_OLDOPTIND}" && \
			OPTARG="${PH_OLDOPTARG}" && \
			exit 1
		PH_RECVD_FLAG="0"
		if [[ "${PH_PIEH_CMD_OPTS}" != "${OPTARG}" ]]
		then
			if ! confopts_ph.sh -p set -a "${PH_RUNAPP}" -o PH_PIEH_CMD_OPTS="${OPTARG}"
			then
				OPTIND="${PH_OLDOPTIND}"
				OPTARG="${PH_OLDOPTARG}"
				exit 1
			fi
			export PH_PIEH_CMD_OPTS="${OPTARG}"
		fi ;;
			   *)
		>&2 printf "\n\033[1;36m%s\033[0;0m\n" "Usage : start${PH_RUNAPPL}.sh '-m ['menu']' '-p' | -h"
		>&2 printf "\n"
		>&2 printf "%3s\033[1;37m%s\n" "" "Where -h displays this usage"
		>&2 printf "%9s%s\n" "" "- Running this script without parameters will start a new instance of '${PH_RUNAPP}' on its allocated tty and that tty will become the active tty"
		>&2 printf "%12s%s\n" "" "- If '${PH_RUNAPP}' is not an integrated application, startup will fail"
		>&2 printf "%12s%s\n" "" "- If '${PH_RUNAPP}' does not have a tty allocated when starting, the first unallocated tty will automatically be allocated to '${PH_RUNAPP}'"
		>&2 printf "%15s%s\n" "" "- If an application in need of a tty attempts to start but all ttys are already allocated, startup will fail"
		>&2 printf "%12s%s\n" "" "- At any application start, all other running applications will first be stopped"
		>&2 printf "%12s%s\n" "" "  Two exceptions to this rule exist :"
		>&2 printf "%15s%s\n" "" "- Applications marked as persistent remain online"
		>&2 printf "%15s%s\n" "" "- 'PieHelper' will not stop any running applications when starting in 'pts' mode"
		>&2 printf "%12s%s\n" "" "- 'PieHelper' will always terminate after any other application starts successfully"
		>&2 printf "%12s%s\n" "" "- Additionally, the following rule(s) also apply when starting '${PH_RUNAPP}' in 'tty' mode :" 
		>&2 printf "%15s%s\n" "" "- If '${PH_RUNAPP}' is already persistently running on its allocated tty, that tty will become the active tty"
		>&2 printf "%15s%s\n" "" "- If '${PH_RUNAPP}' is already non-persistently running on its allocated tty, startup will fail"
		>&2 printf "%15s%s\n" "" "- If '${PH_RUNAPP}' is already running on a pseudo-terminal, that instance will be replaced by a new instance on its allocated tty"
		>&2 printf "%15s%s\n" "" "- 'PieHelper' will always activate persistence for itself before starting on its allocated tty"
		>&2 printf "%9s%s\n" "" "-p allows switching the start mode for '${PH_RUNAPP}' from the default 'tty' setting to 'pts' to"
		>&2 printf "%9s%s\n" "" "   start an instance of '${PH_RUNAPP}' on a pseudo-terminal instead of on its allocated tty"
		>&2 printf "%12s%s\n" "" "- Specifying -p is optional"
		>&2 printf "%12s%s\n" "" "- Additionally, the following rule(s) also apply when starting '${PH_RUNAPP}' in 'pts' mode :"
		>&2 printf "%15s%s\n" "" "- If '${PH_RUNAPP}' is already persistently running on a pseudo-terminal, startup will be skipped but succeed with a warning" 
		>&2 printf "%15s%s\n" "" "- If '${PH_RUNAPP}' is already non-persistently running on a pseudo-terminal, startup will fail"
		>&2 printf "%15s%s\n" "" "- If '${PH_RUNAPP}' is already running on its allocated tty, that instance will be replaced by a new instance on a pseudo-terminal"
		>&2 printf "%9s%s\n" "" "-m allows starting '${PH_RUNAPP}' directly in menu [menu] instead of the default menu which is the current value of"
		>&2 printf "%9s%s\n" "" "   PieHelper option 'PH_PIEH_CMD_OPTS'"
		>&2 printf "%12s%s\n" "" "- If 'PH_PIEH_CMD_OPTS' has no value, it will priorly be set to 'Main'"
		>&2 printf "%12s%s\n" "" "- Specifying -m is optional"
		>&2 printf "%12s%s\n" "" "- Allowed values for [menu] are :"
		>&2 printf "%15s%s\n" "" "- 'Main' or 'Applications' or 'Support' or "
		>&2 printf "%15s%s\n" "" "- 'System' or 'SystemInteractive' or 'SystemRetained' or 'SystemRetaineds' or"
		>&2 printf "%15s%s\n" "" "- 'Controllers' or 'PS3' or 'PS4' or 'XBOX360' or 'XBOXSX' or"
		>&2 printf "%15s%s\n" "" "- 'Supported' or 'Integrated' or 'Halted' or 'Running' or 'Default' or 'Out-of-scope' or"
		>&2 printf "%15s%s\n" "" "- [appname] where [appname] is the name of a Supported or Default application or"
		>&2 printf "%15s%s\n" "" "- 'AppManagement' or 'AppManagement_[appname]' where [appname] is 'Controllers' or the name of a Supported or Default application or"
		>&2 printf "%15s%s\n" "" "- 'OptsManagement' or 'OptsManagement_[appname]' where [appname] is 'Controllers' or the name of a Supported or Default application or"
		>&2 printf "%15s%s\n" "" "- 'TTYManagement' or 'TTYManagement_[appname]' where [appname] is the name of a Supported or Default application"
		>&2 printf "%12s%s\n" "" "- Specifying [menu] is optional"
		>&2 printf "%15s%s\n" "" "- Omitting a value for [menu] will revert to using the default"
		>&2 printf "%12s%s\033[0;0m\n" "" "- This option will be ignored when switching to an active persistent instance of '${PH_RUNAPP}'"
		>&2 printf "\n"
		OPTIND="${PH_OLDOPTIND}"
		OPTARG="${PH_OLDOPTARG}"
		exit 1 ;;
	esac
done
OPTIND="${PH_OLDOPTIND}"
OPTARG="${PH_OLDOPTARG}"

[[ -z "${PH_MODE}" ]] && \
	PH_MODE="tty"
printf "\n\033[1;36m%s\033[0;0m\n\n" "- Starting '${PH_RUNAPP}'" 
if [[ "$("${PH_SUDO}" cat "/proc/${PPID}/comm" 2>/dev/null)" != restart*sh ]]
then
	printf "%8s%s\033[1;33m%s\033[0;0m\n" "" "--> Checking the application state of " "'${PH_RUNAPP}'" 
	PH_RUNAPP_STATE="$(ph_get_app_state_from_app_name "${PH_RUNAPP}")"
	case "${PH_RUNAPP_STATE}" in Integrated|Halted|Running)
		ph_run_with_rollback -c true -m "${PH_RUNAPP_STATE}" ;;
				*)
		ph_set_result -m "Could not start '${PH_RUNAPP}' since it's not an integrated application"
		ph_run_with_rollback -c false -m "Could not start"
		exit "${?}" ;;
	esac
fi
if [[ -z "${PH_PIEH_CMD_OPTS}" ]]
then
	ph_run_with_rollback -c "ph_set_option_to_value '${PH_RUNAPP}' -r \"PH_PIEH_CMD_OPTS'Main\"" || \
		exit 1
fi
if [[ "${PH_MODE}" == "tty" ]]
then
	printf "%8s%s\n" "" "--> Checking for running applications"
	if [[ "$("${PH_SUDO}" cat "/proc/${PPID}/comm" 2>/dev/null)" == +(?)to+(?).sh ]]
	then
		PH_EXCEPTION="$(nawk '$1 ~ /^stop.*\.sh$/ { \
				print substr($1,5,length($1)-7) \
			}' "${PH_SCRIPTS_DIR}/$("${PH_SUDO}" cat "/proc/${PPID}/comm" 2>/dev/null)" 2>/dev/null)"
	fi
	declare -a PH_STOP_APPS
	read -rd '' -a PH_STOP_APPS < <(ph_get_app_list_by_state -s Running -t exact | \
		nawk -v runappl="^${PH_RUNAPPL}$" -v except="^${PH_EXCEPTION}$" 'BEGIN { \
				RS = " " ; \
				ORS = " " \
			} \
			tolower(substr($0,1,4)) !~ except && tolower(substr($0,1,4)) !~ runappl { \
				print \
			} { \
				next \
			}')
	if [[ "${#PH_STOP_APPS[@]}" -eq "0" ]]
	then
		ph_run_with_rollback -c true -m "None"
	else
		printf "%10s\033[33m%s\033[0m\n" "" "Warning : Stopping currently running application(s) ${PH_STOP_APPS[*]// / and }"
		ph_set_result -r 0
	fi
	for PH_i in "${!PH_STOP_APPS[@]}"
	do
		if ! ph_run_with_rollback -c "ph_do_app_action stop '${PH_STOP_APPS[${PH_i}]}'"
		then
			unset PH_STOP_APPS
			exit 1
		fi
		[[ "$(ph_get_app_state_from_app_name "${PH_STOP_APPS["${PH_i}"]}")" == "Running" ]] && \
			unset PH_STOP_APPS["${PH_i}"]
	done
	if [[ "${#PH_STOP_APPS[@]}" -eq "0" ]]
	then
		ph_set_result -m "${PH_RUNAPP} has succesfully started and no other applications were stopped"
	else
		ph_set_result -m "${PH_RUNAPP} has succesfully started after stopping application(s) ${PH_STOP_APPS[*]// / and }"
	fi
	unset PH_STOP_APPS
	ph_ensure_app_tty "${PH_RUNAPP}" || \
		exit 1
fi
printf "%8s%s\033[1;33m%s\033[0;0m\n" "" "--> Determining the tty of " "'${PH_RUNAPP}'"
PH_RUNAPP_STR_TTY="$(ph_get_app_tty_from_app_name "${PH_RUNAPP}")"
if [[ "${PH_RUNAPP_STR_TTY}" == "-" ]]
then
	ph_run_with_rollback -c true -m "None"
else
	ph_run_with_rollback -c true -m "${PH_RUNAPP_STR_TTY}"
fi
printf "%8s%s\033[1;33m%s\033[0;0m\n" "" "--> Checking for the presence of " "'${PH_RUNAPP}'"
declare -a PH_INSTANCES
read -rd '' -a PH_INSTANCES < <(PH_SUBPID="${BASHPID}" ; pgrep "^start${PH_RUNAPPL}.sh" 2>/dev/null | grep -Ev "^(${$}|${PH_SUBPID})$")
if [[ "${#PH_INSTANCES[@]}" -gt "0" ]]
then
	if [[ "${PH_MODE}" == "tty" ]]
	then
		if [[ "${PH_RUNAPP_STR_TTY}" != "-" && "$(pgrep -t "tty${PH_RUNAPP_STR_TTY}" -f "start${PH_RUNAPPL}.sh" >/dev/null 2>&1 ; echo "$?")" -eq "0" ]]
		then
			unset PH_INSTANCES
			if [[ "$(eval "echo -n \"\$PH_${PH_RUNAPPU}_PERSISTENT\"")" == "no" ]]
			then
				ph_set_result -r 0 -w -m "Could not start '${PH_RUNAPP}' on tty${PH_RUNAPP_STR_TTY} since it's already non-persistently running on that tty"
				ph_run_with_rollback -c false -m "Could not start"
			else
				printf "%10s\033[33m%s\033[0m\n" "" "Warning : Already present on tty${PH_RUNAPP_STR_TTY}"
				ph_set_result -r 0 -w -m "Switching to tty${PH_RUNAPP_STR_TTY} since '${PH_RUNAPP}' is already persistently running on that tty"
				ph_show_result
				sleep 2
				if ! "${PH_SUDO}" chvt "${PH_RUNAPP_STR_TTY}" 2>/dev/null
				then
					ph_set_result -m "An error occurred trying to switch to tty${PH_RUNAPP_STR_TTY}"
					false
				else
					true
				fi
			fi
		else
			ph_run_with_rollback -c true -m "Found on a pseudo-terminal"
			printf "%8s%s\033[1;33m%s\033[0;0m%s\n" "" "--> Stopping " "'${PH_RUNAPP}'" " on a pseudo-terminal"
			for PH_i in "${PH_INSTANCES[@]}"
			do
				if ! "${PH_SUDO}" kill "${PH_i}" 2>/dev/null
				then
					unset PH_INSTANCES
					ph_set_result -m "An error occurred trying to kill process ${PH_i}"
					ph_run_with_rollback -c false -m "Could not stop"
					exit "${?}"
				fi
			done
			unset PH_INSTANCES
			ph_run_with_rollback -c true
			"${PH_SUDO}" rm "${PH_TMP_DIR}/Start.report" 2>/dev/null
			if ph_run_with_rollback -c "ph_set_option_to_value '${PH_RUNAPP}' -r \"PH_PIEH_PERSISTENT'yes\""
			then
				if ! ph_run_with_rollback -c "ph_do_app_action start '${PH_RUNAPP}' \\| tee -a '${PH_TMP_DIR}/Start.report'"
				then
					if [[ "${PH_FG_CONSOLE}" -ne "${PH_RUNAPP_STR_TTY}" ]]
					then
						printf "%8s%s\033[1;33m%s\033[1;37m\n\n" "" "--> Displaying the logfile of the failed start of " "'${PH_RUNAPP}'"
						if cat "${PH_TMP_DIR}/Start.report" 2>/dev/null
						then
							printf "\033[0;0m\n\n"
							ph_run_with_rollback -c true -m "${PH_TMP_DIR}/Start.report"
						else
							printf "%10s\033[0;33m%s\033[0;0m\n" "" "Warning : Could not display logfile '${PH_TMP_DIR}/Start.report' of the failed start of '${PH_RUNAPP}'"
							ph_set_result -r 0
						fi
					else
						:
						####### use new fallback app option here
					fi
					"${PH_SUDO}" rm "${PH_TMP_DIR}/Start.report" 2>/dev/null
					exit 1
				fi
				"${PH_SUDO}" rm "${PH_TMP_DIR}/Start.report" 2>/dev/null
				ph_show_result
			fi
		fi
	else
		unset PH_INSTANCES
		if [[ "${PH_RUNAPP_STR_TTY}" != "-" && "$(pgrep -t "tty${PH_RUNAPP_STR_TTY}" -f "start${PH_RUNAPPL}.sh" >/dev/null 2>&1 ; echo "$?")" -eq "0" ]]
		then
			ph_run_with_rollback -c true -m "Found on tty${PH_RUNAPP_STR_TTY}"
			ph_run_with_rollback -c "ph_do_app_action stop '${PH_RUNAPP}' forced" || \
				exit 1
			printf "%8s%s\033[1;33m%s\033[0;0m%s\n" "" "--> Starting " "'${PH_RUNAPP}'" " on a pseudo-terminal"
			ph_run_with_rollback -c true
			sleep 2
			ph_show_menu "${PH_PIEH_CMD_OPTS}"
		else
			if [[ "$(eval "echo -n \"\$PH_${PH_RUNAPPU}_PERSISTENT\"")" == "no" ]]
			then
				ph_set_result -m "Could not start '${PH_RUNAPP}' since it's already non-persistently running on a pseudo-terminal"
				ph_run_with_rollback -c false -m "Could not start"
			else
				printf "%10s\033[33m%s\033[0m\n" "" "Warning : Already present on a pseudo-terminal"
				ph_set_result -r 0 -w -m "Skipped the start of '${PH_RUNAPP}' since it's already persistently running on a pseudo-terminal"
				ph_show_result
			fi
		fi
	fi
else
	ph_run_with_rollback -c true -m "Not found"
	unset PH_INSTANCES
	if [[ "${PH_MODE}" == "tty" ]]
	then
		"${PH_SUDO}" rm "${PH_TMP_DIR}/Start.report" 2>/dev/null
		if ph_run_with_rollback -c "ph_set_option_to_value '${PH_RUNAPP}' -r \"PH_PIEH_PERSISTENT'yes\""
		then
			if ! ph_run_with_rollback -c "ph_do_app_action start '${PH_RUNAPP}' \\| tee -a '${PH_TMP_DIR}/Start.report'"
			then
				if [[ "${PH_FG_CONSOLE}" -ne "${PH_RUNAPP_STR_TTY}" ]]
				then
					printf "%8s%s\033[1;33m%s\033[1;37m\n\n" "" "--> Displaying the logfile of the failed start of " "'${PH_RUNAPP}'"
					if cat "${PH_TMP_DIR}/Start.report" 2>/dev/null
					then
						printf "\033[0;0m\n\n"
						ph_run_with_rollback -c true -m "${PH_TMP_DIR}/Start.report"
					else
						printf "%10s\033[33m%s\033[0m\n" "" "Warning : Could not display logfile '${PH_TMP_DIR}/Start.report' of the failed start of '${PH_RUNAPP}'"
						ph_set_result -r 0
					fi
				else
					:
					####### use new fallback app option here
				fi
				"${PH_SUDO}" rm "${PH_TMP_DIR}/Start.report" 2>/dev/null
				exit 1
			fi
			"${PH_SUDO}" rm "${PH_TMP_DIR}/Start.report" 2>/dev/null
			ph_show_result
		fi
	else
		printf "%8s%s\033[1;33m%s\033[0;0m%s\n" "" "--> Starting " "'${PH_RUNAPP}'" " on a pseudo-terminal"
		ph_run_with_rollback -c true
		sleep 2
		ph_show_menu "${PH_PIEH_CMD_OPTS}"
	fi
fi
exit "${?}"
