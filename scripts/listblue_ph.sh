#!/bin/bash
# List bluetooth adapter(s) (by Davy Keppens on 26/12/2018)
# Enable/Disable debug by running 'confpieh_ph.sh -p debug -m listblue_ph.sh'

. "$(dirname "$0")"/../main/main.sh || exit "$?" && set +x

#set -x

declare PH_OPTION=""
declare PH_i=""
declare PH_OLDOPTARG="$OPTARG"
declare -i PH_OLDOPTIND="$OPTIND"
declare -i PH_NR_ADAPTS="0"
declare -i PH_RET_CODE="0"

OPTIND="1"

while getopts h PH_OPTION 2>/dev/null
do
        case "$PH_OPTION" in *)
                >&2 printf "\033[36m%s\033[0m\n" "Usage : listblue_ph.sh | -h"
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

printf "\n\033[36m%s\033[0m\n" "- Listing available bluetooth adapters"
"$PH_SUDO" systemctl enable bluetooth >/dev/null 2>&1 || PH_RET_CODE="1"
if [[ "$PH_RET_CODE" -eq "0" ]]
then
	"$PH_SUDO" systemctl start bluetooth >/dev/null 2>&1 || PH_RET_CODE="1"
	if [[ "$PH_RET_CODE" -eq "0" ]]
	then
		set -o pipefail
		PH_NR_ADAPTS=`"$PH_SUDO" bt-adapter -l 2>/dev/null | nawk -F'\(' '$0 ~ /No adapters found/ { print "None" ; exit 0 } \
							$0 !~ /Available adapters/ { print substr($2,1,length($2)-1) } { next }' | wc -l`
		PH_RET_CODE="$?" 
		set +o pipefail
		if [[ "$PH_RET_CODE" -eq "0" && "$PH_NR_ADAPTS" -ne "0" ]]
		then
			for PH_i in `"$PH_SUDO" bt-adapter -l 2>/dev/null | nawk -F'\(' 'BEGIN { ORS = " " } $0 !~ /Available adapters/ { print substr($2,1,length($2)-1) } { next }'`
			do
				if [[ "$PH_CTRL_BLUE_ADAPT" == "$PH_i" ]]
				then
					printf "%4s%s\n" "" "'$PH_i' (Default)"
				else
					printf "%4s%s\n" "" "'$PH_i'"
				fi
				ph_set_result -r "$?"
			done
		fi
	fi
fi
if [[ "$PH_RET_CODE" -ne "0" ]]
then
	if [[ "$PH_NR_ADAPTS" -eq "1" ]]
	then
		printf "%4s%s\n" "" "None"
		ph_set_result -r "$?"
	else
		ph_set_result -r 1 -m "Could not list bluetooth adapter(s)"
	fi
fi
ph_show_result
exit "$?"
