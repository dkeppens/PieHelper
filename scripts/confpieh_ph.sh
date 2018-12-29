#!/bin/ksh
# Manage the PieHelper frontend (by Davy Keppens on 04/10/2018)
# Enable debug by uncommenting the line below that says "#set -x"
# Disable debug by commenting out the line below that says "set -x"

if [[ "$1" != "-g" ]]
then
	. $(dirname $0)/../main/main.sh || exit $? && set +x
else
	export PH_FILES_DIR="$(dirname $0)/../files"
	export PH_VERSION=`cat $PH_FILES_DIR/VERSION`
	. $PH_FILES_DIR/../main/functions
fi

#set -x

typeset PH_MODULES=""
typeset PH_ACTION=""
typeset PH_VALUE=""
typeset PH_i=""
typeset PH_j=""
typeset PH_SSTRING=""
typeset PH_STRING=""
typeset PH_DEBUGSTATE=""
typeset PH_RESULT="SUCCESS"
typeset -i PH_COUNT=0

while getopts hp:m:gcsru PH_OPTION 2>/dev/null
do
	case $PH_OPTION in p)
		ph_screen_input "$OPTARG" || exit $?
		[[ "$OPTARG" != @(list|debug) ]] && (! confpieh_ph.sh -h) && exit 1
		[[ -n "$PH_ACTION" ]] && (! confpieh_ph.sh -h) && exit 1
		PH_ACTION="$OPTARG" ;;
			   m)
                ph_screen_input "$OPTARG" || exit $?
		[[ "$PH_ACTION" != @(debug|) ]] && (! confpieh_ph.sh -h) && exit 1
		[[ -n "$PH_MODULES" ]] && (! confpieh_ph.sh -h) && exit 1
		PH_MODULES="$OPTARG" ;;
			   g)
		[[ -n "$PH_ACTION" ]] && (! confpieh_ph.sh -h) && exit 1
		PH_ACTION="getstate" ;;
		           c)
		[[ -n "$PH_ACTION" ]] && (! confpieh_ph.sh -h) && exit 1
		PH_ACTION="configure" ;;
		           s)
		[[ -n "$PH_ACTION" ]] && (! confpieh_ph.sh -h) && exit 1
		PH_ACTION="scratch" ;;
		           r)
		[[ -n "$PH_ACTION" ]] && (! confpieh_ph.sh -h) && exit 1
		PH_ACTION="repair" ;;
		           u)
		[[ -n "$PH_ACTION" ]] && (! confpieh_ph.sh -h) && exit 1
		PH_ACTION="unconfigure" ;;
			   *)
		>&2 printf "%s\n" "Usage : confpieh_ph.sh -h | -c | -s | -r | -u | -g |"
		>&2 printf "%23s%s\n" "" "-p \"list\" |"
		>&2 printf "%23s%s\n" "" "-p \"debug\" -m [module1,module2,...|\"all\"|\"prompt\"]"
		>&2 printf "\n"
		>&2 printf "%3s%s\n" "" "Where -h displays this usage"
		>&2 printf "%9s%s\n" "" "-c sets PieHelper to state \"configured\""
		>&2 printf "%9s%s\n" "" "-s uninstalls PieHelper"
		>&2 printf "%9s%s\n" "" "-r checks all PieHelper TTY related configurations and attempts repair where needed"
		>&2 printf "%9s%s\n" "" "-u sets PieHelper to state \"unconfigured\""
		>&2 printf "%9s%s\n" "" "-g displays the current version and state of PieHelper"
		>&2 printf "%9s%s\n" "" "-p specifies the action to take"
		>&2 printf "%12s%s\n" "" "\"list\" allows the listing of all relevant PieHelper modules and their current debugstate"
		>&2 printf "%12s%s\n" "" "\"debug\" allows switching the debug state of all specified relevant module names"
		>&2 printf "%15s%s\n" "" "-m allows specifying a comma-separated list of module names"
		>&2 printf "%18s%s\n" "" "- The keyword \"all\" can be used to switch the debug state on all relevant PieHelper modules"
		>&2 printf "%18s%s\n" "" "- The keyword \"prompt\" makes confpieh_ph.sh behave interactively when it comes to module selection"
		>&2 printf "\n"
		exit 1 ;;
	esac
done
[[ -n "$PH_MODULES" && "$PH_ACTION" != "debug" ]] && (! confpieh_ph.sh -h) && exit 1
[[ -z "$PH_MODULES" && "$PH_ACTION" == "debug" ]] && (! confpieh_ph.sh -h) && exit 1
case $PH_ACTION in repair)
		ph_repair_pieh
		exit $? ;;
		 getstate)  
		ph_getstate_pieh
		exit $? ;;
		configure)
		ph_configure_pieh
		exit $? ;;
	      unconfigure)
		ph_unconfigure_pieh
		exit $? ;;
		  scratch)
		ph_remove_pieh
		exit $? ;;
		    debug) 	
                case $PH_MODULES in all)
                        PH_MODULES=`$PH_SCRIPTS_DIR/confpieh_ph.sh -p list | tail -n +2 | nawk '$1 !~ /SUCCESS/ { print $1 } { next }' | paste -d',' -s` ;;
				 prompt)
			PH_MODULES=""
			printf "%s\n" "- Using interactive mode"
			while [[ -z "$PH_MODULES" ]]
			do
				[[ $PH_COUNT -gt 0 ]] && printf "\n%10s%s\n\n" "" "ERROR : Invalid response"
				printf "%8s%s" "" "--> Please enter a comma-separated list of relevant PieHelper module names (The keyword \"all\" selects all modules) : "
				read PH_MODULES >/dev/null 2>&1
				ph_screen_input "$PH_MODULES" || exit $?
				((PH_COUNT++))
			done
			printf "%10s%s\n" "" "OK"
			printf "%2s%s\n" "" "SUCCESS"
			confpieh_ph.sh -p debug -m "$PH_MODULES"
			exit $? ;;
		esac
                for PH_i in `sed 's/,/ /g' <<<$PH_MODULES`
                do
			PH_RESULT="SUCCESS"
                        case $PH_i in *.sh)
				PH_j="$PH_i"
                                PH_i=`find $PH_MAIN_DIR/.. -name $PH_i 2>/dev/null`
                                if [[ -n "$PH_i" ]] && [[ "$PH_j" != @(confpieh_ph.sh|10-retropie.sh) ]]
                                then
                                        if grep '#set -x' $PH_i >/dev/null
                                        then
                                                printf "%s\n" "- Enabling debug mode for module $PH_j"
                                                PH_SSTRING='#set -x'
                                                PH_STRING='set -x'
                                                [[ -z "$PH_PIEH_DEBUG" ]] && PH_VALUE="$PH_j" || PH_VALUE="$PH_PIEH_DEBUG,$PH_j"
                                                if ! ph_set_option PieHelper -r PH_PIEH_DEBUG="$PH_VALUE"
						then
							PH_RESULT="FAILED"
							printf "%2s%s\n" "" "$PH_RESULT : Could not enable debug mode for module $PH_j"
							continue
						fi
                                        else
                                                printf "%s\n" "- Disabling debug mode for module $PH_j"
                                                PH_SSTRING='set -x'
                                                PH_STRING='#set -x'
                                                if echo $PH_PIEH_DEBUG | grep ',' >/dev/null
                                                then
                                                        PH_VALUE=`echo $PH_PIEH_DEBUG | sed "s/^$PH_j,//;s/,$PH_j,/,/;s/,$PH_j$//"`
                                                else
                                                        PH_VALUE=""
                                                fi
                                                if ! ph_set_option PieHelper -r PH_PIEH_DEBUG="$PH_VALUE"
						then
							PH_RESULT="FAILED"
							printf "%2s%s\n" "" "$PH_RESULT : Could not disable debug mode for module $PH_j"
							continue
						fi
                                        fi
                                        if sed "s/^$PH_SSTRING/$PH_STRING/g" $PH_i >/tmp/"$PH_j"_debug 2>/dev/null
                                        then
                                                mv /tmp/"$PH_j"_debug $PH_i 2>/dev/null
                                                $PH_SUDO chown $PH_RUN_USER:`$PH_SUDO id -gn $PH_RUN_USER` $PH_i 2>/dev/null
                                                $PH_SUDO chmod 750 $PH_i 2>/dev/null
						printf "%2s%s\n" "" "$PH_RESULT"
                                        else
						PH_RESULT="PARTIALLY FAILED"
                                                if grep '#set -x' $PH_i >/dev/null
                                                then
                                                        PH_VALUE=`echo $PH_PIEH_DEBUG | sed "s/^$PH_j,//;s/,$PH_j,/,/;s/,$PH_j$//"`
                                                        ph_set_option PieHelper -r PH_PIEH_DEBUG="$PH_VALUE"
                                                else
                                                        [[ -z "$PH_PIEH_DEBUG" ]] && PH_VALUE="$PH_j" || PH_VALUE="$PH_PIEH_DEBUG,$PH_j"
                                                        ph_set_option PieHelper -r PH_PIEH_DEBUG="$PH_VALUE"
                                                fi
						[[ "$PH_STRING" == '#set -x' ]] && printf "%2s%s\n" "" "$PH_RESULT : Could not disable debug mode for module $PH_j" || \
							printf "%2s%s\n" "" "$PH_RESULT : Could not enable debug mode for module $PH_j"
                                        fi
                                else
					PH_RESULT="FAILED"
					printf "%s\n" "- Enabling debug module for $PH_j"
					printf "%2s%s\n" "" "$PH_RESULT : Unknown module $PH_j"
                                fi ;;
                                      *)
				PH_RESULT="SUCCESS"
				if `functions | nawk '$1 ~ /^function$/ { print $2 }' | grep ^"$PH_i"$ >/dev/null`
				then
                                	PH_STRING=`echo $PH_PIEH_DEBUG | nawk -v func=^"$PH_i"$ 'BEGIN { RS = "," ; flag = 0 } $1 ~ func { print "Disabling" ; flag = 1 ; exit } END { if (flag==0) { print "Enabling" }}'`
                                      	printf "%s\n" "- $PH_STRING debug mode for module $PH_i"
                                        if [[ "$PH_STRING" == "Enabling" ]]
                                        then
                                                [[ -z "$PH_PIEH_DEBUG" ]] && PH_VALUE="$PH_i" || PH_VALUE="$PH_PIEH_DEBUG,$PH_i"
                                                if ph_set_option PieHelper -r PH_PIEH_DEBUG="$PH_VALUE"
						then
							printf "%2s%s\n" "" "$PH_RESULT"
						else
							PH_RESULT="FAILED"
							printf "%2s%s\n" "" "$PH_RESULT : Could not enable debug mode for module $PH_i"
						fi
                                        else
                                                if echo $PH_PIEH_DEBUG | grep ',' >/dev/null
                                        	then
                                              		PH_VALUE=`echo $PH_PIEH_DEBUG | sed "s/^$PH_i,//;s/,$PH_i,/,/;s/,$PH_i$//"`
                                              	else
                                                      		PH_VALUE=""
                                               	fi
                                               	if ph_set_option PieHelper -r PH_PIEH_DEBUG="$PH_VALUE"
						then
							printf "%2s%s\n" "" "$PH_RESULT"
						else
							PH_RESULT="FAILED"
							printf "%2s%s\n" "" "$PH_RESULT : Could not disable debug mode for module $PH_i"
						fi
                                        fi
                                else
					PH_RESULT="FAILED"
					printf "%s\n" "- Enabling debug mode for module $PH_i"
                                        printf "%2s%s\n" "" "$PH_RESULT : Unknown module $PH_i"
                                fi ;;
                        esac
                done
                exit 0 ;;
		    list)
                printf "%s\n" "- Listing all modules"
                for PH_j in `find $PH_MAIN_DIR/.. ! -name confpieh_ph.sh ! -name 10-retropie.sh -name "*.sh" 2>/dev/null | sort`
                do
                        if grep ^'set -x' $PH_j >/dev/null
                        then
                                PH_DEBUGSTATE="yes"
                        else
                                PH_DEBUGSTATE="no"
                        fi
                        printf "%2s%-40s%s\n" "" "${PH_j##*/}" "debug_enabled=$PH_DEBUGSTATE"
                done
                for PH_j in $(echo `nawk '$1 ~ /^function$/ { print $2 }' $PH_MAIN_DIR/functions ; nawk '$1 ~ /^function$/ { print $2 }' $PH_CONF_DIR/distros/$PH_DISTRO.conf ; \
					nawk '$1 ~ /^function$/ { print $2 }' $PH_MAIN_DIR/functions.user` | sed 's/ /\n/g' | sort | paste -d" " -s)
                do
                        PH_DEBUGSTATE=`echo $PH_PIEH_DEBUG | nawk -v func=^"$PH_j"$ 'BEGIN { RS = "," ; flag = 0 } $1 ~ func { print "yes" ; flag = 1 ; exit } END { if (flag==0) { print "no" }}'`
                        printf "%2s%-40s%s\n" "" "$PH_j" "debug_enabled=$PH_DEBUGSTATE"
                done
		printf "%2s%s\n" "" "$PH_RESULT"
                exit 0 ;;
esac
confpieh_ph.sh -h || exit $?
