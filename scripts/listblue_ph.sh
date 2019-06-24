#!/bin/ksh
# List bluetooth adapter(s) (by Davy Keppens on 26/12/2018)
# Enable/Disable debug by running 'confpieh_ph.sh -p debug -m listblue_ph.sh'

. $(dirname "$0")/../main/main.sh || exit "$?" && set +x

#set -x

typeset PH_OPTION=""
typeset PH_OLDOPTARG="$OPTARG"
typeset PH_i=""
typeset -i PH_OLDOPTIND="$OPTIND"
typeset -i PH_NUM_ADAPT="0"
typeset -i PH_RETCODE="0"
OPTIND="1"

while getopts h PH_OPTION 2>/dev/null
do
        case "$PH_OPTION" in *)
                >&2 printf "%s\n" "Usage : listblue_ph.sh | -h"
                >&2 printf "\n"
                >&2 printf "%3s%s\n" "" "Where -h displays this usage"
                >&2 printf "%9s%s\n" "" "- Running this script without parameters will provide a listing of the following : "
                >&2 printf "%12s%s\n" "" "- The bluetooth adapter currently set as default"
                >&2 printf "%12s%s\n" "" "- A summary of all bluetooth adapters available on the system"
                >&2 printf "\n"
                OPTIND="$PH_OLDOPTIND" ; OPTARG="$PH_OLDOPTARG" ; exit 1 ;;
        esac
done
OPTIND="$PH_OLDOPTIND"
OPTARG="$PH_OLDOPTARG"

printf "\033[36m%s\033[0m\n" "- Displaying bluetooth adapter currently set as default"
[[ "$PH_CTRL_BLUE_ADAPT" != "none" ]] && printf "%8s%s\n" "" "$PH_CTRL_BLUE_ADAPT" || \
				printf "%8s%s\n" "" "None"
printf "%2s\033[32m%s\033[0m\n\n" "" "SUCCESS"
"$PH_SUDO" systemctl enable bluetooth >/dev/null 2>&1
"$PH_SUDO" systemctl start bluetooth >/dev/null 2>&1
printf "\033[36m%s\033[0m\n" "- Listing all currently available bluetooth adapters on the system"
set -o pipefail
PH_NUM_ADAPT=`"$PH_SUDO" bt-adapter -l 2>/dev/null | nawk -F'\(' '$0 ~ /No adapters found/ { print "None" ; exit 0 } \
							$0 !~ /Available adapters/ { print substr($2,1,length($2)-1) } { next }' 2>/dev/null | wc -l 2>/dev/null`
PH_RETCODE="$?" 
[[ "$PH_RETCODE" -ne 0 && "$PH_NUM_ADAPT" -eq 0 ]] && printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED : Could not list bluetooth adapter(s)" && exit 1
set +o pipefail
for PH_i in `"$PH_SUDO" bt-adapter -l 2>/dev/null | nawk -F'\(' 'BEGIN { ORS = " " } $0 !~ /Available adapters/ { print substr($2,1,length($2)-1) } { next }' 2>/dev/null`
do
	[[ "$PH_CTRL_BLUE_ADAPT" == "$PH_i" ]] && printf "%8s%s\n" "" "$PH_i (Default)" || \
					printf "%8s%s\n" "" "$PH_i"
done
[[ "$PH_NUM_ADAPT" -eq 1 && "$PH_RETCODE" -ne 0 ]] && printf "%10s%s\n" "" "None"
printf "%2s\033[32m%s\033[0m\n\n" "" "SUCCESS"
exit 0
