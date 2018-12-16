#!/bin/ksh
# Display some minimal help about the required configuration steps for different controller types and connection methods (by Davy Keppens on 25/11/2018)
# Enable/Disable debug by running confpieh_ph.sh -d confctrl_ph.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

typeset PH_ACTION=""
typeset PH_TYPE=""
typeset PH_CONN=""

while getopts hp:t:c: PH_OPTION 2>/dev/null
do
	case $PH_OPTION in p)
		ph_screen_input "$OPTARG" || exit $?
		[[ "$OPTARG" != "help" ]] && (! confctrl_ph.sh -h) && exit 1
		[[ -n "$PH_ACTION" ]] && (! confctrl_ph.sh -h) && exit 1
		PH_ACTION="$OPTARG" ;;
			   t)
		ph_screen_input "$OPTARG" || exit $?
		[[ "$OPTARG" != @(PS3|PS4|XBOX) ]] && (! confctrl_ph.sh -h) && exit 1
		[[ -n "$PH_TYPE" ]] && (! confctrl_ph.sh -h) && exit 1
		PH_TYPE="$OPTARG" ;;
			   c)
		ph_screen_input "$OPTARG" || exit $?
		[[ "$OPTARG" != @(cabled|bluetooth) ]] (! confctrl_ph.sh -h) && exit 1
		[[ -n "$PH_CONN" ]] && (! confctrl_ph.sh -h) && exit 1
		PH_CONN="$OPTARG" ;;
			   *)
		>&2 printf "%s\n" "Usage : confctrl_ph.sh -h |"
		>&2 printf "%23s%s\n" "" "-p \"help\" -t [ctrltype] -c [conntype]"
		>&2 printf "\n"
		>&2 printf "%3s%s\n" "" "Where -h displays this usage"
		>&2 printf "%9s%s\n" "" "-p specifies the action to take"
		>&2 printf "%12s%s\n" "" "\"help\" allows requesting the display of basic configuration information for controllers of type [ctrltype] using connection method [conntype]"
		>&2 printf "%15s%s\n" "" "-t allows selecting one of a list of supported controller types as value for [ctrltype]"
		>&2 printf "%18s%s\n" "" "- The currently supported controller types are \"PS3\", \"XBOX\" and \"PS4\""
		>&2 printf "%15s%s\n" "" "-c allows selecting one of a list of known controller connection types as value for [conntype]"
		>&2 printf "%18s%s\n" "" "- The currently known controller connection types are \"cabled\" and \"bluetooth\""
		>&2 printf "\n"
		exit 1 ;;
	esac
done
[[ -z "$PH_CONN" || -z "$PH_TYPE" ]] && (! confctrl_ph.sh -h) && exit 1
case $PH_ACTION in help)
	exit 0 ;;
esac
confctrl_ph.sh -h || exit $?
