#!/bin/bash
# Manage supplementary out-of-scope apps (by Davy Keppens on 11/11/2018)
# Enable/Disable debug by running confpieh_ph.sh -p debug -m confsupp_ph.sh

if [[ -r "$(dirname "${0}" 2>/dev/null)/main/main.sh" ]]
then
	if ! source "$(dirname "${0}" 2>/dev/null)/main/main.sh"
	then
		set +x
		>&2 printf "\n%2s\033[1;31m%s\033[0m\n\n" "" "ABORT : Reinstallation of PieHelper is required (Corrupted critical codebase file '$(dirname "${0}" 2>/dev/null)/main/main.sh'"
		exit 1
	fi
	set +x
else
	>&2 printf "\n%2s\033[1;31m%s\033[0m\n\n" "" "ABORT : Reinstallation of PieHelper is required (Missing or unreadable critical codebase file '$(dirname "${0}" 2>/dev/null)/main/main.sh'"
	exit 1
fi

#set -x

declare PH_OPTION=""
declare PH_ACTION=""
declare PH_I_ACTION=""
declare PH_TMP=""
declare PH_APP=""
declare PH_APP2=""
declare PH_APP_USER=""
declare PH_APP_CMD=""
declare PH_APP_PKG=""
declare PH_j=""
declare PH_OLDOPTARG="$OPTARG"
declare -i PH_i=0
declare -i PH_COUNT=0
declare -i PH_APP_TTY=0
declare -i PH_OLDOPTIND=$OPTIND
declare -l PH_APPL=""
declare -l PH_APPL2=""
declare -u PH_APPU=""
OPTIND=1

while getopts p:a:c:u:b:irh PH_OPTION 2>/dev/null
do
	case "$PH_OPTION" in p)
		! ph_screen_input "$OPTARG" && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ "$OPTARG" != @(inst|rem|prompt) ]] && (! confsupp_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ -n "$PH_I_ACTION" && "$OPTARG" != "prompt" ]] && (! confsupp_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ -n "$PH_ACTION" ]] && (! confsupp_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_ACTION="$OPTARG" ;;
			  a)
		! ph_screen_input "$OPTARG" && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ -n "$PH_APP" ]] && (! confsupp_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_APP="$OPTARG"
		PH_APPL=`echo $PH_APP | cut -c1-4`
		PH_APPU=`echo $PH_APP | cut -c1-4` ;;
			  c)
		[[ -n "$PH_APP_CMD" ]] && (! confsupp_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_APP_CMD="$OPTARG" ;;
			  u)
		! ph_screen_input "$OPTARG" && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ -n "$PH_APP_USER" ]] && (! confsupp_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_APP_USER="$OPTARG" ;;
			  b)
		[[ -n "$PH_APP_PKG" ]] && (! confsupp_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_APP_PKG="$OPTARG" ;;
			  i)
		[[ "$PH_ACTION" != @(prompt|) || -n "$PH_APP" || -n "$PH_APP_CMD" || -n "$PH_APP_PKG" ]] && (! confsupp_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ -n "$PH_I_ACTION" ]] && (! confsupp_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_I_ACTION="inst" ;;
			  r)
		[[ "$PH_ACTION" != @(prompt|) || -n "$PH_APP" || -n "$PH_APP_CMD" || -n "$PH_APP_PKG" ]] && (! confsupp_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ -n "$PH_I_ACTION" ]] && (! confsupp_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_I_ACTION="rem" ;;
			  *)
                >&2 printf "%s\n" "Usage : confsupp_ph.sh -h |"
		>&2 printf "%23s%s\n" "" "-p \"inst\" -a [instapp] -b [instpkg] '-u [instusr]' -c [instcmd] |"
		>&2 printf "%23s%s\n" "" "-p \"rem\" -a [remapp] '-b [rempkg]' |"
		>&2 printf "%23s%s\n" "" "-p \"prompt\" [-i|-r]"
                >&2 printf "\n"
                >&2 printf "%3s%s\n" "" "Where -h displays this usage"
                >&2 printf "%9s%s\n" "" "-p specifies the action to take"
                >&2 printf "%12s%s\n" "" "\"inst\" allows installing an out-of-scope application [instapp] with a package [instpkg]"
		>&2 printf "%19s%s\n" "" "and integrating it into PieHelper under account [instusr] and with start command [instcmd]"
                >&2 printf "%15s%s\n" "" "- A maximum of 5 out-of-scope applications can be added"
                >&2 printf "%15s%s\n" "" "-a allows specifying an application name for [instapp]"
                >&2 printf "%18s%s\n" "" "- The first four letters should be a case-insensitive unique identifier of the application"
                >&2 printf "%18s%s\n" "" "- An empty configuration routine for [instapp] will automatically be created in '$PH_FUNCS_DIR/functions.user'"
                >&2 printf "%18s%s\n" "" "  These can be developed by the user"
                >&2 printf "%15s%s\n" "" "-b allows specifying a packagename [instpkg]"
                >&2 printf "%18s%s\n" "" "- A package is a requirement for out-of-scope applications"
                >&2 printf "%18s%s\n" "" "- If the specified package is currently uninstalled it will be installed first"
                >&2 printf "%15s%s\n" "" "-u allows specifying a run account [instusr]"
                >&2 printf "%18s%s\n" "" "- Specifying a run account is optional"
                >&2 printf "%20s%s\n" "" "The run account for PieHelper will be used if no other is specified"
                >&2 printf "%18s%s\n" "" "- Specifying a non-existent run account will create that account and a matching group"
                >&2 printf "%15s%s\n" "" "-c allows specifying a start command [instcmd]"
                >&2 printf "%18s%s\n" "" "- A start command is a requirement for out-of-scope applications"
                >&2 printf "%18s%s\n" "" "- Always use the full path and add all options to use for application start"
                >&2 printf "%18s%s\n" "" "- Any TTY number references in [instcmd] should have the numeric TTY id replaced by the string 'PH_TTY'"
                >&2 printf "%18s%s\n" "" "- Any display number references in [instcmd] should always be '0'" 
                >&2 printf "%18s%s\n" "" "- Start commands should always be surrounded with double quotes"
                >&2 printf "%12s%s\n" "" "\"rem\" allows removing an out-of-scope application [remapp] from PieHelper and (optionally) uninstalling package [rempkg]"
                >&2 printf "%15s%s\n" "" "-a allows specifying an application name [remapp]"
                >&2 printf "%15s%s\n" "" "-b allows specifying a packagename [rempkg]"
                >&2 printf "%18s%s\n" "" "- Specifying a packagename is optional when removing an application"
		>&2 printf "%20s%s\n" "" "If one is specified the package will also be uninstalled"
                >&2 printf "%12s%s\n" "" "\"prompt\" makes confsupp_ph.sh behave interactively when it comes to required application info"
                >&2 printf "%15s%s\n" "" "-i specifies an install action in interactive mode"
                >&2 printf "%18s%s\n" "" "- No surrounding quotes are required when entering any new value in interactive mode"
                >&2 printf "%18s%s\n" "" "- The following application info will be prompted for during interactive install actions :"
                >&2 printf "%21s%s\n" "" "- Application name (required)"
                >&2 printf "%21s%s\n" "" "- Application package name (required)"
                >&2 printf "%21s%s\n" "" "- Application run account"
                >&2 printf "%24s%s\n" "" "- Entering a new value for the run account is optional"
                >&2 printf "%24s%s\n" "" "  The run account for PieHelper will be used if no other is specified"
                >&2 printf "%24s%s\n" "" "- Specifying a non-existent run account will create that account and a matching group"
                >&2 printf "%21s%s\n" "" "- Application start command (required)"
                >&2 printf "%24s%s\n" "" "- Any TTY number references in the value entered for the application's start command should have the numeric TTY id replaced by the string 'PH_TTY'"
                >&2 printf "%24s%s\n" "" "- Any display number references in the value entered for the application's start command should always be '0'" 
                >&2 printf "%15s%s\n" "" "-r specifies a remove action in interactive mode"
                >&2 printf "%18s%s\n" "" "- The following application info will be prompted for during interactive remove actions :"
                >&2 printf "%21s%s\n" "" "- Application name (required)"
                >&2 printf "%21s%s\n" "" "- Application package name"
                >&2 printf "%24s%s\n" "" "- Entering a new value for the package name is optional"
		>&2 printf "%24s%s\n" "" "  If one is specified the package will also be uninstalled"
                >&2 printf "\n"
		OPTIND=$PH_OLDOPTIND
		OPTARG="$PH_OLDOPTARG"
                exit 1 ;;
        esac
done
OPTIND="$PH_OLDOPTIND"
OPTARG="$PH_OLDOPTARG"

[[ -z "$PH_APP_USER" ]] && PH_APP_USER="$PH_RUN_USER"
[[ "$PH_APP" == @(Kodi|Emulationstation|Moonlight|X11|Bash|PieHelper) ]] && printf "%s\n" "- Managing an out-of-scope application '$PH_APP'" && \
				printf "%2s\033[31m%s\033[0m%s\n\n" "" "FAILED" " : Standard application detected -> Use 'confapps_ph.sh' or the PieHelper menu" && exit 1
[[ "$PH_ACTION" == @(inst|rem) && -z "$PH_APP" ]] && (! confsupp_ph.sh -h) && exit 1
[[ "$PH_ACTION" == @(inst) && -z "$PH_APP_PKG" ]] && (! confsupp_ph.sh -h) && exit 1
[[ "$PH_ACTION" == "prompt" && ("$PH_APP_PKG" != "" || "$PH_APP" != "" || "$PH_APP_CMD" != "" || "$PH_APP_USR" != "") ]] && (! confsupp_ph.sh -h) && exit 1
[[ "$PH_ACTION" == "inst" && -z "$PH_APP_CMD" ]] && (! confsupp_ph.sh -h) && exit 1
case $PH_ACTION in inst)
	ph_check_app_name -n -a "$PH_APP" || exit $? ;;
		    rem)
	! ph_check_app_name -s -a "$PH_APP" && printf "\n" && exit 1 ;;
esac
if (([[ "$PH_ACTION" == "inst" ]]) || ([[ -n "$PH_APP_PKG" && "$PH_ACTION" == "rem" ]]))
then
	if ! ph_show_pkg_info "$PH_APP_PKG"
	then
		[[ "$PH_ACTION" == "inst" ]] && printf "\033[36m%s\033[0m\n" "- Adding an out-of-scope application '$PH_APP'" || \
					printf "%s\n" "- Removing an out-of-scope application '$PH_APP'"
		printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED : Invalid package"
		exit 1
	fi
fi
case "$PH_ACTION" in inst)
		printf "%s\n" "- Running some checks"
		printf "%8s%s\n" "" "--> Checking number of out-of-scope applications"
		[[ `cat "$PH_CONF_DIR"/supported_apps 2>/dev/null | wc -l 2>/dev/null` -ge 11 ]] && printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : The maximum number of out-of-scope applications has been reached" && \
										printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" && exit 1
		printf "%10s%s\n" "" "OK ($(echo $((`cat "$PH_CONF_DIR"/supported_apps 2>/dev/null | wc -l 2>/dev/null`-6))))"
		printf "%8s%s\n" "" "--> Checking for package '$PH_APP_PKG'"
		if ph_get_pkg_inststate "$PH_APP_PKG"
		then
			printf "%10s%s\n" "" "OK (Yes)"
		else
			printf "%10s%s\n" "" "Warning : Could not find package '$PH_APP_PKG' -> Adding"
			printf "%8s%s\n" "" "--> Adding package '$PH_APP_PKG'"
			ph_install_pkg -p "${PH_APP_PKG}" && printf "%10s%s\n" "" "OK" || (printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not add package" ; \
											printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" ; return 1) || exit $?
		fi
		printf "%8s%s\n" "" "--> Checking run account"
                id "$PH_APP_USER" >/dev/null 2>&1
                if [[ "$?" -ne 0 ]]
                then
                        printf "%10s%s\n" "" "Warning : User '$PH_APP_USER' not found -> Creating"
                        printf "%8s%s\n" "" "--> Creating group '$PH_APP_USER'"
                        "$PH_SUDO" groupadd -f "$PH_APP_USER" >/dev/null
                        printf "%10s%s\n" "" "OK ('$PH_APP_USER')"
                        printf "%8s%s\n" "" "--> Creating user '$PH_APP_USER'"
                        "$PH_SUDO" useradd -d /home/"$PH_APP_USER" -c "$PH_APP application" -g "$PH_APP_USER" \
                                                        -G tty,audio,video -s /bin/bash "$PH_APP_USER" >/dev/null 2>&1
                        printf "%10s%s\n" "" "OK ('$PH_APP_USER')"
		else
			printf "%10s%s\n" "" "OK ('$PH_APP_USER')"
                fi
		printf "%8s%s\n" "" "--> Checking for dependency on 'X11'"
		echo "$PH_APP_CMD" | nawk -v xinit=^"`which xinit`"$ -v startx=^"`which startx`"$ '$1 ~ xinit || $1 ~ startx { exit 1 }' >/dev/null 2>&1
		if [[ $? -eq 0 ]]
		then
			printf "%10s\033[32m%s\033[0m\n" "" "OK (No)"
			printf "%2s\033[32m%s\033[0m\n\n" "" "SUCCESS"
			printf "%s\n" "- Adding an out-of-scope application '$PH_APP'"
		else
			printf "%10s\033[32m%s\033[0m\n" "" "OK (Yes)"
			printf "%8s%s\n" "" "--> Checking for 'X11' install status"
			ph_get_pkg_inststate "$PH_X11_PKG_NAME"
			if [[ "$?" -eq 0 ]]
			then
				printf "%10s\033[32m%s\033[0m\n" "" "OK (Found)"
				printf "%2s\033[32m%s\033[0m\n\n" "" "SUCCESS"
			else
				printf "%10s%s\n" "" "Warning : X11 Not found -> Installing"
				printf "%2s\033[32m%s\033[0m\n\n" "" "SUCCESS"
				ph_install_app X11 || (printf "\033[36m%s\033[0m\n" "- Adding an out-of-scope application '$PH_APP'" ; \
					printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" ; return 1) || exit "$?"
			fi
			printf "\033[36m%s\033[0m\n" "- Adding an out-of-scope application '$PH_APP'"
			printf "%8s%s\n" "" "--> Detecting next available display"
			PH_i=`nawk -v xinit=^"\`which xinit\`"$ -v startx=^"\`which startx\`"$ 'BEGIN { count = 0 } { for (i=2;i<=NF;i++) { \
							if ($i~/^\:[1-9]$/) { count++ }}} END { print count+1 }' "$PH_CONF_DIR"/supported_apps 2>/dev/null`
			printf "%10s\033[32m%s\033[0m\n" "" "OK"
			printf "%8s%s\n" "" "--> Updating '$PH_APP' start command"
			PH_APP_CMD=`sed "s/ :0 / :$PH_i /g" <<<"$PH_APP_CMD"`
			printf "%10s\033[32m%s\033[0m\n" "" "OK"
		fi
		printf "%8s%s\n" "" "--> Adding '$PH_APP' as a supported application"
		echo -e "$PH_APP\t$PH_APP_CMD" >>"$PH_CONF_DIR"/supported_apps
		printf "%10s\033[32m%s\033[0m\n" "" "OK"
		ph_grant_pieh_access "$PH_APP_USER" "$PH_APP" || (printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" ; return 1) || exit "$?"
		printf "%8s%s\n" "" "--> Adding '$PH_APP' as an integrated application"
		echo -e "$PH_APP\t$PH_APP_USER\t$PH_APP_PKG\t-" >>"$PH_CONF_DIR"/installed_apps
		printf "%10s\033[32m%s\033[0m\n" "" "OK"
		printf "%8s%s\n" "" "--> Adding '$PH_APP' menu items"
		ph_create_app_menus "$PH_APP"
		printf "%10s\033[32m%s\033[0m\n" "" "OK"
		printf "%8s%s\n" "" "--> Adding '$PH_APP' config file"
		ph_create_app_configfile "$PH_APP"
		printf "%10s\033[32m%s\033[0m\n" "" "OK"
		printf "%8s%s\n" "" "--> Adding '$PH_APP' default option values"
		ph_create_app_defaults "$PH_APP"
		printf "%10s\033[32m%s\033[0m\n" "" "OK"
		printf "%8s%s\n" "" "--> Adding '$PH_APP' allowed option values"
		ph_create_app_alloweds "$PH_APP"
		printf "%10s\033[32m%s\033[0m\n" "" "OK"
		printf "%8s%s\n" "" "--> Creating '$PH_APP' default CIFS mountpoint"
		mkdir -p "$PH_CONF_DIR"/../mnt/"$PH_APP" >/dev/null 2>&1
		touch "$PH_CONF_DIR"/../mnt/"$PH_APP"/.gitignore 2>/dev/null
		printf "%10s\033[32m%s\033[0m\n" "" "OK"
		printf "%8s%s\n" "" "--> Adding '$PH_APP' management scripts"
		cp -p "${PH_TEMPLATES_DIR}/StartScript.template" "${PH_SCRIPTS_DIR}/start${PH_APPL}.sh" 2>/dev/null
		cp -p "${PH_TEMPLATES_DIR}/StopScript.template" "${PH_SCRIPTS_DIR}/stop${PH_APPL}.sh" 2>/dev/null
		cp -p "${PH_TEMPLATES_DIR}/RestartScript.template" "${PH_SCRIPTS_DIR}/restart${PH_APPL}.sh" 2>/dev/null
		sed "s/#PH_APPL#/${PH_APPL}/;s/#PH_APP#/${PH_APP}/g" "${PH_SCRIPTS_DIR}/start${PH_APPL}.sh" >"/tmp/start${PH_APPL}_tmp" 2>/dev/null
		[[ "$?" -eq "0" ]] && mv "/tmp/start${PH_APPL}_tmp" "${PH_SCRIPTS_DIR}/start${PH_APPL}.sh" 2>/dev/null
		sed "s/#PH_APPL#/${PH_APPL}/;s/#PH_APP#/${PH_APP}/g" "${PH_SCRIPTS_DIR}/stop${PH_APPL}.sh" >"/tmp/stop${PH_APPL}_tmp" 2>/dev/null
		[[ "$?" -eq "0" ]] && mv "/tmp/stop${PH_APPL}_tmp" "${PH_SCRIPTS_DIR}/stop${PH_APPL}.sh" 2>/dev/null
		sed "s/#PH_APPL#/${PH_APPL}/;s/#PH_APP#/${PH_APP}/g" "${PH_SCRIPTS_DIR}/restart${PH_APPL}.sh" >"/tmp/restart${PH_APPL}_tmp" 2>/dev/null
		[[ "$?" -eq "0" ]] && mv "/tmp/restart${PH_APPL}_tmp" "${PH_SCRIPTS_DIR}/restart${PH_APPL}.sh" 2>/dev/null
		for PH_APP2 in `nawk 'BEGIN { ORS = " " } { print $1 }' "${PH_CONF_DIR}/supported_apps" 2>/dev/null`
		do
			PH_APPL2=`echo "$PH_APP2" | cut -c1-4`
			for PH_i in 1 2
			do
				if [[ "$PH_APPL" != "pieh" ]]
				then
					if [[ "$PH_APPL2" == "pieh" ]]
					then
						cp -p "${PH_TEMPLATES_DIR}/MovetoPieHScript.template" "${PH_SCRIPTS_DIR}/${PH_APPL}to${PH_APPL2}.sh" 2>/dev/null
					else
						[[ "$PH_APP" != "$PH_APP2" ]] && cp -p "${PH_TEMPLATES_DIR}/MoveScript.template" "${PH_SCRIPTS_DIR}/${PH_APPL}to${PH_APPL2}.sh" 2>/dev/null
					fi
				else
					cp -p "${PH_TEMPLATES_DIR}/MovefromPieHScript.template" "${PH_SCRIPTS_DIR}/${PH_APPL}to${PH_APPL2}.sh" 2>/dev/null
				fi
				if [[ "$PH_APP" != "$PH_APP2" ]]
				then
					sed "s/#PH_APPL#/${PH_APPL}/;s/#PH_APP#/${PH_APP}/g;s/#PH_APPL2#/${PH_APPL2}/g;s/#PH_APP2#/${PH_APP2}/g" "${PH_SCRIPTS_DIR}/${PH_APPL}to${PH_APPL2}.sh" >"/tmp/${PH_APPL}_to_tmp" 2>/dev/null
					[[ "$?" -eq "0" ]] && mv "/tmp/${PH_APPL}_to_tmp" "${PH_SCRIPTS_DIR}/${PH_APPL}to${PH_APPL2}.sh" 2>/dev/null
				fi
				PH_TMP="$PH_APP" ; PH_APP="$PH_APP2" ; PH_APP2="$PH_TMP"
				PH_TMP="$PH_APPL" ; PH_APPL="$PH_APPL2" ; PH_APPL2="$PH_TMP"
			done
		done
		"$PH_SUDO" chmod 750 "${PH_SCRIPTS_DIR}/"*.sh 2>/dev/null
		printf "%10s\033[32m%s\033[0m\n" "" "OK"
		printf "%8s%s\n" "" "--> Adding ${PH_APP} user function"
		cat >>"${PH_FUNCS_DIR}/functions.user" <<EOF

function ph_configure_${PH_APPL} {

## add your code here
return 0
}
EOF
		printf "%10s\033[32m%s\033[0m\n" "" "OK (You can optionally add '$PH_APP' configuration code in $PH_FUNCS_DIR/functions.user)"
		printf "%2s\033[32m%s\033[0m\n\n" "" "SUCCESS"
		ph_grant_pieh_access "$PH_APP_USER" "$PH_APP" >/dev/null 2>&1
		exit 0 ;;
		    rem)
		! stop"$PH_APPL".sh && printf "\n" && exit 1
		printf "\033[36m%s\033[0m\n" "- Removing an out-of-scope application '$PH_APP'"
		printf "%8s%s\n" "" "--> Determining TTY allocated to '$PH_APP'"
		PH_APP_TTY=`nawk -v app=^"$PH_APP"$ '$1 ~ app && $4 !~ /-/ { print $4 ; exit 0 } { next }' "$PH_CONF_DIR"/installed_apps 2>/dev/null`
		PH_APP_USER=`ph_get_user_name -a "$PH_APP"`
		[[ "$PH_APP_TTY" -eq 0 ]] && printf "%10s\033[32m%s\033[0m\n" "" "OK (None)" || printf "%10s\033[32m%s\033[0m\n" "" "OK ('TTY$PH_APP_TTY')"
		if [[ "$PH_APP_TTY" -ne 0 ]]
		then
			ph_undo_setup_tty "$PH_APP_TTY" "$PH_APP"
		fi
		ph_remove_app_integration -a "$PH_APP" -u "$PH_APP_USER" || (printf "%2s%s\n\n" "" "FAILED" ; return 1) || exit "$?"
		printf "%8s%s\n" "" "--> Removing '$PH_APP' as a supported application"
		nawk -v app=^"$PH_APP"$ '$1 ~ app { next } { print }' "$PH_CONF_DIR"/supported_apps >/tmp/supported_apps_tmp 2>/dev/null
		if [[ "$?" -eq 0 ]]
		then
			mv /tmp/supported_apps_tmp "$PH_CONF_DIR"/supported_apps 2>/dev/null
		else
			printf "%10s\033[31m%s\033[0m\n\n" "" "ERROR : Could not remove '$PH_APP'"
			printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED"
			exit 1
		fi
		printf "%10s\033[32m%s\033[0m\n" "" "OK"
		printf "%8s%s\n" "" "--> Removing '$PH_APP' menu items"
		rm "$PH_FILES_DIR"/menus/"$PH_APP".lst 2>/dev/null
		[[ "`ls -l $PH_FILES_DIR/menus/OptsManagement.lst 2>/dev/null | nawk -F'/' '{ print $NF }' 2>/dev/null | cut -d'.' -f1 2>/dev/null | cut -d'_' -f2 2>/dev/null`" == "$PH_APP" ]] && \
				ph_set_link_to_app `nawk -v app=^"$PH_APP"$ '$1 !~ app { print $1 ; exit 0 }' "$PH_CONF_DIR"/installed_apps 2>/dev/null`
		rm "$PH_FILES_DIR"/menus/OptsManagement_"$PH_APP".lst 2>/dev/null
		rm "$PH_FILES_DIR"/menus/TTYManagement_"$PH_APP".lst 2>/dev/null
		printf "%10s\033[32m%s\033[0m\n" "" "OK"
		printf "%8s%s\n" "" "--> Removing '$PH_APP' management scripts"
		rm "$PH_SCRIPTS_DIR"/start"$PH_APPL".sh 2>/dev/null
		rm "$PH_SCRIPTS_DIR"/stop"$PH_APPL".sh 2>/dev/null
		rm "$PH_SCRIPTS_DIR"/restart"$PH_APPL".sh 2>/dev/null
		for PH_APP2 in `nawk 'BEGIN { ORS = " " } { print $1 }' "$PH_CONF_DIR"/supported_apps 2>/dev/null`
		do
			PH_APPL2=`echo "$PH_APP2" | cut -c1-4`
			rm "$PH_SCRIPTS_DIR"/"$PH_APPL"to"$PH_APPL2".sh 2>/dev/null
			rm "$PH_SCRIPTS_DIR"/"$PH_APPL2"to"$PH_APPL".sh 2>/dev/null
		done
		printf "%10s\033[32m%s\033[0m\n" "" "OK"
		printf "%8s%s\n" "" "--> Removing '$PH_APP' default CIFS mountpoint"
		rm -r "$PH_CONF_DIR"/../mnt/"$PH_APP" >/dev/null 2>&1
		printf "%10s\033[32m%s\033[0m\n" "" "OK"
		if [[ -n "$PH_APP_PKG" ]]
		then
			printf "%8s%s\n" "" "--> Removing package '$PH_APP_PKG'"
			ph_remove_pkg "$PH_APP_PKG" && printf "%10s\033[32m%s\033[0m\n" "" "OK" || printf "%10s\033[31m%s\033[0m\n" "" "ERROR : Could not remove package"
		fi
		printf "%8s%s\n" "" "--> Removing '$PH_APP' default option values"
		for PH_j in `grep ^"PH_" "$PH_CONF_DIR"/"$PH_APP".conf 2>/dev/null | nawk -F'=' '{ print $1 }' 2>/dev/null | paste -d" " -s 2>/dev/null`
		do
			sed "/^$PH_j=/d" "$PH_FILES_DIR"/options.defaults >/tmp/options_defaults_tmp 2>/dev/null
			[[ $? -eq 0 ]] && mv /tmp/options_defaults_tmp "$PH_FILES_DIR"/options.defaults 2>/dev/null
		done
		printf "%10s\033[32m%s\033[0m\n" "" "OK"
		printf "%8s%s\n" "" "--> Removing '$PH_APP' allowed option values"
		for PH_j in PH_`echo $PH_APPU`_CIFS_SHARE PH_`echo $PH_APPU`_CIFS_USER PH_`echo $PH_APPU`_CIFS_SRV PH_`echo $PH_APPU`_PERSISTENT PH_`echo $PH_APPU`_CIFS_DIR PH_`echo $PH_APPU`_CIFS_SUBDIR PH_`echo $PH_APPU`_CIFS_MPT PH_`echo $PH_APPU`_USE_CTRL PH_`echo $PH_APPU`_NUM_CTRL PH_`echo $PH_APPU`_PRE_CMD PH_`echo $PH_APPU`_POST_CMD
		do
			nawk -F':' -v app=^"$PH_j"$ '$1 ~ app { next } { print }' "$PH_FILES_DIR"/options.allowed >/tmp/options_allowed_tmp 2>/dev/null
			[[ $? -eq 0 ]] && mv /tmp/options_allowed_tmp "$PH_FILES_DIR"/options.allowed 2>/dev/null
		done
		printf "%10s\033[32m%s\033[0m\n" "" "OK"
		printf "%8s%s\n" "" "--> Removing '$PH_APP' config file"
		rm "$PH_CONF_DIR"/"$PH_APP".conf 2>/dev/null
		printf "%10s\033[32m%s\033[0m\n" "" "OK"
		printf "%8s%s\n" "" "--> Removing '$PH_APP' user function"
		nawk -v app="_$PH_APPL"$ 'BEGIN { FLAG=0 } $1 ~ /^function$/ && $2 ~ app { FLAG=1 ; while ($1!~/^}$/) { getline } ; getline ; FLAG=0 ; next } \
										{ if (FLAG==0) { print $0 }}' "$PH_FUNCS_DIR"/functions.user >/tmp/functions.user_tmp 2>/dev/null
		[[ $? -eq 0 ]] && mv /tmp/functions.user_tmp "$PH_FUNCS_DIR"/functions.user 2>/dev/null
		printf "%10s\033[32m%s\033[0m\n" "" "OK"
		ph_revoke_pieh_access "$PH_APP_USER" "$PH_APP" || (printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" ; return 1) || exit "$?"
		printf "%2s\033[32m%s\033[0m\n\n" "" "SUCCESS"
		exit 0 ;;
		 prompt)
		printf "\033[36m%s\033[0m\n" "- Using interactive mode"
		while [[ -z "$PH_APP" ]]
		do
			[[ $PH_COUNT -gt 0 ]] && printf "\n%10s\033[31m%s\033[0m\n\n" "" "ERROR : Invalid response"
			printf "%8s%s" "" "--> Please enter an application name : "
			read PH_APP 2>/dev/null
			ph_screen_input "$PH_APP" || exit "$?"
			((PH_COUNT++))
			PH_APPL=`echo "$PH_APP" | cut -c1-4`
		done
		PH_COUNT=0
		printf "%10s\033[32m%s\033[0m\n" "" "OK"
		case "$PH_I_ACTION" in inst)
			while [[ -z "$PH_APP_CMD" ]]
			do
				[[ $PH_COUNT -gt 0 ]] && printf "\n%10s\033[31m%s\033[0m\n\n" "" "ERROR : Invalid response"
				printf "%8s%s\n\n" "" "--> Please enter '$PH_APP' start command : "
				printf "%10s%s\n" "" "- Use the full path and add all command-line options to use for '$PH_APP' start"
				printf "%10s%s\n" "" "- Any TTY number references should have the numeric TTY id replaced by the string 'PH_TTY'"
				printf "%10s%s\n\n" "" "- Any display number references should always be '0'"
				printf "%8s%s" "" "Start command : "
				read PH_APP_CMD 2>/dev/null
				((PH_COUNT++))
			done
			printf "%10s\033[32m%s\033[0m\n" "" "OK"
			PH_COUNT=0
			printf "%8s%s\n\n" "" "--> Please enter '$PH_APP' run account (Optional) : "
			printf "%10s%s\n" "" "- Leaving this empty will set the run account to the same as PieHelper's ('$PH_RUN_USER')"
                	printf "%10s%s\n\n" "" "- Specifying a non-existent account will create that account and a matching group"
			printf "%8s%s" "" "Run account : "
			read PH_APP_USER
			ph_screen_input "$PH_APP_USER" || exit $?
			[[ -z "$PH_APP_USER" ]] && PH_APP_USER="$PH_RUN_USER"
			printf "%10s\033[32m%s\033[0m\n" "" "OK ('$PH_APP_USER')"
			while [[ -z "$PH_APP_PKG" ]]
			do
				[[ $PH_COUNT -gt 0 ]] && printf "\n%10s\033[31m%s\033[0m\n\n" "" "ERROR : Invalid response"
				printf "%8s%s" "" "--> Please enter '$PH_APP' package name : "
				read PH_APP_PKG 2>/dev/null
				((PH_COUNT++))
			done
			printf "%10s\033[32m%s\033[0m\n" "" "OK"
			printf "%2s\033[32m%s\033[0m\n\n" "" "SUCCESS"
			confsupp_ph.sh -p inst -a "$PH_APP" -c "$PH_APP_CMD" -u "$PH_APP_USER" -b "$PH_APP_PKG" | more
			exit "$?" ;;
				   	rem)
			printf "%8s%s\n\n" "" "--> Please enter '$PH_APP' package name (Optional) : "
			printf "%10s%s\n\n" "" "Leaving this empty will leave '$PH_APP' package installed"
			printf "%8s%s" "" "Package name : "
			read PH_APP_PKG
			printf "%10s\033[32m%s\033[0m\n" "" "OK"
			printf "%2s\033[32m%s\033[0m\n\n" "" "SUCCESS"
			if [[ -z "$PH_APP_PKG" ]]
			then
				confsupp_ph.sh -p rem -a "$PH_APP" | more
			else
				confsupp_ph.sh -p rem -a "$PH_APP" -b "$PH_APP_PKG" | more
			fi
			exit "$?" ;;
		esac ;;
esac
confsupp_ph.sh -h || exit "$?"
