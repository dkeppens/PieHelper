#!/bin/ksh
# Restart Bash (by Davy Keppens on 04/10/2018)
# Enable/Disable debug by running confpieh_ph.sh -d restartbash.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

stopbash.sh $1 || exit $?
startbash.sh || exit $?
exit 0
