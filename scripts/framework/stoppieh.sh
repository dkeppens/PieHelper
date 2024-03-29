#!/bin/bash
# Run 'PieHelper' stop action (by Davy Keppens on 04/10/2018)
# Enable/Disable debug by running 'confpieh_ph.sh -p debug -m stoppieh.sh'

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
declare PH_STOPAPP
declare PH_STOPAPP_STATE
declare PH_STOP_MODE
declare PH_MODE
declare PH_OPTION
declare PH_OLDOPTARG
declare -i PH_OLDOPTIND
declare -i PH_STOPAPP_TTY
declare -i PH_SUBPID
declare -l PH_STOPAPPL

PH_OLDOPTARG="${OPTARG}"
PH_OLDOPTIND="${OPTIND}"
PH_i=""
PH_STOPAPP="PieHelper"
PH_STOPAPP_STATE=""
PH_STOP_MODE=""
PH_MODE=""
PH_OPTION=""
PH_STOPAPP_TTY="0"
PH_SUBPID="0"
PH_STOPAPPL="${PH_STOPAPP:0:4}"

OPTIND="1"

while getopts :pfh PH_OPTION
do
	case "${PH_OPTION}" in p)
		[[ -n "${PH_MODE}" ]] && \
			(! "stop${PH_STOPAPPL}.sh" -h) && \
			OPTIND="${PH_OLDOPTIND}" && \
			OPTARG="${PH_OLDOPTARG}" && \
			exit 1
		PH_MODE="pts" ;;
			       f)
		[[ -n "${PH_STOP_MODE}" ]] && \
			(! "stop${PH_STOPAPPL}.sh" -h) && \
			OPTIND="${PH_OLDOPTIND}" && \
			OPTARG="${PH_OLDOPTARG}" && \
			exit 1
		PH_STOP_MODE="forced" ;;
			       *)
		>&2 printf "\n\033[1;36m%s\033[0;0m\n" "Usage : stop${PH_STOPAPPL}.sh '-p' | -h"
		>&2 printf "\n"
		>&2 printf "%3s\033[1;37m%s\n" "" "Where -h displays this usage"
		>&2 printf "%9s%s\n" "" "- Running this script without parameters will stop an instance of '${PH_STOPAPP}' running on its allocated tty"
		>&2 printf "%12s%s\n" "" "- If '${PH_STOPAPP}' is not a supported application, stop will fail"
		>&2 printf "%12s%s\n" "" "- If a tty is allocated to '${PH_STOPAPP}' it remains allocated"
		>&2 printf "%15s%s\n" "" "- An applications tty is freed only when unintegrating the application"
		>&2 printf "%12s%s\n" "" "- Additionally, the following rule(s) also apply when stopping '${PH_STOPAPP}' in 'tty' mode :"
		>&2 printf "%15s%s\n" "" "- If no active instance of '${PH_STOPAPP}' can be found on its allocated tty, stop will be skipped but succeed with a warning"
		>&2 printf "%15s%s\n" "" "- If '${PH_STOPAPP}' is running on a pseudo-terminal, stop will fail"
		>&2 printf "%9s%s\n" "" "-p allows switching the stop mode from the default 'tty' setting to 'pts' to"
		>&2 printf "%9s%s\n" "" "   stop an instance of '${PH_STOPAPP}' that is running on a pseudo-terminal instead of on its allocated tty"
		>&2 printf "%12s%s\n" "" "- Specifying -p is optional"
		>&2 printf "%12s%s\n" "" "- Additionally, the following rule(s) also apply when stopping '${PH_STOPAPP}' in 'pts' mode :"
		>&2 printf "%15s%s\n" "" "- If no active instance of '${PH_STOPAPP}' can be found on a pseudo-terminal, stop will be skipped but succeed with a warning"
		>&2 printf "%15s%s\033[0;0m\n" "" "- If '${PH_STOPAPP}' is running on its allocated tty, stop will fail"
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
[[ -z "${PH_STOP_MODE}" ]] && \
	PH_STOP_MODE="normal"
printf "\n\033[1;36m%s\033[0;0m\n\n" "- Stopping '${PH_STOPAPP}'"
printf "%8s%s\033[1;33m%s\033[0;0m\n" "" "--> Checking the application state of " "'${PH_STOPAPP}'"
PH_STOPAPP_STATE="$(ph_get_app_state_from_app_name "${PH_STOPAPP}")"
case "${PH_STOPAPP_STATE}" in Supported|Integrated|Halted)
	ph_set_result -w -m "Skipping the stop of '${PH_STOPAPP}' since it is already stopped"
	ph_run_with_rollback -c true -m "Nothing to do"
	ph_show_result ;;
		Running)
	ph_run_with_rollback -c true "${PH_STOPAPP_STATE}"
	printf "%8s%s\033[1;33m%s\033[0;0m\n" "" "--> Determining the tty of " "'${PH_STOPAPP}'"
	PH_STOPAPP_TTY="$(ph_get_app_tty_from_app_name "${PH_STOPAPP}")"
	ph_run_with_rollback -c true -m "tty${PH_STOPAPP_TTY}"
	printf "%8s%s\033[1;33m%s\033[0;0m%s\033[1;37m%s\033[0;0m\n" "" "--> Checking if " "'${PH_STOPAPP}'" " is running on its tty " "(tty${PH_STOPAPP_TTY})"
	if pgrep -t "tty${PH_STOPAPP_TTY}" -f "start${PH_STOPAPPL}.sh" >/dev/null 2>&1
	then
		if [[ "${PH_MODE}" == "tty" ]]
		then
			ph_run_with_rollback -c true -m "Yes"
			[[ "${PH_STOP_MODE}" == "normal" && "$("${PH_SUDO}" cat "/proc/${PPID}/comm" 2>/dev/null)" != @(start*sh|+(?)to+(?).sh|restart!("${PH_STOPAPPL}").sh) ]] && \
				PH_STOP_MODE="forced"
			if ph_run_with_rollback -c "ph_do_app_action stop '${PH_STOPAPP}' '${PH_STOP_MODE}'"
			then
				ph_show_result
			fi
		else
			ph_set_result -m "Could not stop '${PH_STOPAPP}' since it's running on a tty -> Do not use option '-p'"
			ph_run_with_rollback -c false -m "Yes"
		fi
	else
		if [[ "${PH_MODE}" == "tty" ]]
		then
			ph_set_result -m "Could not stop '${PH_STOPAPP}' since it's running on a pseudo-terminal -> Use option '-p'"
			ph_run_with_rollback -c false -m "No"
		else
			ph_run_with_rollback -c true -m "No"
			printf "%8s%s\033[1;33m%s\033[0;0m\n" "" "--> Stopping " "'${PH_STOPAPP}'"
			declare -a PH_INSTANCES
			if ! read -rd '' -a PH_INSTANCES < <(PH_SUBPID="${BASHPID}" ; pgrep "^start${PH_STOPAPPL}.sh" 2>/dev/null | grep -Ev "^(${$}|${PH_SUBPID})$")
			then
				unset PH_INSTANCES
				ph_set_result -m "An error occurred trying to determine a list of running instances of '${PH_STOPAPP}'" 
				ph_run_with_rollback -c false -m "Could not stop '${PH_STOPAPP}' on a pseudo-terminal"
			else
				for PH_i in "${PH_INSTANCES[@]}"
				do
					if ! "${PH_SUDO}" kill "${PH_i}" >/dev/null 2>&1
					then
						unset PH_INSTANCES
						ph_set_result -m "An error occurred trying to kill process ID '${PH_i}'"
						ph_run_with_rollback -c false -m "Could not stop '${PH_STOPAPP}' on a pseudo-terminal" || \
							exit 1
					fi
				done
				unset PH_INSTANCES
				ph_run_with_rollback -c true
				ph_show_result
			fi
		fi
	fi ;;
		*)	
	ph_set_result -m "Could not stop '${PH_STOPAPP}' since it's not a supported application"
	ph_run_with_rollback -c false -m "${PH_STOPAPP_STATE}" ;;
esac
exit "${?}"
