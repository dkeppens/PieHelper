#!/bin/ksh
# Restart Moonlight (by Davy Keppens on 04/10/2018)
# Enable/Disable debug by running confpieh_ph.sh -d restartmoon.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

stopmoon.sh $1 || exit $?
startmoon.sh || exit $?
exit 0
