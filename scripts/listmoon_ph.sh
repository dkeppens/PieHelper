#!/bin/ksh
# List Moonlight shared games (by Davy Keppens on 23/11/2018)
# Enable/Disable debug by running confpieh_ph.sh -p debug -m listmoon_ph.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

typeset PH_MOON_PATH=""
typeset PH_OPTION=""
typeset PH_GAME=""
typeset PH_OLDOPTARG="$OPTARG"
typeset -i PH_COUNT=0
typeset -i PH_ANSWER=0
typeset -i PH_TOTAL=0
typeset -i PH_OLDOPTIND=$OPTIND
OPTIND=1

while getopts h PH_OPTION 2>/dev/null
do
        case $PH_OPTION in *)
                >&2 printf "%s\n" "Usage : listmoon_ph.sh | -h"
                >&2 printf "\n"
                >&2 printf "%3s%s\n" "" "Where -h displays this usage"
                >&2 printf "%9s%s\n" "" "- Running this script without parameters will attempt to connect with the remote host configured in option PH_MOON_SRV"
                >&2 printf "%9s%s\n" "" "  and retrieve a list of all games shared to Moonlight from the NVIDIA Geforce Experience software running on that host"
                >&2 printf "\n"
                OPTIND=$PH_OLDOPTIND ; OPTARG="$PH_OLDOPTARG" ; exit 1 ;;
        esac
done
OPTIND=$PH_OLDOPTIND
OPTARG="$PH_OLDOPTARG"

ph_check_app_name -i -a Moonlight || exit $?
PH_MOON_PATH=`nawk '$1 ~ /^Moonlight$/ { printf $2 }' $PH_CONF_DIR/supported_apps 2>/dev/null`
PH_MOON_USER=`nawk '$1 ~ /^Moonlight$/ { printf $2 }' $PH_CONF_DIR/installed_apps 2>/dev/null`
[[ -z "$PH_MOON_SRV" ]] && printf "%2s%s\n" "" "FAILED : Option PH_MOON_SRV is not configured" && exit 1
$PH_SUDO -E su "$PH_MOON_USER" -c "LD_LIBRARY_PATH=/usr/local/lib:/usr/lib:/lib $PH_MOON_PATH list $PH_MOON_SRV" >/dev/null 2>&1
[[ $? -ne 0 ]] && printf "%2s%s\n" "" "FAILED : Moonlight is not fully configured" && exit 1
PH_TOTAL=`$PH_SUDO -E su "$PH_MOON_USER" -c "LD_LIBRARY_PATH=/usr/local/lib:/usr/lib:/lib $PH_MOON_PATH list $PH_MOON_SRV | tail -n +2" | wc -l`
printf "%s\n" "- Listing/Selecting Moonlight shared game(s)"
while [[ $PH_ANSWER -eq 0 || $PH_ANSWER -gt $((PH_TOTAL+1)) ]]
do
	[[ $PH_COUNT -gt 0 ]] && printf "\n%2s%s\n" "" "ERROR : Invalid response"
	[[ -z `$PH_SUDO -E su "$PH_MOON_USER" -c "LD_LIBRARY_PATH=/usr/local/lib:/usr/lib:/lib $PH_MOON_PATH list $PH_MOON_SRV | tail -n +2"` ]] && printf "%2s%s\n" "" "\"none\"" && printf "%2s%s\n\n" "" "SUCCESS" && exit 0
	printf "\n"
	if [[ -z "$PH_MOON_GAME" ]]
	then
		printf "%2s%s\n\n" "" "INFO : No current default set"
		$PH_SUDO -E su "$PH_MOON_USER" -c "LD_LIBRARY_PATH=/usr/local/lib:/usr/lib:/lib $PH_MOON_PATH list $PH_MOON_SRV | tail -n +2"
	else
		$PH_SUDO -E su "$PH_MOON_USER" -c "LD_LIBRARY_PATH=/usr/local/lib:/usr/lib:/lib $PH_MOON_PATH list $PH_MOON_SRV | tail -n +2" | \
						nawk -v curr=^"$PH_MOON_GAME"$ '$2 ~ curr { printf "%-40s%s%s\n", $0, "\t", "Current default" ; next } { printf "%s\n", $0 }'
	fi
	printf "%s\n" "$((PH_TOTAL+1)). Exit"
	printf "\n"
	printf "%2s%s" "" "Your choice for gamestreaming ? "
	read PH_ANSWER 2>/dev/null
	((PH_COUNT++))
done
if [[ $PH_ANSWER -ne $((PH_TOTAL+1)) ]]
then
	printf "%2s%s\n" "" "OK"
	PH_GAME=`$PH_SUDO -E su "$PH_MOON_USER" -c "LD_LIBRARY_PATH=/usr/local/lib:/usr/lib:/lib $PH_MOON_PATH list $PH_MOON_SRV | tail -n +2" | nawk -v game=$PH_ANSWER 'NR ~ game { print $2 ; exit 0 } { next }'`
	confopts_ph.sh -p set -a Moonlight -o PH_MOON_GAME="$PH_GAME" || (printf "2%s%s\n" "" "FAILED" ; return 1) || exit $?
else
	printf "%2s%s\n" "" "SUCCESS"
fi
exit 0
