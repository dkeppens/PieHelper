#!/bin/ksh
# Restart Kodi (by Davy Keppens on 04/10/2018)
# Enable/Disable debug by running confpieh_ph.sh -d restartkodi.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

stopkodi.sh $1 || exit $?
startkodi.sh || exit $?
exit 0
