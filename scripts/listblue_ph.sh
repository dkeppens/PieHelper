#!/bin/bash
# List bluetooth adapters (by Davy Keppens on 26/12/2018)
# Enable/Disable debug by running 'confpieh_ph.sh -p debug -m listblue_ph.sh'

if [[ -f "$(dirname "${0}" 2>/dev/null)/app/main.sh" && -r "$(dirname "${0}" 2>/dev/null)/app/main.sh" ]]
then
	source "$(dirname "${0}" 2>/dev/null)/app/main.sh"
	set +x
else
	printf "\n%2s\033[1;31m%s\033[0m\n\n" "" "ABORT : Reinstallation of PieHelper is required (Missing or unreadable critical codebase file '$(dirname "${0}" 2>/dev/null)/app/main.sh'"
	exit 1
fi

#set -x

declare PH_OPTION
declare PH_OLDOPTARG
declare -i PH_OLDOPTIND
declare -i PH_INDEX

PH_OLDOPTARG="${OPTARG}"
PH_OLDOPTIND="${OPTIND}"
PH_OPTION=""
PH_INDEX="0"

OPTIND="1"

while getopts :h PH_OPTION
do
	case "${PH_OPTION}" in *)
		>&2 printf "\033[1;36m%s\033[0;0m\n" "Usage : listblue_ph.sh | -h"
		>&2 printf "\n"
		>&2 printf "%3s\033[1;37m%s\n" "" "Where -h displays this usage"
		>&2 printf "%9s%s\n" "" "- Running this script without parameters will list : "
		>&2 printf "%12s%s\n" "" "- A summary of all available bluetooth adapters"
		>&2 printf "%12s%s\033[0m\n" "" "- The bluetooth adapter currently set as default"
		>&2 printf "\n"
		OPTIND="${PH_OLDOPTIND}"
		OPTARG="${PH_OLDOPTARG}"
		exit 1 ;;
	esac
done
OPTIND="${PH_OLDOPTIND}"
OPTARG="${PH_OLDOPTARG}"

printf "\n\033[1;36m%s\033[0m\n\n" "- Listing bluetooth adapters"
if ph_run_with_rollback -c "ph_enable_services bluetooth"
then
	if ph_run_with_rollback -c "ph_start_services bluetooth"
	then
		printf "%8s%s\n" "" "--> Listing bluetooth adapters"
		if read -r -a PH_BLUE_ADAPTS -d ';' < <("${PH_SUDO}" bt-adapter -l 2>/dev/null | nawk -F"(" '$0 ~ /No adapters found/ { \
				exit 0 \
			} \
			$0 !~ /Available adapters/ { \
				print substr($2,1,length($2)-1) \
			} { \
				next \
			} END { \
				printf ";" \
			}')
		then
			if [[ "${#PH_BLUE_ADAPTS[@]}" -gt "0" ]]
			then
				printf "\n"
				for PH_INDEX in "${!PH_BLUE_ADAPTS[@]}"
				do
					if [[ "${PH_CONT_BLUE_ADAPT}" == "${PH_BLUE_ADAPTS["${PH_INDEX}"]}" ]]
					then
						printf "%12s\033[1;37%-4s\033[1;33m%-10s\t\033[1;37m%s\033[0m\n" "" "$((PH_INDEX+1))." "${PH_BLUE_ADAPTS["${PH_INDEX}"]}" "(Default)"
					else
						printf "%12s\033[1;37m%-4s\033[1;33m%-10s\033[0m\n" "" "$((PH_INDEX+1))." "${PH_BLUE_ADAPTS["${PH_INDEX}"]}"
					fi
				done
				printf "\n"
				ph_run_with_rollback -c true
			else
				printf "%10s\033[33m%s\033[0m\n" "" "Warning : None"
				ph_set_result -w -r 0 -m "No bluetooth adapters found"
			fi
		else
			ph_set_result -m "An error occurred trying to determine all available bluetooth adapters"
			ph_run_with_rollback -c false -m "Could not list" || \
				exit 1
		fi
		unset PH_BLUE_ADAPTS 2>/dev/null
	fi
fi
ph_show_result
exit "${?}"
