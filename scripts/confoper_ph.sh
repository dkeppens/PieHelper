#!/bin/bash
# Perform initial Raspberry Pi configuration (by Davy Keppens on 17/01/2019)
# Enable/Disable debug by running confpieh_ph.sh -p debug -m confoper_ph.sh

#set -x

typeset PH_i=""
typeset PH_DEF_USER=""
typeset PH_OPTION=""
typeset PH_STRING=""
typeset PH_ANSWER=""
typeset PH_HOME=""
typeset PH_ACTION=""
typeset PH_FUNCTIONS=""
typeset PH_MESSAGE="Invalid response"
typeset PH_LOCALE_ENCODING=""
typeset PH_LOCALE_NAME=""
typeset PH_CUR_DIR="$( cd "$( dirname "$0" )" && pwd )"
typeset PH_OLDOPTARG="$OPTARG"
typeset -i PH_RET_CODE=0
typeset -i PH_COUNT=0
typeset -i PH_COUNT2=0
typeset -i PH_FLAG=0
typeset -i PH_INTERACTIVE=0
typeset -i PH_OLDOPTIND=$OPTIND
PH_USER=""
PH_DEL_PIUSER="yes"
PH_HOST=""
PH_AUDIO=""
PH_BOOTENV=""
PH_LOCALE=""
PH_TZONE=""
PH_NETWAIT=""
PH_KEYB=""
PH_SSH_STATE=""
PH_VID_MEM=""
PH_RIGHTSCAN=""
PH_LEFTSCAN=""
PH_BOTTOMSCAN=""
PH_UPPERSCAN=""
PH_RESULT="SUCCESS"
PATH=$PH_CUR_DIR:$PATH
OPTIND=1

export PATH PH_USER PH_DEL_PIUSER PH_HOST PH_AUDIO PH_BOOTENV PH_LOCALE PH_TZONE PH_KEYB PH_SSH_STATE PH_VID_MEM PH_RIGHTSCAN PH_LEFTSCAN PH_BOTTOMSCAN PH_UPPERSCAN PH_RESULT PH_COUNT PH_NETWAIT

function ph_getdef {

typeset PH_PARAM="$1"
typeset PH_VALUE=""

printf "%8s%s\n" "" "--> Getting default value for parameter $PH_PARAM"
if grep ^"$PH_PARAM=" "$PH_CUR_DIR/../files/OS.defaults" >/dev/null
then
	PH_VALUE="`nawk -F\' -v param=^\"$PH_PARAM=\"$ '$1 ~ param { print $2 ; exit 0 } { next }' $PH_CUR_DIR/../files/OS.defaults`"
	printf "%10s%s\n" "" "OK ($PH_VALUE)"
else
	printf "%10s%s\n" "" "ERROR : Could not retrieve $PH_PARAM default"
	return 1
fi
eval export "$PH_PARAM"="$PH_VALUE"
return 0
}

function ph_savedef {

typeset PH_PARAM="$1"
typeset PH_VALUE="$2"

PH_COUNT=$((PH_COUNT+1))
printf "%8s%s\n" "" "--> Storing default for parameter $PH_PARAM -> Running precheck"
printf "%10s%s\n" "" "OK"
printf "%8s%s\n" "" "--> Prechecking for existing default"
if grep ^"$PH_PARAM=" "$PH_CUR_DIR/../files/OS.defaults" >/dev/null
then
	if [[ `nawk -F\' -v opt=^"$PH_PARAM="$ '$1 ~ opt { print $2 }' $PH_CUR_DIR/../files/OS.defaults` == "$PH_VALUE" ]]
	then
		printf "%10s%s\n" "" "OK (Nothing to do)"
		return 0
	fi
	printf "%10s%s\n" "" "OK (Found) -> Removing"
	printf "%8s%s\n" "" "--> Removing existing stored default of parameter $PH_PARAM"
	sed "/^$PH_PARAM=/d" "$PH_CUR_DIR/../files/OS.defaults" >/tmp/OS.defaults_tmp 2>&1
	[[ $? -eq 0 ]] && (printf "%10s%s\n" "" "OK" ; mv /tmp/OS.defaults_tmp "$PH_CUR_DIR/../files/OS.defaults" ; return 0) || \
				(printf "%10s%s\n" "" "ERROR : Could not remove existing default" ; return 1) || return $?
else
	printf "%10s%s\n" "" "OK (Not Found)"
fi
printf "%8s%s\n" "" "--> Storing \"$PH_VALUE\" as default value of parameter $PH_PARAM"
echo "$PH_PARAM='$PH_VALUE'" >>"$PH_CUR_DIR/../files/OS.defaults"
printf "%10s%s\n" "" "OK"
return 0
}

function ph_check_keyb_layout_validity {

if ! localectl list-x11-keymap-layouts | grep ^"$1"$ >/dev/null
then
	return 1
fi
return 0
}

function ph_check_locale_validity {

if ! cat /usr/share/i18n/SUPPORTED | grep ^"$1 " >/dev/null
then
	return 1
fi
return 0
}

function ph_check_tzone_validity {

if ! timedatectl list-timezones | grep ^"$1"$ >/dev/null
then
	return 1
fi
return 0
}

function ph_check_user_validity {

if ! id "$1" >/dev/null 2>&1
then
	return 1
fi
return 0
}

function ph_set_result {

typeset -i PH_RET_CODE=$1

case $PH_RET_CODE in 0)
		[[ "$PH_RESULT" == "FAILED" ]] && PH_RESULT="PARTIALLY FAILED" ;;
		     1)
		if [[ "$2" == "first" ]]
		then
			if [[ "$3" == "last" ]]
			then
				[[ "$PH_RESULT" == "SUCCESS" ]] && PH_RESULT="FAILED"
			else
				[[ "$PH_RESULT" == "SUCCESS" ]] && PH_RESULT="PARTIALLY FAILED"
			fi
		else
			if [[ "$3" != "last" ]]
			then
				[[ "$PH_RESULT" == "SUCCESS" ]] && PH_RESULT="PARTIALLY FAILED"
			fi
		fi
esac
return 0
}

function ph_screen_input {

if [[ `echo "$*" | sed 's/[ ,/.]//g'` == *+([![:word:]])* ]] 2>/dev/null
then
        printf "%2s%s\n\n" "" "ABORT : Invalid input characters detected"
        return 1
fi
return 0
}

if [[ -f /usr/bin/pacman ]]
then
	. $PH_CUR_DIR/../conf/distros/Archlinux.conf
	typeset PH_KEYB_PKG="systemd"
	PH_DEF_USER="alarm"
	pacman-key --init >/dev/null 2>&1
	pacman-key --populate archlinuxarm >/dev/null 2>&1
else
	. $PH_CUR_DIR/../conf/distros/Debian.conf
	typeset PH_KEYB_PKG="keyboard-configuration systemd"
	PH_DEF_USER="pi"
fi

while getopts p:s:a:n:e:t:c:f:z:u:l:b:r:k:m:w:hdi PH_OPTION 2>/dev/null
do
	case $PH_OPTION in p)
		[[ -n "$PH_ACTION" ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ "$OPTARG" != @(all|ssh|sshkey|user|locale|keyb|tzone|host|netwait|filesys|audio|overscan|memsplit|update|bootenv|boot|savedef|dispdef|all-usedef) ]] && \
			(! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_ACTION="$OPTARG" ;;
			   d)
		PH_DEL_PIUSER="no" ;;
			   m)
		[[ -n "$PH_VID_MEM" ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ "$OPTARG" != @(512|256|128|64|32|16|def) ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_VID_MEM="$OPTARG" ;;
			   r)
		[[ -n "$PH_RIGHTSCAN" ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ "$OPTARG" != +([[:digit:]]) && "$OPTARG" != "def" ]] && printf "%s\n" "- Executing overscan function" && printf "%2s%s\n" "" "FAILED : Non-numeric value given for right overscan" && exit 1
		PH_RIGHTSCAN="$OPTARG" ;;
			   l)
		[[ -n "$PH_LEFTSCAN" ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ "$OPTARG" != +([[:digit:]]) && "$OPTARG" != "def" ]] && printf "%s\n" "- Executing overscan function" && printf "%2s%s\n" "" "FAILED : Non-numeric value given for left overscan" && exit 1
		PH_LEFTSCAN="$OPTARG" ;;
			   b)
		[[ -n "$PH_BOTTOMSCAN" ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ "$OPTARG" != +([[:digit:]]) && "$OPTARG" != "def" ]] && printf "%s\n" "- Executing overscan function" && printf "%2s%s\n" "" "FAILED : Non-numeric value given for bottom overscan" && exit 1
		PH_BOTTOMSCAN="$OPTARG" ;;
			   u)
		[[ -n "$PH_UPPERSCAN" ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ "$OPTARG" != +([[:digit:]]) && "$OPTARG" != "def" ]] && printf "%s\n" "- Executing overscan function" && printf "%2s%s\n" "" "FAILED : Non-numeric value given for upper overscan" && exit 1
		PH_UPPERSCAN="$OPTARG" ;;
			   z)
		[[ -n "$PH_TZONE" ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_TZONE="$OPTARG" ;;
			   f)
		[[ -n "$PH_LOCALE" ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_LOCALE="$OPTARG" ;;
			   i)
		[[ $PH_INTERACTIVE -eq 1 ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_INTERACTIVE=1 ;;
			   k)
		[[ -n "$PH_KEYB" ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_KEYB="$OPTARG" ;;
			   w)
		[[ -n "$PH_NETWAIT" ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ "$OPTARG" != @(enabled|disabled|def) ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_NETWAIT="$OPTARG" ;;
			   c)
		[[ -n "$PH_AUDIO" ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		! ph_screen_input "$OPTARG" && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ "$OPTARG" != @(hdmi|jack|auto|def) ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_AUDIO="$OPTARG" ;;
			   e)
		[[ -n "$PH_BOOTENV" ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		! ph_screen_input "$OPTARG" && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ "$OPTARG" != @(cli|gui|def) ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_BOOTENV="$OPTARG" ;;
			   n)
		[[ -n "$PH_HOST" ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		! ph_screen_input "$OPTARG" && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_HOST="$OPTARG" ;;
			   s)
		[[ -n "$PH_SSH_STATE" ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		! ph_screen_input "$OPTARG" && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ "$OPTARG" != @(allowed|disallowed|def) ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_SSH_STATE="$OPTARG" ;;
			   a)
		[[ -n "$PH_USER" ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		! ph_screen_input "$OPTARG" && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_USER="$OPTARG" ;;
			   *)
		>&2 printf "%s\n" "Usage : confoper_ph.sh -h |"
		>&2 printf "%23s%s\n" "" "-p \"all\" [[[-a [alluser] '-d']|-a \"def\"] -s [\"allowed\"|\"disallowed\"|\"def\"] -n [hostname|\"def\"] -e [\"cli\"|\"gui\"|\"def\"] -w [\"enabled\"|\"disabled\"|\"def\"] \\"
		>&2 printf "%23s%s\n" "" "           -c [\"hdmi\"|\"jack\"|\"def\"] -f [newloc|\"def\"] -z [tzone|\"def\"] '-l [lowerscan|\"def\"]' '-r [rightscan|\"def\"]' '-b [bottomscan|\"def\"]' \\"
		>&2 printf "%23s%s\n" "" "           '-u [upperscan|\"def\"]' -k [keyb|\"def\"] -m [16|32|64|128|256|512|\"def\"]|-i] |"
		>&2 printf "%23s%s\n" "" "-p \"all-usedef\" |"
		>&2 printf "%23s%s\n" "" "-p \"savedef\" [[-a [alluser] '-d'] -s [\"allowed\"|\"disallowed\"] -n [hostname] -e [\"cli\"|\"gui\"] -c [\"hdmi\"|\"jack\"] -w [\"enabled\"|\"disabled\"] \\"
		>&2 printf "%23s%s\n" "" "           -f [newloc] -z [tzone] '-l [lowerscan]' '-r [rightscan]' '-b [bottomscan]' '-u [upperscan]' -k [keyb] -m [16|32|64|128|256|512]| \\"
		>&2 printf "%23s%s\n" "" "           -i '[\"user\"|\"del_stduser\"|\"ssh\"|\"host\"|\"bootenv\"|\"audio\"|\"locale\"|\"tzone\"|\"overscan\"|\"keyb\"|\"memsplit\"|\"netwait\"]'] |"
		>&2 printf "%23s%s\n" "" "-p \"dispdef\" |"
                >&2 printf "%23s%s\n" "" "-p \"ssh\" [-s [\"allowed\"|\"disallowed\"|\"def\"]|-i] |"
                >&2 printf "%23s%s\n" "" "-p \"sshkey\" [-a [[sshuser]|\"def\"]|-i] |"
                >&2 printf "%23s%s\n" "" "-p \"user\" [[[-a [newuser] '-d']|-a \"def\"]|-i] |"
                >&2 printf "%23s%s\n" "" "-p \"host\" [-n [hostname|\"def\"]-i] |"
                >&2 printf "%23s%s\n" "" "-p \"bootenv\" [-e [\"cli\"|\"gui\"|\"def\"]|-i] |"
                >&2 printf "%23s%s\n" "" "-p \"locale\" [-f [newloc|\"def\"]|-i] |"
                >&2 printf "%23s%s\n" "" "-p \"netwait\" [-w [\"enabled\"|\"disabled\"|\"def\"]|-i] |"
                >&2 printf "%23s%s\n" "" "-p \"tzone\" [-z [tzone|\"def\"]|-i] |"
                >&2 printf "%23s%s\n" "" "-p \"memsplit\" [-m [16|32|64|128|256|512|\"def\"]|-i] |"
                >&2 printf "%23s%s\n" "" "-p \"keyb\" [-k [keyb|\"def\"]|-i] |"
                >&2 printf "%23s%s\n" "" "-p \"audio\" [-c [\"hdmi\"|\"jack\"|\"def\"]|-i] |"
                >&2 printf "%23s%s\n" "" "-p \"overscan\" ['-l [lowerscan|\"def\"]' '-r [rightscan|\"def\"]' '-b [bottomscan|\"def\"]' '-u [upperscan|\"def\"]'|-i] |"
                >&2 printf "%23s%s\n" "" "-p \"filesys\" |"
                >&2 printf "%23s%s\n" "" "-p \"update\" |"
                >&2 printf "%23s%s\n" "" "-p \"boot\""
		>&2 printf "\n"
		>&2 printf "%3s%s\n" "" "Where -h displays this usage"
                >&2 printf "%9s%s\n" "" "-p specifies the action to take"
                >&2 printf "%12s%s\n" "" "\"all\" allows executing all other functions besides \"all\" in a logical order, using all further parameters provided where needed"
		>&2 printf "%15s%s\n" "" "- The order in which all functions will be executed is the following : \"user\", \"sshkey\", \"locale\", \"keyb\", \"tzone\""
		>&2 printf "%15s%s\n" "" "  \"host\", \"filesys\", \"audio\", \"overscan\", \"memsplit\", \"ssh\", \"update\", \"netwait\", \"bootenv\" and \"boot\""
		>&2 printf "%15s%s\n" "" "- Special remarks for function \"all\" :"
		>&2 printf "%18s%s\n" "" "- Any function that fails will generate an error but further function execution will not be interrupted"
		>&2 printf "%18s%s\n" "" "- Any functions requiring a user account parameter will use [alluser] as the value for that parameter"
		>&2 printf "%18s%s\n" "" "- A reboot will only be performed once after all functions have concluded instead of at the end of every function requiring a reboot"
		>&2 printf "%15s%s\n" "" "-i allows specifying using interactive mode"
		>&2 printf "%18s%s\n" "" "- The following info will be prompted for during interactive mode :"
		>&2 printf "%21s%s\n" "" "- The value to use for \"create new user\", \"delete standard user '$PH_DEF_USER'\", \"create ssh key for user\", \"system locale\", \"keyboard layout\", \"system timezone\""
		>&2 printf "%21s%s\n" "" "  \"system hostname\", \"audio channel\", \"top, bottom, left and right overscan\", \"memory reserved for the GPU\", \"SSH state\", \"wait for network on boot\" and \"default boot environment\""
                >&2 printf "%12s%s\n" "" "\"all-usedef\" functions like \"all\" but will use the default value stored for each required parameter"
                >&2 printf "%15s%s\n" "" "- If no stored default can be found for one or more of the required parameters, the related function will fail but processing of the remaining function(s) will not be interrupted"
                >&2 printf "%12s%s\n" "" "\"savedef\" allows storing the value specified for each additional parameter given as the default value for that parameter"
		>&2 printf "%15s%s\n" "" "- For the default of any of the 4 optional overscan parameters :"
		>&2 printf "%18s%s\n" "" "- If a new value is given and differs from the pre-existing value or there is no pre-existing value, the new value will be stored"
		>&2 printf "%18s%s\n" "" "- If a new value is given and is equal to a pre-existing value, no operation is performed"
		>&2 printf "%18s%s\n" "" "- If a new value is not given and there is no pre-existing value or a pre-existing value not equal to '16', a new value of '16' will be stored for left and right overscan"
		>&2 printf "%18s%s\n" "" "- If a new value is not given and there is no pre-existing value or a pre-existing value not equal to '30', a new value of '30' will be stored for top and bottom overscan"
		>&2 printf "%18s%s\n" "" "- If a new value is not given and there is a pre-existing value equal to '16', no operation is performed for left and right overscan"
		>&2 printf "%18s%s\n" "" "- If a new value is not given and there is a pre-existing value equal to '30', no operation is performed for top and bottom overscan"
		>&2 printf "%15s%s\n" "" "- For the default of the optional '-d' parameter, the value will always be stored if there is no currently stored value for it or"
		>&2 printf "%15s%s\n" "" "  if the currently stored default value for it differs from 'yes'"
		>&2 printf "%15s%s\n" "" "- For any other parameters, a pre-existing default value that differs from the new value specified will be replaced with the new value and"
		>&2 printf "%15s%s\n" "" "  no operation will be performed for a pre-existing default value equal to the new value"
		>&2 printf "%15s%s\n" "" "-i allows specifying using interactive mode"
		>&2 printf "%18s%s\n" "" "-i can be followed by one of a list of allowed parameters"
		>&2 printf "%18s%s\n" "" "- If one of a list of allowed parameters is given, the related info will be prompted for"
		>&2 printf "%18s%s\n" "" "- The following info will be prompted for during interactive mode if none of a list of allowed parameters is given :"
		>&2 printf "%21s%s\n" "" "- The default value to store for \"create new user\", \"delete standard user '$PH_DEF_USER'\", \"create ssh key for user\", \"system locale\", \"keyboard layout\", \"system timezone\""
		>&2 printf "%21s%s\n" "" "  \"system hostname\", \"audio channel\", \"top, bottom, left and right overscan\", \"memory reserved for the GPU\", \"SSH state\", \"wait for network on boot\" and \"default boot environment\""
                >&2 printf "%12s%s\n" "" "\"dispdef\" allows displaying all currently stored default values"
                >&2 printf "%12s%s\n" "" "\"ssh\" allows choosing whether to allow or disallow SSH logins to this system for all users besides \"root\""
		>&2 printf "%15s%s\n" "" "-s allows selecting either \"allowed\", \"disallowed\" or \"def\""
		>&2 printf "%18s%s\n" "" "- Selecting \"def\" will use the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%15s%s\n" "" "- Using this function will restart the SSH server"
		>&2 printf "%15s%s\n" "" "-i allows specifying using interactive mode"
                >&2 printf "%12s%s\n" "" "\"sshkey\" allows creating a public/private RSA2 keypair for SSH logins for user [sshuser]"
		>&2 printf "%15s%s\n" "" "- The public key will be placed in '/home/[sshuser]/.ssh/id_rsa.pub' and automatically be trusted for SSH connections"
		>&2 printf "%15s%s\n" "" "- The private key will be placed in '/home/[sshuser]/.ssh/id_rsa' and can be used when initiating passwordless SSH connections to this machine"
		>&2 printf "%18s%s\n" "" "- To connect passwordless from a windows machine using Putty, the private key needs to be converted to Putty format using puttygen.exe on"
		>&2 printf "%18s%s\n" "" "  a windows machine and the save location of the converted key should be configured in the Putty.exe session manager"
		>&2 printf "%15s%s\n" "" "-a allows setting a value for [sshuser]"
		>&2 printf "%18s%s\n" "" "- The keyword \"def\" can be used to specify using the stored default value for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%18s%s\n" "" "- The value specified for [sshuser] should already be an existing user account"
		>&2 printf "%15s%s\n" "" "-i allows specifying using interactive mode"
                >&2 printf "%12s%s\n" "" "\"user\" allows creating a user account [newuser] and grant that user full sudo rights"
		>&2 printf "%15s%s\n" "" "-a allows setting a value for [newuser]"
		>&2 printf "%18s%s\n" "" "- [newuser] can be an already existing account as long as that user is not currently logged in"
		>&2 printf "%18s%s\n" "" "- The following rules apply if [newuser] is an already existing account :"
		>&2 printf "%21s%s\n" "" "- If user [newuser] is currently logged in, this function will fail"
		>&2 printf "%21s%s\n" "" "- All properties for user [newuser] will be set to the same values that would have been used if [newuser] had been a non-existing acccount"
		>&2 printf "%24s%s\n" "" "- If group [newuser] does not exist, it will be created"
		>&2 printf "%21s%s\n" "" "- The password for user [newuser] will not be changed"
		>&2 printf "%18s%s\n" "" "- The following rules apply if [newuser] is a non-existing account :"
		>&2 printf "%21s%s\n" "" "- The primary group for account [newuser] will be set to it's new according private group named [newuser]"
		>&2 printf "%24s%s\n" "" "- The new group [newuser] will automatically be created"
		>&2 printf "%21s%s\n" "" "- The secondary groups for account [newuser] will be set to \"tty\",\"input\",\"audio\" and \"video\""
		>&2 printf "%21s%s\n" "" "- The value for [newuser]'s password will be prompted for"
		>&2 printf "%21s%s\n" "" "- The home directory for [newuser] will be created as '/home/[newuser]'"
		>&2 printf "%21s%s\n" "" "- The shell for [newuser] will be set to '/bin/bash'"
		>&2 printf "%18s%s\n" "" "- The keyword \"def\" can be used to specify using the stored default value for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%21s%s\n" "" "- The stored default for the '-d' parameter will automatically be used as well"
		>&2 printf "%18s%s\n" "" "-d allows specifying the system default user account \"$PH_DEF_USER\" should not be removed (the default action) along with"
		>&2 printf "%18s%s\n" "" "  it's home directory, mail spool directory and sudo configuration"
		>&2 printf "%21s%s\n" "" "- Specifying -d is optional"
		>&2 printf "%21s%s\n" "" "- Specifying -d when using the keyword \"def\" for [newuser] is not allowed"
		>&2 printf "%21s%s\n" "" "- If -d is not used and user '$PH_DEF_USER' is currently logged on, removal will be delayed until the next system reboot which will be proposed"
		>&2 printf "%15s%s\n" "" "-i allows specifying using interactive mode"
		>&2 printf "%18s%s\n" "" "- The following info will be prompted for during interactive mode :"
		>&2 printf "%21s%s\n" "" "- The value to use for operation \"create new user\" and operation \"delete standard user '$PH_DEF_USER'\""
                >&2 printf "%12s%s\n" "" "\"netwait\" allows specifying whether the system should wait for networking to become available before continuing the application part of the boot process"
		>&2 printf "%15s%s\n" "" "-w allows selecting either \"enabled\" or \"disabled\""
		>&2 printf "%18s%s\n" "" "- The keyword \"def\" can be used to specify using the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%15s%s\n" "" "-i allows specifying using interactive mode"
                >&2 printf "%12s%s\n" "" "\"host\" allows changing the hostname for this machine to [hostname]"
		>&2 printf "%15s%s\n" "" "-n allows setting a value for [hostname]"
		>&2 printf "%18s%s\n" "" "- The keyword \"def\" can be used to specify using the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%15s%s\n" "" "-i allows specifying using interactive mode"
                >&2 printf "%12s%s\n" "" "\"bootenv\" allows selecting a preferred default environment to boot into on system restarts"
		>&2 printf "%15s%s\n" "" "-e allows selecting either \"cli\", \"gui\" or \"def\""
		>&2 printf "%18s%s\n" "" "- Selecting \"def\" will use the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%15s%s\n" "" "-i allows specifying using interactive mode"
                >&2 printf "%12s%s\n" "" "\"keyb\" allows setting the default keyboard layout to [keyb]"
		>&2 printf "%15s%s\n" "" "-k allows setting a value for [keyb]"
		>&2 printf "%18s%s\n" "" "- The keyword \"def\" can be used to specify using the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%18s%s\n" "" "- The value specified for [keyb] should be a valid keyboard layout"
		>&2 printf "%18s%s\n" "" "- If the new value specified for is different from the one currently configured on Archlinux machines, a reboot is required which will be proposed"
		>&2 printf "%15s%s\n" "" "-i allows specifying using interactive mode"
                >&2 printf "%12s%s\n" "" "\"memsplit\" allows setting the amount of memory to reserve exclusively for the GPU"
		>&2 printf "%15s%s\n" "" "-m allows selecting either \"16\", \"32\", \"64\", \"128\", \"256\" or \"def\""
		>&2 printf "%18s%s\n" "" "- Selecting \"def\" will use the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%18s%s\n" "" "- If the new value is different from the one currently set, activation of the new value requires a system reboot that will be proposed"
		>&2 printf "%15s%s\n" "" "-i allows specifying using interactive mode"
                >&2 printf "%12s%s\n" "" "\"tzone\" allows setting the default system timezone to [tzone]"
		>&2 printf "%15s%s\n" "" "-z allows setting a value for [tzone]"
		>&2 printf "%18s%s\n" "" "- The keyword \"def\" can be used to specify using the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%18s%s\n" "" "- The value specified for [tzone] should be a valid timezone identifier"
		>&2 printf "%15s%s\n" "" "-i allows specifying using interactive mode"
                >&2 printf "%12s%s\n" "" "\"locale\" allows generating locale [newloc] and setting it as the system's default locale"
		>&2 printf "%15s%s\n" "" "-f allows setting a value for [newloc]"
		>&2 printf "%18s%s\n" "" "- [newloc] should be specified in the format 'locale.encoding'"
		>&2 printf "%18s%s\n" "" "- The keyword \"def\" can be used to specify using the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%18s%s\n" "" "- The value specified for [newloc] should be a system supported locale"
		>&2 printf "%15s%s\n" "" "-i allows specifying using interactive mode"
                >&2 printf "%12s%s\n" "" "\"audio\" allows forcing audio output to the specified channel"
		>&2 printf "%15s%s\n" "" "-c allows selecting either \"hdmi\", \"jack\" or \"def\""
		>&2 printf "%18s%s\n" "" "- \"jack\" stands for the standard 3.5 inch audio jack"
		>&2 printf "%18s%s\n" "" "- The keyword \"def\" can be used to specify using the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%18s%s\n" "" "- If the new value is different from the one currently set, activation of the new value requires a system reboot that will be proposed"
		>&2 printf "%15s%s\n" "" "-i allows specifying using interactive mode"
                >&2 printf "%12s%s\n" "" "\"overscan\" allows specifying values to use when correcting left overscan [leftscan], right overscan [rightscan], bottom overscan [bottomscan] and upper overscan [upperscan]"
		>&2 printf "%15s%s\n" "" "- Specifying a value for any of the overscan settings is optional"
		>&2 printf "%18s%s\n" "" "- Any overscan setting that is not specified will leave that setting's currently configured value unchanged"
		>&2 printf "%15s%s\n" "" "-u allows setting a value for [upperscan]"
		>&2 printf "%18s%s\n" "" "- The keyword \"def\" can be used to specify using the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%15s%s\n" "" "-b allows setting a value for [bottomscan]"
		>&2 printf "%18s%s\n" "" "- The keyword \"def\" can be used to specify using the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%15s%s\n" "" "-l allows setting a value for [leftscan]"
		>&2 printf "%18s%s\n" "" "- The keyword \"def\" can be used to specify using the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%15s%s\n" "" "-r allows setting a value for [rightscan]"
		>&2 printf "%18s%s\n" "" "- The keyword \"def\" can be used to specify using the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%15s%s\n" "" "- If the current value of any of the overscan settings is changed, the new value(s) will only be active after a system reboot that will be proposed"
		>&2 printf "%15s%s\n" "" "-i allows specifying using interactive mode"
		>&2 printf "%18s%s\n" "" "- The following info will be prompted for during interactive mode :"
		>&2 printf "%21s%s\n" "" "- The value to use for \"top, bottom, left and right overscan\""
                >&2 printf "%12s%s\n" "" "\"filesys\" allows growing the filesystem of your system to use all available harddisk space"
		>&2 printf "%15s%s\n" "" "- Running this function more than once will do nothing"
		>&2 printf "%15s%s\n" "" "- If the filesystem size was changed, the new size will only be available after a system reboot and a reboot will be proposed"
                >&2 printf "%12s%s\n" "" "\"update\" allows running a silent update of all packages currently installed on this system"
                >&2 printf "%12s%s\n" "" "\"boot\" allows rebooting this system"
		>&2 printf "\n"
		OPTIND=$PH_OLDOPTIND
		OPTARG="$PH_OLDOPTARG"
		unset PH_REVERSE
		exit 1 ;;
	esac
done
OPTIND=$PH_OLDOPTIND
OPTARG="$PH_OLDOPTARG"

[[ -z "$PH_ACTION" ]] && (! confoper_ph.sh -h) && exit 1
(([[ "$PH_ACTION" == "savedef" && $# -gt 4 ]]) && ([[ $PH_INTERACTIVE -eq 1 ]])) && (! confoper_ph.sh -h) && exit 1
(([[ "$PH_ACTION" == "savedef" && $PH_INTERACTIVE -eq 1 ]]) && ([[ -n "$4" && "$4" != @(ssh|bootenv|user|del_stduser|host|locale|tzone|overscan|audio|keyb|memsplit|netwait) ]])) && (! confoper_ph.sh -h) && exit 1
(([[ "$PH_ACTION" == "user" && "$PH_USER" == "def" ]]) && ([[ "$PH_DEL_PIUSER" == "no" ]])) && (! confoper_ph.sh -h) && exit 1
[[ "$PH_ACTION" == "all-usedef" && $# -gt 2 ]] && (! confoper_ph.sh -h) && exit 1
[[ "$PH_ACTION" != @(all|savedef|user) && "$PH_DEL_PIUSER" == "no" ]] && (! confoper_ph.sh -h) && exit 1
(([[ "$PH_ACTION" == @(all|user|sshkey) && -z "$PH_USER" ]]) && ([[ $PH_INTERACTIVE -eq 0 ]])) && (! confoper_ph.sh -h) && exit 1
(([[ "$PH_ACTION" == @(all|netwait) && -z "$PH_NETWAIT" ]]) && ([[ $PH_INTERACTIVE -eq 0 ]])) && (! confoper_ph.sh -h) && exit 1
(([[ "$PH_ACTION" == @(all|host) && -z "$PH_HOST" ]]) && ([[ $PH_INTERACTIVE -eq 0 ]])) && (! confoper_ph.sh -h) && exit 1
(([[ "$PH_ACTION" == @(all|memsplit) && -z "$PH_VID_MEM" ]]) && ([[ $PH_INTERACTIVE -eq 0 ]])) && (! confoper_ph.sh -h) && exit 1
(([[ "$PH_ACTION" == @(all|ssh) && -z "$PH_SSH_STATE" ]]) && ([[ $PH_INTERACTIVE -eq 0 ]])) && (! confoper_ph.sh -h) && exit 1
(([[ "$PH_ACTION" == @(all|bootenv) && -z "$PH_BOOTENV" ]]) && ([[ $PH_INTERACTIVE -eq 0 ]])) && (! confoper_ph.sh -h) && exit 1
(([[ "$PH_ACTION" == @(all|audio) && -z "$PH_AUDIO" ]]) && ([[ $PH_INTERACTIVE -eq 0 ]])) && (! confoper_ph.sh -h) && exit 1
(([[ "$PH_ACTION" == @(all|tzone) && -z "$PH_TZONE" ]]) && ([[ $PH_INTERACTIVE -eq 0 ]])) && (! confoper_ph.sh -h) && exit 1
[[ -n "$PH_TZONE" && "$PH_ACTION" != @(all|savedef|tzone) ]] && (! confoper_ph.sh -h) && exit 1
[[ -n "$PH_BOOTENV" && "$PH_ACTION" != @(all|savedef|bootenv) ]] && (! confoper_ph.sh -h) && exit 1
[[ -n "$PH_USER" && "$PH_ACTION" != @(all|savedef|user|sshkey) ]] && (! confoper_ph.sh -h) && exit 1
[[ -n "$PH_HOST" && "$PH_ACTION" != @(all|savedef|host) ]] && (! confoper_ph.sh -h) && exit 1
[[ -n "$PH_NETWAIT" && "$PH_ACTION" != @(all|savedef|netwait) ]] && (! confoper_ph.sh -h) && exit 1
[[ -n "$PH_LOCALE" && "$PH_ACTION" != @(all|savedef|locale) ]] && (! confoper_ph.sh -h) && exit 1
[[ -n "$PH_KEYB" && "$PH_ACTION" != @(all|savedef|keyb) ]] && (! confoper_ph.sh -h) && exit 1
[[ -n "$PH_AUDIO" && "$PH_ACTION" != @(all|savedef|audio) ]] && (! confoper_ph.sh -h) && exit 1
[[ -n "$PH_SSH_STATE" && "$PH_ACTION" != @(all|savedef|ssh) ]] && (! confoper_ph.sh -h) && exit 1
[[ -n "$PH_VID_MEM" && "$PH_ACTION" != @(all|savedef|memsplit) ]] && (! confoper_ph.sh -h) && exit 1
(([[ -n "$PH_RIGHTSCAN" || -n "$PH_LEFTSCAN" ]]) && ([[ "$PH_ACTION" != @(all|savedef|overscan) ]])) && (! confoper_ph.sh -h) && exit 1
(([[ -n "$PH_BOTTOMSCAN" || -n "$PH_UPPERSCAN" ]]) && ([[ "$PH_ACTION" != @(all|savedef|overscan) ]])) && (! confoper_ph.sh -h) && exit 1
[[ $PH_INTERACTIVE -eq 1 && "$PH_ACTION" == @(filesys|update|boot|dispdef|all-usedef) ]] && (! confoper_ph.sh -h) && exit 1
(([[ $PH_INTERACTIVE -eq 1 ]]) && ([[ -n "$PH_USER" || -n "$PH_TZONE" || -n "$PH_SSH_STATE" || -n "$PH_AUDIO" || -n "$PH_HOST" || -n "$PH_BOOTENV" || -n "$PH_LOCALE" || -n "$PH_KEYB" ]])) && (! confoper_ph.sh -h) && exit 1
(([[ $PH_INTERACTIVE -eq 1 ]]) && ([[ -n "$PH_VID_MEM" || -n "$PH_LEFTSCAN" || -n "$PH_BOTTOMSCAN" || -n "$PH_UPPERSCAN" || "$PH_DEL_PIUSER" == "no" || -n "$PH_NETWAIT" ]])) && (! confoper_ph.sh -h) && exit 1

if [[ "$PH_ACTION" != @(savedef|dispdef) && `cat /proc/$PPID/comm` != "confoper_ph.sh" ]]
then
	printf "%s\n" "- Checking prerequisites for system configuration"
	printf "%8s%s\n" "" "--> Checking run account"
	[[ `whoami` == "root" ]] && printf "%10s%s\n" "" "OK (root)" || (printf "%10s%s\n" "" "ERROR : confoper_ph.sh must be run as root" ; printf "%2s%s\n" "" "FAILED" ; exit 1) || exit $?
	printf "%2s%s\n" "" "SUCCESS"
	printf "%s\n" "- Checking prerequisites for PieHelper"
	printf "%8s%s\n" "" "--> Checking for presence of /proc filesystem"
	if mount | grep ^"proc on /proc type proc" >/dev/null
	then
        	printf "%10s%s\n" "" "OK (Found)"
	else
		printf "%10s%s\n" "" "ERROR : Not found"
		printf "%2s%s\n" "" "FAILED"
		exit 1
	fi
	for PH_i in sudo ksh "$PH_KEYB_PKG" alsa-utils tzdata
	do
		printf "%8s%s\n" "" "--> Checking for package $PH_i"
		if ph_get_pkg_inststate "$PH_i"
		then
			printf "%10s%s\n" "" "OK (Found)"
		else
			printf "%10s%s\n" "" "Warning : Not found -> Installing"
			printf "%8s%s\n" "" "--> Installing $PH_i"
			if ph_install_pkg "$PH_i"
			then
				printf "%10s%s\n" "" "OK"
			else
				printf "%10s%s\n" "" "ERROR : Could not install $PH_i"
				printf "%2s%s\n" "" "FAILED"
				exit 1
			fi
		fi
	done
	printf "%8s%s\n" "" "--> Checking for systemd service management"
	[[ -f `which systemctl 2>/dev/null` ]] && printf "%10s%s\n" "" "OK (Found)" || (printf "%10s%s\n" "" "ERROR : Not found" ; printf "%2s%s\n" "" "FAILED" ; exit 1) || exit $?
	printf "%8s%s\n" "" "--> Checking for package manager"
	if [[ -f /usr/bin/pacman || -f /usr/bin/apt-get ]]
	then
		[[ -f /usr/bin/apt-get ]] && printf "%10s%s\n" "" "OK (apt-get)" || printf "%10s%s\n" "" "OK (pacman)"
	else
		printf "%10s%s\n" "" "ERROR : Not found"
		printf "%2s%s\n" "" "FAILED"
		exit 1
	fi
	printf "%2s%s\n" "" "SUCCESS"
fi
if [[ "$PH_ACTION" == "locale" && "$PH_LOCALE" != "def" ]]
then
	if [[ $PH_INTERACTIVE -eq 0 ]]
	then
		if ! ph_check_locale_validity "$PH_LOCALE"
		then
			printf "%s\n" "- Executing function $PH_ACTION"
			printf "%2s%s\n" "" "FAILED : Not a system supported locale"
			exit 1
		fi
	fi
fi
if [[ "$PH_ACTION" == "tzone" && "$PH_TZONE" != "def" ]]
then
	if [[ $PH_INTERACTIVE -eq 0 ]]
	then
		if ! ph_check_tzone_validity "$PH_TZONE"
		then
			printf "%s\n" "- Executing function $PH_ACTION"
			printf "%2s%s\n" "" "FAILED : Invalid timezone identifier specified"
			exit 1
		fi
	fi
fi
if [[ "$PH_ACTION" == "keyb" && "$PH_KEYB" != "def" ]]
then
	if [[ $PH_INTERACTIVE -eq 0 ]]
	then
		if ! ph_check_keyb_layout_validity "$PH_KEYB"
		then
			printf "%s\n" "- Executing function $PH_ACTION"
			printf "%2s%s\n" "" "FAILED : Invalid keyboard layout specified"
			exit 1
		fi
	fi
fi
if [[ "$PH_ACTION" == "sshkey" && "$PH_USER" != "def" ]]
then
	if [[ $PH_INTERACTIVE -eq 0 ]]
	then
		if ! ph_check_user_validity "$PH_USER"
		then
			printf "%s\n" "- Executing function $PH_ACTION for user $PH_USER"
			printf "%2s%s\n" "" "FAILED : User does not exist"
			exit 1
		fi
	fi
fi
if [[ "$PH_ACTION" == "user" ]]
then
	if [[ $PH_INTERACTIVE -eq 0 ]]
	then
		if who -us | nawk '{ print $1 }' | grep ^"$PH_USER"$ >/dev/null
		then
			printf "%s\n" "- Executing function $PH_ACTION for user $PH_USER"
			printf "%2s%s\n" "" "FAILED : User is currently logged in"
			exit 1
		fi
	fi
fi
case $PH_ACTION in all)
	if [[ $PH_INTERACTIVE -eq 1 ]]
	then
		"$PH_CUR_DIR/confoper_ph.sh" -p user -i
		ph_set_result $?
		"$PH_CUR_DIR/confoper_ph.sh" -p sshkey -i
		ph_set_result $?
		"$PH_CUR_DIR/confoper_ph.sh" -p locale -i
		ph_set_result $?
		"$PH_CUR_DIR/confoper_ph.sh" -p keyb -i
		ph_set_result $?
		"$PH_CUR_DIR/confoper_ph.sh" -p tzone -i
		ph_set_result $?
		"$PH_CUR_DIR/confoper_ph.sh" -p host -i
		ph_set_result $?
		"$PH_CUR_DIR/confoper_ph.sh" -p filesys
		ph_set_result $?
		"$PH_CUR_DIR/confoper_ph.sh" -p audio -i
		ph_set_result $?
		"$PH_CUR_DIR/confoper_ph.sh" -p overscan -i
		ph_set_result $?
		"$PH_CUR_DIR/confoper_ph.sh" -p memsplit -i
		ph_set_result $?
		"$PH_CUR_DIR/confoper_ph.sh" -p ssh -i
		ph_set_result $?
		"$PH_CUR_DIR/confoper_ph.sh" -p update
		ph_set_result $?
		"$PH_CUR_DIR/confoper_ph.sh" -p bootenv -i
		ph_set_result $?
		"$PH_CUR_DIR/confoper_ph.sh" -p netwait -i
		ph_set_result $?
	else
		if [[ "$PH_DEL_PIUSER" == "yes" ]]
		then
			"$PH_CUR_DIR/confoper_ph.sh" -p user -a "$PH_USER"
			ph_set_result $?
		else
			"$PH_CUR_DIR/confoper_ph.sh" -p user -a "$PH_USER" -d
			ph_set_result $?
		fi
		"$PH_CUR_DIR/confoper_ph.sh" -p sshkey -a "$PH_USER"
		ph_set_result $?
		"$PH_CUR_DIR/confoper_ph.sh" -p locale -f "$PH_LOCALE"
		ph_set_result $?
		"$PH_CUR_DIR/confoper_ph.sh" -p keyb -k "$PH_KEYB"
		ph_set_result $?
		"$PH_CUR_DIR/confoper_ph.sh" -p tzone -z "$PH_TZONE"
		ph_set_result $?
		"$PH_CUR_DIR/confoper_ph.sh" -p host -n "$PH_HOST"
		ph_set_result $?
		"$PH_CUR_DIR/confoper_ph.sh" -p filesys
		ph_set_result $?
		"$PH_CUR_DIR/confoper_ph.sh" -p audio -c "$PH_AUDIO"
		ph_set_result $?
		"$PH_CUR_DIR/confoper_ph.sh" -p overscan -u "$PH_UPPERSCAN" -b "$PH_BOTTOMSCAN" -l "$PH_LEFTSCAN" -r "$PH_RIGHTSCAN"
		ph_set_result $?
		"$PH_CUR_DIR/confoper_ph.sh" -p memsplit -m "$PH_VID_MEM"
		ph_set_result $?
		"$PH_CUR_DIR/confoper_ph.sh" -p ssh -s "$PH_SSH_STATE"
		ph_set_result $?
		"$PH_CUR_DIR/confoper_ph.sh" -p update
		ph_set_result $?
		"$PH_CUR_DIR/confoper_ph.sh" -p bootenv -e "$PH_BOOTENV"
		ph_set_result $?
		"$PH_CUR_DIR/confoper_ph.sh" -p netwait -w "$PH_NETWAIT"
		ph_set_result $?
	fi
	printf "\n"
	printf "%2s%s\n" "" "Total : $PH_RESULT"
	printf "\n"
	printf "%s" "Press Enter to reboot"
	read 2>/dev/null
	init 6 ;;
	     all-usedef)
	"$PH_CUR_DIR/confoper_ph.sh" -p user -a "def"
	ph_set_result $?
	"$PH_CUR_DIR/confoper_ph.sh" -p sshkey -a "def"
	ph_set_result $?
	"$PH_CUR_DIR/confoper_ph.sh" -p locale -f "def"
	ph_set_result $?
	"$PH_CUR_DIR/confoper_ph.sh" -p keyb -k "def"
	ph_set_result $?
	"$PH_CUR_DIR/confoper_ph.sh" -p tzone -z "def"
	ph_set_result $?
	"$PH_CUR_DIR/confoper_ph.sh" -p host -n "def"
	ph_set_result $?
	"$PH_CUR_DIR/confoper_ph.sh" -p filesys
	ph_set_result $?
	"$PH_CUR_DIR/confoper_ph.sh" -p audio -c "def"
	ph_set_result $?
	"$PH_CUR_DIR/confoper_ph.sh" -p overscan -u "def" -b "def" -l "def" -r "def"
	ph_set_result $?
	"$PH_CUR_DIR/confoper_ph.sh" -p memsplit -m "def"
	ph_set_result $?
	"$PH_CUR_DIR/confoper_ph.sh" -p ssh -s "def"
	ph_set_result $?
	"$PH_CUR_DIR/confoper_ph.sh" -p update
	ph_set_result $?
	"$PH_CUR_DIR/confoper_ph.sh" -p bootenv -e "def"
	ph_set_result $?
	"$PH_CUR_DIR/confoper_ph.sh" -p netwait -w "def"
	ph_set_result $?
	printf "\n"
	printf "%2s%s\n" "" "Total : $PH_RESULT"
	printf "\n"
	printf "%s" "Press Enter to reboot"
	read 2>/dev/null
	init 6 ;;
		dispdef)
	printf "%s\n" "- Executing function $PH_ACTION"
	for PH_i in PH_USER PH_DEL_PIUSER PH_LOCALE PH_KEYB PH_TZONE PH_HOST PH_AUDIO PH_BOTTOMSCAN PH_UPPERSCAN PH_RIGHTSCAN PH_LEFTSCAN PH_VID_MEM PH_SSH_STATE PH_NETWAIT PH_BOOTENV
	do
		case $PH_i in PH_USER)
				printf "%8s%s\n" "" "--> Displaying stored default value for 'create new user'/'create SSH key for user' operation" ;;
			    PH_DEL_PIUSER)
				printf "%8s%s\n" "" "--> Displaying stored default value for delete standard user '$PH_DEF_USER' operation" ;;
				PH_LOCALE)
				printf "%8s%s\n" "" "--> Displaying stored default value for system locale" ;;
				  PH_KEYB)
				printf "%8s%s\n" "" "--> Displaying stored default value for keyboard layout" ;;
				 PH_TZONE)
				printf "%8s%s\n" "" "--> Displaying stored default value for system timezone" ;;
				  PH_HOST)
				printf "%8s%s\n" "" "--> Displaying stored default value for system hostname" ;;
				 PH_AUDIO)
				printf "%8s%s\n" "" "--> Displaying stored default value for audio channel" ;;
			    PH_BOTTOMSCAN)
				printf "%8s%s\n" "" "--> Displaying stored default value for overscan bottom" ;;
			     PH_UPPERSCAN)
				printf "%8s%s\n" "" "--> Displaying stored default value for overscan top" ;;
			     PH_RIGHTSCAN)
				printf "%8s%s\n" "" "--> Displaying stored default value for overscan right" ;;
			      PH_LEFTSCAN)
				printf "%8s%s\n" "" "--> Displaying stored default value for overscan left" ;;
			       PH_VID_MEM)	
				printf "%8s%s\n" "" "--> Displaying stored default value for 'memory reserved for the GPU'" ;;
			     PH_SSH_STATE)
				printf "%8s%s\n" "" "--> Displaying stored default value for SSH state" ;;
			       PH_BOOTENV)
				printf "%8s%s\n" "" "--> Displaying stored default value for default boot environment" ;;
			       PH_NETWAIT)
				printf "%8s%s\n" "" "--> Displaying stored default value for 'wait for network on boot'" ;;
		esac
		if [[ -z `nawk -F\' -v opt=^"$PH_i="$ '$1 ~ opt { print $2 }' "$PH_CUR_DIR/../files/OS.defaults"` ]]
		then
			printf "%10s%s\n" "" "\"none\""
		else
			printf "%10s%s\n" "" "\"`nawk -F\' -v opt=^\"$PH_i=\"$ '$1 ~ opt { print $2 }' \"$PH_CUR_DIR/../files/OS.defaults\"`\""
		fi
	done
	printf "%2s%s\n\n" "" "SUCCESS" ;;
		savedef)
	printf "%s\n" "- Executing function $PH_ACTION"
	if [[ $# -eq 2 ]]
	then
		for PH_i in PH_DEL_PIUSER PH_BOTTOMSCAN PH_UPPERSCAN PH_RIGHTSCAN PH_LEFTSCAN
		do
			if [[ "$PH_i" == "PH_DEL_PIUSER" ]]
			then
				if ! grep ^"PH_DEL_PIUSER=$PH_DEL_PIUSER"$ "$PH_CUR_DIR/../files/OS.defaults" >/dev/null
				then
					ph_savedef "PH_DEL_PIUSER" "$PH_DEL_PIUSER" 
					ph_set_result $?
				fi
			else
				if [[ "$PH_i" == @(PH_RIGHTSCAN|PH_LEFTSCAN) ]]
				then
					if ! grep ^"$PH_i=16"$ "$PH_CUR_DIR/../files/OS.defaults" >/dev/null
					then
						ph_savedef "$PH_i" "16" 
						ph_set_result $?
					fi
				else
					if ! grep ^"$PH_i=30"$ "$PH_CUR_DIR/../files/OS.defaults" >/dev/null
					then
						ph_savedef "$PH_i" "30" 
						ph_set_result $?
					fi
				fi
			fi
		done
	else
		if [[ $PH_INTERACTIVE -eq 1 ]]
		then
			if [[ -z "$4" ]]
			then
				PH_FUNCTIONS="PH_SSH_STATE PH_USER PH_HOST PH_VID_MEM PH_AUDIO PH_TZONE PH_KEYB PH_BOOTENV PH_DEL_PIUSER PH_BOTTOMSCAN PH_UPPERSCAN PH_RIGHTSCAN PH_LEFTSCAN PH_NETWAIT PH_LOCALE"
			else
				case $4 in user)
					PH_FUNCTIONS="PH_USER" ;;
				     del_stduser)
					PH_FUNCTIONS="PH_DEL_PIUSER" ;;
					 locale)
					PH_FUNCTIONS="PH_LOCALE" ;;
		 			   keyb)
					PH_FUNCTIONS="PH_KEYB" ;;
					  tzone)
					PH_FUNCTIONS="PH_TZONE" ;;
					   host)
					PH_FUNCTIONS="PH_HOST" ;;
					  audio)
					PH_FUNCTIONS="PH_AUDIO" ;;
				       overscan)
					PH_FUNCTIONS="PH_BOTTOMSCAN PH_UPPERSCAN PH_RIGHTSCAN PH_LEFTSCAN" ;;
				       memsplit)	
					PH_FUNCTIONS="PH_VID_MEM" ;;
					    ssh)
					PH_FUNCTIONS="PH_SSH_STATE" ;;
					bootenv)
					PH_FUNCTIONS="PH_BOOTENV" ;;
					netwait)
					PH_FUNCTIONS="PH_NETWAIT" ;;
				esac
			fi
			for PH_i in $PH_FUNCTIONS
			do
				PH_COUNT=0
				PH_ANSWER=""
				while [[ -z "$PH_ANSWER" ]]
				do
					[[ $PH_COUNT -gt 0 ]] && printf "\n%10s%s\n\n" "" "ERROR : Invalid response"
					case $PH_i in PH_USER)
						printf "%8s%s" "" "--> Please enter the value for 'create new user'/'create SSH key for user' operation : " ;;
						PH_DEL_PIUSER)
						printf "%8s%s" "" "--> Please enter the value for delete standard user '$PH_DEF_USER' operation (yes/no) : " ;;
						    PH_LOCALE)
						printf "%8s%s" "" "--> Please enter the value for system locale (must be a system supported locale) : " ;;
		 				      PH_KEYB)
						printf "%8s%s" "" "--> Please enter the value for keyboard layout (must be a valid keyboard layout) : " ;;
						     PH_TZONE)
						printf "%8s%s" "" "--> Please enter the value for system timezone (must be a valid timezone identifier) : " ;;
						      PH_HOST)
						printf "%8s%s" "" "--> Please enter the value for system hostname : " ;;
						     PH_AUDIO)
						printf "%8s%s" "" "--> Please enter the value for audio channel (hdmi/jack/auto) : " ;;
						PH_BOTTOMSCAN)
						printf "%8s%s" "" "--> Please enter the value for overscan bottom (must be numeric or empty (empty defaults to '30')) : " ;;
						 PH_UPPERSCAN)
						printf "%8s%s" "" "--> Please enter the value for overscan top (must be numeric or empty (empty defaults to '30')) : " ;;
						 PH_RIGHTSCAN)
						printf "%8s%s" "" "--> Please enter the value for overscan right (must be numeric or empty (empty defaults to '16')) : " ;;
						  PH_LEFTSCAN)
						printf "%8s%s" "" "--> Please enter the value for overscan left (must be numeric or empty (empty defaults to '16')) : " ;;
						   PH_VID_MEM)	
						printf "%8s%s" "" "--> Please enter the value for 'memory reserved for the GPU' (16/32/64/128/256/512) : " ;;
						 PH_SSH_STATE)
						printf "%8s%s" "" "--> Please enter the value for SSH state (allowed/disallowed) : " ;;
						   PH_BOOTENV)
						printf "%8s%s" "" "--> Please enter the value for default boot environment (cli/gui) : " ;;
						   PH_NETWAIT)
						printf "%8s%s" "" "--> Please enter the value for 'wait for network on boot' (enabled/disabled) : " ;;
					esac
					read PH_ANSWER 2>/dev/null
					PH_COUNT=$((PH_COUNT+1))
					case $PH_i in PH_USER)
						if ph_screen_input "$PH_ANSWER"
						then
							PH_USER="$PH_ANSWER"
							printf "%10s%s\n" "" "OK"
							continue
						else
							exit 1
						fi ;;
						PH_DEL_PIUSER)
						[[ "$PH_ANSWER" == @(yes|no) ]] && PH_DEL_PIUSER="$PH_ANSWER" && printf "%10s%s\n" "" "OK" && break ;;
						    PH_LOCALE)
						ph_check_locale_validity "$PH_ANSWER" && PH_LOCALE="$PH_ANSWER" && printf "%10s%s\n" "" "OK" && break ;;
		 				      PH_KEYB)
						ph_check_keyb_layout_validity "$PH_ANSWER" && PH_KEYB="$PH_ANSWER" && printf "%10s%s\n" "" "OK" && break ;;
						     PH_TZONE)
						ph_check_tzone_validity "$PH_ANSWER" && PH_TZONE="$PH_ANSWER" && printf "%10s%s\n" "" "OK" && break ;;
						      PH_HOST)
						if ph_screen_input "$PH_ANSWER"
						then
							PH_HOST="$PH_ANSWER"
							printf "%10s%s\n" "" "OK"
							continue
						else
							exit 1
						fi ;;
						     PH_AUDIO)
						[[ "$PH_ANSWER" == @(auto|hdmi|jack) ]] && PH_AUDIO="$PH_ANSWER" && printf "%10s%s\n" "" "OK" && break ;;
						PH_BOTTOMSCAN)
						[[ "$PH_ANSWER" == @(+([[:digit:]])|) ]] && PH_BOTTOMSCAN="$PH_ANSWER" && printf "%10s%s\n" "" "OK" && break ;;
						 PH_UPPERSCAN)
						[[ "$PH_ANSWER" == @(+([[:digit:]])|) ]] && PH_UPPERSCAN="$PH_ANSWER" && printf "%10s%s\n" "" "OK" && break ;;
						 PH_RIGHTSCAN)
						[[ "$PH_ANSWER" == @(+([[:digit:]])|) ]] && PH_RIGHTSCAN="$PH_ANSWER" && printf "%10s%s\n" "" "OK" && break ;;
						  PH_LEFTSCAN)
						[[ "$PH_ANSWER" == @(+([[:digit:]])|) ]] && PH_LEFTSCAN="$PH_ANSWER" && printf "%10s%s\n" "" "OK" && break ;;
						   PH_VID_MEM)	
						[[ "$PH_ANSWER" == @(16|32|64|128|256|512) ]] && PH_VID_MEM="$PH_ANSWER" && printf "%10s%s\n" "" "OK" && break ;;
						 PH_SSH_STATE)
						[[ "$PH_ANSWER" == @(allowed|disallowed) ]] && PH_SSH_STATE="$PH_ANSWER" && printf "%10s%s\n" "" "OK" && break ;;
						   PH_BOOTENV)
						[[ "$PH_ANSWER" == @(cli|gui) ]] && PH_BOOTENV="$PH_ANSWER" && printf "%10s%s\n" "" "OK" && break ;;
						   PH_NETWAIT)
						[[ "$PH_ANSWER" == @(enabled|disabled) ]] && PH_NETWAIT="$PH_ANSWER" && printf "%10s%s\n" "" "OK" && break ;;
					esac
					PH_ANSWER=""
				done
			done
		fi
		for PH_i in PH_SSH_STATE PH_USER PH_HOST PH_VID_MEM PH_AUDIO PH_TZONE PH_KEYB PH_BOOTENV PH_DEL_PIUSER PH_BOTTOMSCAN PH_UPPERSCAN PH_RIGHTSCAN PH_LEFTSCAN PH_NETWAIT PH_LOCALE
		do
			[[ `eval echo -n "\\$\$PH_i"` == "def" ]] && (printf "%2s%s\n" "" "FAILED : Unsupported value \"def\" detected for parameter $PH_i" ; exit 0) && exit 1
		done
		for PH_i in PH_SSH_STATE PH_USER PH_HOST PH_VID_MEM PH_AUDIO PH_TZONE PH_KEYB PH_BOOTENV PH_DEL_PIUSER PH_BOTTOMSCAN PH_UPPERSCAN PH_RIGHTSCAN PH_LEFTSCAN PH_NETWAIT PH_LOCALE
		do
			if [[ -n `eval echo -n "\\$\$PH_i"` ]]
			then
				if ! grep ^"$PH_i="`eval echo -n "\\$\$PH_i"`$ "$PH_CUR_DIR/../files/OS.defaults" >/dev/null
				then
					ph_savedef "$PH_i" "`eval echo -n \"\\$\$PH_i\"`" 
					ph_set_result $?
				fi
			else
				if [[ "$PH_i" == @(PH_RIGHTSCAN|PH_LEFTSCAN) ]]
				then
					if ! grep ^"$PH_i=16"$ "$PH_CUR_DIR/../files/OS.defaults" >/dev/null
					then
						ph_savedef "$PH_i" "16"
						ph_set_result $?
					fi
				fi
				if [[ "$PH_i" == @(PH_BOTTOMSCAN|PH_UPPERSCAN) ]]
				then
					if ! grep ^"$PH_i=30"$ "$PH_CUR_DIR/../files/OS.defaults" >/dev/null
					then
						ph_savedef "$PH_i" "30"
						ph_set_result $?
					fi
				fi
			fi
		done
	fi
	printf "%2s%s\n" "" "INFO : Your defaults are stored in ${PH_CUR_DIR%/*}/files/OS.defaults"
	[[ $PH_COUNT -ne 0 ]] && printf "%2s%s\n" "" "Total : $PH_RESULT" || printf "%2s%s\n" "" "Total : $PH_RESULT : Nothing to do"
	[[ "$PH_RESULT" != "SUCCESS" ]] && exit 1 || exit 0 ;;
		      *)
	[[ "$PH_ACTION" != "update" ]] && printf "%s\n" "- Executing function $PH_ACTION"
	PH_RET_CODE=0
	PH_COUNT=0
	PH_ANSWER=""
	case $PH_ACTION in user)
		if [[ $PH_INTERACTIVE -eq 1 ]]
		then
			for PH_i in PH_USER PH_DEL_PIUSER
			do
				PH_ANSWER=""
				PH_COUNT=0
				while [[ -z "$PH_ANSWER" ]]
				do
					[[ $PH_COUNT -gt 0 ]] && printf "\n%10s%s\n\n" "" "ERROR : $PH_MESSAGE"
					PH_MESSAGE="Invalid response"
					[[ "$PH_i" == "PH_USER" ]] && printf "%8s%s" "" "--> Please enter the value for 'create new user' operation (cannot be a logged-in user) : " || \
							printf "%8s%s" "" "--> Please enter the value for delete standard user '$PH_DEF_USER' operation (yes/no) : "
					read PH_ANSWER 2>/dev/null
					[[ "$PH_ANSWER" == "def" ]] && PH_COUNT=$((PH_COUNT+1)) && PH_ANSWER="" && PH_MESSAGE="Unsupported value entered" && continue
					if ph_screen_input "$PH_ANSWER"
					then
						if [[ "$PH_i" == "PH_USER" ]]
						then
							if ((! who -us | nawk '{ print $1 }' | grep ^"$PH_ANSWER"$ >/dev/null) && ([[ -n "$PH_ANSWER" ]]))
							then
								PH_USER="$PH_ANSWER"
								printf "%10s%s\n" "" "OK"
								break
							else
								[[ -n "$PH_ANSWER" ]] && printf "%10s%s\n" "" "ERROR : User is currently logged in" && printf "%2s%s\n" "" "FAILED" && exit 1
							fi
						else
							[[ "$PH_ANSWER" == @(yes|no) ]] && printf "%10s%s\n" "" "OK" && PH_DEL_PIUSER="$PH_ANSWER" && break
						fi
					else
						exit 1
					fi
					PH_COUNT=$((PH_COUNT+1))
					PH_ANSWER=""
				done
			done
		fi
		if [[ "$PH_USER" == "def" ]]
		then
			ph_getdef PH_USER || (printf "%2s%s\n" "" "FAILED" ; exit 1) || exit $?
			ph_getdef PH_DEL_PIUSER || (printf "%2s%s\n" "" "FAILED" ; exit 1) || exit $?
			if who -us | nawk '{ print $1 }' | grep ^"$PH_USER"$ >/dev/null 2>&1
			then
				printf "%8s%s\n" "" "--> Modifying user $PH_USER"
				printf "%10s%s\n" "" "ERROR : User is currently logged in"
				printf "%2s%s\n" "" "FAILED"
				exit 1
			fi
		fi
		printf "%8s%s\n" "" "--> Checking for group $PH_USER"
		if ! grep ^"$PH_USER:" /etc/group >/dev/null 2>&1
		then
			printf "%10s%s\n" "" "Warning : (Not found) -> Creating"
			printf "%8s%s\n" "" "--> Creating group $PH_USER"
			if groupadd "$PH_USER" >/dev/null 2>&1
			then
				printf "%10s%s\n" "" "OK"
			else
				printf "%10s%s\n" "" "ERROR : Could not create group"
				printf "%2s%s\n" "" "FAILED"
				exit 1
			fi
		else
			printf "%10s%s\n" "" "OK (Nothing to do)"
		fi
		printf "%8s%s\n" "" "--> Checking for user $PH_USER"
		if id $PH_USER >/dev/null 2>&1
		then
			printf "%10s%s\n" "" "Warning : Found -> Modifying"
			printf "%8s%s\n" "" "--> Modifying user $PH_USER"
			if usermod -d "${HOME%/*}/$PH_USER" -m -c "$PH_USER account" -s /bin/bash -G tty,input,video,audio -g "$PH_USER" "$PH_USER" >/dev/null 2>&1
			then
				printf "%10s%s\n" "" "OK"
			else
				printf "%10s%s\n" "" "ERROR : Could not modify user"
				printf "%2s%s\n" "" "FAILED"
				exit 1
			fi
		else
			printf "%10s%s\n" "" "OK (Not found) -> Creating"
			printf "%8s%s\n" "" "--> Creating user $PH_USER"
			if useradd -d "${HOME%/*}/$PH_USER" -c "$PH_USER account" -m -s /bin/bash -G tty,input,video,audio -g "$PH_USER" "$PH_USER" >/dev/null 2>&1
			then
				printf "%10s%s\n" "" "OK"
			else
				printf "%10s%s\n" "" "ERROR : Could not create user"
				printf "%2s%s\n" "" "FAILED"
				exit 1
			fi
		fi
		while true
		do
			[[ $PH_COUNT2 -ne 0 ]] && printf "\n%10s%s\n\n" "" "ERROR : Could not set password"
			printf "%8s%s\n\n" "" "--> Please provide a password for $PH_USER"
			passwd "$PH_USER"
			[[ $? -eq 0 ]] && printf "\n%10s%s\n" "" "OK" && break
			PH_COUNT2=$((PH_COUNT2+1))
		done
		PH_COUNT2=0
		printf "%8s%s\n" "" "--> Checking for sudo rules for user $PH_USER"
		if [[ -f /etc/sudoers.d/010_"$PH_USER"-nopasswd ]]
		then
			printf "%10s%s\n" "" "OK (Found)"
		else
			printf "%10s%s\n" "" "Warning : Not Found -> Creating"
			printf "%8s%s\n" "" "--> Creating sudo rules for user $PH_USER"
			echo "$PH_USER ALL=(ALL) NOPASSWD:SETENV: ALL" >/tmp/010_"$PH_USER"-nopasswd_tmp
			if ! mv /tmp/010_"$PH_USER"-nopasswd_tmp /etc/sudoers.d/010_"$PH_USER"-nopasswd 2>&1
			then
				printf "%10s%s\n" "" "ERROR : Could not create sudo rules"
				PH_RESULT="PARTIALLY FAILED"
			else
				chown root:root /etc/sudoers.d/010_"$PH_USER"-nopasswd 2>/dev/null
				chmod 440 /etc/sudoers.d/010_"$PH_USER"-nopasswd 2>/dev/null
				printf "%10s%s\n" "" "OK"
			fi
		fi
		if (([[ "$PH_DEL_PIUSER" == "yes" ]]) && (id "$PH_DEF_USER" >/dev/null 2>&1))
		then
			if who -us | nawk '{ print $1 }' | grep ^"$PH_DEF_USER"$ >/dev/null
			then
				printf "%8s%s\n" "" "--> Setting up delayed removal of user '$PH_DEF_USER'"
				echo "#!/bin/sh" >/tmp/remove_std_user_tmp
				echo "`which sudo` userdel -r $PH_DEF_USER" >>/tmp/remove_std_user_tmp
				echo "`which sudo` unlink /etc/rc3.d/S99remove_std_user" >>/tmp/remove_std_user_tmp
				echo "`which sudo` rm /etc/init.d/remove_std_user" >>/tmp/remove_std_user_tmp
				mv /tmp/remove_std_user_tmp /etc/init.d/remove_std_user 2>/dev/null
				ln -s /etc/init.d/remove_std_user /etc/rc3.d/S99remove_std_user 2>/dev/null
				chmod 755 /etc/init.d/remove_std_user
				printf "%10s%s\n" "" "OK"
			else
				printf "%8s%s\n" "" "--> Removing user '$PH_DEF_USER'"
				if userdel -r "$PH_DEF_USER" >/dev/null 2>&1
				then
					printf "%10s%s\n" "" "OK"
				else
					printf "%10s%s\n" "" "ERROR : Could not delete user '$PH_DEF_USER'"
					PH_RESULT="PARTIALLY FAILED"
				fi
			fi
			printf "%8s%s\n" "" "--> Deleting sudo rules for default user '$PH_DEF_USER'"
			if rm /etc/sudoers.d/010_"$PH_DEF_USER"-nopasswd >/dev/null 2>&1
			then
				printf "%10s%s\n" "" "OK"
			else
				printf "%10s%s\n" "" "ERROR : Could not delete sudo rules for default user"
				PH_RESULT="PARTIALLY FAILED"
			fi
		fi
		if (([[ `cat /proc/$PPID/comm` != "confoper_ph.sh" ]]) && (who -us | nawk '{ print $1 }' | grep ^"$PH_DEF_USER"$ >/dev/null))
		then
			while [[ "$PH_ANSWER" != @(y|n) ]]
			do
				[[ $PH_COUNT -gt 0 ]] && printf "\n%10s%s\n\n" "" "ERROR : Invalid response"
				printf "%8s%s" "" "--> Reboot to process removal of default user (y/n) ? "
				read PH_ANSWER 2>/dev/null
				PH_COUNT=$((PH_COUNT+1))
			done
			printf "%10s%s\n" "" "OK"
		fi
		printf "%2s%s\n" "" "$PH_RESULT"
		[[ "$PH_ANSWER" == "y" ]] && init 6
		[[ "$PH_RESULT" == "SUCCESS" ]] && exit 0 || exit 1 ;;
			 sshkey)
		if [[ $PH_INTERACTIVE -eq 1 ]]
		then
			while [[ -z "$PH_ANSWER" ]]
			do
				[[ $PH_COUNT -gt 0 ]] && printf "\n%10s%s\n\n" "" "ERROR : $PH_MESSAGE"
				printf "%8s%s" "" "--> Please enter the value for 'create SSH key for user' (should be an existing user) : "
				read PH_ANSWER 2>/dev/null
				[[ "$PH_ANSWER" == "def" ]] && PH_COUNT=$((PH_COUNT+1)) && PH_ANSWER="" && PH_MESSAGE="Unsupported value entered" && continue
				if ph_screen_input "$PH_ANSWER"
				then
					if ph_check_user_validity "$PH_ANSWER"
					then
						PH_USER="$PH_ANSWER"
						printf "%10s%s\n" "" "OK"
						break
					else
						printf "%10s%s\n" "" "ERROR : User does not exist"
						printf "%2s%s\n" "" "FAILED"
						exit 1
					fi
				else
					exit 1
				fi
				PH_COUNT=$((PH_COUNT+1))
				PH_ANSWER=""
			done
		fi
		if [[ "$PH_USER" == "def" ]]
		then
			ph_getdef PH_USER || (printf "%2s%s\n" "" "FAILED" ; exit 1) || exit $?
			if ! ph_check_user_validity "$PH_USER"
			then
				printf "%10s%s\n" "" "ERROR : User does not exist"
				printf "%2s%s\n" "" "FAILED"
				exit 1
			fi
		fi
		PH_HOME="/home/$PH_USER"
		printf "%8s%s\n" "" "--> Checking for existing keys for user $PH_USER"
		if [[ ! -f "$PH_HOME/.ssh/id_rsa.pub" ]]
		then
			printf "%10s%s\n" "" "OK (None)"
			printf "%8s%s\n" "" "--> Creating public/private keypair and trusting public key"
			mkdir $PH_HOME/.ssh 2>/dev/null
			chmod 700 "$PH_HOME/.ssh" 2>/dev/null
			chown -R "$PH_USER":"$PH_USER" "$PH_HOME/.ssh" 2>/dev/null
			if ssh-keygen -t rsa -b 2048 -N "" -f "$PH_HOME/.ssh/id_rsa" >/dev/null 2>&1
			then
				chmod 600 "$PH_HOME/.ssh/id_rsa" 2>/dev/null
				chmod 644 "$PH_HOME/.ssh/id_rsa.pub" 2>/dev/null
				chmod 755 "$PH_HOME" 2>/dev/null
				cp -p "$PH_HOME/.ssh/id_rsa" "$PH_HOME/.ssh/authorized_keys"
				chown -R "$PH_USER":"$PH_USER" "$PH_HOME" 2>/dev/null
				printf "%10s%s\n" "" "OK"
			else
				printf "%10s%s\n" "" "ERROR : Could not create a keypair"
				PH_RESULT="FAILED"
			fi
		else
			printf "%10s%s\n" "" "OK (Nothing to do)"
		fi
		printf "%2s%s\n" "" "$PH_RESULT"
		[[ "$PH_RESULT" == "SUCCESS" ]] && exit 0 || exit 1 ;;
			 locale)
		if [[ $PH_INTERACTIVE -eq 1 ]]
		then
			while [[ -z "$PH_ANSWER" ]]
			do
				[[ $PH_COUNT -gt 0 ]] && printf "\n%10s%s\n\n" "" "ERROR : $PH_MESSAGE"
				printf "%8s%s" "" "--> Please enter the value for system locale (should be a system supported locale) : "
				read PH_ANSWER 2>/dev/null
				[[ "$PH_ANSWER" == "def" ]] && PH_COUNT=$((PH_COUNT+1)) && PH_ANSWER="" && PH_MESSAGE="Unsupported value entered" && continue
				if ph_check_locale_validity "$PH_ANSWER"
				then
					PH_LOCALE="$PH_ANSWER"
					printf "%10s%s\n" "" "OK"
					break
				else
					PH_MESSAGE="Not a system supported locale"
				fi
				PH_COUNT=$((PH_COUNT+1))
				PH_ANSWER=""
			done
		fi
		if [[ "$PH_LOCALE" == "def" ]]
		then
			ph_getdef PH_LOCALE || (printf "%2s%s\n" "" "FAILED" ; exit 1) || exit $?
		fi
		printf "%8s%s\n" "" "--> Checking currently configured system locale"
		PH_VALUE="`localectl status | nawk -F'=' '$0 ~ /System Locale/ { print $2 }'`"
		if [[ "$PH_VALUE" != "$PH_LOCALE" ]]
		then
			printf "%10s%s\n" "" "OK ($PH_VALUE)"
			printf "%8s%s\n" "" "--> Generating locales"
			PH_VALUE="$PH_LOCALE `localectl list-locales | paste -s -d\" \"`"
			for PH_i in $PH_VALUE
			do
				PH_LOCALE_NAME=`grep -i ^"$PH_i " /usr/share/i18n/SUPPORTED | nawk '{ print $1 }'`
				PH_LOCALE_ENCODING=`grep -i ^"$PH_i " /usr/share/i18n/SUPPORTED | nawk '{ print $2 }'`
				if ! grep -i "$PH_LOCALE_NAME $PH_LOCALE_ENCODING" /etc/locale.gen >/dev/null 2>&1
				then
					echo "$PH_LOCALE_NAME $PH_LOCALE_ENCODING" >>/etc/locale.gen
				else
					if grep -i "# $PH_LOCALE_NAME $PH_LOCALE_ENCODING" /etc/locale.gen >/dev/null 2>&1
					then
						if nawk -v loc=^"$PH_LOCALE_NAME"$ '$1 ~ /^#$/ && $2 ~ loc { for(i=2;i<=NF;i++) { print $i ; next } { print }}' /etc/locale.gen >/tmp/locale.gen_tmp 2>/dev/null
						then
							mv /tmp/locale.gen_tmp /etc/locale.gen 2>/dev/null
						else
							rm /tmp/locale.gen_tmp 2>/dev/null
							printf "%10s%s\n" "" "ERROR : Could not generate locale"
							PH_RESULT="FAILED"
						fi
					fi
				fi
			done
			locale 2>/dev/null | sed 's/\(.*\)=\(.*\)/\1='$PH_LOCALE'/g' >/etc/default/locale
			cp -p /etc/default/locale /etc/locale.conf
			unset LANG
			if [[ "$PH_RESULT" != "FAILED" ]]
			then
				if locale-gen >/dev/null 2>&1
				then
					printf "%10s%s\n" "" "OK"
					printf "%8s%s\n" "" "--> Configuring locale $PH_LOCALE"
					if localectl set-locale LANG="$PH_LOCALE" >/dev/null 2>&1
					then
						printf "%10s%s\n" "" "OK"
						. /etc/default/locale
					else
						printf "%10s%s\n" "" "ERROR : Could not configure locale"
						PH_RESULT="PARTIALLY FAILED"
					fi
				else
					printf "%10s%s\n" "" "ERROR : Could not generate locale"
					PH_RESULT="FAILED"
				fi
			fi
		else
			printf "%10s%s\n" "" "OK (Nothing to do)"
		fi
		printf "%2s%s\n" "" "$PH_RESULT"
		[[ "$PH_RESULT" == "SUCCESS" ]] && exit 0 || exit 1 ;;
			   keyb)
		if [[ $PH_INTERACTIVE -eq 1 ]]
		then
			while [[ -z "$PH_ANSWER" ]]
			do
				[[ $PH_COUNT -gt 0 ]] && printf "\n%10s%s\n\n" "" "ERROR : $PH_MESSAGE"
				printf "%8s%s" "" "--> Please enter the value for keyboard layout (should be a valid keyboard layout) : "
				read PH_ANSWER 2>/dev/null
				[[ "$PH_ANSWER" == "def" ]] && PH_COUNT=$((PH_COUNT+1)) && PH_ANSWER="" && PH_MESSAGE="Unsupported value entered" && continue
				if ph_check_keyb_layout_validity "$PH_ANSWER"
				then
					PH_KEYB="$PH_ANSWER"
					printf "%10s%s\n" "" "OK"
					break
				else
					PH_MESSAGE="Invalid keyboard layout specified"
				fi
				PH_COUNT=$((PH_COUNT+1))
				PH_ANSWER=""
			done
		fi
		if [[ "$PH_KEYB" == "def" ]]
		then
			ph_getdef PH_KEYB || (printf "%2s%s\n" "" "FAILED" ; exit 1) || exit $?
		fi
		printf "%8s%s\n" "" "--> Checking currently configured keyboard layout"
		if [[ -f /usr/bin/pacman ]]
		then
			PH_VALUE="`localectl status | nawk -F': ' '$0 ~ /X11 Layout/ { print $2 ; exit 0 } { next }'`"
			if [[ "$PH_VALUE" != "$PH_KEYB" ]]
			then
				printf "%10s%s\n" "" "OK ($PH_VALUE)"
				printf "%8s%s\n" "" "--> Configuring keyboard layout"
				if localectl set-x11-keymap be >/dev/null 2>&1
				then
					if ! nawk -F'=' -v val="$PH_KEYB" '$1 ~ /KEYMAP/ { print $1 "=" val ; next } { print }' /etc/vconsole.conf >/tmp/vconsole.conf_tmp 2>/dev/null
					then
						printf "%10s%s\n" "" "ERROR : Could not configure keyboard"
						rm /tmp/vconsole.conf_tmp 2>/dev/null
						localectl set-x11-keymap "$PH_VALUE" >/dev/null 2>&1
					else
						printf "%10s%s\n" "" "OK"
						mv /tmp/vconsole.conf_tmp /etc/vconsole.conf 2>/dev/null
						! grep "KEYMAP=$PH_KEYB" /etc/vconsole.conf >/dev/null && echo "KEYMAP=$PH_KEYB" >>/etc/vconsole.conf
						if [[ `cat /proc/$PPID/comm` != "confoper_ph.sh" ]]
						then
							while [[ "$PH_ANSWER" != @(y|n) ]]
							do
								[[ $PH_COUNT -gt 0 ]] && printf "\n%10s%s\n\n" "" "ERROR : Invalid response"
								printf "%8s%s" "" "--> Reboot to activate keyboard settings (y/n) ? "
								read PH_ANSWER 2>/dev/null
								PH_COUNT=$((PH_COUNT+1))
							done
							printf "%10s%s\n" "" "OK"
						fi
					fi
				else
					printf "%10s%s\n" "" "ERROR : Could not configure keyboard"
					PH_RESULT="FAILED"
				fi
			else
				printf "%10s%s\n" "" "OK (Nothing to do)"
			fi
		else
			PH_VALUE="`nawk -F'\"' '$1 ~ /^XKBLAYOUT=$/ { print $2 ; exit 0 } { next }' /etc/default/keyboard`"
			if [[ "$PH_VALUE" != "$PH_KEYB" ]]
			then
				printf "%10s%s\n" "" "OK ($PH_VALUE)"
				printf "%8s%s\n" "" "--> Configuring keyboard layout"
				cp -p /etc/default/keyboard /tmp/default_keyboard_bck 2>/dev/null
				nawk -F'"' -v val="$PH_KEYB" '$1 ~ /^XKBLAYOUT=$/ { print $1 "\"" val "\"" ; next } { print }' /etc/default/keyboard >/tmp/default_keyboard_tmp 2>/dev/null
				if [[ $? -eq 0 ]]
				then
					mv /tmp/default_keyboard_tmp /etc/default/keyboard 2>/dev/null
					if dpkg-reconfigure -f noninteractive keyboard-configuration >/dev/null 2>&1
					then
						printf "%10s%s\n" "" "OK"
						rm /tmp/default_keyboard_bck 2>/dev/null
						invoke-rc.d keyboard-setup start >/dev/null 2>&1
						setsid sh -c 'exec setupcon -k --force <> /dev/tty1 >&0 2>&1' >/dev/null 2>&1
						udevadm trigger --subsystem-match=input --action=change >/dev/null 2>&1
					else
						printf "%10s%s\n" "" "ERROR : Could not configure keyboard"
						mv /tmp/default_keyboard_bck /etc/default/keyboard 2>/dev/null
						PH_RESULT="FAILED"
					fi
				else
					printf "%10s%s\n" "" "ERROR : Could not configure keyboard"
					PH_RESULT="FAILED"
				fi
			else
				printf "%10s%s\n" "" "OK (Nothing to do)"
			fi
		fi
		printf "%2s%s\n" "" "$PH_RESULT"
		[[ "$PH_ANSWER" == "y" ]] && init 6
		[[ "$PH_RESULT" == "SUCCESS" ]] && exit 0 || exit 1 ;;
			  tzone)
		if [[ $PH_INTERACTIVE -eq 1 ]]
		then
			while [[ -z "$PH_ANSWER" ]]
			do
				[[ $PH_COUNT -gt 0 ]] && printf "\n%10s%s\n\n" "" "ERROR : $PH_MESSAGE"
				printf "%8s%s" "" "--> Please enter the value for system timezone (should be a valid timezone identifier) : "
				read PH_ANSWER 2>/dev/null
				[[ "$PH_ANSWER" == "def" ]] && PH_COUNT=$((PH_COUNT+1)) && PH_ANSWER="" && PH_MESSAGE="Unsupported value entered" && continue
				if ph_check_tzone_validity "$PH_ANSWER"
				then
					PH_TZONE="$PH_ANSWER"
					printf "%10s%s\n" "" "OK"
					break
				else
					PH_MESSAGE="Invalid timezone identifier specified"
				fi
				PH_COUNT=$((PH_COUNT+1))
				PH_ANSWER=""
			done
		fi
		if [[ "$PH_TZONE" == "def" ]]
		then
			ph_getdef PH_TZONE || (printf "%2s%s\n" "" "FAILED" ; exit 1) || exit $?
		fi
		printf "%8s%s\n" "" "--> Checking current timezone"
		PH_VALUE="`cat /etc/timezone`"
		if [[ "$PH_VALUE" != "$PH_TZONE" ]]
		then
			printf "%10s%s\n" "" "OK ($PH_VALUE)"
			cp -p /etc/localtime /tmp/localtime_bck 2>/dev/null
			cp -p /etc/timezone /tmp/timezone_bck 2>/dev/null
			printf "%8s%s\n" "" "--> Configuring timezone"
			rm /etc/localtime 2>/dev/null
			if timedatectl set-timezone "$PH_TZONE" >/dev/null 2>&1
			then
				rm /tmp/localtime_bck /tmp/timezone_bck 2>/dev/null
				printf "%10s%s\n" "" "OK"
			else
				mv /tmp/timezone_bck /etc/timezone 2>/dev/null
				mv /tmp/localtime_bck /etc/localtime 2>/dev/null
				printf "%10s%s\n" "" "ERROR : Could not configure timezone"
				PH_RESULT="FAILED"
			fi
		else
			printf "%10s%s\n" "" "OK (Nothing to do)"
		fi
		printf "%2s%s\n" "" "$PH_RESULT"
		[[ "$PH_RESULT" == "SUCCESS" ]] && exit 0 || exit 1 ;;
			   host)
		if [[ $PH_INTERACTIVE -eq 1 ]]
		then
			while [[ -z "$PH_ANSWER" ]]
			do
				[[ $PH_COUNT -gt 0 ]] && printf "\n%10s%s\n\n" "" "ERROR : $PH_MESSAGE"
				printf "%8s%s" "" "--> Please enter the value for system hostname : "
				read PH_ANSWER 2>/dev/null
				[[ "$PH_ANSWER" == "def" ]] && PH_COUNT=$((PH_COUNT+1)) && PH_ANSWER="" && PH_MESSAGE="Unsupported value entered" && continue
				if ph_screen_input "$PH_ANSWER"
				then
					PH_HOST="$PH_ANSWER"
					printf "%10s%s\n" "" "OK"
					break
				else
					exit 1
				fi
				PH_COUNT=$((PH_COUNT+1))
				PH_ANSWER=""
			done
		fi
		if [[ "$PH_HOST" == "def" ]]
		then
			ph_getdef PH_HOST || (printf "%2s%s\n" "" "FAILED" ; exit 1) || exit $?
		fi
		printf "%8s%s\n" "" "--> Checking current hostname"
		if [[ "$PH_HOST" != "$HOSTNAME" ]]
		then
			printf "%10s%s\n" "" "OK ($HOSTNAME)"
			printf "%8s%s\n" "" "--> Configuring hostname"
			echo "$PH_HOST" >/etc/hostname
			cp -p /etc/hosts /tmp/hosts_bck 2>/dev/null
			if nawk -v oldhost=^"$HOSTNAME"$ -v newhost="$PH_HOST" '$2 ~ oldhost { print $1 "\t" newhost ; next } { print }' /etc/hosts >/tmp/hosts_tmp 2>/dev/null
			then
				mv /tmp/hosts_tmp /etc/hosts 2>/dev/null
				if ! hostname "$PH_HOST" >/dev/null 2>&1
				then
					mv /tmp/hosts_bck /etc/hosts 2>/dev/null
					printf "%10s%s\n" "" "ERROR : Could not set hostname"
					PH_RESULT="FAILED"
				else
					printf "%10s%s\n" "" "OK"
					rm /tmp/hosts_bck 2>/dev/null
				fi
			else
				printf "%10s%s\n" "" "ERROR : Could not set hostname"
				PH_RESULT="FAILED"
			fi
		else
			printf "%10s%s\n" "" "OK (Nothing to do)"
		fi
		printf "%2s%s\n" "" "$PH_RESULT"
		[[ "$PH_RESULT" == "SUCCESS" ]] && exit 0 || exit 1 ;;
			filesys)
		PH_RESULT="FAILED : Currently unimplemented"
		printf "%2s%s\n" "" "$PH_RESULT"
		[[ "$PH_RESULT" == "SUCCESS" ]] && exit 0 || exit 1 ;;
			  audio)
		if [[ $PH_INTERACTIVE -eq 1 ]]
		then
			while [[ -z "$PH_ANSWER" ]]
			do
				[[ $PH_COUNT -gt 0 ]] && printf "\n%10s%s\n\n" "" "ERROR : $PH_MESSAGE"
				printf "%8s%s" "" "--> Please enter the value for audio channel (hdmi/jack/auto) : "
				PH_MESSAGE="Invalid response"
				read PH_ANSWER 2>/dev/null
				[[ "$PH_ANSWER" == "def" ]] && PH_COUNT=$((PH_COUNT+1)) && PH_ANSWER="" && PH_MESSAGE="Unsupported value entered" && continue
				if [[ "$PH_ANSWER" == @(hdmi|jack|auto) ]]
				then
					PH_AUDIO="$PH_ANSWER"
					printf "%10s%s\n" "" "OK"
					break
				fi
				PH_COUNT=$((PH_COUNT+1))
				PH_ANSWER=""
			done
		fi
		if [[ "$PH_AUDIO" == "def" ]]
		then
			ph_getdef PH_AUDIO || (printf "%2s%s\n" "" "FAILED" ; exit 1) || exit $?
		fi
		printf "%8s%s\n" "" "--> Checking currently configured audio output"
		PH_VALUE="`amixer cget numid=3 | tail -1 | nawk -F'=' '{ print $2 }'`"
		case $PH_VALUE in 1)
				PH_VALUE="auto" ;;
				  2)
				PH_VALUE="hdmi" ;;
				  3)
				PH_VALUE="jack" ;;
		esac
		if [[ "$PH_VALUE" != "$PH_AUDIO" ]]
		then
			printf "%10s%s\n" "" "OK ($PH_VALUE)"
			printf "%8s%s\n" "" "--> Configuring audio output"
			case $PH_AUDIO in auto)
				PH_AUDIO="1" ;;
				  	  hdmi)
				PH_AUDIO="2" ;;
				  	  jack)
				PH_AUDIO="3" ;;
			esac
			if amixer cset numid=3 "$PH_AUDIO" >/dev/null 2>&1
			then
				printf "%10s%s\n" "" "OK"
			else
				printf "%10s%s\n" "" "ERROR : Could not configure audio output"
				PH_RESULT="FAILED"
			fi
		else
			printf "%10s%s\n" "" "OK (Nothing to do)"
		fi
		printf "%2s%s\n" "" "$PH_RESULT"
		[[ "$PH_RESULT" == "SUCCESS" ]] && exit 0 || exit 1 ;;
		       overscan)
		if [[ $PH_INTERACTIVE -eq 1 ]]
		then
			for PH_i in PH_BOTTOMSCAN PH_UPPERSCAN PH_RIGHTSCAN PH_LEFTSCAN
			do
				PH_ANSWER=""
				PH_COUNT=0
				while [[ -z "$PH_ANSWER" ]]
				do
					[[ $PH_COUNT -gt 0 ]] && printf "\n%10s%s\n\n" "" "ERROR : $PH_MESSAGE"
					case $PH_i in PH_BOTTOMSCAN)
							printf "%8s%s" "" "--> Please enter the value for overscan bottom (must be numeric or empty (empty is leave unchanged)) : " ;;
						       PH_UPPERSCAN)
							printf "%8s%s" "" "--> Please enter the value for overscan top (must be numeric or empty (empty is leave unchanged)) : " ;;
						       PH_RIGHTSCAN)
							printf "%8s%s" "" "--> Please enter the value for overscan right (must be numeric or empty (empty is leave unchanged)) : " ;;
						       	PH_LEFTSCAN)
							printf "%8s%s" "" "--> Please enter the value for overscan left (must be numeric or empty (empty is leave unchanged)) : " ;;
					esac
					PH_MESSAGE="Invalid response"
					read PH_ANSWER 2>/dev/null
					[[ "$PH_ANSWER" == "def" ]] && PH_COUNT=$((PH_COUNT+1)) && PH_ANSWER="" && PH_MESSAGE="Unsupported value entered" && continue
					if [[ "$PH_ANSWER" == +([[:digit:]]) || -z "$PH_ANSWER" ]]
					then
						eval export "$PH_i"="$PH_ANSWER"
						printf "%10s%s\n" "" "OK"
						break
					fi
					PH_COUNT=$((PH_COUNT+1))
					PH_ANSWER=""
				done
			done
		fi
		for PH_i in PH_BOTTOMSCAN PH_UPPERSCAN PH_LEFTSCAN PH_RIGHTSCAN
		do
			if [[ `eval echo -n "\\$\$PH_i"` == "def" ]]
			then
				PH_COUNT2=$((PH_COUNT2+1))
				if ! ph_getdef "$PH_i"
				then
					PH_RET_CODE=$((PH_RET_CODE+1))
					continue
				fi
			fi
			case $PH_i in PH_BOTTOMSCAN)
				PH_STRING="overscan_bottom" ;;
			       PH_UPPERSCAN)
				PH_STRING="overscan_top" ;;
			        PH_LEFTSCAN)
				PH_STRING="overscan_left" ;;
			       PH_RIGHTSCAN)
				PH_STRING="overscan_right" ;;
			esac
			if [[ -n `eval echo -n "\\$\$PH_i"` ]]
			then
				printf "%8s%s\n" "" "--> Checking currently configured value for $PH_STRING"
				if [[ `nawk -F'=' -v str=^"$PH_STRING"$ '$1 ~ str { print $2 ; exit 0 } { next }' /boot/config.txt` == `eval echo -n "\\$\$PH_i"` ]]
				then
					PH_COUNT2=$((PH_COUNT2+1))
					printf "%10s%s\n" "" "OK (Nothing to do)"
				else
					printf "%10s%s\n" "" "OK"
					PH_COUNT2=$((PH_COUNT2+1))
					printf "%8s%s\n" "" "--> Configuring value `eval echo -n \"\\$\$PH_i\"` for $PH_STRING"
					nawk -F'=' -v str=^"$PH_STRING"$ -v val=`eval echo -n "\\$\$PH_i"` '$1 ~ str { print $1 "=" val ; next } { print }' /boot/config.txt >/tmp/boot_config.txt_tmp 2>/dev/null
					if [[ $? -eq 0 ]]
					then
						printf "%10s%s\n" "" "OK"
						mv /tmp/boot_config.txt_tmp /boot/config.txt
						if [[ `cat /proc/$PPID/comm` != "confoper_ph.sh" ]]
						then
							while [[ "$PH_ANSWER" != @(y|n) ]]
							do
								[[ $PH_COUNT -gt 0 ]] && printf "\n%10s%s\n\n" "" "ERROR : Invalid response"
								printf "%8s%s" "" "--> Reboot to activate the new values (y/n) ? "
								read PH_ANSWER 2>/dev/null
								PH_COUNT=$((PH_COUNT+1))
							done
							printf "%10s%s\n" "" "OK"
						fi
					else
						printf "%10s%s\n" "" "ERROR : Could not configure $PH_STRING"
						PH_RETCODE=$((PH_RET_CODE+1))
						continue
					fi
				fi
			else
				printf "%8s%s\n" "" "--> Configuring value for $PH_STRING"
				printf "%10s%s\n" "" "Warning : No new value entered for $PH_i -> Skipping" 
				PH_COUNT2=$((PH_COUNT2+1))
			fi
		done
		if [[ $PH_RET_CODE -eq $PH_COUNT2 ]]
		then
			printf "%2s%s\n" "" "FAILED"
		else
			[[ $PH_RET_CODE -eq 0 ]] && printf "%2s%s\n" "" "SUCCESS" || printf "%2s%s\n" "" "PARTIALLY FAILED"
		fi
		[[ "$PH_ANSWER" == "y" ]] && init 6
		[[ $PH_RET_CODE -eq 0 ]] && exit 0 || exit 1 ;;
		       memsplit)
		if [[ $PH_INTERACTIVE -eq 1 ]]
		then
			while [[ -z "$PH_ANSWER" ]]
			do
				[[ $PH_COUNT -gt 0 ]] && printf "\n%10s%s\n\n" "" "ERROR : $PH_MESSAGE"
				printf "%8s%s" "" "--> Please enter the value for 'memory reserved for the GPU' (16/32/64/128/256/512) : "
				PH_MESSAGE="Invalid response"
				read PH_ANSWER 2>/dev/null
				[[ "$PH_ANSWER" == "def" ]] && PH_COUNT=$((PH_COUNT+1)) && PH_ANSWER="" && PH_MESSAGE="Unsupported value entered" && continue
				if [[ "$PH_ANSWER" == @(16|32|64|128|256|512) ]]
				then
					PH_VID_MEM="$PH_ANSWER"
					printf "%10s%s\n" "" "OK"
					break
				fi
				PH_COUNT=$((PH_COUNT+1))
				PH_ANSWER=""
			done
		fi
		if [[ "$PH_VID_MEM" == "def" ]]
		then
			ph_getdef PH_VID_MEM || (printf "%2s%s\n" "" "FAILED" ; exit 1) || exit $?
		fi
		printf "%8s%s\n" "" "--> Checking currently configured GPU memory"
		PH_VALUE="`nawk -F'=' -v str=^\"gpu_mem\"$ '$1 ~ str { print $2 ; exit 0 } { next }' /boot/config.txt`"
		if [[ "$PH_VID_MEM" != "$PH_VALUE" ]]
		then
			printf "%10s%s\n" "" "OK ($PH_VALUE)"
			printf "%8s%s\n" "" "--> Configuring memory reservation for the GPU"
			nawk -F'=' -v str=^"gpu_mem" -v val="$PH_VID_MEM" '$1 ~ str { print $1 "=" val ; next } { print }' /boot/config.txt >/tmp/boot_config.txt_tmp 2>/dev/null
			if [[ $? -eq 0 ]]
			then
				printf "%10s%s\n" "" "OK"
				mv /tmp/boot_config.txt_tmp /boot/config.txt
				if [[ `cat /proc/$PPID/comm` != "confoper_ph.sh" ]]
				then
					while [[ "$PH_ANSWER" != @(y|n) ]]
					do
						[[ $PH_COUNT -gt 0 ]] && printf "\n%10s%s\n\n" "" "ERROR : Invalid response"
						printf "%8s%s" "" "--> Reboot to activate the new values (y/n) ? "
						read PH_ANSWER 2>/dev/null
						PH_COUNT=$((PH_COUNT+1))
					done
					printf "%10s%s\n" "" "OK"
				fi
			else
				printf "%10s%s\n" "" "ERROR : Could not configure GPU memory reservation"
				PH_RESULT="FAILED"
			fi
		else
			printf "%10s%s\n" "" "OK (Nothing to do)"
		fi
		printf "%2s%s\n" "" "$PH_RESULT"
		[[ "$PH_ANSWER" == "y" ]] && init 6
		[[ "$PH_RESULT" == "SUCCESS" ]] && exit 0 || exit 1 ;;
			    ssh)
		if [[ $PH_INTERACTIVE -eq 1 ]]
		then
			while [[ -z "$PH_ANSWER" ]]
			do
				[[ $PH_COUNT -gt 0 ]] && printf "\n%10s%s\n\n" "" "ERROR : $PH_MESSAGE"
				printf "%8s%s" "" "--> Please enter the value for SSH state (allowed/disallowed) : "
				PH_MESSAGE="Invalid response"
				read PH_ANSWER 2>/dev/null
				[[ "$PH_ANSWER" == "def" ]] && PH_COUNT=$((PH_COUNT+1)) && PH_ANSWER="" && PH_MESSAGE="Unsupported value entered" && continue
				if [[ "$PH_ANSWER" == @(allowed|disallowed) ]]
				then
					PH_SSH_STATE="$PH_ANSWER"
					printf "%10s%s\n" "" "OK"
					break
				fi
				PH_COUNT=$((PH_COUNT+1))
				PH_ANSWER=""
			done
		fi
		if [[ "$PH_SSH_STATE" == "def" ]]
		then
			ph_getdef PH_SSH_STATE || (printf "%2s%s\n" "" "FAILED" ; exit 1) || exit $?
		fi
		if [[ "$PH_SSH_STATE" == "allowed" ]]
		then
			printf "%8s%s\n" "" "--> Checking for current SSH state"
			if systemctl is-enabled ssh >/dev/null 2>&1
			then
				printf "%10s%s\n" "" "OK (Nothing to do)"
			else
				printf "%10s%s\n" "" "OK (Disabled)"
				printf "%8s%s\n" "" "--> Enabling SSH"
				if ! systemctl enable ssh >/dev/null 2>&1
				then
					printf "%10s%s\n" "" "ERROR : Could not enable SSH"
					PH_RESULT="PARTIALLY FAILED"
				else
					printf "%10s%s\n" "" "OK"
				fi
			fi
			printf "%8s%s\n" "" "--> Checking for current sshd status"
			if systemctl is-active ssh >/dev/null 2>&1
			then
				printf "%10s%s\n" "" "OK (Nothing to do)"
			else
				printf "%10s%s\n" "" "OK (Inactive)"
				printf "%8s%s\n" "" "--> Starting sshd"
				if ! systemctl start ssh >/dev/null 2>&1
				then
					printf "%10s%s\n" "" "ERROR : Could not start sshd"
					[[ "$PH_RESULT" == "PARTIALLY FAILED" ]] && PH_RESULT="FAILED"
					[[ "$PH_RESULT" == "SUCCESS" ]] && PH_RESULT="PARTIALLY FAILED"
				else
					printf "%10s%s\n" "" "OK"
				fi
			fi
		else
			printf "%8s%s\n" "" "--> Checking for current SSH state"
			if ! systemctl is-enabled ssh >/dev/null 2>&1
			then
				printf "%10s%s\n" "" "OK (Nothing to do)"
			else
				printf "%10s%s\n" "" "OK (Enabled)"
				printf "%8s%s\n" "" "--> Disabling SSH"
				if ! systemctl disable ssh >/dev/null 2>&1
				then
					printf "%10s%s\n" "" "ERROR : Could not disable SSH"
					PH_RESULT="PARTIALLY FAILED"
				else
					printf "%10s%s\n" "" "OK"
				fi
			fi
			printf "%8s%s\n" "" "--> Checking for current sshd status"
			if ! systemctl is-active ssh >/dev/null 2>&1
			then
				printf "%10s%s\n" "" "OK (Nothing to do)"
			else
				printf "%10s%s\n" "" "OK (Active)"
				printf "%8s%s\n" "" "--> Stopping sshd"
				if ! systemctl stop ssh >/dev/null 2>&1
				then
					printf "%10s%s\n" "" "ERROR : Could not stop sshd"
					[[ "$PH_RESULT" == "PARTIALLY FAILED" ]] && PH_RESULT="FAILED"
					[[ "$PH_RESULT" == "SUCCESS" ]] && PH_RESULT="PARTIALLY FAILED"
				else
					printf "%10s%s\n" "" "OK"
				fi
			fi
		fi
		printf "%2s%s\n" "" "$PH_RESULT"
		[[ "$PH_RESULT" == "SUCCESS" ]] && exit 0 || exit 1 ;;
			 update)
		ph_update_system | sed 's/Starting system update/Executing function update/'
		exit $? ;;
			netwait)
		if [[ $PH_INTERACTIVE -eq 1 ]]
		then
			while [[ -z "$PH_ANSWER" ]]
			do
				[[ $PH_COUNT -gt 0 ]] && printf "\n%10s%s\n\n" "" "ERROR : $PH_MESSAGE"
				printf "%8s%s" "" "--> Please enter the value for 'wait for network on boot' (enabled/disabled) : "
				PH_MESSAGE="Invalid response"
				read PH_ANSWER 2>/dev/null
				[[ "$PH_ANSWER" == "def" ]] && PH_COUNT=$((PH_COUNT+1)) && PH_ANSWER="" && PH_MESSAGE="Unsupported value entered" && continue
				if [[ "$PH_ANSWER" == @(enabled|disabled) ]]
				then
					PH_NETWAIT="$PH_ANSWER"
					printf "%10s%s\n" "" "OK"
					break
				fi
				PH_COUNT=$((PH_COUNT+1))
				PH_ANSWER=""
			done
		fi
		if [[ "$PH_NETWAIT" == "def" ]]
		then
			ph_getdef PH_NETWAIT || (printf "%2s%s\n" "" "FAILED" ; exit 1) || exit $?
		fi
		printf "%8s%s\n" "" "--> Checking current value for 'wait for network on boot'"
		[[ -f /etc/systemd/system/dhcpcd.service.d/wait.conf ]] && PH_VALUE="enabled" || PH_VALUE="disabled"
		if [[ "$PH_NETWAIT" != "$PH_VALUE" ]]
		then
			printf "%10s%s\n" "" "OK ($PH_VALUE)"
			if [[ "$PH_NETWAIT" == "enabled" ]]
			then
				printf "%8s%s\n" "" "--> Creating dhcpd configuration file"
				mkdir -p /etc/systemd/system/dhcpcd.service.d/ 2>/dev/null
				cat >/etc/systemd/system/dhcpcd.service.d/wait.conf << EOF 2>/dev/null
[Service]
ExecStart=
ExecStart=/usr/lib/dhcpcd5/dhcpcd -q -w
EOF
				if [[ $? -ne 0 ]]
				then
					printf "%10s%s\n" "" "ERROR : Could not create configuration file"
					PH_RESULT="FAILED" 
				else
					printf "%10s%s\n" "" "OK"
				fi
			else
				printf "%8s%s\n" "" "--> Removing dhcpd configuration file"
				rm -f /etc/systemd/system/dhcpcd.service.d/wait.conf 2>/dev/null
				if [[ $? -ne 0 ]]
				then
					printf "%10s%s\n" "" "ERROR : Could not remove configuration file"
					PH_RESULT="FAILED" 
				else
					printf "%10s%s\n" "" "OK"
				fi
			fi
		else
			printf "%10s%s\n" "" "OK (Nothing to do)"
		fi
		printf "%2s%s\n" "" "$PH_RESULT"
		[[ "$PH_RESULT" == "SUCCESS" ]] && exit 0 || exit 1 ;;
			bootenv)
		if [[ $PH_INTERACTIVE -eq 1 ]]
		then
			while [[ -z "$PH_ANSWER" ]]
			do
				[[ $PH_COUNT -gt 0 ]] && printf "\n%10s%s\n\n" "" "ERROR : $PH_MESSAGE"
				printf "%8s%s" "" "--> Please enter the value for default boot environment (cli/gui) : "
				PH_MESSAGE="Invalid response"
				read PH_ANSWER 2>/dev/null
				[[ "$PH_ANSWER" == "def" ]] && PH_COUNT=$((PH_COUNT+1)) && PH_ANSWER="" && PH_MESSAGE="Unsupported value entered" && continue
				if [[ "$PH_ANSWER" == @(cli|gui) ]]
				then
					PH_BOOTENV="$PH_ANSWER"
					printf "%10s%s\n" "" "OK"
					break
				fi
				PH_COUNT=$((PH_COUNT+1))
				PH_ANSWER=""
			done
		fi
		if [[ "$PH_BOOTENV" == "def" ]]
		then
			ph_getdef PH_BOOTENV || (printf "%2s%s\n" "" "FAILED" ; exit 1) || exit $?
		fi
		if ((grep "PH_RUNAPP_CMD='/home/dkeppens/PieHelper/scripts/startpieh.sh'" /etc/profile.d/PieHelper_tty* >/dev/null 2>&1) && ([[ "$PH_BOOTENV" == "gui" ]]))
		then
			printf "%8s%s\n" "" "--> Setting default boot environment to $PH_BOOTENV"
			printf "%10s%s\n" "" "ERROR : PieHelper is configured and is not compatible with a graphical default boot environment"
			printf "%2s%s\n" "" "FAILED"
			exit 1
		fi
		printf "%8s%s\n" "" "--> Checking current default boot environment"
		[[ "$PH_BOOTENV" == "cli" ]] && PH_BOOTENV="multi-user.target" || \
			PH_BOOTENV="graphical.target"
		if [[ `systemctl get-default` != "$PH_BOOTENV" ]]
		then
			[[ "$PH_BOOTENV" == "graphical.target" ]] && printf "%10s%s\n" "" "OK (multi-user.target)" || \
						printf "%10s%s\n" "" "OK (graphical.target)"
			printf "%8s%s\n" "" "--> Setting default boot environment to $PH_BOOTENV"
			if systemctl set-default "$PH_BOOTENV" >/dev/null 2>&1
			then
				printf "%10s%s\n" "" "OK"
			else
				printf "%10s%s\n" "" "ERROR : Could not configure default boot environment"
				PH_RESULT="FAILED"
			fi
		else
			printf "%10s%s\n" "" "OK (Nothing to do)"
		fi
		printf "%2s%s\n" "" "$PH_RESULT"
		[[ "$PH_RESULT" == "SUCCESS" ]] && exit 0 || exit 1 ;;
			   boot)
		printf "%2s%s\n" "" "$PH_RESULT"
		printf "\n"
		printf "%s" "Press Enter to reboot"
		read 2>/dev/null
		init 6 ;;
	esac
	[[ $PH_RET_CODE -ne 0 ]] && PH_RESULT="FAILED"
	printf "%2s%s\n" "" "$PH_RESULT" && exit $PH_RET_CODE ;;
esac