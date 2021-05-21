#!/bin/bash
# Manage PieHelper frontend (by Davy Keppens on 04/10/2018)
# Enable debug by uncommenting the line below that says "#set -x"
# Disable debug by commenting out the line below that says "set -x"

if [[ -f "$(dirname "$0" 2>/dev/null)/app/main.sh" && -r "$(dirname "$0" 2>/dev/null)/app/main.sh" ]]
then
	if ! source "$(dirname "$0" 2>/dev/null)/app/main.sh"
	then
		printf "\n%2s\033[1;31m%s\033[0;0m\n\n" "" "ABORT : Reinstallation of PieHelper is required (Could not load critical codebase file '$(dirname "$0" 2>/dev/null)/app/main.sh'"
		exit 1
	else
		set +x
	fi
else
	printf "\n%2s\033[1;31m%s\033[0;0m\n\n" "" "ABORT : Reinstallation of PieHelper is required (Missing or unreadable critical codebase file '$(dirname "$0" 2>/dev/null)/app/main.sh'"
	exit 1
fi

#set -x

declare PH_ACTION=""
declare PH_VALUE=""
declare PH_APP="PieHelper"
declare PH_i=""
declare PH_j=""
declare PH_SSTRING=""
declare PH_STRING=""
declare PH_CHILD=""
declare PH_TMP_NAME=""
declare PH_NEED_TOTAL_RESULT=""
declare PH_DEBUGSTATE=""
declare PH_LIST_MODULES=""
declare PH_OLDOPTARG="$OPTARG"
declare -i PH_OLDOPTIND="$OPTIND"
declare -i PH_COUNT="0"
declare -i PH_ERR_COUNT="0"
declare -i PH_RET_CODE="0"

PH_MODULES=""

function ph_prompt_module_input {

declare -i PH_COUNT="0"

printf "\033[36m%s\033[0m\n\n" "- Using interactive mode"
while [[ -z "$PH_MODULES" || "$PH_MODULES" == "prompt" ]]
do
	[[ "$PH_COUNT" -gt "0" ]] && \
		printf "\n%10s\033[33m%s\033[0m\n" "" "Warning : Invalid response"
	printf "%8s%s\n\n" "" "--> Enter a comma-separated list of relevant PieHelper modules"
	printf "%12s%s\n" "" "- The keyword 'all' can be used to select all relevant modules"
	printf "%12s%s\n" "" "- The keyword 'disabled' can be used to select all relevant modules for which debug is currently disabled"
	printf "%12s%s\n" "" "- The keyword 'enabled' can be used to select all relevant modules for which debug is currently enabled"
	printf "%12s%s\n\n" "" "- The keyword 'prompt' is invalid in interactive mode"
	printf "%8s%s" "" "Your choice : "
	read -r PH_MODULES >/dev/null 2>&1
	((PH_COUNT++))
done
ph_run_with_rollback -c true
ph_show_result
return "$?"
}

function ph_check_module_validity {

declare PH_i=""
declare PH_FOUND=""
declare -i PH_RET_CODE="0"
declare -i PH_COUNT="0"

PH_COUNT="$(echo -n "$PH_MODULES" | nawk 'BEGIN { \
		RS = "," \
	} END { \
		print NR \
	}')"
printf "\033[36m%s\033[0m\n\n" "- Checking module(s) validity"
for PH_i in ${PH_MODULES//,/ }
do
	printf "%8s%s\n" "" "--> Checking validity of module '${PH_i}'"
	((PH_COUNT++))
	[[ "$PH_i" == @(@(en|dis)abled|prompt|all) ]] && \
		PH_FOUND="$PH_i"
	if [[ -n "$PH_FOUND" && "$PH_COUNT" -gt "1" ]]
	then
		ph_set_result -m "Keyword '${PH_FOUND}' cannot be specified together with module names"
		PH_RET_CODE="1"
	else
		if [[ "$PH_ACTION" == "debug" ]]
		then
			if [[ "$PH_i" == "confpieh_ph.sh" ]]
			then
				ph_set_result -m "Debug for module '${PH_i}' should be handled manually"
				PH_RET_CODE="1"
			fi
			if [[ "$PH_i" == *.expect ]]
			then
				ph_set_result -m "Debug for module '${PH_i}' is not supported"
				PH_RET_CODE="1"
			fi
		fi
		case "$PH_i" in *.sh|*.expect)
			if ! "$PH_SUDO" find "${PH_BASE_DIR}/" -mount -name "$PH_i" >/dev/null 2>&1
			then
				ph_set_result -m "The specified module name '${PH_i}' does not exist"
				PH_RET_CODE="1"
			fi ;;
				*)
			if ! functions 2>/dev/null | nawk '$1 ~ /^function$/ {
					print $2
				}' | grep -E "^${PH_i}$" >/dev/null
			then
				ph_set_result -m "The specified module name '${PH_i}' does not exist"
				PH_RET_CODE="1"
			fi ;;
		esac
	fi
	[[ "$PH_RET_CODE" -eq "1" ]] && \
		break
	ph_run_with_rollback -c true
done
if [[ "$PH_RET_CODE" -ne "0" ]]
then
	ph_run_with_rollback -c false -m "Invalid module"
else
	if [[ -z "$PH_MODULES" ]]
	then
		printf "%10s\033[33m%s\033[0m\n" "" "Warning : No modules selected"
		ph_set_result -r 0 -w -m "No modules selected"
	fi
fi
ph_show_result
return "$?"
}

OPTIND="1"

while getopts p:m:gcrvuqh PH_OPTION 2>/dev/null
do
	case "$PH_OPTION" in p)
		ph_screen_input "$OPTARG"
		[[ -n "$PH_ACTION" || "$OPTARG" != @(list|debug) ]] && \
			OPTARG="$PH_OLDOPTARG" && \
			OPTIND="$PH_OLDOPTIND" && \
			(! confpieh_ph.sh -h) && \
			exit 1
		PH_ACTION="$OPTARG" ;;
			     m)
		[[ -n "$PH_MODULES" ]] && \
			OPTARG="$PH_OLDOPTARG" && \
			OPTIND="$PH_OLDOPTIND" && \
			(! confpieh_ph.sh -h) && \
			exit 1
		PH_MODULES="$OPTARG" ;;
			     g)
		[[ -n "$PH_ACTION" ]] && \
			OPTARG="$PH_OLDOPTARG" && \
			OPTIND="$PH_OLDOPTIND" && \
			(! confpieh_ph.sh -h) && \
			exit 1
		PH_ACTION="getstate" ;;
		             c)
		[[ -n "$PH_ACTION" ]] && \
			OPTARG="$PH_OLDOPTARG" && \
			OPTIND="$PH_OLDOPTIND" && \
			(! confpieh_ph.sh -h) && \
			exit 1
		PH_ACTION="configure" ;;
		             r)
		[[ -n "$PH_ACTION" ]] && \
			OPTARG="$PH_OLDOPTARG" && \
			OPTIND="$PH_OLDOPTIND" && \
			(! confpieh_ph.sh -h) && \
			exit 1
		PH_ACTION="remove" ;;
		             v)
		[[ -n "$PH_ACTION" ]] && \
			OPTARG="$PH_OLDOPTARG" && \
			OPTIND="$PH_OLDOPTIND" && \
			(! confpieh_ph.sh -h) && \
			exit 1
		PH_ACTION="repair" ;;
		             u)
		[[ -n "$PH_ACTION" ]] && \
			OPTARG="$PH_OLDOPTARG" && \
			OPTIND="$PH_OLDOPTIND" && \
			(! confpieh_ph.sh -h) && \
			exit 1
		PH_ACTION="unconfigure" ;;
		             q)
		[[ -n "$PH_ACTION" ]] && \
			OPTARG="$PH_OLDOPTARG" && \
			OPTIND="$PH_OLDOPTIND" && \
			(! confpieh_ph.sh -h) && \
			exit 1
		PH_ACTION="update" ;;
			     *)
		>&2 printf "\n"
		>&2 printf "\033[36m%s\033[0m\n" "Usage : confpieh_ph.sh -h | -c | -r | -v | -u | -g | -q |"
		>&2 printf "%23s\033[36m%s\033[0m\n" "" "-p \"list\" -m [module1,module2,...|\"all\"|\"enabled\"|\"disabled\"] |"
		>&2 printf "%23s\033[36m%s\033[0m\n" "" "-p \"debug\" -m [module1,module2,...|\"all\"|\"prompt\"|\"enabled\"|\"disabled\"]"
		>&2 printf "\n"
		>&2 printf "%3s%s\n" "" "Where -h displays this usage"
		>&2 printf "%9s%s\n" "" "-c sets PieHelper configuration state to 'Configured'"
		>&2 printf "%9s%s\n" "" "-r uninstalls PieHelper"
		>&2 printf "%12s%s\n" "" "Uninstall will automatically unconfigure PieHelper before uninstalling"
		>&2 printf "%9s%s\n" "" "-v verifies all PieHelper configurations and repairs where needed"
		>&2 printf "%12s%s\n" "" "Verification needs to run as 'root'"
		>&2 printf "%9s%s\n" "" "-u sets PieHelper configuration state to 'Unconfigured'"
		>&2 printf "%9s%s\n" "" "-g displays the current version and configuration state of PieHelper"
		>&2 printf "%9s%s\n" "" "-q checks online for available PieHelper updates"
		>&2 printf "%9s%s\n" "" "-p specifies the action to take"
		>&2 printf "%12s%s\n" "" "\"list\" allows listing all specified relevant PieHelper modules and their debug state"
		>&2 printf "%15s%s\n" "" "-m allows specifying a list of modules"
		>&2 printf "%18s%s\n" "" "- Multiple modules should be comma-separated"
		>&2 printf "%18s%s\n" "" "- Relevant modules are PieHelper shell scripts, 'Expect' scripts and the name of any PieHelper functions appropriate to the system OS"
		>&2 printf "%18s%s\n" "" "- The following are considered invalid for 'list' operations :"
		>&2 printf "%21s%s\n" "" "- Invalid modules such as '10-retropie.sh'"
		>&2 printf "%18s%s\n" "" "- Specifying one or more invalid module(s) will generate an error and block remaining module processing"
		>&2 printf "%18s%s\n" "" "- The keyword 'all' can be used to select all relevant module(s)"
		>&2 printf "%18s%s\n" "" "- The keyword 'enabled' can be used to select relevant modules with debug state 'Enabled'"
		>&2 printf "%18s%s\n" "" "- The keyword 'disabled' can be used to select relevant modules with debug state 'Disabled'"
		>&2 printf "%18s%s\n" "" "- The keyword 'prompt' makes 'confpieh_ph.sh' behave interactively when it comes to module selection"
		>&2 printf "%21s%s\n" "" "- The following info will be prompted for during interactive debug state operations :"
		>&2 printf "%24s%s\n" "" "- relevant module(s)"
		>&2 printf "%12s%s\n" "" "\"debug\" allows switching the debug state of all specified relevant PieHelper modules"
		>&2 printf "%15s%s\n" "" "-m allows specifying a list of modules"
		>&2 printf "%18s%s\n" "" "- Multiple modules should be comma-separated"
		>&2 printf "%18s%s\n" "" "- Relevant modules are PieHelper shell scripts and the name of any PieHelper functions appropriate to the system OS"
		>&2 printf "%18s%s\n" "" "- The following are considered invalid for 'debug' operations :"
		>&2 printf "%21s%s\n" "" "- Modules that should be debugged manually such as 'confpieh_ph.sh'"
		>&2 printf "%21s%s\n" "" "- Invalid modules such as '10-retropie.sh'"
		>&2 printf "%21s%s\n" "" "- Modules that require debugging through proprietary means such as 'Expect' scripts"
		>&2 printf "%18s%s\n" "" "- Valid modules with debug state 'Disabled' will have their debug state set to 'Enabled'"
		>&2 printf "%18s%s\n" "" "- Valid modules with debug state 'Enabled' will have their debug state set to 'Disabled'"
		>&2 printf "%18s%s\n" "" "- Specifying one or more invalid module(s) will generate an error and block remaining module processing"
		>&2 printf "%18s%s\n" "" "- The keyword 'all' can be used to select all relevant module(s)"
		>&2 printf "%18s%s\n" "" "- The keyword 'enabled' can be used to select relevant modules with debug state 'Enabled'"
		>&2 printf "%18s%s\n" "" "- The keyword 'disabled' can be used to select relevant modules with debug state 'Disabled'"
		>&2 printf "%18s%s\n" "" "- The keyword 'prompt' makes 'confpieh_ph.sh' behave interactively when it comes to module selection"
		>&2 printf "%21s%s\n" "" "- The following info will be prompted for during interactive debug state operations :"
		>&2 printf "%24s%s\n" "" "- relevant module(s)"
		>&2 printf "\n"
		OPTIND="$PH_OLDOPTIND"
		OPTARG="$PH_OLDOPTARG"
		exit 1 ;;
	esac
done
OPTIND="$PH_OLDOPTIND"
OPTARG="$PH_OLDOPTARG"

[[ ( -n "$PH_MODULES" && "$PH_ACTION" != @(debug|list) ) || \
	( -z "$PH_MODULES" && "$PH_ACTION" == @(debug|list) ) ]] && \
	(! confpieh_ph.sh -h) && exit 1
if [[ "$PH_ACTION" == @(debug|list|getstate|unconfigure) ]]
then
	[[ "$("$PH_SUDO" cat "/proc/${PPID}/comm" 2>/dev/null)" != "confpieh_ph.sh" ]] && \
		printf "\n"
fi
[[ "$(ps -o args "$PPID" 2>/dev/null | tail -1)" == *confpieh_ph.sh*-p*"${PH_ACTION}"* ]] && \
	PH_CHILD="yes"
case "$PH_ACTION" in repair)
		ph_repair_pieh
		exit "$?" ;;
		   getstate)  
		printf "\033[36m%s\033[0m\n" "- Displaying PieHelper info"
		ph_get_pieh_conf_state
		ph_show_result
		exit "$?" ;;
		  configure)
		confapps_ph.sh -p conf -a PieHelper
		exit "$?" ;;
	        unconfigure)
		printf "\033[36m%s\033[0m\n\n" "- Unconfiguring ${PH_APP}"
		ph_unconfigure_pieh -u
		exit "$?" ;;
		     remove)
		confapps_ph.sh -p uninst -a PieHelper
		exit "$?" ;;
		     update)
		confapps_ph.sh -p update -a PieHelper
		exit "$?" ;;
		      debug)
		[[ "$PH_MODULES" == @(all|enabled|disabled) ]] && \
			PH_REQUESTED="$PH_MODULES"
                case "$PH_MODULES" in all)
                        PH_MODULES="$(confpieh_ph.sh -p list -m "$PH_MODULES" | nawk 'BEGIN { \
					ORS = "," \
				} \
				$2 ~ /^debug_state=/ && $1 !~ /.expect$/ && $1 !~ /confpieh_ph.sh$/ { \
					print $1 \
				}')" ;;
				   prompt)
			ph_prompt_module_input
			ph_set_result -t -r "$?"
			confpieh_ph.sh -p debug -m "$PH_MODULES"
			ph_set_result -t -r "$?"
			ph_show_result -t
			exit "$?" ;;
				   enabled)
			PH_MODULES="$(confpieh_ph.sh -p list -m "$PH_MODULES" | nawk -v comp="^debug_state=enabled$" 'BEGIN { \
					ORS = "," \
				} \
				$2 ~ comp && $1 !~ /^confpieh_ph.sh$/ { \
					print $1 \
				}')" ;;
				   disabled)
			PH_MODULES="$(confpieh_ph.sh -p list -m "$PH_MODULES" | nawk -v comp="^debug_state=disabled$" 'BEGIN { \
					ORS = "," \
				} \
				$2 ~ comp && $1 !~ /.expect$/ && $1 !~ /^confpieh_ph.sh$/ { \
					print $1 \
				}')" ;;
				   *)
			PH_REQUESTED="requested"
			if ph_check_module_validity
			then
				[[ -z "$PH_MODULES" ]] && \
					exit 0
				ph_set_result -t -r 0
			else
				exit 1
			fi ;;
		esac
		printf "\033[36m%s\033[0m\n" "- Changing module(s) debug state : '$PH_REQUESTED'"
		if [[ -z "$PH_MODULES" ]]
		then
			ph_set_result -r 0 -w -m "No module(s) selected"
			ph_show_result
			exit "$?"
		fi
                for PH_i in ${PH_MODULES//,/ }
                do
			PH_RET_CODE="0"
			((PH_COUNT++))
			[[ "$PH_COUNT" -eq "1" ]] && \
				printf "\n"
                        case "$PH_i" in *.sh)
				PH_j="$PH_i"
				PH_DEBUGSTATE="$(echo -n "$PH_PIEH_DEBUG" | nawk -v func="^${PH_j}$" 'BEGIN { \
						RS = "," ; \
						flag = 0 \
					} \
					$1 ~ func { \
						print "Disabled" ; \
						flag = 1 ; \
						exit \
					} END { \
						if (flag==0) { \
							print "Enabled" \
						} \
					}')"
				printf "%8s%s\n" "" "--> Setting the debug state of module '${PH_j}' to '${PH_DEBUGSTATE}'"
				if [[ "$PH_DEBUGSTATE" == "disabled" ]]
				then
					if echo "$PH_PIEH_DEBUG" | grep ',' >/dev/null
					then
						PH_VALUE="$(sed "s/^${PH_j}$//;s/^${PH_j},//;s/,${PH_j},/,/;s/,${PH_j}$//"<<<"$PH_PIEH_DEBUG")"
					else
						PH_VALUE=""
					fi
					PH_SSTRING='set -x'
					PH_STRING='#set -x'
				else
					[[ -z "$PH_PIEH_DEBUG" ]] && \
						PH_VALUE="$PH_j" || \
						PH_VALUE="${PH_PIEH_DEBUG},${PH_j}"
					PH_SSTRING='#set -x'
					PH_STRING='set -x'
				fi
				if ph_run_with_rollback -c "ph_set_option_to_value PieHelper -r \"PH_PIEH_DEBUG'${PH_VALUE}\"" >/dev/null 2>&1
				then
                                	if PH_i="$("$PH_SUDO" find "$PH_BASE_DIR" -mount -name "$PH_i" 2>/dev/null)"
					then
                                       		if sed -i "s/^${PH_SSTRING}/${PH_STRING}/g" "$PH_i" 2>/dev/null
                                       		then
							ph_run_with_rollback -c true
						fi
					fi
				fi
				((PH_ERR_COUNT++))
				ph_set_result -w -m "${PH_ERR_COUNT} errors occurred while trying to change module state(s)"
				printf "%10s\033[33m%s\033[0m\n" "" "Warning : Could not ${PH_DEBUGSTATE%.} debug on module '${PH_i}'"
				continue ;;
                                        *)
                                PH_DEBUGSTATE="$(echo "$PH_PIEH_DEBUG" | nawk -v func="^${PH_i}$" 'BEGIN { \
						RS = "," ; \
						flag = 0 \
					} \
					$1 ~ func { \
						printf "disabled" ; \
						flag = 1 ; \
						exit \
					} END { \
						if (flag==0) { \
							printf "enabled" \
						} \
					}')"
				printf "%8s%s\n" "" "--> Setting the debug state of module '${PH_i}' to '${PH_DEBUGSTATE}'"
				if [[ "$PH_DEBUGSTATE" == "enabled" ]]
				then
					[[ -z "$PH_PIEH_DEBUG" ]] && \
						PH_VALUE="$PH_i" || \
						PH_VALUE="${PH_PIEH_DEBUG},${PH_i}"
				else
					if echo "$PH_PIEH_DEBUG" | grep ',' >/dev/null
					then
						PH_VALUE="$(sed "s/^${PH_i}$//;s/^${PH_i},//;s/,${PH_i},/,/;s/,${PH_i}$//"<<<"$PH_PIEH_DEBUG")"
					else
						PH_VALUE=""
					fi
				fi
				if ! ph_run_with_rollback -c "ph_set_option_to_value PieHelper -r \"PH_PIEH_DEBUG'${PH_VALUE}\"" >/dev/null 2>&1
				then
					((PH_ERR_COUNT++))
					ph_set_result -w -m "${PH_ERR_COUNT} errors occurred while trying to change module state(s)"
					printf "%10s\033[33m%s\033[0m\n" "" "Warning : Could not ${PH_DEBUGSTATE%.} debug on module '${PH_i}'"
                                fi ;;
                        esac
                done
		ph_secure_pieh "${PH_CONF_DIR}/PieHelper.conf"
		ph_show_result
		PH_RET_CODE="$?"
		[[ "$PH_CHILD" == "yes" ]] && \
			exit "$PH_RET_CODE"
		if [[ "$(echo "$PH_MODULES" | nawk 'BEGIN { \
				RS = "," \
			} END { \
				printf NR \
			}')" -gt "1" || "$PH_REQUESTED" == "requested" ]]
		then
                	ph_set_result -t -r "$PH_RET_CODE"
			ph_show_result -t
			PH_RET_CODE="$?"
		fi
                exit "$PH_RET_CODE" ;;
		      list)
		case "$PH_MODULES" in prompt)
			ph_prompt_module_input
			ph_set_result -t -r "$?"
			confpieh_ph.sh -p list -m "$PH_MODULES"
			ph_set_result -t -r "$?"
			ph_show_result -t
			exit "$?" ;;
				      *)
			if [[ "$PH_MODULES" == @(all|enabled|disabled) ]]
			then
				PH_REQUESTED="$PH_MODULES"
				PH_MODULES="$(echo -n "$PH_MODULES" | cut -c1 | tr "[:lower:]" "[:upper:]")$(echo -n "$PH_MODULES" | cut -c2-)"
				for PH_i in $("$PH_SUDO" -E find "$PH_BASE_DIR" -mount \( -name "*.sh" -or -name "*.expect" \) 2>/dev/null | sort)
				do
					PH_i="${PH_i##*/}"
					if [[ "$PH_i" == *.expect ]]
					then
						PH_DEBUGSTATE="disabled"
					else
						PH_DEBUGSTATE="$(echo "$PH_PIEH_DEBUG" | nawk -v func="^${PH_i}$" 'BEGIN { \
								RS = "," ; \
								flag = 0 \
							} \
							$1 ~ func { \
								printf "enabled" ; \
								flag = 1 ; \
								exit \
							} END { \
								if (flag==0) { \
									printf "disabled" \
								} \
							}')"
					fi
					if [[ "$PH_MODULES" == "All" || "$PH_DEBUGSTATE" == "$PH_MODULES" ]]
					then
						[[ -z "$PH_LIST_MODULES" ]] && \
							PH_LIST_MODULES="$PH_i" || \
							PH_LIST_MODULES="${PH_LIST_MODULES},${PH_i}"
					fi
				done
				for PH_i in $(nawk '$1 ~ /^function$/ { \
						print $2 \
					}' "${PH_MAIN_DIR}/functions" "${PH_MAIN_DIR}/functions.update" "${PH_MAIN_DIR}/functions.user" "${PH_MAIN_DIR}/distros/functions.${PH_DISTRO}" 2>/dev/null | \
					sed 's/ /\n/g' | sort | paste -d" " -s)
				do
					PH_DEBUGSTATE="$(echo "$PH_PIEH_DEBUG" | nawk -v func="^${PH_i}$" 'BEGIN { \
							RS = "," ; \
							flag = 0 \
						} \
						$1 ~ func { \
							printf "enabled" ; \
							flag = 1 ; \
							exit \
						} END { \
							if (flag==0) { \
								printf "disabled" \
							} \
						}')"
					if [[ "$PH_MODULES" == "All" || "$PH_DEBUGSTATE" == "$PH_MODULES" ]]
					then
						[[ -z "$PH_LIST_MODULES" ]] && \
							PH_LIST_MODULES="$PH_i" || \
							PH_LIST_MODULES="${PH_LIST_MODULES},${PH_i}"
					fi
				done
				PH_MODULES="$PH_LIST_MODULES"
			else
				if ph_check_module_validity
				then
					[[ -z "$PH_MODULES" ]] && \
						exit 0
					ph_set_result -t -r 0
				else
					exit 1
				fi
				PH_REQUESTED="requested"
			fi
			printf "\033[36m%s\033[0m\n" "- Listing relevant PieHelper modules : '${PH_REQUESTED}'"
			if [[ -z "$PH_MODULES" ]]
			then
				ph_set_result -r 0 -w -m "No module(s) selected"
				ph_show_result
				exit "$?"
			fi
			for PH_i in ${PH_MODULES//,/ }
			do
				((PH_COUNT++))
				[[ "$PH_COUNT" -eq "1" ]] && \
					printf "\n"
				PH_DEBUGSTATE="$(echo "$PH_PIEH_DEBUG" | nawk -v func="^${PH_i}$" 'BEGIN { \
						RS = "," ; \
						flag = 0 \
					} \
					$1 ~ func { \
						printf "enabled" ; \
						flag = 1 ; \
						exit \
					} END { \
						if (flag==0) { \
							printf "disabled" \
						} \
					}')"
				if printf "%4s%-60s%s\n" "" "$PH_i" "debug_state=$PH_DEBUGSTATE"
				then
					ph_set_result -r 0
				else
					((PH_ERR_COUNT++))
					ph_set_result -r 1 -m "$PH_ERR_COUNT module(s) failed to list"
				fi
			done
			ph_show_result
			PH_RET_CODE="$?"
			[[ "$PH_CHILD" == "yes" ]] && exit \
				"$PH_RET_CODE"
			if [[ "$(echo -n "$PH_MODULES" | nawk 'BEGIN { \
					RS = "," \
				} END { \
					print NR \
				}')" -gt "1" || "$PH_REQUESTED" == "requested" ]]
			then
                		ph_set_result -t -r "$PH_RET_CODE"
				ph_show_result -t
				PH_RET_CODE="$?"
			fi
                	exit "$PH_RET_CODE" ;;
		esac ;;
esac
confpieh_ph.sh -h
exit "$?"
