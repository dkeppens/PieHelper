#!/bin/ksh
# Restart Emulationstation (by Davy Keppens on 04/10/2018)
# Enable/Disable debug by running confpieh_ph.sh -d restartemul.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

stopemul.sh $1 || exit $?
startemul.sh || exit $?
exit 0
