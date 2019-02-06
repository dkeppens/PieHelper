#!/bin/ksh
# List Moonlight shared games (by Davy Keppens on 23/11/2018)
# Enable/Disable debug by running confpieh_ph.sh -p debug -m listmoon_ph.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

typeset PH_MOON_PATH=""
typeset PH_OPTION=""
typeset PH_OLDOPTARG="$OPTARG"
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
printf "%s\n" "- Listing Moonlight shared games"
printf "\n"
[[ -z "$PH_MOON_SRV" ]] && printf "%2s%s\n" "" "FAILED : Option PH_MOON_SRV is not configured" && exit 1
$PH_SUDO -E su "$PH_MOON_USER" -c "LD_LIBRARY_PATH=/usr/local/lib:/usr/lib:/lib $PH_MOON_PATH list $PH_MOON_SRV" >/dev/null 2>&1
[[ $? -ne 0 ]] && printf "%2s%s\n" "" "FAILED : Moonlight is not fully configured" && exit 1
[[ -z `$PH_SUDO -E su "$PH_MOON_USER" -c "LD_LIBRARY_PATH=/usr/local/lib:/usr/lib:/lib $PH_MOON_PATH list $PH_MOON_SRV | tail -n +2"` ]] && printf "%2s%s\n" "" "\"none\"" && exit 0
$PH_SUDO -E su "$PH_MOON_USER" -c "LD_LIBRARY_PATH=/usr/local/lib:/usr/lib:/lib $PH_MOON_PATH list $PH_MOON_SRV | tail -n +2"
printf "\n"
printf "%2s%s\n" "" "SUCCESS"
exit 0
