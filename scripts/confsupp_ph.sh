#!/bin/ksh
# Manage supplementary out-of-scope apps (by Davy Keppens on 11/11/2018)
# Enable/Disable debug by running confpieh_ph.sh -p debug -m confsupp_ph.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

typeset PH_OPTION=""
typeset PH_ACTION=""
typeset PH_I_ACTION=""
typeset PH_TMP=""
typeset PH_APP=""
typeset PH_APP2=""
typeset PH_APP_USER=""
typeset PH_APP_CMD=""
typeset PH_APP_PKG=""
typeset PH_j=""
typeset PH_OLDOPTARG="$OPTARG"
typeset -i PH_i=0
typeset -i PH_COUNT=0
typeset -i PH_APP_TTY=0
typeset -i PH_OLDOPTIND=$OPTIND
typeset -l PH_APPL=""
typeset -l PH_APPL2=""
typeset -u PH_APPU=""
OPTIND=1

while getopts p:a:c:u:b:irh PH_OPTION 2>/dev/null
do
	case $PH_OPTION in p)
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
                >&2 printf "%15s%s\n" "" "-b allows specifying a packagename [instpkg]"
                >&2 printf "%18s%s\n" "" "- A package is a requirement for out-of-scope applications"
                >&2 printf "%18s%s\n" "" "- If the specified package is currently uninstalled it will be installed first"
                >&2 printf "%15s%s\n" "" "-u allows specifying a run account [instusr]"
                >&2 printf "%18s%s\n" "" "- Specifying a run account is optional"
                >&2 printf "%20s%s\n" "" "The run account for PieHelper will be used if no other is specified"
                >&2 printf "%18s%s\n" "" "- Specifying a non-existent run account will create that account and a matching group"
                >&2 printf "%15s%s\n" "" "-c allows specifying a start command [instcmd]"
                >&2 printf "%18s%s\n" "" "- A start command is a requirement for out-of-scope applications"
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
OPTIND=$PH_OLDOPTIND
OPTARG="$PH_OLDOPTARG"

[[ -z "$PH_APP_USER" ]] && PH_APP_USER="$PH_RUN_USER"
[[ "$PH_APP" == @(Kodi|Emulationstation|Moonlight|X11|Bash|PieHelper) ]] && printf "%s\n" "- Managing an out-of-scope application $PH_APP" && \
				printf "%2s%s\n\n" "" "FAILED : Standard application detected -> Use confapps_ph.sh" && exit 1
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
	if ! ph_show_pkg_info $PH_APP_PKG
	then
		[[ "$PH_ACTION" == "inst" ]] && printf "%s\n" "- Adding a new out-of-scope application $PH_APP" || \
					printf "%s\n" "- Removing out-of-scope application $PH_APP"
		printf "%2s%s\n\n" "" "FAILED : Invalid package"
		exit 1
	fi
fi
case $PH_ACTION in inst)
		printf "%s\n" "- Running some checks"
		printf "%8s%s\n" "" "--> Checking current number of out-of-scope applications"
		[[ `cat $PH_CONF_DIR/supported_apps | wc -l` -ge 11 ]] && printf "%10s%s\n" "" "ERROR : The maximum number of out-of-scope applications has been reached" && \
										printf "%2s%s\n\n" "" "FAILED" && exit 1
		printf "%10s%s\n" "" "OK ($(echo $((`cat $PH_CONF_DIR/supported_apps | wc -l`-6))))"
		printf "%8s%s\n" "" "--> Checking for package \"$PH_APP_PKG\""
		if ph_get_pkg_inststate "$PH_APP_PKG"
		then
			printf "%10s%s\n" "" "OK (Yes)"
		else
			printf "%10s%s\n" "" "Warning : Could not find package $PH_APP_PKG -> Installing"
			printf "%8s%s\n" "" "--> Installing package \"$PH_APP_PKG\""
			ph_install_pkg "$PH_APP_PKG" && printf "%10s%s\n" "" "OK" || (printf "%10s%s\n" "" "ERROR : Could not install package $PH_APP_PKG" ; \
											printf "%2s%s\n\n" "" "FAILED" ; return 1) || exit $?
		fi
		printf "%8s%s\n" "" "--> Checking run account"
                id $PH_APP_USER >/dev/null 2>&1
                if [[ $? -ne 0 ]]
                then
                        printf "%10s%s\n" "" "Warning : User $PH_APP_USER does not exist -> Creating"
                        printf "%8s%s\n" "" "--> Creating group $PH_APP_USER"
                        $PH_SUDO groupadd -f $PH_APP_USER >/dev/null
                        printf "%10s%s\n" "" "OK ($PH_APP_USER)"
                        printf "%8s%s\n" "" "--> Creating user $PH_APP_USER"
                        $PH_SUDO useradd -d /home/$PH_APP_USER -c "$PH_APP application" -g $PH_APP_USER \
                                                        -G tty,audio,video -s /bin/bash $PH_APP_USER >/dev/null 2>&1
                        printf "%10s%s\n" "" "OK ($PH_APP_USER)"
		else
			printf "%10s%s\n" "" "OK ($PH_APP_USER)"
                fi
		printf "%8s%s\n" "" "--> Checking for dependency on X11"
		echo $PH_APP_CMD | nawk -v xinit=^"`which xinit`"$ -v startx=^"`which startx`"$ '$1 ~ xinit || $1 ~ startx { exit 1 }' >/dev/null
		if [[ $? -eq 0 ]]
		then
			printf "%10s%s\n" "" "OK (No)"
			printf "%2s%s\n" "" "SUCCESS"
			printf "%s\n" "- Adding a new out-of-scope application $PH_APP"
		else
			printf "%10s%s\n" "" "OK (Yes)"
			printf "%8s%s\n" "" "--> Checking for X11 install status"
			ph_get_pkg_inststate $PH_X11_PKG_NAME
			if [[ $? -eq 0 ]]
			then
				printf "%10s%s\n" "" "OK (Found)"
				printf "%2s%s\n" "" "SUCCESS"
			else
				printf "%10s%s\n" "" "Warning : X11 Not found -> Installing"
				printf "%2s%s\n" "" "SUCCESS"
				ph_install_app X11 || (printf "%s\n" "- Adding a new out-of-scope application $PH_APP" ; \
					printf "%2s%s\n\n" "" "FAILED" ; return 1) || exit $?
			fi
			printf "%s\n" "- Adding a new out-of-scope application $PH_APP"
			printf "%8s%s\n" "" "--> Attempting to detect next available display"
			PH_i=`nawk -v xinit=^"\`which xinit\`"$ -v startx=^"\`which startx\`"$ 'BEGIN { count = 0 } { for (i=2;i<=NF;i++) { \
							if ($i~/^\:[1-9]$/) { count++ }}} END { print count+1 }' $PH_CONF_DIR/supported_apps`
			printf "%10s%s\n" "" "OK"
			printf "%8s%s\n" "" "--> Updating start command"
			PH_APP_CMD=`sed "s/ :0 / :$PH_i /g" <<<$PH_APP_CMD`
			printf "%10s%s\n" "" "OK"
		fi
		printf "%8s%s\n" "" "--> Adding a new menu item"
		cat >$PH_FILES_DIR/menus/$PH_APP.lst <<EOF
Show $PH_APP current state:ph_check_app_name -s -a $PH_APP | more
Start or switch to $PH_APP:start$PH_APPL.sh | more
Stop $PH_APP:stop$PH_APPL.sh force | more
Restart $PH_APP:restart$PH_APPL.sh | more
Install $PH_APP and integrate with PieHelper:confapps_ph.sh -p int -a $PH_APP
Remove $PH_APP from PieHelper and uninstall:confapps_ph.sh -p rem -a $PH_APP
Configure $PH_APP (requires development from user):confapps_ph.sh -p conf -a $PH_APP
Update $PH_APP to the latest version (only if installed as a package):ph_update_pkg \$PH_`echo $PH_APPU`_PKG_NAME | more
List all available options for $PH_APP:confopts_ph.sh -p list -a $PH_APP | more
View the current value of $PH_APP option(s) (Variable expansion disabled):confopts_ph.sh -p prompt -a $PH_APP -g
View the current value of $PH_APP option(s) (Variable expansion enabled):confopts_ph.sh -p prompt -a $PH_APP -g -r
Change the value of read-write $PH_APP option(s) (Variable expansion disabled):confopts_ph.sh -p prompt -a $PH_APP -s
Change the value of read-write $PH_APP option(s) (Variable expansion enabled):confopts_ph.sh -p prompt -a $PH_APP -s -r
Display help for $PH_APP option(s) (Variable expansion disabled):confopts_ph.sh -p prompt -a $PH_APP -d
Display help for $PH_APP option(s) (Variable expansion enabled):confopts_ph.sh -p prompt -a $PH_APP -d -r
Display TTY currently allocated to $PH_APP:confapps_ph.sh -p tty -a $PH_APP | more
Move $PH_APP to another TTY:confapps_ph.sh -p move -a $PH_APP -t prompt
Go to Main menu:ph_show_menu Main
Go to Apps menu:ph_show_menu Apps
Return to previous screen:return
EOF
		printf "%10s%s\n" "" "OK"
		printf "%8s%s\n" "" "--> Adding a config file"
		cat >$PH_CONF_DIR/$PH_APP.conf <<EOF
# General $PH_APP configuration
# Do NOT edit the configuration files manually. Always use PieHelper to make changes
# Refer to the $PH_APP documentation for more info on some of these settings

PH_`echo $PH_APPU`_PERSISTENT='no'							# - This indicates whether $PH_APP, when active, should be kept running on it's allocated TTY
											#   whenever any application other than $PH_APP starts
											#   Persistent applications will only stop when a direct stop or restart is issued
											# - Default is 'no'
											# - Allowed values are 'yes' and 'no'
											# - Important : * If an application does not render to the default frame buffer it can stay visible in foreground when switching to
											#                 a TTY that is allocated to a persistent-marked application
											#               * That behaviour can be avoided by setting persistence to 'no' for both applications
PH_`echo $PH_APPU`_PKG_NAME='$PH_APP_PKG'						# - This is the package name for $PH_APP if available
											# - Default is '$PH_APP_PKG'
PH_`echo $PH_APPU`_CMD_OPTS=''								# - These are the command line options you wish to launch $PH_APP with
											# - Amongst others, this can be used for passing event-based input devices when required as parameters by $PH_APP
											#   When passing event-based input devices, replace the numeric id in the device reference with the string 'PH_CTRL%' where
											#   where '%' is '1' for device 1, '2' for device 2, etc
											# - Changes to an option holding an application's command line options where event-based input devices are present will automatically be reflected
											#   to the application's option determining the controller amount unless all event device parameters are being removed
											# - Default is ''
PH_`echo $PH_APPU`_USE_CTRL='no'							# - This indicates whether you want to use controllers with $PH_APP or not
											# - Controller type to be used and the toggle for optional mapping with xboxdrv should be configured first using 'confopts_ph.sh'
											#   or the PieHelper menu
											# - The amount of controllers to use can be set with option PH_`echo $PH_APPU`_NUM_CTRL
											# - If this is set to 'yes' and the specified amount of controllers of the type configured can not be detected on $PH_APP startup,
											#   startup will fail
											# - Default is 'no'
											# - Allowed values are 'yes' and 'no'
PH_`echo $PH_APPU`_NUM_CTRL='1'								# - This is the number of controllers you want to use with $PH_APP
											# - Changes to an option that sets the controller amount for an application will automatically be reflected to
											#   the option holding that application's command line options if event-based input devices are present as command-line parameters
											# - Default is '1'
											# - Allowed values are '1', '2', '3' and '4'
PH_`echo $PH_APPU`_CIFS_SHARE='no'							# - This indicates whether you want to mount a CIFS share from a local network server PH_`echo $PH_APPU`_CIFS_SRV before $PH_APP starts and
											#   umount it after $PH_APP shuts down
											# - Default is 'no'
											# - Allowed values are 'yes' and 'no'
											# - Important : * Keep in mind that setting this to 'yes' requires you to enable CIFS sharing on PH_`echo $PH_APPU`_CIFS_SRV
											#               * You should also make sure your PI has adequate permissions to access that share
											#               * Lastly, a user account PH_`echo $PH_APPU`_CIFS_USER with a password PH_`echo $PH_APPU`_CIFS_PASS should be created on PH_`echo $PH_APPU`_CIFS_SRV
PH_`echo $PH_APPU`_CIFS_USER=''								# - This is the user account on local network server PH_`echo $PH_APPU`_CIFS_SRV with password PH_`echo $PH_APPU`_CIFS_PASS
											#   if PH_`echo $PH_APPU`_CIFS_SHARE is set to 'yes'
											# - Default is ''
PH_`echo $PH_APPU`_CIFS_PASS=''								# - This is the password for user PH_`echo $PH_APPU`_CIFS_USER on local network server PH_`echo $PH_APPU`_CIFS_SRV if PH_`echo $PH_APPU`_CIFS_SHARE is set to 'yes'
											# - The password should not contain any single quote (') characters
											# - Default is ''
PH_`echo $PH_APPU`_CIFS_SRV=''								# - This is the ip address of your local network server where CIFS sharing is enabled if PH_`echo $PH_APPU`_CIFS_SHARE is set to 'yes'
											# - Default is ''
											# - Allowed values are valid ipv4 addresses and an empty string
PH_`echo $PH_APPU`_CIFS_DIR=''								# - This is the pathname of the CIFS share on local network server PH_`echo $PH_APPU`_CIFS_SRV if PH_`echo $PH_APPU`_CIFS_SHARE is set to 'yes'
											# - Default is ''
											# - Allowed values are pathnames (Values starting with '/' or '$') and an empty string
PH_`echo $PH_APPU`_CIFS_SUBDIR=''							#  - This is the pathname relative to PH_`echo $PH_APPU`_CIFS_DIR on local network server PH_`echo $PH_APPU`_CIFS_SRV that will be mounted on PH_`echo $PH_APPU`_CIFS_MPT
											#   if PH_`echo $PH_APPU`_CIFS_SHARE is set to 'yes'
											# - Default is ''
											# - Allowed values are pathnames (Values starting with '/' or '$') and an empty string
PH_`echo $PH_APPU`_CIFS_MPT='\$PH_CONF_DIR/../mnt/$PH_APP'				# - This is the full pathname of a directory on your PI where you want to mount PH_`echo $PH_APPU`_CIFS_SUBDIR if PH_`echo $PH_APPU`_CIFS_SHARE is set to 'yes'
											# - A default directory named 'mnt' with a subfolder for each integrated application is automatically created under the root of the PieHelper
											#   install location but other values can be set if preferred
											#   If a different value is set, make sure the directory specified is empty
											# - Default is '\$PH_CONF_DIR/../mnt/$PH_APP'
											# - Allowed values are pathnames (Values starting with '/' or '$') and an empty string
PH_`echo $PH_APPU`_PRE_CMD=''								# - This is the full command to run before starting $PH_APP. If PH_`echo $PH_APPU`_CIFS_SHARE is set to 'yes', it will be run when the CIFS share is mounted
											#   Make sure the run account used for $PH_APP has adequate permission when customising this
											# - PRE-commands that fail will only generate a warning and not block further $PH_APP startup
											# - Default is ''
											# - Allowed values are full pathnames (Values starting with '/' or '$') of scripts, sourceable scripts and executables or an empty string
											#   Sourceable scripts can use variable names known to PieHelper
PH_`echo $PH_APPU`_POST_CMD=''								# - This is the full command to run after stopping $PH_APP. If PH_`echo $PH_APPU`_CIFS_SHARE is set to 'yes', it will be run when the CIFS share is mounted
											#   Make sure the run account used for $PH_APP has adequate permissions when customising this
											# - POST-commands that fail will only generate a warning
											# - Default is ''
											# - Allowed values are full pathnames (Values starting with '/' or '$') of scripts, sourceable scripts and executables or an empty string
											#   Sourceable scripts can use variable names known to PieHelper

# Exports

export PH_`echo $PH_APPU`_PERSISTENT PH_`echo $PH_APPU`_PKG_NAME PH_`echo $PH_APPU`_CMD_OPTS PH_`echo $PH_APPU`_USE_CTRL PH_`echo $PH_APPU`_NUM_CTRL PH_`echo $PH_APPU`_CIFS_SHARE PH_`echo $PH_APPU`_CIFS_USER PH_`echo $PH_APPU`_CIFS_PASS PH_`echo $PH_APPU`_CIFS_SRV PH_`echo $PH_APPU`_CIFS_DIR PH_`echo $PH_APPU`_CIFS_SUBDIR PH_`echo $PH_APPU`_CIFS_MPT
export PH_`echo $PH_APPU`_POST_CMD PH_`echo $PH_APPU`_PRE_CMD
EOF
		printf "%10s%s\n" "" "OK"
		printf "%8s%s\n" "" "--> Adding options to options.defaults"
		echo "PH_`echo $PH_APPU`_PERSISTENT='no'" >>$PH_FILES_DIR/options.defaults
		echo "PH_`echo $PH_APPU`_PKG_NAME='$PH_APP_PKG'" >>$PH_FILES_DIR/options.defaults
		echo "PH_`echo $PH_APPU`_CMD_OPTS=''" >>$PH_FILES_DIR/options.defaults
		echo "PH_`echo $PH_APPU`_USE_CTRL='no'" >>$PH_FILES_DIR/options.defaults
		echo "PH_`echo $PH_APPU`_NUM_CTRL='1'" >>$PH_FILES_DIR/options.defaults
		echo "PH_`echo $PH_APPU`_CIFS_SHARE='no'" >>$PH_FILES_DIR/options.defaults
		echo "PH_`echo $PH_APPU`_CIFS_USER=''" >>$PH_FILES_DIR/options.defaults
		echo "PH_`echo $PH_APPU`_CIFS_PASS=''" >>$PH_FILES_DIR/options.defaults
		echo "PH_`echo $PH_APPU`_CIFS_SRV=''" >>$PH_FILES_DIR/options.defaults
		echo "PH_`echo $PH_APPU`_CIFS_DIR=''" >>$PH_FILES_DIR/options.defaults
		echo "PH_`echo $PH_APPU`_CIFS_SUBDIR=''" >>$PH_FILES_DIR/options.defaults
		echo "PH_`echo $PH_APPU`_CIFS_MPT='\$PH_CONF_DIR/../mnt/$PH_APP'" >>$PH_FILES_DIR/options.defaults
		echo "PH_`echo $PH_APPU`_PRE_CMD=''" >>$PH_FILES_DIR/options.defaults
		echo "PH_`echo $PH_APPU`_POST_CMD=''" >>$PH_FILES_DIR/options.defaults
		printf "%10s%s\n" "" "OK"
		printf "%8s%s\n" "" "--> Adding options to options.allowed"
		echo "PH_`echo $PH_APPU`_PERSISTENT:yes or no:\"\$PH_OPTARG_VAL\" == @(yes|no)" >>$PH_FILES_DIR/options.allowed
		echo "PH_`echo $PH_APPU`_CIFS_SHARE:yes or no:\"\$PH_OPTARG_VAL\" == @(yes|no)" >>$PH_FILES_DIR/options.allowed
		echo "PH_`echo $PH_APPU`_CIFS_SRV:a valid ipv4 address or an empty string:\`\$(ph_check_ip_validity \"\$PH_OPTARG_VAL\") echo \$?\` -eq 0" >>$PH_FILES_DIR/options.allowed
		echo "PH_`echo $PH_APPU`_CIFS_DIR:an empty string or starting with / or \$:\"\$PH_OPTARG_VAL\" == @(/*|\\\$*|)" >>$PH_FILES_DIR/options.allowed
		echo "PH_`echo $PH_APPU`_CIFS_SUBDIR:an empty string or starting with / or \$:\"\$PH_OPTARG_VAL\" == @(/*|\\\$*|)" >>$PH_FILES_DIR/options.allowed
		echo "PH_`echo $PH_APPU`_CIFS_MPT:an empty string or starting with / or \$:\"\$PH_OPTARG_VAL\" == @(/*|\\\$*|)" >>$PH_FILES_DIR/options.allowed
		echo "PH_`echo $PH_APPU`_USE_CTRL:yes or no:\"\$PH_OPTARG_VAL\" == @(yes|no)" >>$PH_FILES_DIR/options.allowed
		echo "PH_`echo $PH_APPU`_NUM_CTRL:1, 2, 3 or 4:\"\$PH_OPTARG_VAL\" == @(1|2|3|4)" >>$PH_FILES_DIR/options.allowed
		echo "PH_`echo $PH_APPU`_PRE_CMD:an empty string or starting with / or \$:\"\$PH_OPTARG_VAL\" == @(/*|\\\$*|)" >>$PH_FILES_DIR/options.allowed
		echo "PH_`echo $PH_APPU`_POST_CMD:an empty string or starting with / or \$:\"\$PH_OPTARG_VAL\" == @(/*|\\\$*|)" >>$PH_FILES_DIR/options.allowed
		printf "%10s%s\n" "" "OK"
		printf "%8s%s\n" "" "--> Creating default mountpoint for CIFS mounts"
		mkdir -p "$PH_CONF_DIR"/../mnt/"$PH_APP" >/dev/null 2>&1
		touch "$PH_CONF_DIR/../mnt/$PH_APP/.gitignore"
		printf "%10s%s\n" "" "OK"
		printf "%8s%s\n" "" "--> Adding scripts"
		cp -p $PH_FILES_DIR/StartScript.template $PH_SCRIPTS_DIR/start"$PH_APPL".sh
		cp -p $PH_FILES_DIR/StopScript.template $PH_SCRIPTS_DIR/stop"$PH_APPL".sh
		cp -p $PH_FILES_DIR/RestartScript.template $PH_SCRIPTS_DIR/restart"$PH_APPL".sh
		sed "s/#PH_APPL#/$PH_APPL/;s/#PH_APP#/$PH_APP/" $PH_SCRIPTS_DIR/start"$PH_APPL".sh >/tmp/start"$PH_APPL"_tmp
		[[ $? -eq 0 ]] && mv /tmp/start"$PH_APPL"_tmp $PH_SCRIPTS_DIR/start"$PH_APPL".sh
		sed "s/#PH_APPL#/$PH_APPL/;s/#PH_APP#/$PH_APP/" $PH_SCRIPTS_DIR/stop"$PH_APPL".sh >/tmp/stop"$PH_APPL"_tmp
		[[ $? -eq 0 ]] && mv /tmp/stop"$PH_APPL"_tmp $PH_SCRIPTS_DIR/stop"$PH_APPL".sh
		sed "s/#PH_APPL#/$PH_APPL/;s/#PH_APP#/$PH_APP/" $PH_SCRIPTS_DIR/restart"$PH_APPL".sh >/tmp/restart"$PH_APPL"_tmp
		[[ $? -eq 0 ]] && mv /tmp/restart"$PH_APPL"_tmp $PH_SCRIPTS_DIR/restart"$PH_APPL".sh
		for PH_APP2 in `nawk 'BEGIN { ORS = " " } { print $1 }' $PH_CONF_DIR/supported_apps`
		do
			PH_APPL2=`echo $PH_APP2 | cut -c1-4`
			for PH_i in 1 2
			do
				if [[ "$PH_APPL" != "pieh" ]]
				then
					if [[ "$PH_APPL2" == "pieh" ]]
					then
						cp -p $PH_FILES_DIR/MovetoPieHScript.template $PH_SCRIPTS_DIR/"$PH_APPL"to"$PH_APPL2".sh
					else
						cp -p $PH_FILES_DIR/MoveScript.template $PH_SCRIPTS_DIR/"$PH_APPL"to"$PH_APPL2".sh
					fi
				else
					cp -p $PH_FILES_DIR/MovefromPieHScript.template $PH_SCRIPTS_DIR/"$PH_APPL"to"$PH_APPL2".sh
				fi
				sed "s/#PH_APPL#/$PH_APPL/;s/#PH_APP#/$PH_APP/;s/#PH_APPL2#/$PH_APPL2/;s/#PH_APP2#/$PH_APP2/" $PH_SCRIPTS_DIR/"$PH_APPL"to"$PH_APPL2".sh >/tmp/"$PH_APPL"_to_tmp
				[[ $? -eq 0 ]] && mv /tmp/"$PH_APPL"_to_tmp $PH_SCRIPTS_DIR/"$PH_APPL"to"$PH_APPL2".sh
				PH_TMP="$PH_APP" ; PH_APP="$PH_APP2" ; PH_APP2="$PH_TMP"
				PH_TMP="$PH_APPL" ; PH_APPL="$PH_APPL2" ; PH_APPL2="$PH_TMP"
			done
		done
		$PH_SUDO chmod 750 $PH_SCRIPTS_DIR/*.sh
		printf "%10s%s\n" "" "OK"
		printf "%8s%s\n" "" "--> Adding $PH_APP to supported applications configuration file"
		echo -e "$PH_APP\t$PH_APP_CMD" >>$PH_CONF_DIR/supported_apps
		printf "%10s%s\n" "" "OK"
		if nawk -v user=^"$PH_APP_USER"$ '$2 ~ user { exit 1 } { next }' $PH_CONF_DIR/installed_apps >/dev/null 2>&1
		then
			if [[ "$PH_APP_USER" != "$PH_RUN_USER" ]]
			then
				ph_grant_pieh_access "$PH_APP_USER"
			fi
		fi
		printf "%8s%s\n" "" "--> Adding $PH_APP to integrated applications configuration file"
		echo -e "$PH_APP\t$PH_APP_USER\tyes\t-" >>$PH_CONF_DIR/installed_apps
		printf "%10s%s\n" "" "OK"
		printf "%8s%s\n" "" "--> Adding user functions"
		cat >>$PH_MAIN_DIR/functions.user <<EOF

function ph_configure_$PH_APPL {

## add your code here
return 0
}
EOF
		printf "%10s%s\n" "" "OK (You can optionally add configuration code for $PH_APP in $PH_MAIN_DIR/functions.user)"
		printf "%2s%s\n\n" "" "SUCCESS"
		exit 0 ;;
		    rem)
		! stop"$PH_APPL".sh && printf "\n" && exit 1
		printf "%s\n" "- Removing out-of-scope application $PH_APP"
		printf "%8s%s\n" "" "--> Determining TTY allocated to $PH_APP"
		PH_APP_TTY=`nawk -v app=^"$PH_APP"$ '$1 ~ app && $4 !~ /-/ { print $4 ; exit 0 } { next }' $PH_CONF_DIR/installed_apps 2>/dev/null`
		[[ $PH_APP_TTY -eq 0 ]] && printf "%10s%s\n" "" "OK (None)" || printf "%10s%s\n" "" "OK (TTY$PH_APP_TTY)"
		PH_APP_USER=`nawk -v app=^"$PH_APP"$ '$1 ~ app { print $2 ; exit 0 } { next }' $PH_CONF_DIR/installed_apps 2>/dev/null`
		printf "%8s%s\n" "" "--> Removing $PH_APP from supported applications configuration file"
		nawk -v app=^"$PH_APP"$ '$1 ~ app { next } { print }' $PH_CONF_DIR/supported_apps >/tmp/supported_apps_tmp
		[[ $? -eq 0 ]] && (printf "%10s%s\n" "" "OK" ; mv /tmp/supported_apps_tmp $PH_CONF_DIR/supported_apps) || \
					(printf "%10s%s\n" "" "ERROR : Could not remove $PH_APP from supported applications configuration file" ; \
					 printf "%2s%s\n\n" "" "FAILED" ; return 1) || exit $?
		if [[ $PH_APP_TTY -ne 0 ]]
		then
			ph_undo_setup_tty $PH_APP_TTY "$PH_APP"
		else
			printf "%8s%s\n" "" "--> Removing $PH_APP from installed applications configuration file"
			nawk -v app=^"$PH_APP"$ '$1 ~ app { next } { print }' $PH_CONF_DIR/installed_apps >/tmp/installed_apps_tmp
			[[ $? -eq 0 ]] && (printf "%10s%s\n" "" "OK" ; mv /tmp/installed_apps_tmp $PH_CONF_DIR/installed_apps) || \
				(printf "%10s%s\n" "" "ERROR : Could not remove $PH_APP from installed applications configuration file" ; \
				 printf "%2s%s\n\n" "" "FAILED" ; return 1) || exit $?
		fi
		if nawk -v user=^"$PH_APP_USER"$ '$2 ~ user { exit 1 } { next }' $PH_CONF_DIR/installed_apps >/dev/null 2>&1
		then
			if [[ "$PH_RUN_USER" != "$PH_APP_USER" ]]
			then
				ph_revoke_pieh_access "$PH_APP_USER"
			fi
		fi
		printf "%8s%s\n" "" "--> Removing $PH_APP menu item"
		rm $PH_FILES_DIR/menus/$PH_APP.lst 2>/dev/null
		printf "%10s%s\n" "" "OK"
		printf "%8s%s\n" "" "--> Removing $PH_APP scripts"
		rm $PH_SCRIPTS_DIR/start"$PH_APPL".sh 2>/dev/null
		rm $PH_SCRIPTS_DIR/stop"$PH_APPL".sh 2>/dev/null
		rm $PH_SCRIPTS_DIR/restart"$PH_APPL".sh 2>/dev/null
		for PH_APP2 in `nawk 'BEGIN { ORS = " " } { print $1 }' $PH_CONF_DIR/supported_apps`
		do
			PH_APPL2=`echo $PH_APP2 | cut -c1-4`
			rm $PH_SCRIPTS_DIR/"$PH_APPL"to"$PH_APPL2".sh 2>/dev/null
			rm $PH_SCRIPTS_DIR/"$PH_APPL2"to"$PH_APPL".sh 2>/dev/null
		done
		printf "%10s%s\n" "" "OK"
		printf "%8s%s\n" "" "--> Removing default mountpoint for $PH_APP CIFS mounts"
		rm -r "$PH_CONF_DIR"/../mnt/"$PH_APP" >/dev/null 2>&1
		printf "%10s%s\n" "" "OK"
		if [[ -n "$PH_APP_PKG" ]]
		then
			printf "%8s%s\n" "" "--> Removing package \"$PH_APP_PKG\""
			ph_remove_pkg "$PH_APP_PKG" && printf "%10s%s\n" "" "OK" || printf "%10s%s\n" "" "ERROR : Could not remove package"
		fi
		printf "%8s%s\n" "" "--> Removing $PH_APP options from options.defaults"
		for PH_j in `grep ^"PH_" $PH_CONF_DIR/$PH_APP.conf | nawk -F'=' '{ print $1 }' | paste -d" " -s`
		do
			sed "/^$PH_j=/d" $PH_FILES_DIR/options.defaults >/tmp/options_defaults_tmp
			[[ $? -eq 0 ]] && mv /tmp/options_defaults_tmp $PH_FILES_DIR/options.defaults
		done
		printf "%10s%s\n" "" "OK"
		printf "%8s%s\n" "" "--> Removing $PH_APP options from options.allowed"
		for PH_j in PH_`echo $PH_APPU`_CIFS_SHARE PH_`echo $PH_APPU`_CIFS_SRV PH_`echo $PH_APPU`_PERSISTENT PH_`echo $PH_APPU`_CIFS_DIR PH_`echo $PH_APPU`_CIFS_SUBDIR PH_`echo $PH_APPU`_CIFS_MPT PH_`echo $PH_APPU`_USE_CTRL PH_`echo $PH_APPU`_NUM_CTRL PH_`echo $PH_APPU`_PRE_CMD PH_`echo $PH_APPU`_POST_CMD
		do
			nawk -F':' -v app=^"$PH_j"$ '$1 ~ app { next } { print }' $PH_FILES_DIR/options.allowed >/tmp/options_allowed_tmp
			[[ $? -eq 0 ]] && mv /tmp/options_allowed_tmp $PH_FILES_DIR/options.allowed
		done
		printf "%10s%s\n" "" "OK"
		printf "%8s%s\n" "" "--> Removing $PH_APP config file"
		rm $PH_CONF_DIR/$PH_APP.conf 2>/dev/null
		printf "%10s%s\n" "" "OK"
		printf "%8s%s\n" "" "--> Removing $PH_APP user functions"
		nawk -v app="_$PH_APPL"$ 'BEGIN { FLAG=0 } $1 ~ /^function$/ && $2 ~ app { FLAG=1 ; while ($1!~/^}$/) { getline } ; getline ; FLAG=0 ; next } \
										{ if (FLAG==0) { print $0 }}' $PH_MAIN_DIR/functions.user >/tmp/functions.user_tmp 2>&1
		[[ $? -eq 0 ]] && mv /tmp/functions.user_tmp $PH_MAIN_DIR/functions.user 2>&1
		printf "%10s%s\n" "" "OK"
		printf "%2s%s\n\n" "" "SUCCESS"
		exit 0 ;;
		 prompt)
		printf "%s\n" "- Using interactive mode"
		while [[ -z "$PH_APP" ]]
		do
			[[ $PH_COUNT -gt 0 ]] && printf "\n%10s%s\n\n" "" "ERROR : Invalid reponse"
			printf "%8s%s" "" "--> Please enter an application name : "
			read PH_APP 2>/dev/null
			ph_screen_input "$PH_APP" || exit $?
			((PH_COUNT++))
			PH_APPL=`echo $PH_APP | cut -c1-4`
		done
		PH_COUNT=0
		printf "%10s%s\n" "" "OK"
		case $PH_I_ACTION in inst)
			while [[ -z "$PH_APP_CMD" ]]
			do
				[[ $PH_COUNT -gt 0 ]] && printf "\n%10s%s\n\n" "" "ERROR : Invalid reponse"
				printf "%8s%s\n" "" "--> Please enter the full start command for $PH_APP"
				printf "%12s%s" "" "Any TTY number references should be replaced by the string 'PH_TTY' : "
				read PH_APP_CMD 2>/dev/null
				((PH_COUNT++))
			done
			printf "%10s%s\n" "" "OK"
			PH_COUNT=0
			printf "%8s%s\n\n" "" "--> Please enter the run account for $PH_APP (Optional)"
			printf "%12s%s\n" "" "- Leaving this empty will set the run account to the same as PieHelper's (\"$PH_RUN_USER\")"
                	printf "%12s%s" "" "- Specifying a non-existent account will create that account and a matching group : "
			read PH_APP_USER
			ph_screen_input "$PH_APP_USER" || exit $?
			[[ -z "$PH_APP_USER" ]] && PH_APP_USER="$PH_RUN_USER"
			printf "%10s%s\n" "" "OK ($PH_APP_USER)"
			while [[ -z "$PH_APP_PKG" ]]
			do
				[[ $PH_COUNT -gt 0 ]] && printf "\n%10s%s\n\n" "" "ERROR : Invalid reponse"
				printf "%8s%s" "" "--> Please enter the package name for application $PH_APP : "
				read PH_APP_PKG 2>/dev/null
				((PH_COUNT++))
			done
			printf "%10s%s\n" "" "OK"
			printf "%2s%s\n" "" "SUCCESS"
			confsupp_ph.sh -p inst -a "$PH_APP" -c "$PH_APP_CMD" -u "$PH_APP_USER" -b "$PH_APP_PKG" | more
			exit $? ;;
				   rem)
			printf "%8s%s\n" "" "--> Please enter the package for $PH_APP (Optional)"
			printf "%12s%s" "" "Leaving this empty will leave the package installed : "
			read PH_APP_PKG
			printf "%10s%s\n" "" "OK"
			printf "%2s%s\n" "" "SUCCESS"
			if [[ -z "$PH_APP_PKG" ]]
			then
				confsupp_ph.sh -p rem -a "$PH_APP" | more
			else
				confsupp_ph.sh -p rem -a "$PH_APP" -b "$PH_APP_PKG" | more
			fi
			exit $? ;;
		esac ;;
esac
confsupp_ph.sh -h || exit $?
