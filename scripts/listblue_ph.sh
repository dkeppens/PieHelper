#!/bin/ksh
# List bluetooth adapter(s) (by Davy Keppens on 26/12/2018)
# Enable/Disable debug by running confpieh_ph.sh -d listblue_ph.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

typeset PH_i=""
typeset -i PH_NUM_ADAPT=0
typeset -i PH_RETCODE=0

printf "%s\n" "- Displaying bluetooth adapter currently set as default"
[[ "$PH_CTRL_BLUE_ADAPT" != "none" ]] && printf "%8s%s\n" "" "$PH_CTRL_BLUE_ADAPT" || \
				printf "%8s%s\n" "" "\"none\""
printf "%2s%s\n" "" "SUCCESS"
printf "%s\n" "- Listing all currently available bluetooth adapters on the system"
set -o pipefail
PH_NUM_ADAPT=`bt-adapter -l 2>/dev/null | nawk -F'\(' '$0 ~ /No adapters found/ { print "none" ; exit 0 } \
							$0 !~ /Available adapters/ { print substr($2,1,length($2)-1) } { next }' | wc -l`
PH_RETCODE=$? 
[[ $PH_RETCODE -ne 0 && $PH_NUM_ADAPT -eq 0 ]] && printf "%2s%s\n" "" "FAILED : Could not list bluetooth adapter(s)" && exit 1
set +o pipefail
for PH_i in `bt-adapter -l 2>/dev/null | nawk -F'\(' 'BEGIN { ORS = " " } $0 !~ /Available adapters/ { print substr($2,1,length($2)-1) } { next }'`
do
	[[ "$PH_CTRL_BLUE_ADAPT" == "$PH_i" ]] && printf "%8s%s\n" "" "$PH_i (Default)" || \
					printf "%8s%s\n" "" "$PH_i"
done
[[ $PH_NUM_ADAPT -eq 1 && $PH_RETCODE -ne 0 ]] && printf "%10s%s\n" "" "\"none\""
printf "%2s%s\n" "" "SUCCESS"
exit 0