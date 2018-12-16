#!/bin/ksh
# Restart PieHelper (by Davy Keppens on 04/10/2018)
# Enable/Disable debug by running confpieh_ph.sh -d restartpieh.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

typeset PH_RUNAPP="PieHelper"
typeset PH_OPTION=""
typeset PH_FLAG=""
typeset PH_OLDOPTARG="$OPTARG"
typeset -l PH_RUNAPPL=`echo $PH_RUNAPP | cut -c1-4`
typeset -i PH_OLDOPTIND=$OPTIND
OPTIND=1


while getopts ph PH_OPTION
do
	case $PH_OPTION in p)
		[[ `tty` != /dev/pts/* ]] && printf "%s\n" "- Restarting $PH_RUNAPP" && printf "%2s%s\n" "" "FAILED : Not currently on a pseudo-terminal" && \
						OPTIND=$PH_OLDOPTIND && OPTARG="$PH_OLDOPTARG" && exit 1
		PH_FLAG="pseudo" ;;
			   *)
                >&2 printf "%s\n" "Usage : restart$PH_RUNAPPL.sh -h|-p"
                >&2 printf "\n"
                >&2 printf "%3s%s\n" "" "Where -h displays this usage"
                >&2 printf "%9s%s\n" "" "-p requests to attempt restarting an instance of $PH_RUNAPP running on a pseudo-terminal"
                >&2 printf "\n"
		OPTIND=$PH_OLDOPTIND
		OPTARG="$PH_OLDOPTARG"
                exit 1 ;;
	esac
done
OPTIND=$PH_OLDOPTIND
OPTARG="$PH_OLDOPTARG"
if [[ "$PH_FLAG" == "" ]]
then
	$PH_SCRIPTS_DIR/stop$PH_RUNAPPL.sh force || exit $?
	$PH_SCRIPTS_DIR/start$PH_RUNAPPL.sh || exit $?
else
	$PH_SCRIPTS_DIR/stop$PH_RUNAPPL.sh -p || exit $?
	$PH_SCRIPTS_DIR/start$PH_RUNAPPL.sh -p || exit $?
fi
exit 0
