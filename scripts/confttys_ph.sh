#!/bin/bash
# Run application management routines (by Davy Keppens on 03/11/2018)
# Enable/Disable debug by running 'confpieh_ph.sh -p debug -m confttys_ph.sh'

if [[ -r "$(dirname "${0}" 2>/dev/null)/framework/main/main.sh" ]]
then
	if ! source "$(dirname "${0}" 2>/dev/null)/framework/main/main.sh"
	then
		set +x
		>&2 printf "\n%2s\033[1;31m%s\033[0m\n\n" "" "ABORT : Reinstallation of PieHelper is required (Corrupted critical codebase file '$(dirname "${0}" 2>/dev/null)/framework/main/main.sh'"
		exit 1
	fi
	set +x
else
	>&2 printf "\n%2s\033[1;31m%s\033[0m\n\n" "" "ABORT : Reinstallation of PieHelper is required (Missing or unreadable critical codebase file '$(dirname "${0}" 2>/dev/null)/framework/main/main.sh'"
	exit 1
fi

#set -x

declare PH_APP
declare PH_APP_STR_TTY
declare PH_HEADER
declare PH_ROUTINE
declare PH_OPTION
declare PH_OLDOPTARG
declare -i PH_OLDOPTIND

declare -ix PH_ROUTINE_DEPTH
declare -ix PH_SKIP_DEPTH_MEMBERS
declare -ix PH_ROUTINE_FLAG

PH_OLDOPTARG="${OPTARG}"
PH_OLDOPTIND="${OPTIND}"
PH_APP=""
PH_APP_STR_TTY=""
PH_HEADER="Run a specified routine on a tty"
PH_ROUTINE=""
PH_OPTION=""

OPTIND="1"
PH_ROUTINE_DEPTH="0"
PH_SKIP_DEPTH_MEMBERS="0"
PH_ROUTINE_FLAG="1"

while getopts :r:t:a:h PH_OPTION
do
	case "${PH_OPTION}" in r)
		[[ -n "${PH_ROUTINE}" || "${OPTARG}" != @(move|list|info) ]] && \
			(! confttys_ph.sh -h) && \
			OPTARG="${PH_OLDOPTARG}" && \
			OPTIND="${PH_OLDOPTIND}" && \
			exit 1
		PH_ROUTINE="${OPTARG}" ;;
			   t)
		[[ -n "${PH_APP_STR_TTY}" || "${OPTARG}" != @(+([[:digit:]])|prompt|auto) || \
			( "${OPTARG}" == @(+([[:digit:]])) && ( "${OPTARG}" -le "1" || "${OPTARG}" -gt "${PH_PIEH_MAX_TTYS}" )) ]] && \
			(! confttys_ph.sh -h) && \
			OPTARG="${PH_OLDOPTARG}" && \
			OPTIND="${PH_OLDOPTIND}" && \
			exit 1
		PH_APP_STR_TTY="-t ${OPTARG}" ;;
			   a)
		[[ -n "${PH_APP}" || -z "${OPTARG}" ]] && \
			(! confttys_ph.sh -h) && \
			OPTARG="${PH_OLDOPTARG}" && \
			OPTIND="${PH_OLDOPTIND}" && \
			exit 1
		PH_APP="-a ${OPTARG}" ;;
			   *)
		>&2 printf "\n\n"
		>&2 printf "%2s\033[1;36m%s%s\033[1;4;35m%s\033[0m\n" "" "TTYs" " : " "${PH_HEADER}"
		>&2 printf "\n\n"
		>&2 printf "%4s\033[1;5;33m%s\033[0m\n" "" "General options"
		>&2 printf "\n\n"
		>&2 printf "%6s\033[1;36m%s\033[1;37m%s\n" "" "$(basename "${0}" 2>/dev/null) : " "-r [routine] -t [[tty]|\"prompt\"|\"auto\"] |"
		>&2 printf "%23s%s\n" "" "-h"
		>&2 printf "\n"
		>&2 printf "%15s%s\n" "" "Where : -h displays this usage"
		>&2 printf "%15s%s\n" "" "-t Allows selecting the tty to operate on as [tty]"
		>&2 printf "%18s%s\n" "" "- Supported values for [tty] are :"
		>&2 printf "%21s%s\n" "" "- A numeric value from 2 up to and including the value of PieHelper option 'PH_PIEH_MAX_TTYS'"
		>&2 printf "%21s%s\n" "" "- Reserved keyword 'prompt' which allows for interactive [tty] specification"
		>&2 printf "%21s%s\n" "" "- Reserved keyword 'auto' which will select the first unallocated tty within the allowed numeric range"
		>&2 printf "%23s%s\n" "" "-r allows specifying a tty routine [routine] to run"
		>&2 printf "%25s%s\n" "" "- Supported values for [routine] are :"
		>&2 printf "%27s%s\n" "" "- \"list\" will list all ttys allocated to an application and the name of that application"
		>&2 printf "%27s%s\n" "" "- \"info\" will show general information about a specified tty [tty]"
		>&2 printf "%27s%s\n" "" "- \"move\" will allocate the specified tty [tty] to an application named [app]"
		>&2 printf "\n"
		>&2 printf "%4s\033[1;5;33m%s\033[0m\n" "" "Routine-specific options"
		>&2 printf "\n"
		>&2 printf "%6s\033[1;36m%s\033[1;5;33m%s\033[0;1;37m\n" "" "$(basename "${0}" 2>/dev/null) : " "-r \"move\" -t [[tty]|\"prompt\"|\"auto\"] -a [[app]\"prompt\"]"
		>&2 printf "\n"
		>&2 printf "%15s\033[0m\033[1;37m%s\n" "" "Where : -a Allows specifying an application named [app]"
		>&2 printf "%18s%s\n" "" "- Supported values for [app] are :"
		>&2 printf "%21s%s\n" "" "- The name of an Integrated, Halted or Running application"
		>&2 printf "%21s%s\033[0m\n" "" "- Reserved keyword 'prompt' which allows for interactive [app] specification"
		>&2 printf "\n"
		OPTARG="${PH_OLDOPTARG}"
		OPTIND="${PH_OLDOPTIND}"
		exit 1 ;;
	esac
done
OPTARG="${PH_OLDOPTARG}"
OPTIND="${PH_OLDOPTIND}"

[[ -z "${PH_ROUTINE}" || ( "${PH_ROUTINE}" != "move" && -n "${PH_APP}" ) || ( "${PH_ROUTINE}" != @(info|move) && -n "${PH_APP_STR_TTY}" ) || \
	( "${PH_ROUTINE}" == @(info|move) && -z "${PH_APP_STR_TTY}" ) || ( "${PH_ROUTINE}" == "move" && -z "${PH_APP}" ) || \
	( -n "${PH_APP}" && "$(ph_check_app_state_validity -a "${PH_APP}" -q -i; echo "${?}")" -ne "0" ) ]] && \
	(! confttys_ph.sh -h) && \
	exit 1

ph_do_app_routine -r "${PH_ROUTINE}" ${PH_APP} ${PH_APP_STR_TTY}
exit "${?}"
