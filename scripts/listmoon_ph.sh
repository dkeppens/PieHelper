#!/bin/bash
# List games for Moonlight shared by an NVIDIA SHIELD server (by Davy Keppens on 23/11/2018)
# Enable/Disable debug by running 'confpieh_ph.sh -p debug -m listmoon_ph.sh'

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

declare PH_APP_EXEC
declare PH_APP_USER
declare PH_APP_STATE
declare PH_APP_INST_STATE
declare PH_MOON_GAME
declare PH_MESSAGE
declare PH_OPTION
declare PH_OLDOPTARG
declare -i PH_OLDOPTIND
declare -i PH_COUNT
declare -i PH_ANSWER
declare -i PH_INDEX

PH_OLDOPTARG="${OPTARG}"
PH_OLDOPTIND="${OPTIND}"
PH_APP_EXEC=""
PH_APP_USER=""
PH_APP_STATE=""
PH_APP_INST_STATE=""
PH_MOON_GAME=""
PH_MESSAGE="Moonlight has not been"
PH_OPTION=""
PH_COUNT="0"
PH_ANSWER="0"
PH_INDEX="0"

OPTIND="1"

while getopts :h PH_OPTION
do
	case "${PH_OPTION}" in *)
		>&2 printf "\n\n"
		>&2 printf "%2s\033[1;36m%s%s\033[1;4;35m%s\033[0m\n" "" "Moonlight games" " : " "Select one of the games shared by NVIDIA SHIELD as the default for Moonlight streaming"
		>&2 printf "\n\n"
		>&2 printf "%4s\033[1;5;33m%s\033[0m\n" "" "General options"
		>&2 printf "\n\n"
		>&2 printf "%6s\033[1;36m%s\033[1;37m%s\n" "" "$(basename "${0}" 2>/dev/null) : " "| -h"
		>&2 printf "\n"
		>&2 printf "%15s\033[0m\033[1;37m%s\n" "" "Where : -h displays this usage"
		>&2 printf "%9s%s\n" "" "- Running this script without parameters will :"
		>&2 printf "%12s%s\033[1;33m%s\033[0m\n" "" "- Connect to an NVIDIA SHIELD server, defined by Moonlight option " "'PH_MOON_SRV'"
		>&2 printf "%12s\033[1;37m%s\n" "" "- Retrieve a list of shared games that can be streamed to Moonlight"
		>&2 printf "%12s%s\033[0m\n" "" "- Allow setting one of those games as the default game for Moonlight"
		>&2 printf "\n"
		OPTIND="${PH_OLDOPTIND}"
		OPTARG="${PH_OLDOPTARG}"
		exit 1 ;;
	esac
done
OPTIND="${PH_OLDOPTIND}"
OPTARG="${PH_OLDOPTARG}"

printf "\n\033[1;36m%s\033[0m\n\n" "- Listing shared games"
printf "%8s%s\n" "" "--> Checking Moonlight states"
PH_APP_STATE="$(ph_get_app_state_from_app_name Moonlight)"
PH_APP_INST_STATE="$(ph_get_app_inst_state_from_app_name Moonlight)"
if [[ "${PH_APP_STATE}" != "Default" && "${PH_APP_INST_STATE}" == *I ]]
then
	ph_run_with_rollback -c true -m "${PH_APP_STATE}"
	printf "%8s%s\n" "" "--> Checking for an NVIDIA SHIELD server"
	if [[ -z "${PH_MOON_SRV}" ]]
	then
		ph_set_result -m "Could not list games since the NVIDIA SHIELD server is unknown (option 'PH_MOON_SRV' has no value)"
	else
		if ping -c 1 "${PH_MOON_SRV}" >/dev/null 2>&1
		then
			ph_run_with_rollback -c true -m "${PH_MOON_SRV}"
			PH_APP_EXEC="$(ph_get_app_executable -a Moonlight)"
			PH_APP_USER="$(ph_get_app_user_from_app_name Moonlight)"
			printf "%8s%s\033[1;33m%s\033[0m\n" "" "--> Checking pairing with SHIELD server " "'${PH_MOON_SRV}'"
			if ! "${PH_SUDO}" -u "${PH_APP_USER}" LD_LIBRARY_PATH=/usr/local/lib:/usr/lib:/lib "${PH_APP_EXEC}" list "${PH_MOON_SRV}" >/dev/null 2>&1
			then
				printf "%10s\033[33m%s\n" "" "Warning : Not paired"
				ph_set_result -r 0
				printf "%8s%s\033[1;33m%s\033[0m\n" "" "--> Pairing with SHIELD server " "'${PH_MOON_SRV}'"
				if ! "${PH_SUDO}" -u "${PH_APP_USER}" LD_LIBRARY_PATH=/usr/local/lib:/usr/lib:/lib "${PH_APP_EXEC}" pair "${PH_MOON_SRV}" 2>/dev/null
				then
					ph_set_result -m "An error occurred trying to pair with NVIDIA SHIELD server '${PH_MOON_SRV}'"
					ph_run_with_rollback -c false -m "Could not pair"
					exit "${?}"
				fi
			fi
			ph_run_with_rollback -c true
			printf "%8s%s\n" "" "--> Choose the default game for Moonlight streaming"
			if read -r -a PH_MOON_GAMES -d ';' < <("${PH_SUDO}" -u "${PH_APP_USER}" LD_LIBRARY_PATH=/usr/local/lib:/usr/lib:/lib "${PH_APP_EXEC}" list "${PH_MOON_SRV}" 2>/dev/null | nawk ' \
				$1 ~ /^[[:digit:]]+\.$/ { \
					$1 = "" ; \
					print $0 \
				} { \
					next \
				} END { \
					printf ";" \
				}')
			then
				if [[ "${#PH_MOON_GAMES[@]}" -eq "0" ]]
				then
					printf "%10s\033[33m%s\033[0m\n" "" "Warning : No shared games found"
					ph_set_result -r 0 -w -m "No games are currently shared by NVIDIA SHIELD server '${PH_MOON_SRV}'"
				else
					while [[ "${PH_ANSWER}" -lt "1" || "${PH_ANSWER}" -gt "$(("${#PH_MOON_GAMES[@]}"+1))" ]]
					do
						if [[ "${PH_COUNT}" -gt "0" ]]
						then
							printf "\n%10s\033[33m%s\033[0m\n" "" "Warning : Invalid response"
							printf "%8s%s\n\n" "" "--> Choose the default game for Moonlight streaming"
						else
							printf "\n"
						fi
						if [[ -z "${PH_MOON_GAME}" ]]
						then
							printf "%10s%s\033[1;37m%s\033[0m\n\n" "" "INFO : " "No default set"
						fi
						for PH_INDEX in "${!PH_MOON_GAMES[@]}"
						do
							if [[ "${PH_MOON_GAMES["${PH_INDEX}"]}" == "${PH_MOON_GAME}" ]]
							then
								printf "%12s\033[1;37m%-4s\033[1;33m%-10s\t\033[1;37m%s\033[0m" "" "$((PH_INDEX+1))." "${PH_MOON_GAMES["${PH_INDEX}"]}" "(Default)"
							else
								printf "%12s\033[1;37m%-4s\033[1;33m%-10s\033[0m" "" "$((PH_INDEX+1))." "${PH_MOON_GAMES["${PH_INDEX}"]}"
							fi
						done
						printf "%12s\033[1;37m%-4s\033[1;33m%-10s\033[0m\n" "" "$(("${#PH_MOON_GAMES[@]}"+1))." "Exit"
						printf "\n"
						printf "%10s\033[1;37m%s\033[0m" "" "Your choice : "
						read -r PH_ANSWER 2>/dev/null
						((PH_COUNT++))
					done
					printf "\n"
					if [[ "${PH_ANSWER}" -ne "$(("${#PH_MOON_GAMES[@]}"+1))" ]]
					then
						ph_run_with_rollback -c true -m "${PH_MOON_GAMES["$((PH_ANSWER-1))"]}"
						ph_run_with_rollback -c "ph_set_option_to_value Moonlight -r \"PH_MOON_GAME'${PH_MOON_GAMES[$((PH_ANSWER-1))]}\"" || \
							exit 1
						ph_set_result -m "The default game for Moonlight streaming is now '${PH_MOON_GAMES[$((PH_ANSWER-1))]}'"
					else
						ph_run_with_rollback -c true
						ph_set_result -w -m "Quitting at user request"
					fi
				fi
				unset PH_MOON_GAMES
				ph_show_result
				exit "${?}"
			else
				unset PH_MOON_GAMES 2>/dev/null
				ph_set_result -r 1 -m "An error occurred trying to list games shared by NVIDIA SHIELD server '${PH_MOON_SRV}'"
			fi
		else
			ph_set_result -m "Could not list games since NVIDIA SHIELD server '${PH_MOON_SRV}' is unavailable"
		fi
	fi
	ph_run_with_rollback -c false -m "Could not list"
else
	if [[ "${PH_APP_STATE}" == "Default" ]]
	then
		PH_MESSAGE="${PH_MESSAGE} supported"
	fi
	if [[ "${PH_APP_INST_STATE}" == *U ]]
	then
		if [[ "${PH_MESSAGE}" == *supported ]]
		then
			PH_MESSAGE="${PH_MESSAGE} and installed"
		else
			PH_MESSAGE="${PH_MESSAGE} installed"
		fi
	fi
	ph_set_result -m "${PH_MESSAGE} yet"
	ph_run_with_rollback -c false -m "Invalid state"
fi
ph_show_result
exit "${?}"
