#!/bin/bash
# Perform initial Raspberry Pi configuration (by Davy Keppens on 17/01/2019)
# Enable/Disable debug by running confpieh_ph.sh -p debug -m confoper_ph.sh

#set -x

typeset PH_i=""
typeset PH_OPTION=""
typeset PH_STRING=""
typeset PH_ANSWER=""
typeset PH_ACTION=""
typeset PH_CUR_DIR="$( cd "$( dirname "$0" )" && pwd )"
typeset PH_OLDOPTARG="$OPTARG"
typeset -i PH_RET_CODE=0
typeset -i PH_COUNT=0
typeset -i PH_FLAG=0
typeset -i PH_OLDOPTIND=$OPTIND
PH_USER=""
PH_DEL_PIUSER="yes"
PH_HOST=""
PH_AUDIO=""
PH_BOOTENV=""
PH_LOCALE=""
PH_TZONE=""
PH_KEYB=""
PH_SSH_STATE=""
PH_SPLASH_STATE=""
PH_VID_MEM=""
PH_RIGHTSCAN=""
PH_LEFTSCAN=""
PH_BOTTOMSCAN=""
PH_UPPERSCAN=""
PH_RESULT="SUCCESS"
PATH=$PH_CUR_DIR:$PATH
OPTIND=1

export PATH PH_USER PH_DEL_PIUSER PH_HOST PH_AUDIO PH_BOOTENV PH_LOCALE PH_TZONE PH_KEYB PH_SSH_STATE PH_SPLASH_STATE PH_VID_MEM PH_RIGHTSCAN PH_LEFTSCAN PH_BOTTOMSCAN PH_UPPERSCAN PH_RESULT PH_COUNT

function ph_getdef {

typeset PH_PARAM="$1"
typeset PH_VALUE=""

printf "%8s%s\n" "" "--> Getting default value for parameter $PH_PARAM"
if grep ^"$PH_PARAM=" "$PH_CUR_DIR/../files/OS.defaults" >/dev/null
then
	PH_VALUE="`nawk -F'=' -v param=^\"$PH_PARAM\"$ '$1 ~ param { print $2 ; exit 0 } { next }' $PH_CUR_DIR/../files/OS.defaults`"
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
	printf "%10s%s\n" "" "OK (Found) -> Removing"
	printf "%8s%s\n" "" "--> Removing existing stored default of parameter $PH_PARAM"
	sed "/^$PH_PARAM=/d" "$PH_CUR_DIR/../files/OS.defaults" >/tmp/OS.defaults_tmp 2>&1
	[[ $? -eq 0 ]] && (printf "%10s%s\n" "" "OK" ; mv /tmp/OS.defaults_tmp "$PH_CUR_DIR/../files/OS.defaults" ; return 0) || \
				(printf "%10s%s\n" "" "ERROR : Could not remove existing default" ; return 1) || return $?
else
	printf "%10s%s\n" "" "OK (Not Found)"
fi
printf "%8s%s\n" "" "--> Storing \"$PH_VALUE\" as default value of parameter $PH_PARAM"
echo "$PH_PARAM=$PH_VALUE" >>"$PH_CUR_DIR/../files/OS.defaults"
printf "%10s%s\n" "" "OK"
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
else
	. $PH_CUR_DIR/../conf/distros/Debian.conf
fi

while getopts p:hs:a:n:e:t:c:f:z:u:l:b:r:k:m:d PH_OPTION 2>/dev/null
do
	case $PH_OPTION in p)
		[[ -n "$PH_ACTION" ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ "$OPTARG" != @(all|ssh|sshkey|user|locale|keyb|tzone|host|filesys|audio|splash|overscan|memsplit|update|bootenv|boot|savedef|all-usedef) ]] && \
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
			   k)
		[[ -n "$PH_KEYB" ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_KEYB="$OPTARG" ;;
			   c)
		[[ -n "$PH_AUDIO" ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		! ph_screen_input "$OPTARG" && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ "$OPTARG" != @(hdmi|jack|def) ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
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
			   t)
		[[ -n "$PH_SPLASH_STATE" ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		! ph_screen_input "$OPTARG" && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ "$OPTARG" != @(enabled|disabled|def) ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_SPLASH_STATE="$OPTARG" ;;
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
		>&2 printf "%23s%s\n" "" "-p \"all\" [[-a [alluser] '-d']|-a \"def\"] -s [\"allowed\"|\"disallowed\"|\"def\"] -n [hostname|\"def\"] -e [\"cli\"|\"gui\"|\"def\"] -t [\"enabled\"|\"disabled\"|\"def\"] \\"
		>&2 printf "%23s%s\n" "" "           -c [\"hdmi\"|\"jack\"|\"def\"] -f [newloc|\"def\"] -z [tzone|\"def\"] '-l [lowerscan|\"def\"]' '-r [rightscan|\"def\"]' '-b [bottomscan|\"def\"]' \\"
		>&2 printf "%23s%s\n" "" "           '-u [upperscan|\"def\"]' -k [keyb|\"def\"] -m [16|32|64|128|256|512|\"def\"] |"
		>&2 printf "%23s%s\n" "" "-p \"all-usedef\" |"
		>&2 printf "%23s%s\n" "" "-p \"savedef\" [-a [alluser] '-d'] -s [\"allowed\"|\"disallowed\"] -n [hostname] -e [\"cli\"|\"gui\"] -t [\"enabled\"|\"disabled\"] -c [\"hdmi\"|\"jack\"] \\"
		>&2 printf "%23s%s\n" "" "           -f [newloc] -z [tzone] '-l [lowerscan]' '-r [rightscan]' '-b [bottomscan]' '-u [upperscan]' -k [keyb] -m [16|32|64|128|256|512] |"
                >&2 printf "%23s%s\n" "" "-p \"ssh\" -s [\"allowed\"|\"disallowed\"|\"def\"] |"
                >&2 printf "%23s%s\n" "" "-p \"splash\" -t [\"enabled\"|\"disabled\"|\"def\"] |"
                >&2 printf "%23s%s\n" "" "-p \"sshkey\" -a [[sshuser]|\"def\"] |"
                >&2 printf "%23s%s\n" "" "-p \"user\" [[-a [newuser] '-d']|-a \"def\"] |"
                >&2 printf "%23s%s\n" "" "-p \"host\" -n [hostname|\"def\"] |"
                >&2 printf "%23s%s\n" "" "-p \"bootenv\" -e [\"cli\"|\"gui\"|\"def\"] |"
                >&2 printf "%23s%s\n" "" "-p \"locale\" -f [newloc|\"def\"] |"
                >&2 printf "%23s%s\n" "" "-p \"tzone\" -z [tzone|\"def\"] |"
                >&2 printf "%23s%s\n" "" "-p \"memsplit\" -m [16|32|64|128|256|512|\"def\"] |"
                >&2 printf "%23s%s\n" "" "-p \"keyb\" -k [keyb|\"def\"] |"
                >&2 printf "%23s%s\n" "" "-p \"audio\" -c [\"hdmi\"|\"jack\"|\"def\"] |"
                >&2 printf "%23s%s\n" "" "-p \"overscan\" '-l [lowerscan|\"def\"]' '-r [rightscan|\"def\"]' '-b [bottomscan|\"def\"]' '-u [upperscan|\"def\"]' |"
                >&2 printf "%23s%s\n" "" "-p \"filesys\" |"
                >&2 printf "%23s%s\n" "" "-p \"update\" |"
                >&2 printf "%23s%s\n" "" "-p \"boot\""
		>&2 printf "\n"
		>&2 printf "%3s%s\n" "" "Where -h displays this usage"
                >&2 printf "%9s%s\n" "" "-p specifies the action to take"
                >&2 printf "%12s%s\n" "" "\"all\" allows executing all other functions besides \"all\" in a logical order, using all further parameters provided where needed"
		>&2 printf "%15s%s\n" "" "- The order in which all functions will be executed is the following : \"user\", \"sshkey\", \"locale\", \"keyb\", \"tzone\""
		>&2 printf "%15s%s\n" "" "  \"host\", \"filesys\", \"audio\", \"splash\", \"overscan\", \"memsplit\", \"ssh\", \"update\", \"bootenv\" and \"boot\""
		>&2 printf "%15s%s\n" "" "- Special remarks for function \"all\" :"
		>&2 printf "%18s%s\n" "" "- Any function that fails will generate an error but further function execution will not be interrupted"
		>&2 printf "%18s%s\n" "" "- Any functions requiring a user account parameter will use [alluser] as the value for that parameter"
		>&2 printf "%21s%s\n" "" "- The value specified for [alluser] can be an already existing user account or a new account"
		>&2 printf "%21s%s\n" "" "  If [alluser] is an already existing user account :"
		>&2 printf "%24s%s\n" "" "- The primary group for account [alluser] will be set to it's according private group named [alluser]"
		>&2 printf "%27s%s\n" "" "- The group [alluser] will automatically be created if it does not exist"
		>&2 printf "%24s%s\n" "" "- The secondary groups for account [alluser] will be set to \"tty\",\"input\",\"audio\" and \"video\""
		>&2 printf "%18s%s\n" "" "- A reboot will only be performed once after all functions have concluded instead of at the end of every function requiring a reboot"
                >&2 printf "%12s%s\n" "" "\"all-usedef\" functions like \"all\" but will use the default value stored for each required parameter"
                >&2 printf "%15s%s\n" "" "- If no stored default can be found for one or more of the required parameters, the related function will fail but further function execution will not be interrupted"
                >&2 printf "%12s%s\n" "" "\"savedef\" allows storing the value specified for each additional parameter given as the default value for that parameter"
		>&2 printf "%15s%s\n" "" "- For the default of any of the 4 optional overscan parameters :"
		>&2 printf "%18s%s\n" "" "- If a new value is given and differs from the pre-existing value or there is no pre-existing value, the new value will be stored"
		>&2 printf "%18s%s\n" "" "- If a new value is given and is equal to a pre-existing value, no operation is performed"
		>&2 printf "%18s%s\n" "" "- If a new value is not given and there is no pre-existing value or a pre-existing value not equal to '16', a new value of '16' will be stored"
		>&2 printf "%18s%s\n" "" "- If a new value is not given and there is a pre-existing value equal to '16', no operation is performed"
		>&2 printf "%15s%s\n" "" "- For the default of the optional '-d' parameter, the value will always be stored if there is no currently stored value for it or"
		>&2 printf "%15s%s\n" "" "  if the currently stored default value for it differs from 'yes'"
		>&2 printf "%15s%s\n" "" "- For any other parameters, a pre-existing default value that differs from the new value specified will be replaced with the new value and"
		>&2 printf "%15s%s\n" "" "  no operation will be performed for a pre-existing default value equal to the new value"
                >&2 printf "%12s%s\n" "" "\"ssh\" allows choosing whether to allow or disallow SSH logins to this system for all users besides \"root\""
		>&2 printf "%15s%s\n" "" "-s allows selecting either \"allowed\", \"disallowed\" or \"def\""
		>&2 printf "%18s%s\n" "" "- Selecting \"def\" will use the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%15s%s\n" "" "- Using this function will restart the SSH server"
                >&2 printf "%12s%s\n" "" "\"sshkey\" allows creating a public/private RSA2 keypair for SSH logins for user [sshuser]"
		>&2 printf "%15s%s\n" "" "- The public key will be placed in '/home/[sshuser]/.ssh/id_rsa.pub' and automatically be trusted for SSH connections"
		>&2 printf "%15s%s\n" "" "- The private key will be placed in '/home/[sshuser]/.ssh/id_rsa' and can be used when initiating passwordless SSH connections to this machine"
		>&2 printf "%18s%s\n" "" "- To connect passwordless from a windows machine using Putty, the private key needs to be converted to Putty format using puttygen.exe on"
		>&2 printf "%18s%s\n" "" "  a windows machine and the save location of the converted key should be configured in the Putty.exe session manager"
		>&2 printf "%15s%s\n" "" "-a allows setting a value for [sshuser]"
		>&2 printf "%18s%s\n" "" "- The keyword \"def\" can be used to specify using the stored default value for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%18s%s\n" "" "- The value specified for [sshuser] should already be an existing user account"
                >&2 printf "%12s%s\n" "" "\"user\" allows creating a new user account [newuser] and grant that user full sudo rights"
		>&2 printf "%15s%s\n" "" "-a allows setting a value for [newuser]"
		>&2 printf "%18s%s\n" "" "- The keyword \"def\" can be used to specify using the stored default value for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%21s%s\n" "" "- The stored default for the '-d' parameter will automatically be used as well"
		>&2 printf "%18s%s\n" "" "- The value specified for [newuser] should not be an already existing user account"
		>&2 printf "%18s%s\n" "" "- The primary group for account [newuser] will be set to it's new according private group named [newuser]"
		>&2 printf "%21s%s\n" "" "- The new group [newuser] will automatically be created"
		>&2 printf "%18s%s\n" "" "- The secondary groups for account [newuser] will be set to \"tty\",\"input\",\"audio\" and \"video\""
		>&2 printf "%18s%s\n" "" "- The value for [newuser]'s password will be prompted for"
		>&2 printf "%18s%s\n" "" "- The home directory for [newuser] will be created as '/home/[newuser]'"
		>&2 printf "%18s%s\n" "" "- The shell for [newuser] will be set to '/bin/bash'"
		>&2 printf "%18s%s\n" "" "-d allows specifying the system default user account \"pi\" should not be removed (the default action) along with"
		>&2 printf "%18s%s\n" "" "  it's home directory, mail spool directory and sudo configuration"
		>&2 printf "%21s%s\n" "" "- Specifying -d is optional"
		>&2 printf "%21s%s\n" "" "- Specifying -d when using the keyword \"def\" for [newuser] is not allowed"
                >&2 printf "%12s%s\n" "" "\"host\" allows changing the hostname for this machine to [hostname]"
		>&2 printf "%15s%s\n" "" "-n allows setting a value for [hostname]"
		>&2 printf "%18s%s\n" "" "- The keyword \"def\" can be used to specify using the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
                >&2 printf "%12s%s\n" "" "\"bootenv\" allows selecting a preferred default environment to boot into on system restarts"
		>&2 printf "%15s%s\n" "" "-e allows selecting either \"cli\", \"gui\" or \"def\""
		>&2 printf "%18s%s\n" "" "- Selecting \"def\" will use the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
                >&2 printf "%12s%s\n" "" "\"splash\" allows choosing whether or not to display the default Raspberry Pi splash screen on system startup"
		>&2 printf "%15s%s\n" "" "-t allows selecting either \"enabled\", \"disabled\" or \"def\""
		>&2 printf "%18s%s\n" "" "- Selecting \"def\" will use the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
                >&2 printf "%12s%s\n" "" "\"keyb\" allows setting the default keyboard layout to [keyb]"
		>&2 printf "%15s%s\n" "" "-k allows setting a value for [keyb]"
		>&2 printf "%18s%s\n" "" "- The keyword \"def\" can be used to specify using the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%18s%s\n" "" "- The value specified for [keyb] should be a valid keyboard layout name"
                >&2 printf "%12s%s\n" "" "\"memsplit\" allows setting the amount of memory to reserve exclusively for the GPU"
		>&2 printf "%15s%s\n" "" "-m allows selecting either \"16\", \"32\", \"64\", \"128\", \"256\" or \"def\""
		>&2 printf "%18s%s\n" "" "- Selecting \"def\" will use the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%18s%s\n" "" "- If the new value is different from the one currently set, activation of the new value requires a system reboot that will be proposed"
                >&2 printf "%12s%s\n" "" "\"tzone\" allows setting the default system timezone to [tzone]"
		>&2 printf "%15s%s\n" "" "-z allows setting a value for [tzone]"
		>&2 printf "%18s%s\n" "" "- The keyword \"def\" can be used to specify using the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%18s%s\n" "" "- The value specified for [tzone] should be a valid timezone identifier"
                >&2 printf "%12s%s\n" "" "\"locale\" allows generating locale [newloc] and setting it as the system's default locale"
		>&2 printf "%15s%s\n" "" "-f allows setting a value for [newloc]"
		>&2 printf "%18s%s\n" "" "- The keyword \"def\" can be used to specify using the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%18s%s\n" "" "- The value specified for [newloc] should be a system supported locale"
                >&2 printf "%12s%s\n" "" "\"audio\" allows forcing audio output to the specified channel"
		>&2 printf "%15s%s\n" "" "-c allows selecting either \"hdmi\", \"jack\" or \"def\""
		>&2 printf "%18s%s\n" "" "- \"jack\" stands for the standard 3.5 inch audio jack"
		>&2 printf "%18s%s\n" "" "- The keyword \"def\" can be used to specify using the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%18s%s\n" "" "- If the new value is different from the one currently set, activation of the new value requires a system reboot that will be proposed"
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
(([[ "$PH_ACTION" == "user" && "$PH_USER" == "def" ]]) && ([[ "$PH_DEL_PIUSER" == "no" ]])) && (! confoper_ph.sh -h) && exit 1
[[ "$PH_ACTION" == "all-usedef" && $# -gt 2 ]] && (! confoper_ph.sh -h) && exit 1
[[ "$PH_ACTION" != @(all|savedef|user) && "$PH_DEL_PIUSER" == "no" ]] && (! confoper_ph.sh -h) && exit 1
[[ "$PH_ACTION" == @(all|user|sshkey) && -z "$PH_USER" ]] && (! confoper_ph.sh -h) && exit 1
[[ "$PH_ACTION" == @(all|host) && -z "$PH_HOST" ]] && (! confoper_ph.sh -h) && exit 1
[[ "$PH_ACTION" == @(all|memsplit) && -z "$PH_VID_MEM" ]] && (! confoper_ph.sh -h) && exit 1
[[ "$PH_ACTION" == @(all|ssh) && -z "$PH_SSH_STATE" ]] && (! confoper_ph.sh -h) && exit 1
[[ "$PH_ACTION" == @(all|bootenv) && -z "$PH_BOOTENV" ]] && (! confoper_ph.sh -h) && exit 1
[[ "$PH_ACTION" == @(all|audio) && -z "$PH_AUDIO" ]] && (! confoper_ph.sh -h) && exit 1
[[ "$PH_ACTION" == @(all|splash) && -z "$PH_SPLASH_STATE" ]] && (! confoper_ph.sh -h) && exit 1
[[ "$PH_ACTION" == @(all|tzone) && -z "$PH_TZONE" ]] && (! confoper_ph.sh -h) && exit 1
[[ -n "$PH_TZONE" && "$PH_ACTION" != @(all|savedef|tzone) ]] && (! confoper_ph.sh -h) && exit 1
[[ -n "$PH_BOOTENV" && "$PH_ACTION" != @(all|savedef|bootenv) ]] && (! confoper_ph.sh -h) && exit 1
[[ -n "$PH_USER" && "$PH_ACTION" != @(all|savedef|user|sshkey) ]] && (! confoper_ph.sh -h) && exit 1
[[ -n "$PH_HOST" && "$PH_ACTION" != @(all|savedef|host) ]] && (! confoper_ph.sh -h) && exit 1
[[ -n "$PH_AUDIO" && "$PH_ACTION" != @(all|savedef|audio) ]] && (! confoper_ph.sh -h) && exit 1
[[ -n "$PH_SSH_STATE" && "$PH_ACTION" != @(all|savedef|ssh) ]] && (! confoper_ph.sh -h) && exit 1
[[ -n "$PH_SPLASH_STATE" && "$PH_ACTION" != @(all|savedef|splash) ]] && (! confoper_ph.sh -h) && exit 1
[[ -n "$PH_VID_MEM" && "$PH_ACTION" != @(all|savedef|memsplit) ]] && (! confoper_ph.sh -h) && exit 1
(([[ -n "$PH_RIGHTSCAN" || -n "$PH_LEFTSCAN" ]]) && ([[ "$PH_ACTION" != @(all|savedef|overscan) ]])) && (! confoper_ph.sh -h) && exit 1
(([[ -n "$PH_BOTTOMSCAN" || -n "$PH_UPPERSCAN" ]]) && ([[ "$PH_ACTION" != @(all|savedef|overscan) ]])) && (! confoper_ph.sh -h) && exit 1
if [[ "$PH_ACTION" == "locale" ]]
then
	if ((! cat /usr/share/i18n/SUPPORTED | grep ^"$PH_LOCALE"$ >/dev/null) && ([[ "$PH_LOCALE" != "def" ]]))
	then
		printf "%s\n" "- Executing function $PH_ACTION"
		printf "%2s%s\n" "" "FAILED : Unsupported system locale specified"
		exit 1
	fi
fi
if [[ "$PH_ACTION" == "tzone" ]]
then
	if ((! timedatectl list-timezones | grep ^"$PH_TZONE"$ >/dev/null) && ([[ "$PH_TZONE" != "def" ]]))
	then
		printf "%s\n" "- Executing function $PH_ACTION"
		printf "%2s%s\n" "" "FAILED : Unknown timezone specified"
		exit 1
	fi
fi
if [[ "$PH_ACTION" == "keyb" ]]
then
	if ((! localectl list-x11-keymap-layouts | grep ^"$PH_KEYB"$ >/dev/null) && ([[ "$PH_KEYB" != "def" ]]))
	then
		printf "%s\n" "- Executing function $PH_ACTION"
		printf "%2s%s\n" "" "FAILED : Unknown keyboard layout specified"
		exit 1
	fi
fi
if [[ "$PH_ACTION" == "sshkey" ]]
then
	if ((! id "$PH_USER" >/dev/null 2>&1) && ([[ "$PH_USER" != "def" ]]))
	then
		printf "%s\n" "- Executing function $PH_ACTION for user $PH_USER"
		printf "%2s%s\n" "" "FAILED : $PH_USER is not an existing user account"
		exit 1
	fi
fi
if [[ "$PH_ACTION" == "user" ]]
then
	if id "$PH_USER" >/dev/null 2>&1
	then
		printf "%s\n" "- Executing function $PH_ACTION for user $PH_USER"
		printf "%2s%s\n" "" "FAILED : $PH_USER is an already existing user account"
		exit 1
	fi
fi

if [[ "$PH_ACTION" != "savedef" && `cat /proc/$PPID/comm` != "confoper_ph.sh" ]]
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
	for PH_i in sudo ksh
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
	printf "%2s%s\n" "" "SUCCESS"
fi
case $PH_ACTION in all)
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
	"$PH_CUR_DIR/confoper_ph.sh" -p splash -t "$PH_SPLASH_STATE"
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
	printf "\n"
	printf "%2s%s\n" "" "Total : $PH_RESULT"
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
	"$PH_CUR_DIR/confoper_ph.sh" -p splash -t "def"
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
	printf "\n"
	printf "%2s%s\n" "" "Total : $PH_RESULT"
	init 6 ;;
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
				if ! grep ^"$PH_i=16"$ "$PH_CUR_DIR/../files/OS.defaults" >/dev/null
				then
					ph_savedef "$PH_i" "16" 
					ph_set_result $?
				fi
			fi
		done
	else
		for PH_i in PH_SSH_STATE PH_USER PH_HOST PH_VID_MEM PH_AUDIO PH_SPLASH_STATE PH_TZONE PH_KEYB PH_BOOTENV PH_DEL_PIUSER PH_BOTTOMSCAN PH_UPPERSCAN PH_RIGHTSCAN PH_LEFTSCAN PH_LOCALE
		do
			[[ `eval echo -n "\\$\$PH_i"` == "def" ]] && (printf "%2s%s\n" "" "FAILED : Unsupported value \"def\" detected for parameter $PH_i" ; exit 0) && exit 1
		done
		for PH_i in PH_SSH_STATE PH_USER PH_HOST PH_VID_MEM PH_AUDIO PH_SPLASH_STATE PH_TZONE PH_KEYB PH_BOOTENV PH_DEL_PIUSER PH_BOTTOMSCAN PH_UPPERSCAN PH_RIGHTSCAN PH_LEFTSCAN PH_LOCALE
		do
			if [[ -n `eval echo -n "\\$\$PH_i"` ]]
			then
				if ! grep ^"$PH_i="`eval echo -n "\\$\$PH_i"`$ "$PH_CUR_DIR/../files/OS.defaults" >/dev/null
				then
					ph_savedef "$PH_i" "`eval echo -n \"\\$\$PH_i\"`" 
					ph_set_result $?
				fi
			else
				if [[ "$PH_i" == @(PH_BOTTOMSCAN|PH_UPPERSCAN|PH_RIGHTSCAN|PH_LEFTSCAN) ]]
				then
					if ! grep ^"$PH_i=16"$ "$PH_CUR_DIR/../files/OS.defaults" >/dev/null
					then
						ph_savedef "$PH_i" "16"
						ph_set_result $?
					fi
				fi
			fi
		done
	fi
	[[ $PH_COUNT -ne 0 ]] && printf "%2s%s\n" "" "Total : $PH_RESULT" || printf "%2s%s\n" "" "Total : $PH_RESULT : Nothing to do"
	[[ "$PH_RESULT" != "SUCCESS" ]] && exit 1 || exit 0 ;;
		      *)
	[[ "$PH_ACTION" != "update" ]] && printf "%s\n" "- Executing function $PH_ACTION"
	PH_RET_CODE=0
	PH_COUNT=0
	PH_ANSWER=""
	case $PH_ACTION in user)
		if [[ "$PH_USER" == "def" ]]
		then
			ph_getdef PH_USER || (printf "%2s%s\n" "" "FAILED" ; exit 1) || exit $?
			ph_getdef PH_DEL_PIUSER || (printf "%2s%s\n" "" "FAILED" ; exit 1) || exit $?
		fi
		printf "%2s%s\n" "" "Currently uninplemented"
		PH_RET_CODE=$? ;;
			 sshkey)
		if [[ "$PH_USER" == "def" ]]
		then
			ph_getdef PH_USER || (printf "%2s%s\n" "" "FAILED" ; exit 1) || exit $?
		fi
		printf "%2s%s\n" "" "Currently uninplemented"
		PH_RET_CODE=$? ;;
			 locale)
		if [[ "$PH_LOCALE" == "def" ]]
		then
			ph_getdef PH_LOCALE || (printf "%2s%s\n" "" "FAILED" ; exit 1) || exit $?
		fi
		printf "%2s%s\n" "" "Currently uninplemented"
		PH_RET_CODE=$? ;;
			   keyb)
		if [[ "$PH_KEYB" == "def" ]]
		then
			ph_getdef PH_KEYB || (printf "%2s%s\n" "" "FAILED" ; exit 1) || exit $?
		fi
		printf "%2s%s\n" "" "Currently uninplemented"
		PH_RET_CODE=$? ;;
			  tzone)
		if [[ "$PH_TZONE" == "def" ]]
		then
			ph_getdef PH_TZONE || (printf "%2s%s\n" "" "FAILED" ; exit 1) || exit $?
		fi
		printf "%2s%s\n" "" "Currently uninplemented"
		PH_RET_CODE=$? ;;
			   host)
		if [[ "$PH_HOST" == "def" ]]
		then
			ph_getdef PH_HOST || (printf "%2s%s\n" "" "FAILED" ; exit 1) || exit $?
		fi
		printf "%2s%s\n" "" "Currently uninplemented"
		PH_RET_CODE=$? ;;
			filesys)
		printf "%2s%s\n" "" "Currently uninplemented"
		PH_RET_CODE=$? ;;
			  audio)
		if [[ "$PH_AUDIO" == "def" ]]
		then
			ph_getdef PH_AUDIO || (printf "%2s%s\n" "" "FAILED" ; exit 1) || exit $?
		fi
		printf "%2s%s\n" "" "Currently uninplemented"
		PH_RET_CODE=$? ;;
			 splash)
		if [[ "$PH_SPLASH_STATE" == "def" ]]
		then
			ph_getdef PH_SPLASH_STATE || (printf "%2s%s\n" "" "FAILED" ; exit 1) || exit $?
		fi
		printf "%2s%s\n" "" "Currently uninplemented"
		PH_RET_CODE=$? ;;
		       overscan)
		for PH_i in PH_BOTTOMSCAN PH_UPPERSCAN PH_LEFTSCAN PH_RIGHTSCAN
		do
			if [[ `eval echo -n "\\$\$PH_i"` == "def" ]]
			then
				if ! ph_getdef "$PH_i"
				then
					PH_RET_CODE=1
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
					printf "%10s%s\n" "" "OK (Nothing to do)"
				else
					printf "%10s%s\n" "" "OK"
					printf "%8s%s\n" "" "--> Configuring value `eval echo -n \"\\$\$PH_i\"` for $PH_STRING"
					nawk -F'=' -v str=^"$PH_STRING"$ -v val=`eval echo -n "\\$\$PH_i"` '$1 ~ str { print $1 "=" val ; next } { print }' /boot/config.txt >/tmp/boot_config.txt_tmp 2>/dev/null
					if [[ $? -eq 0 ]]
					then
						PH_FLAG=1
						printf "%10s%s\n" "" "OK"
						mv /tmp/boot_config.txt_tmp /boot/config.txt
					else
						printf "%10s%s\n" "" "ERROR : Could not configure $PH_STRING"
						PH_RETCODE=1
						continue
					fi
				fi
			else
				printf "%8s%s\n" "" "--> Configuring value for $PH_STRING"
				printf "%10s%s\n" "" "Warning : No new value entered for $PH_i -> Skipping" 
			fi
		done
		if [[ $PH_FLAG -eq 1 && `cat /proc/$PPID/comm` != "confoper_ph.sh" ]]
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
		[[ $PH_RET_CODE -ne 0 ]] && printf "%2s%s\n" "" "AT LEAST PARTIALLY FAILED" || printf "%2s%s\n" "" "SUCCESS"
		[[ "$PH_ANSWER" == "y" ]] && init 6
		exit $PH_RET_CODE ;;
		       memsplit)
		if [[ "$PH_VID_MEM" == "def" ]]
		then
			ph_getdef PH_VID_MEM || (printf "%2s%s\n" "" "FAILED" ; exit 1) || exit $?
		fi
		printf "%8s%s\n" "" "--> Checking currently configured GPU memory"
		PH_VALUE=`nawk -F'=' -v str=^"gpu_mem"$ '$1 ~ str { print $2 ; exit 0 } { next }' /boot/config.txt`
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
				printf "%10s%s\n" "" "ERROR : Could not configure GPU memory"
				PH_RESULT="FAILED"
			fi
		else
			printf "%10s%s\n" "" "OK (Nothing to do)"
		fi
		printf "%2s%s\n" "" "$PH_RESULT"
		[[ "$PH_ANSWER" == "y" ]] && init 6
		[[ "$PH_RESULT" == "SUCCESS" ]] && exit 0 || exit 1 ;;
			    ssh)
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
			bootenv)
		if [[ "$PH_BOOTENV" == "def" ]]
		then
			ph_getdef PH_BOOTENV || (printf "%2s%s\n" "" "FAILED" ; exit 1) || exit $?
		fi
		printf "%8s%s\n" "" "--> Checking current default boot environment"
		[[ "$PH_BOOTENV" == "cli" ]] && PH_BOOTENV="multi-user.target" || PH_BOOTENV="graphical.target"
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
		init 6 ;;
	esac
	[[ $PH_RET_CODE -ne 0 ]] && PH_RESULT="FAILED"
	printf "%2s%s\n" "" "$PH_RESULT" && exit $PH_RET_CODE ;;
esac
