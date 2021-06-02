#!/bin/ksh
# List Moonlight shared games (by Davy Keppens on 23/11/2018)
# Enable/Disable debug by running 'confpieh_ph.sh -p debug -m listmoon_ph.sh'

. "$(dirname "$0")"/../main/main.sh || exit "$?" && set +x

#set -x

typeset PH_MOON_PATH=""
typeset PH_OPTION=""
typeset PH_GAME=""
typeset PH_OLDOPTARG="$OPTARG"
typeset -i PH_OLDOPTIND="$OPTIND"
typeset -i PH_COUNT="0"
typeset -i PH_ANSWER="0"
typeset -i PH_TOTAL="0"

OPTIND="1"

while getopts h PH_OPTION 2>/dev/null
do
        case "$PH_OPTION" in *)
                >&2 printf "\033[36m%s\033[0m\n" "Usage : listmoon_ph.sh | -h"
                >&2 printf "\n"
                >&2 printf "%3s%s\n" "" "Where -h displays this usage"
                >&2 printf "%9s%s\n" "" "- Running this script without parameters will attempt to connect with the remote host configured in option PH_MOON_SRV"
                >&2 printf "%9s%s\n" "" "  and retrieve a list of all games shared to Moonlight from the NVIDIA Geforce Experience software running on that host"
                >&2 printf "\n"
                OPTIND="$PH_OLDOPTIND" ; OPTARG="$PH_OLDOPTARG" ; exit 1 ;;
        esac
done
OPTIND="$PH_OLDOPTIND"
OPTARG="$PH_OLDOPTARG"

printf "\n\033[36m%s\033[0m\n\n" "- Listing/Selecting Moonlight shared game(s)"
if ph_check_app_state_validity -s -a Moonlight
then
	PH_MOON_PATH="$(nawk '$1 ~ /^Moonlight$/ { printf $3 }' "$PH_CONF_DIR"/supported_apps 2>/dev/null)"
	PH_MOON_USER="$(nawk '$1 ~ /^Moonlight$/ { printf $2 }' "$PH_CONF_DIR"/integrated_apps 2>/dev/null)"
	PH_MOON_USER="moonlight"
	if [[ -z "$PH_MOON_SRV" ]]
	then
		ph_set_result -r 1 -m "Option 'PH_MOON_SRV' is unconfigured"
	else
		if ! "$PH_SUDO" -E su "$PH_MOON_USER" -c "LD_LIBRARY_PATH=/usr/local/lib:/usr/lib:/lib $PH_MOON_PATH list $PH_MOON_SRV" >/dev/null 2>&1
		then
			ph_set_result -r 1 -m "'Moonlight' is unconfigured : First configure 'Moonlight' through the PieHelper menu or run 'confapps_ph.sh -p conf -a Moonlight'"
		else
			PH_TOTAL="$("$PH_SUDO" -E su "$PH_MOON_USER" -c "LD_LIBRARY_PATH=/usr/local/lib:/usr/lib:/lib $PH_MOON_PATH list $PH_MOON_SRV | tail -n +2" | wc -l)"
			while [[ "$PH_ANSWER" -eq "0" || "$PH_ANSWER" -gt "$((PH_TOTAL+1))" ]]
			do
				[[ "$PH_COUNT" -gt "0" ]] && printf "\n%2s\033[31m%s\033[0m\n\n" "" "ERROR : Invalid response"
				printf "%8s%s\n\n" "" "--> Choose NVIDIA SHIELD default game for streaming"
				if [[ -z "$PH_MOON_GAME" ]]
				then
					printf "%2s%s\n\n" "" "INFO : No default set"
					"$PH_SUDO" -E su "$PH_MOON_USER" -c "LD_LIBRARY_PATH=/usr/local/lib:/usr/lib:/lib $PH_MOON_PATH list $PH_MOON_SRV | tail -n +2"
				else
					"$PH_SUDO" -E su "$PH_MOON_USER" -c "LD_LIBRARY_PATH=/usr/local/lib:/usr/lib:/lib $PH_MOON_PATH list $PH_MOON_SRV | tail -n +2" | \
						nawk -v curr=^"$PH_MOON_GAME"$ '$2 ~ curr { printf "%-40s%s%s\n", $0, "\t", "default" ; next } { printf "%s\n", $0 }' 2>/dev/null
				fi
				printf "%s\n" "$((PH_TOTAL+1)). Exit"
				printf "\n"
				printf "%10s%s" "" "Your choice : "
				read PH_ANSWER 2>/dev/null
				((PH_COUNT++))
			done
			printf "\n"
			if [[ "$PH_ANSWER" -ne "$((PH_TOTAL+1))" ]]
			then
				PH_GAME="$("$PH_SUDO" -E su "$PH_MOON_USER" -c "LD_LIBRARY_PATH=/usr/local/lib:/usr/lib:/lib $PH_MOON_PATH list $PH_MOON_SRV | tail -n +2" 2>/dev/null | \
						nawk -v game="$PH_ANSWER" 'NR ~ game { print $2 ; exit 0 } { next }' 2>/dev/null)"
				printf "%10s\033[32m%s\033[0m\n" "" "OK ('$PH_GAME')"
				ph_set_result -r 0
				ph_set_option_to_value Moonlight -r "PH_MOON_GAME'$PH_GAME"
				ph_set_result -r "$?"
			else
				printf "%10s\033[32m%s\033[0m\n" "" "OK"
				ph_set_result -r 0 -m "Quit by user" -w
			fi
		fi
	fi
fi
ph_show_result
exit "$?"
