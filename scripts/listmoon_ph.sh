#!/bin/ksh
# List Moonlight shared games (by Davy Keppens on 23/11/2018)
# Enable/Disable debug by running confpieh_ph.sh -d listmoon_ph.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

typeset PH_MOON_PATH=""

ph_check_app_name -i -a Moonlight || exit $?
PH_MOON_PATH=`nawk '$1 ~ /^Moonlight$/ { printf $2 }' $PH_CONF_DIR/supported_apps`
printf "%s\n" "- Listing Moonlight shared games"
$PH_MOON_PATH list $PH_MOON_SRV | tail -n +3
$PH_MOON_PATH list $PH_MOON_SRV >/dev/null 2>&1
[[ $? -eq 0 ]] && printf "%2s%s\n" "" "SUCCESS" || (printf "%2s%s\n" "" "FAILED" ; return 1) || return $?
