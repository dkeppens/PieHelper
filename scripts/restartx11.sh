#!/bin/ksh
# Restart X11 (by Davy Keppens on 04/10/2018)
# Enable/Disable debug by running confpieh_ph.sh -d restartx11.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

stopx11.sh $1 || exit $?
startx11.sh || exit $?
exit 0
