#!/bin/bash
# Perform OS configuration tasks (by Davy Keppens on 17/01/2019)
# Enable/Disable debug by running 'confpieh_ph.sh -p debug -m confoper_ph.sh'
# if PieHelper is 'Configured' or
# Enable debug by uncommenting the line below that says "#set -x"
# Disable debug by commenting out the line below that says "set -x"
# if PieHelper is 'Unconfigured'

#set -x

declare PH_i
declare PH_DEF_USER
declare PH_DISTRO
declare PH_STRING
declare PH_ANSWER
declare PH_HOME
declare PH_ACTION
declare PH_FUNCTIONS
declare PH_MESSAGE
declare PH_LOCALE_ENCODING
declare PH_LOCALE_NAME
declare PH_OLD_RESULT
declare PH_OPTION
declare PH_OLDOPTARG
declare -i PH_OLDOPTIND
declare -i PH_COUNT2
declare -i PH_INTERACTIVE_FLAG
declare -i PH_RET_CODE

PH_i=""
PH_DEF_USER=""
PH_DISTRO=""
PH_STRING=""
PH_ANSWER=""
PH_HOME=""
PH_ACTION=""
PH_FUNCTIONS=""
PH_MESSAGE="Invalid response"
PH_LOCALE_ENCODING=""
PH_LOCALE_NAME=""
PH_OLD_RESULT=""
PH_OPTION=""
PH_OLDOPTARG="${OPTARG}"
PH_OLDOPTIND="${OPTIND}"
PH_COUNT2="0"
PH_INTERACTIVE_FLAG="1"
PH_RET_CODE="0"

OPTIND="1"
PH_USER=""
PH_DEL_PIUSER=""
PH_HOST=""
PH_AUDIO=""
PH_ENV=""
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
PH_SSH_KEY=""
PH_CHOICE=""
PH_SUDO="$(command -v sudo)"
PH_DISTRO=""
PH_SCRIPTS_DIR="$(cd "$(dirname "${0}")" && pwd)"
PH_INST_DIR="${PH_SCRIPTS_DIR%/PieHelper/scripts}"
PH_BASE_DIR="${PH_INST_DIR}/PieHelper"
PH_BUILD_DIR="${PH_BASE_DIR}/builds"
PH_SNAPSHOT_DIR="${PH_BASE_DIR}/snapshots"
PH_MNT_DIR="${PH_BASE_DIR}/mnt"
PH_CONF_DIR="${PH_BASE_DIR}/conf/framework"
PH_MAIN_DIR="${PH_SCRIPTS_DIR}/framework/main"
PH_FUNCS_DIR="${PH_BASE_DIR}/functions"
PH_TMP_DIR="${PH_BASE_DIR}/tmp"
PH_FILES_DIR="${PH_BASE_DIR}/files"
PH_MENUS_DIR="${PH_FILES_DIR}/menus"
PH_TEMPLATES_DIR="${PH_FILES_DIR}/templates"
PH_EXCLUDES_DIR="${PH_FILES_DIR}/excludes"
PATH="${PH_SCRIPTS_DIR}:${PATH}"
PH_RESULT="SUCCESS"
PH_TOTAL_RESULT="SUCCESS"
PH_RESULT_TYPE_USED="Normal"

declare -ix PH_COUNT="0"
declare -ix PH_SCRIPT_COUNT="0"
declare -ix PH_RESULT_COUNT="0"
declare -ix PH_TOTAL_RESULT_COUNT="0"

export PH_USER PH_DEL_PIUSER PH_HOST PH_AUDIO PH_ENV PH_LOCALE PH_TZONE PH_NETWAIT PH_KEYB PH_SSH_STATE PH_VID_MEM PH_RIGHTSCAN PH_LEFTSCAN PH_BOTTOMSCAN PH_UPPERSCAN PH_SSH_KEY PH_RESULT PH_CHOICE PH_SUDO PH_DISTRO
export PH_SCRIPTS_DIR PH_INST_DIR PH_BASE_DIR PH_BUILD_DIR PH_SNAPSHOT_DIR PH_MNT_DIR PH_CONF_DIR PH_MAIN_DIR PH_FUNCS_DIR PH_TMP_DIR PH_FILES_DIR PH_MENUS_DIR PH_TEMPLATES_DIR PH_EXCLUDES_DIR
export PATH PH_RESULT PH_TOTAL_RESULT PH_RESULT_TYPE_USED

if [[ -f /usr/bin/pacman ]]
then
	PH_DISTRO="Archlinux" ]]
else
	PH_DISTRO="Debian"
fi

function ph_present_list {

declare -i PH_i
declare -i PH_ANSWER
declare -i PH_COUNT
declare -n PH_DEFAULT

PH_i="0"
PH_ANSWER="0"
PH_COUNT="0"
PH_DEFAULT="${1}"

PH_PARAM="${1}"

PH_CHOICE=""
case "${PH_PARAM}" in PH_AUDIO)
	PH_LIST=(hdmi jack auto) ;;
		    PH_TZONE)
	PH_LIST=($(timedatectl list-timezones 2>/dev/null | nawk 'BEGIN { \
			ORS = " " \
		} { \
			print \
		}')) ;;
		    PH_SSH_STATE)
	PH_LIST=(allowed disallowed) ;;
		    PH_SSH_KEY)
	PH_LIST=($(nawk -F':' 'BEGIN { \
			ORS = " " \
		} \
		$7 !~ /\usr\/sbin\/nologin/ && $7 !~ /\/bin\/false/ && $7 !~ /\/bin\/sync/ && $1 !~ /^root$/ { \
			print $1 \
		}' /etc/passwd 2>/dev/null)) ;;
		    PH_DEL_PIUSER)
	PH_LIST=(yes no) ;;
		    PH_ENV)
	PH_LIST=(cli gui) ;;
		    PH_LOCALE)
	PH_LIST=($(nawk 'BEGIN { \
			ORS = " " \
		} { \
			print $1 \
		}' /usr/share/i18n/SUPPORTED 2>/dev/null)) ;;
		    PH_NETWAIT)
	PH_LIST=(enabled disabled) ;;
		    PH_VID_MEM)
	PH_LIST=(16 32 64 128 256 512) ;;
		    PH_KEYB)
	PH_LIST=($(localectl list-x11-keymap-layouts 2>/dev/null | nawk 'BEGIN { \
			ORS = " " \
		} { \
			print \
		}')) ;;
		    *)
	unset -n PH_DEFAULT
	unset PH_LIST PH_PARAM
	return 1 ;;
esac
printf "\n"
if ph_getdef "${PH_PARAM}" >/dev/null
then
	PH_LIST+=( "Retain current value ('${PH_DEFAULT}')" )
fi
while [[ "${PH_ANSWER}" -lt "1" || "${PH_ANSWER}" -gt "${#PH_LIST[@]}" ]]
do
	if [[ "${PH_COUNT}" -gt "0" ]]
	then
		printf "\n%10s\033[33m%s\033[0m\n" "" "Warning : Invalid response"
	else
		printf "\n"
	fi
	(for PH_i in "${!PH_LIST[@]}"
	do
		printf "%14s%s\n" "" "$((PH_i+1)). ${PH_LIST[${PH_i}]}"
	done) | column
	PH_COUNT="$((PH_COUNT+1))"
	printf "\n%8s%s" "" "Your choice ? "
	read -r PH_ANSWER 2>/dev/null
done
if [[ "${PH_ANSWER}" -eq "${#PH_LIST[@]}" ]]
then
	PH_CHOICE="${PH_DEFAULT}"
else
	PH_CHOICE="${PH_LIST["$((PH_ANSWER-1))"]}"
fi
printf "%10s\033[32m%s\033[0m\n" "" "OK ('${PH_CHOICE}')"
unset -n PH_DEFAULT
unset PH_LIST PH_PARAM
return 0
}

function ph_getdef {

declare PH_PARAM
declare PH_CUR_VALUE

PH_PARAM="${1}"
PH_CUR_VALUE=""

printf "%8s%s\n" "" "--> Retrieving parameter '${PH_PARAM}' default value"
if grep -E "^${PH_PARAM}=" "${PH_CONF_DIR}/OS.defaults" >/dev/null 2>&1
then
	PH_CUR_VALUE="$(nawk -F"'" -v param="^${PH_PARAM}=$" '$1 ~ param { \
			print $2 ; \
			exit 0 \
		} { \
			next \
		}' "${PH_CONF_DIR}/OS.defaults" 2>/dev/null)"
	printf "%10s\033[32m%s\033[0m\n" "" "OK ('${PH_CUR_VALUE}')"
else
	>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not retrieve default"
	return 1
fi
eval export "${PH_PARAM}=\"${PH_CUR_VALUE}\""
return 0
}

function ph_savedef {

declare PH_PARAM
declare PH_VALUE
declare PH_CUR_VALUE

PH_PARAM="${1}"
PH_VALUE="${2}"
PH_CUR_VALUE=""

PH_COUNT="$((PH_COUNT+1))"
printf "%8s%s\n" "" "--> Checking parameter '${PH_PARAM}' existing default"
if grep -E "^${PH_PARAM}=" "${PH_CONF_DIR}/OS.defaults" >/dev/null 2>&1
then
	PH_CUR_VALUE="$(nawk -F"'" -v opt="^${PH_PARAM}=$" '$1 ~ opt { \
			print $2 \
		}' "${PH_CONF_DIR}/OS.defaults" 2>/dev/null)"
	if [[ "${PH_CUR_VALUE}" == "${PH_VALUE}" ]]
	then
		printf "%10s\033[32m%s\033[0m\n" "" "OK (Nothing to do)"
		return 0
	fi
	printf "%10s\033[32m%s\033[0m\n" "" "OK (Found) -> Removing"
	printf "%8s%s\n" "" "--> Removing parameter '${PH_PARAM}' existing default value '${PH_CUR_VALUE}'"
	if sed -i -e "/^${PH_PARAM}=/d" "${PH_CONF_DIR}/OS.defaults" 2>/dev/null
	then
		printf "%10s\033[32m%s\033[0m\n" "" "OK"
		return 0
	else
		>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not remove default"
		return 1
	fi
else
	printf "%10s\033[32m%s\033[0m\n" "" "OK (Not Found)"
fi
printf "%8s%s\n" "" "--> Storing parameter '${PH_PARAM}' default value '${PH_VALUE}'"
if echo "${PH_PARAM}='${PH_VALUE}'" | tee -a "${PH_CONF_DIR}/OS.defaults" >/dev/null 2>&1
then
	printf "%10s\033[32m%s\033[0m\n" "" "OK"
else
	>&2 printf "%10s\033[31m%s\033[0m\n" "" "ERROR : Could not store default"
	return 1
fi
return 0
}

function ph_check_keyb_layout_validity {

if ! localectl list-x11-keymap-layouts 2>/dev/null | grep -E "^${1}$" >/dev/null
then
	return 1
fi
return 0
}

function ph_check_locale_validity {

if ! cat /usr/share/i18n/SUPPORTED 2>/dev/null | grep -E "^${1} " >/dev/null
then
	return 1
fi
return 0
}

function ph_check_tzone_validity {

if ! timedatectl list-timezones 2>/dev/null | grep -E "^${1}$" >/dev/null
then
	return 1
fi
return 0
}

function ph_check_user_state {

if ! id "${1}" >/dev/null 2>&1
then
	return 1
fi
return 0
}

function ph_reset_result {

declare PH_OPTION=""
declare PH_OLDOPTARG="$OPTARG"
declare -i PH_OLDOPTIND="$OPTIND"

OPTIND="1"
PH_RESULT_TYPE_USED="Normal"

while getopts t PH_OPTION 2>/dev/null
do
        case "$PH_OPTION" in t)
                PH_RESULT_TYPE_USED="Total" ;;
        esac
done
OPTIND="$PH_OLDOPTIND"
OPTARG="$PH_OLDOPTARG"

if [[ "$PH_RESULT_TYPE_USED" == "Total" ]]
then
        PH_TOTAL_RESULT="SUCCESS"
        PH_TOTAL_RESULT_COUNT="0"
else
        PH_RESULT="SUCCESS"
        PH_RESULT_COUNT="0"
fi
PH_RESULT_TYPE_USED="Normal"
return 0
}

function ph_set_result {

declare PH_OPTION=""
declare PH_FIRST="no"
declare PH_OLDOPTARG="$OPTARG"
declare -i PH_OLDOPTIND="$OPTIND"
declare -i PH_RET_CODE="0"
declare -i PH_RET_CODE_RECVD="1"

OPTIND="1"
PH_RESULT_TYPE_USED="Normal"

while getopts r:m:taw PH_OPTION 2>/dev/null
do
        case "$PH_OPTION" in r)
                PH_RET_CODE_RECVD="0"
                PH_RET_CODE="$OPTARG" ;;
                             m)
                PH_RESULT_MSG="$OPTARG" ;;
                             a)
                PH_RESULT="Abort"
                PH_RESULT_TYPE_USED="$PH_RESULT" ;;
                             w)
                PH_RESULT="Warning"
                PH_RESULT_TYPE_USED="$PH_RESULT" ;;
                             t)
                PH_RESULT_TYPE_USED="Total" ;;
        esac
done
OPTIND="$PH_OLDOPTIND"
OPTARG="$PH_OLDOPTARG"

case "$PH_RESULT_TYPE_USED" in Warning|Abort|Normal)
                declare -n PH_RESULT_TYPE="PH_RESULT" ;;
                               Total)
                declare -n PH_RESULT_TYPE="PH_TOTAL_RESULT" ;;
esac
if [[ "$PH_RET_CODE_RECVD" -eq "0" ]]
then
        if [[ "$PH_RESULT_TYPE_USED" == "Total" ]]
        then
                [[ "$PH_TOTAL_RESULT_COUNT" -eq "0" ]] && PH_FIRST="yes"
                ((PH_TOTAL_RESULT_COUNT++))
        else
                [[ "$PH_RESULT_COUNT" -eq "0" ]] && PH_FIRST="yes"
                ((PH_RESULT_COUNT++))
        fi
        case "$PH_RET_CODE" in 0)
                [[ "$PH_RESULT_TYPE" == @(Abort|FAILED) ]] && PH_RESULT_TYPE="PARTIALLY FAILED" ;;
                               *)
                if [[ "$PH_FIRST" == "yes" ]]
                then
                        [[ "$PH_RESULT_TYPE" == @(SUCCESS|Warning) ]] && PH_RESULT_TYPE="FAILED"
                else
                        [[ "$PH_RESULT_TYPE" == @(SUCCESS|Warning) ]] && PH_RESULT_TYPE="PARTIALLY FAILED"
                fi ;;
        esac
fi
PH_RESULT_TYPE_USED="Normal"
unset -n PH_RESULT_TYPE
if [[ "$PH_RESULT" == "Abort" ]]
then
	ph_show_result || exit "$?"
fi
return 0
}

function ph_show_result {

declare PH_OPTION=""
declare PH_RESULT_PREFIX="Result > "
declare PH_RESULT_SUFFIX=""
declare PH_OLDOPTARG="$OPTARG"
declare -i PH_OLDOPTIND="$OPTIND"
declare -i PH_RESULT_INDENT="0"

OPTIND="1"

while getopts i:t PH_OPTION 2>/dev/null
do
        case "$PH_OPTION" in i)
                PH_RESULT_INDENT="$OPTARG" ;;
                             t)
                PH_RESULT_TYPE_USED="Total" ;;
        esac
done
OPTIND="$PH_OLDOPTIND"
OPTARG="$PH_OLDOPTARG"

if [[ "$PH_RESULT_TYPE_USED" == @(Warning|Abort|Normal) ]]
then
        declare -n PH_RESULT_TYPE="PH_RESULT"
else
        PH_RESULT_PREFIX="##### Total Result > "
        declare -n PH_RESULT_TYPE="PH_TOTAL_RESULT"
fi
[[ "$PH_RESULT_INDENT" -eq "0" ]] && PH_RESULT_INDENT="2"
if [[ -n "$PH_RESULT_MSG" ]]
then
        PH_RESULT_SUFFIX=" : $PH_RESULT_MSG"
fi
case "$PH_RESULT_TYPE" in Warning)
        printf "\n%""$PH_RESULT_INDENT""s\033[36m%s\033[33m%s%s\033[0m\n\n" "" "$PH_RESULT_PREFIX" "$PH_RESULT_TYPE" "$PH_RESULT_SUFFIX" ;;
                          SUCCESS)
        printf "\n%""$PH_RESULT_INDENT""s\033[36m%s\033[1;32m%s%s\033[0m\n\n" "" "$PH_RESULT_PREFIX" "$PH_RESULT_TYPE" "$PH_RESULT_SUFFIX" ;;
                          *)
        printf "\n%""$PH_RESULT_INDENT""s\033[36m%s\033[1;31m%s%s\033[0m\n\n" "" "$PH_RESULT_PREFIX" "$PH_RESULT_TYPE" "$PH_RESULT_SUFFIX" ;;
esac
PH_RESULT_MSG=""
unset -n PH_RESULT_TYPE
if [[ "$PH_RESULT_TYPE_USED" == "Total" ]]
then
        if [[ "$PH_TOTAL_RESULT" == "SUCCESS" ]]
        then
                ph_reset_result -t
                return 0
        else
                ph_reset_result -t
                return 1
        fi
else
        if [[ "$PH_RESULT" == @(SUCCESS|Warning) ]]
        then
                ph_reset_result
                return 0
        else
                ph_reset_result
                return 1
        fi
fi
}

function ph_screen_input {

if [[ "$(echo "$*" | sed 's/[ ,/.]//g')" == *+([![:word:]])* ]] 2>/dev/null
then
        printf "%2s\033[31m%s\033[0m\n\n" "" "ABORT : Invalid input characters detected"
        return 1
fi
return 0
}

source "${PH_FUNCS_DIR}/distros/functions.${PH_DISTRO}" 2>/dev/null
source "${PH_CONF_DIR}/distros/${PH_DISTRO}.conf" 2>/dev/null

if [[ "$PH_DISTRO" == "Archlinux" ]]
then
	declare PH_KEYB_PKGS="systemd"
	PH_DEF_USER="alarm"
	pacman-key --init >/dev/null 2>&1
	pacman-key --populate archlinuxarm >/dev/null 2>&1
else
	declare PH_KEYB_PKGS="keyboard-configuration systemd"
	PH_DEF_USER="pi"
fi

while getopts p:d:m:r:l:b:u:z:f:k:w:c:e:n:s:a:t:hi PH_OPTION 2>/dev/null
do
	case "$PH_OPTION" in p)
		[[ -n "$PH_ACTION" ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
#		[[ "$OPTARG" != @(all|ssh|sshkey|user|locale|keyb|tzone|host|netwait|filesys|audio|overscan|memsplit|del_stduser|update|bootenv|boot|savedef|dispdef|all-usedef) ]] && \
		[[ "$OPTARG" != @(all|ssh|sshkey|user|locale|keyb|tzone|host|netwait|audio|overscan|memsplit|del_stduser|update|bootenv|boot|savedef|dispdef|all-usedef) ]] && \
			(! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_ACTION="$OPTARG" ;;
			     d)
		[[ -n "$PH_DEL_PIUSER" ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ "$OPTARG" != @(yes|no|def) ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_DEL_PIUSER="$OPTARG" ;;
			     m)
		[[ -n "$PH_VID_MEM" ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ "$OPTARG" != @(512|256|128|64|32|16|def) ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_VID_MEM="$OPTARG" ;;
			     r)
		[[ -n "$PH_RIGHTSCAN" ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ "$OPTARG" != +([[:digit:]]) && "$OPTARG" != "def" ]] && printf "\033[36m%s\033[0m\n" "- Executing overscan function" && >&2 printf "%2s\033[31m%s\033[0m%s\n\n" "" "FAILED" " : Value for right overscan must be numeric or 'def'" && exit 1
		PH_RIGHTSCAN="$OPTARG" ;;
			     l)
		[[ -n "$PH_LEFTSCAN" ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ "$OPTARG" != +([[:digit:]]) && "$OPTARG" != "def" ]] && printf "\033[36m%s\033[0m\n" "- Executing overscan function" && >&2 printf "%2s\033[31m%s\033[0m%s\n\n" "" "FAILED" " : Value for left overscan must be numeric or 'def'" && exit 1
		PH_LEFTSCAN="$OPTARG" ;;
			     b)
		[[ -n "$PH_BOTTOMSCAN" ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ "$OPTARG" != +([[:digit:]]) && "$OPTARG" != "def" ]] && printf "\033[36m%s\033[0m\n" "- Executing overscan function" && >&2 printf "%2s\033[31m%s\033[0m%s\n\n" "" "FAILED" " : Value for bottom overscan must be numeric or 'def'" && exit 1
		PH_BOTTOMSCAN="$OPTARG" ;;
			     u)
		[[ -n "$PH_UPPERSCAN" ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ "$OPTARG" != +([[:digit:]]) && "$OPTARG" != "def" ]] && printf "\033[36m%s\033[0m\n" "- Executing overscan function" && >&2 printf "%2s\033[31m%s\033[0m%s\n\n" "" "FAILED" " : Value for upper overscan must be numeric or 'def'" && exit 1
		PH_UPPERSCAN="$OPTARG" ;;
			     z)
		[[ -n "$PH_TZONE" ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_TZONE="$OPTARG" ;;
			     f)
		[[ -n "$PH_LOCALE" ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_LOCALE="$OPTARG" ;;
			     i)
		[[ "$PH_INTERACTIVE_FLAG" -eq "0" ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_INTERACTIVE_FLAG="0" ;;
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
		[[ -n "$PH_ENV" ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		! ph_screen_input "$OPTARG" && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		[[ "$OPTARG" != @(cli|gui|def) ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_ENV="$OPTARG" ;;
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
			     t)
		[[ -n "$PH_SSH_KEY" ]] && (! confoper_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		! ph_screen_input "$OPTARG" && OPTARG="$PH_OLDOPTARG" && OPTIND=$PH_OLDOPTIND && exit 1
		PH_SSH_KEY="$OPTARG" ;;
			     *)
		>&2 printf "\n"
		>&2 printf "\033[36m%s\033[0m\n" "Usage : confoper_ph.sh -h |"
		>&2 printf "%23s\033[36m%s\033[0m\n" "" "-p \"all\" -a [user|\"def\"] -s [\"allowed\"|\"disallowed\"|\"def\"] -n [hostname|\"def\"] -e [\"cli\"|\"gui\"|\"def\"] -w [\"enabled\"|\"disabled\"|\"def\"] \\"
		>&2 printf "%23s\033[36m%s\033[0m\n" "" "           -c [\"hdmi\"|\"jack\"|\"def\"] -f [locale|\"def\"] -z [tzone|\"def\"] '-l [leftscan|\"def\"]' '-r [rightscan|\"def\"]' '-b [bottomscan|\"def\"]' \\"
		>&2 printf "%23s\033[36m%s\033[0m\n" "" "           '-u [upperscan|\"def\"]' -k [keyb|\"def\"] -m [16|32|64|128|256|512|\"def\"] -t [sshkeyuser|\"def\"] -d [\"yes\"|\"no\"|\"def\"]|-i] |"
		>&2 printf "%23s\033[36m%s\033[0m\n" "" "-p \"all-usedef\" |"
		>&2 printf "%23s\033[36m%s\033[0m\n" "" "-p \"savedef\" -a [user] -s [\"allowed\"|\"disallowed\"] -n [hostname] -e [\"cli\"|\"gui\"] -c [\"hdmi\"|\"jack\"] -w [\"enabled\"|\"disabled\"] \\"
		>&2 printf "%23s\033[36m%s\033[0m\n" "" "           -f [locale] -z [tzone] '-l [lowerscan]' '-r [rightscan]' '-b [bottomscan]' '-u [upperscan]' -k [keyb] -m [16|32|64|128|256|512] -t [sshkeyuser] -d [\"yes\"|\"no\"] \\"
		>&2 printf "%23s\033[36m%s\033[0m\n" "" "           -i '[\"user\"|\"del_stduser\"|\"ssh\"|\"host\"|\"bootenv\"|\"audio\"|\"locale\"|\"tzone\"|\"overscan\"|\"keyb\"|\"memsplit\"|\"netwait\"|\"sshkey\"]'] |"
		>&2 printf "%23s\033[36m%s\033[0m\n" "" "-p \"dispdef\" |"
                >&2 printf "%23s\033[36m%s\033[0m\n" "" "-p \"ssh\" [-s [\"allowed\"|\"disallowed\"|\"def\"]|-i] |"
                >&2 printf "%23s\033[36m%s\033[0m\n" "" "-p \"sshkey\" [-t [sshkeyuser|\"def\"]|-i] |"
                >&2 printf "%23s\033[36m%s\033[0m\n" "" "-p \"user\" [[[-a [user] '-d']|-a \"def\"]|-i] |"
                >&2 printf "%23s\033[36m%s\033[0m\n" "" "-p \"host\" [-n [hostname|\"def\"]-i] |"
                >&2 printf "%23s\033[36m%s\033[0m\n" "" "-p \"bootenv\" [-e [\"cli\"|\"gui\"|\"def\"]|-i] |"
                >&2 printf "%23s\033[36m%s\033[0m\n" "" "-p \"locale\" [-f [locale|\"def\"]|-i] |"
                >&2 printf "%23s\033[36m%s\033[0m\n" "" "-p \"netwait\" [-w [\"enabled\"|\"disabled\"|\"def\"]|-i] |"
                >&2 printf "%23s\033[36m%s\033[0m\n" "" "-p \"tzone\" [-z [tzone|\"def\"]|-i] |"
                >&2 printf "%23s\033[36m%s\033[0m\n" "" "-p \"memsplit\" [-m [16|32|64|128|256|512|\"def\"]|-i] |"
                >&2 printf "%23s\033[36m%s\033[0m\n" "" "-p \"keyb\" [-k [keyb|\"def\"]|-i] |"
                >&2 printf "%23s\033[36m%s\033[0m\n" "" "-p \"audio\" [-c [\"hdmi\"|\"jack\"|\"def\"]|-i] |"
                >&2 printf "%23s\033[36m%s\033[0m\n" "" "-p \"del_stduser\" [-d [\"yes\"|\"no\"|\"def\"]|-i] |"
                >&2 printf "%23s\033[36m%s\033[0m\n" "" "-p \"overscan\" ['-l [lowerscan|\"def\"]' '-r [rightscan|\"def\"]' '-b [bottomscan|\"def\"]' '-u [upperscan|\"def\"]'|-i] |"
#               >&2 printf "%23s\033[36m%s\033[0m\n" "" "-p \"filesys\" |"
                >&2 printf "%23s\033[36m%s\033[0m\n" "" "-p \"update\" |"
                >&2 printf "%23s\033[36m%s\033[0m\n" "" "-p \"boot\""
		>&2 printf "\n"
		>&2 printf "%3s%s\n" "" "Where -h displays this usage"
                >&2 printf "%9s%s\n" "" "-p specifies the action to take"
                >&2 printf "%12s%s\n" "" "\"all\" allows executing all other functions besides itself, \"savedef\", \"dispdef\" and \"all-usedef\", in a logical order, using all additional parameters provided as needed"
		>&2 printf "%15s%s\n" "" "- When not using interactive mode, all other parameters for this function are required"
		>&2 printf "%15s%s\n" "" "- The order in which all functions will be executed is the following : \"keyb\", \"user\", \"sshkey\", \"locale\", \"tzone\""
#		>&2 printf "%15s%s\n" "" "  \"host\", \"filesys\", \"audio\", \"overscan\", \"memsplit\", \"ssh\", \"update\", \"netwait\", \"bootenv\", \"del_stduser\" and \"boot\""
		>&2 printf "%15s%s\n" "" "  \"host\", \"audio\", \"overscan\", \"memsplit\", \"ssh\", \"update\", \"netwait\", \"bootenv\", \"del_stduser\" and \"boot\""
		>&2 printf "%15s%s\n" "" "- Special remarks for function \"all\" :"
		>&2 printf "%18s%s\n" "" "- Any function that fails will generate an error but further function execution will not be interrupted"
		>&2 printf "%18s%s\n" "" "- A reboot will only be performed once after all functions have concluded instead of at the end of every function requiring a reboot"
		>&2 printf "%15s%s\n" "" "-i allows specifying using interactive mode"
		>&2 printf "%18s%s\n" "" "- The following functions are considered interactive and will always prompt for required info in interactive mode :"
		>&2 printf "%21s%s\n" "" "- \"user\", \"del_stduser\", \"sshkey\", \"locale\", \"keyb\", \"tzone\""
		>&2 printf "%21s%s\n" "" "  \"host\", \"audio\", \"overscan\", \"memsplit\", \"ssh\", \"netwait\" and \"bootenv\""
                >&2 printf "%12s%s\n" "" "\"all-usedef\" functions like \"all\" but runs non-interactively by using the currently stored default values for interactive functions"
                >&2 printf "%15s%s\n" "" "- If no stored default can be found for one or more of the functions, the related function(s) will fail but processing of the remaining function(s) will not be interrupted"
                >&2 printf "%12s%s\n" "" "\"savedef\" allows storing a default value for the parameters required by all interactive functions"
		>&2 printf "%15s%s\n" "" "- An error will be generated when a newly entered default is rejected, but further processing of any remaining default values specified will continue"
		>&2 printf "%15s%s\n" "" "- 'root' cannot be stored as a default value for either [user] or [sshkeyuser]"
		>&2 printf "%15s%s\n" "" "- The string 'def' cannot be used as the default value to store for any parameter"
		>&2 printf "%15s%s\n" "" "- The following rules apply to the 4 overscan parameters :"
		>&2 printf "%18s%s\n" "" "- If non-numeric values are given as default values, a warning will be generated and the values '30' and '16' will be stored instead for bottom and upperscan, or for leftscan and rightscan respectively"
		>&2 printf "%18s%s\n" "" "- A default for each overscan parameter is saved every time this function runs, even when their respective parameters were not passed"
		>&2 printf "%18s%s\n" "" "- If a parameter is passed and the new value given differs from the pre-existing stored default or no default is currently stored, the new value will be stored"
		>&2 printf "%18s%s\n" "" "- If a parameter is passed and the new value given is equal to a pre-existing stored default, no operation is performed"
		>&2 printf "%18s%s\n" "" "- For left and right overscan, if the applicable parameter is not passed and no stored default for it currently exists or is not equal to '16', a new value of '16' will be stored"
		>&2 printf "%18s%s\n" "" "- For upper and bottom overscan, if the applicable parameter is not passed and no stored default for it currently exists or is not equal to '30', a new value of '30' will be stored"
		>&2 printf "%18s%s\n" "" "- For left and right overscan, if the applicable parameter is not passed and has a currently stored default of '16', no operation is performed"
		>&2 printf "%18s%s\n" "" "- For upper and bottom overscan, if the applicable parameter is not passed and has a currently stored default of '30', no operation is performed"
		>&2 printf "%15s%s\n" "" "- For any other parameters, any pre-existing stored defaults, different from the new value entered for the applicable parameter will be replaced by the new value and"
		>&2 printf "%15s%s\n" "" "  no operation will be performed for any pre-existing stored default, equal to the newly entered value for the applicable parameter"
		>&2 printf "%15s%s\n" "" "- When not using interactive mode, any combination of all other parameters can additionally be passed for processing, including none at all"
		>&2 printf "%15s%s\n" "" "-i allows specifying using interactive mode"
		>&2 printf "%18s%s\n" "" "- Optionally, the name of one interactive function can be passed to apply the operation exclusively to the specified function"
		>&2 printf "%18s%s\n" "" "- If an non-interactive function name is given, the operation will fail"
		>&2 printf "%18s%s\n" "" "- If no optional functionname is passed, all interactive functions will prompt for their respective required info and store the newly entered defaults"
                >&2 printf "%12s%s\n" "" "\"dispdef\" allows displaying the currently stored default value for all interactive functions"
                >&2 printf "%12s%s\n" "" "\"ssh\" allows choosing whether to allow or disallow SSH logins to this system for all users except 'root'"
		>&2 printf "%15s%s\n" "" "-s allows selecting either \"allowed\", \"disallowed\" or \"def\""
		>&2 printf "%18s%s\n" "" "- Selecting \"def\" will use the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%15s%s\n" "" "- Using this function will restart the SSH server"
		>&2 printf "%15s%s\n" "" "-i allows specifying using interactive mode"
                >&2 printf "%12s%s\n" "" "\"sshkey\" allows creating a public/private RSA2 keypair for SSH logins for a given user [sshkeyuser]"
		>&2 printf "%15s%s\n" "" "- The public key will be placed in './.ssh/id_rsa.pub' under the home directory of user [sshkeyuser] and automatically be trusted for SSH connections"
		>&2 printf "%15s%s\n" "" "- The private key will be placed in './.ssh/id_rsa' under the home directory of user [sshkeyuser] and can be used to initiate passwordless SSH connections to this machine"
		>&2 printf "%18s%s\n" "" "- To connect passwordless from a windows machine using Putty, the private key needs to be converted to Putty format using puttygen.exe on"
		>&2 printf "%18s%s\n" "" "  a windows machine and the save location of the converted key should be configured in the Putty.exe session manager"
		>&2 printf "%15s%s\n" "" "-t allows passing a value for [sshkeyuser]"
		>&2 printf "%18s%s\n" "" "- [sshkeyuser] must be an existing user and cannot be 'root' or this function will fail"
		>&2 printf "%18s%s\n" "" "- The keyword \"def\" can be used to specify using the stored default value for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%15s%s\n" "" "-i allows specifying using interactive mode"
                >&2 printf "%12s%s\n" "" "\"user\" allows creating/modifying a user account [user] and granting full sudo rights to that account"
		>&2 printf "%15s%s\n" "" "-a allows passing a value for [user]"
		>&2 printf "%18s%s\n" "" "- [user] can be a new account or any already existing account except 'root'"
		>&2 printf "%18s%s\n" "" "- The following rules apply if the value for [user] is an existing account :"
		>&2 printf "%21s%s\n" "" "- If [user] is currently logged in or is 'root', this function will fail"
		>&2 printf "%21s%s\n" "" "- Otherwise, all properties for user [user], except for the password, will be configured as follows :"
		>&2 printf "%24s%s\n" "" "- The primary group for [user] will be set to [user]"
		>&2 printf "%27s%s\n" "" "- If group [user] does not exist, it will be created"
		>&2 printf "%24s%s\n" "" "- The secondary groups for [user] will be set/changed to \"tty\",\"input\",\"audio\" and \"video\" exclusively"
		>&2 printf "%24s%s\n" "" "- The home directory for [user] will be set/changed to '/home/[user]'"
		>&2 printf "%24s%s\n" "" "- The shell for [user] will be set/changed to '/bin/bash'"
		>&2 printf "%24s%s\n" "" "- Full sudo rights will be granted to [user] if not already present"
		>&2 printf "%18s%s\n" "" "- The following rules apply if the value for [user] is a non-existing account :"
		>&2 printf "%21s%s\n" "" "- The primary group for [user] will be set to [user]"
		>&2 printf "%24s%s\n" "" "- If group [user] does not exist, it will be created"
		>&2 printf "%21s%s\n" "" "- The secondary groups for [user] will be set to \"tty\",\"input\",\"audio\" and \"video\" exclusively"
		>&2 printf "%21s%s\n" "" "- The value for [user]'s password will be prompted for"
		>&2 printf "%21s%s\n" "" "- The home directory for [user] will be set to '/home/[user]'"
		>&2 printf "%21s%s\n" "" "- The shell for [user] will be set to '/bin/bash'"
		>&2 printf "%21s%s\n" "" "- Full sudo rights will be granted to [user]"
		>&2 printf "%18s%s\n" "" "- The keyword \"def\" can be used to specify using the stored default value for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%15s%s\n" "" "-i allows specifying using interactive mode"
                >&2 printf "%12s%s\n" "" "\"del_stduser\" allows specifying whether the system's default user account \"$PH_DEF_USER\" should be removed along with"
		>&2 printf "%12s%s\n" "" "  it's home directory, mail spool directory and sudo configuration"
		>&2 printf "%15s%s\n" "" "- If user '$PH_DEF_USER' is currently logged in, this function will fail"
		>&2 printf "%15s%s\n" "" "- If user '$PH_DEF_USER' does not exist, this function will generate a warning"
		>&2 printf "%15s%s\n" "" "-d allows selecting either \"yes\", \"no\" or \"def\""
		>&2 printf "%18s%s\n" "" "- Selecting \"def\" will use the value stored as the default for this parameter"
		>&2 printf "%15s%s\n" "" "-i allows specifying using interactive mode"
                >&2 printf "%12s%s\n" "" "\"netwait\" allows specifying whether the system should wait for networking to be available before continuing the application part of the boot process"
		>&2 printf "%15s%s\n" "" "-w allows selecting either \"enabled\", \"disabled\" or \"def\""
		>&2 printf "%18s%s\n" "" "- Selecting \"def\" will use the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%15s%s\n" "" "-i allows specifying using interactive mode"
                >&2 printf "%12s%s\n" "" "\"host\" allows changing the hostname of this machine to [hostname]"
		>&2 printf "%15s%s\n" "" "-n allows passing a value for [hostname]"
		>&2 printf "%18s%s\n" "" "- The keyword \"def\" can be used to specify using the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%15s%s\n" "" "-i allows specifying using interactive mode"
                >&2 printf "%12s%s\n" "" "\"bootenv\" allows selecting a preferred default environment to start at system boot"
		>&2 printf "%15s%s\n" "" "-e allows selecting either \"cli\", \"gui\" or \"def\""
		>&2 printf "%18s%s\n" "" "- Selecting \"def\" will use the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%15s%s\n" "" "-i allows specifying using interactive mode"
                >&2 printf "%12s%s\n" "" "\"keyb\" allows setting the default keyboard layout to [keyb]"
		>&2 printf "%15s%s\n" "" "-k allows passing a value for [keyb]"
		>&2 printf "%18s%s\n" "" "- The keyword \"def\" can be used to specify using the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%18s%s\n" "" "- The value for [keyb] should be a valid keyboard layout"
		>&2 printf "%18s%s\n" "" "- On Archlinux machines, if the new value specified is different from the currently configured keyboard layout, a reboot is required and will be proposed"
		>&2 printf "%15s%s\n" "" "-i allows specifying using interactive mode"
                >&2 printf "%12s%s\n" "" "\"memsplit\" allows setting the amount of memory, exclusively reserved for the GPU"
		>&2 printf "%15s%s\n" "" "-m allows selecting either \"16\", \"32\", \"64\", \"128\", \"256\" or \"def\""
		>&2 printf "%18s%s\n" "" "- Selecting \"def\" will use the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%18s%s\n" "" "- If the new value is different from the one currently set, activation of the new value requires a system reboot that will be proposed"
		>&2 printf "%15s%s\n" "" "-i allows specifying using interactive mode"
                >&2 printf "%12s%s\n" "" "\"tzone\" allows setting the system's default timezone to [tzone]"
		>&2 printf "%15s%s\n" "" "-z allows passing a value for [tzone]"
		>&2 printf "%18s%s\n" "" "- The keyword \"def\" can be used to specify using the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%18s%s\n" "" "- The value specified for [tzone] should be a valid timezone identifier"
		>&2 printf "%15s%s\n" "" "-i allows specifying using interactive mode"
                >&2 printf "%12s%s\n" "" "\"locale\" allows generating locale [locale] and configuring it as the system's default locale"
		>&2 printf "%15s%s\n" "" "-f allows passing a value for [locale]"
		>&2 printf "%18s%s\n" "" "- [locale] should be specified in the format 'locale.encoding'"
		>&2 printf "%18s%s\n" "" "- The keyword \"def\" can be used to specify using the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%18s%s\n" "" "- The value specified for [newloc] should be a system supported locale"
		>&2 printf "%15s%s\n" "" "-i allows specifying using interactive mode"
                >&2 printf "%12s%s\n" "" "\"audio\" allows forcing audio output to a specific channel"
		>&2 printf "%15s%s\n" "" "-c allows selecting either \"hdmi\", \"jack\" or \"def\""
		>&2 printf "%18s%s\n" "" "- \"jack\" stands for the standard 3.5 inch audio jack"
		>&2 printf "%18s%s\n" "" "- The keyword \"def\" can be used to specify using the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%18s%s\n" "" "- If the new value is different from the one currently configured, activation of the new value requires a system reboot that will be proposed"
		>&2 printf "%15s%s\n" "" "-i allows specifying using interactive mode"
                >&2 printf "%12s%s\n" "" "\"overscan\" allows specifying values to use when correcting left overscan [leftscan], right overscan [rightscan], bottom overscan [bottomscan] and upper overscan [upperscan]"
		>&2 printf "%15s%s\n" "" "- Specifying either of the four overscan function parameters is optional"
		>&2 printf "%18s%s\n" "" "- Any overscan function parameter left unspecified will leave that parameter's currently configured value unchanged"
		>&2 printf "%15s%s\n" "" "-u allows passing a value for [upperscan]"
		>&2 printf "%18s%s\n" "" "- The keyword \"def\" can be used to specify using the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%15s%s\n" "" "-b allows passing a value for [bottomscan]"
		>&2 printf "%18s%s\n" "" "- The keyword \"def\" can be used to specify using the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%15s%s\n" "" "-l allows passing a value for [leftscan]"
		>&2 printf "%18s%s\n" "" "- The keyword \"def\" can be used to specify using the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%15s%s\n" "" "-r allows passing a value for [rightscan]"
		>&2 printf "%18s%s\n" "" "- The keyword \"def\" can be used to specify using the value stored as the default for this parameter"
		>&2 printf "%21s%s\n" "" "- If no stored default value can be found, this function will fail"
		>&2 printf "%15s%s\n" "" "- If the current value of any of the overscan parameters is changed, the new value(s) will only be active after a system reboot that will be proposed"
		>&2 printf "%15s%s\n" "" "-i allows specifying using interactive mode"
#               >&2 printf "%12s%s\n" "" "\"filesys\" allows growing the filesystem of your system to use all available harddisk space"
#		>&2 printf "%15s%s\n" "" "- Running this function more than once will do nothing"
#		>&2 printf "%15s%s\n" "" "- If the filesystem size was changed, the new size will only be available after a system reboot that will be proposed"
                >&2 printf "%12s%s\n" "" "\"update\" allows running a silent update of all packages currently installed on this system"
		>&2 printf "%15s%s\n" "" "- A reboot is recommended (but only required if kernel and/or bootloader/firmware were included in the update) and will always be proposed"
                >&2 printf "%12s%s\n" "" "\"boot\" allows rebooting this system"
		>&2 printf "\n"
		OPTIND="$PH_OLDOPTIND"
		OPTARG="$PH_OLDOPTARG"
		unset PH_USER PH_DEL_PIUSER PH_HOST PH_AUDIO PH_ENV PH_LOCALE PH_TZONE PH_NETWAIT PH_KEYB PH_SSH_STATE PH_VID_MEM
		unset PH_RIGHTSCAN PH_LEFTSCAN PH_BOTTOMSCAN PH_UPPERSCAN PH_SSH_KEY PH_RESULT PH_CHOICE PH_COUNT
		exit 1 ;;
	esac
done
OPTIND="$PH_OLDOPTIND"
OPTARG="$PH_OLDOPTARG"

[[ -z "$PH_ACTION" ]] && (! confoper_ph.sh -h) && exit 1
[[ "$PH_ACTION" == "all-usedef" && "$#" -gt "2" ]] && (! confoper_ph.sh -h) && exit 1
if [[ "$PH_INTERACTIVE_FLAG" -eq "0" ]]
then
	[[ "$PH_ACTION" == "savedef" && "$#" -gt "4" ]] && (! confoper_ph.sh -h) && exit 1
	if [[ "$PH_ACTION" == "savedef" && -n "$4" ]] && [[ "$4" != @(ssh|bootenv|user|del_stduser|host|locale|tzone|overscan|audio|keyb|memsplit|netwait|sshkey) ]]
	then
		(! confoper_ph.sh -h) && exit 1
	fi
else
	[[ "$PH_ACTION" == @(all|user) && -z "$PH_USER" ]] && (! confoper_ph.sh -h) && exit 1
	[[ "$PH_ACTION" == @(all|del_stduser) && -z "$PH_DEL_PIUSER" ]] && (! confoper_ph.sh -h) && exit 1
	[[ "$PH_ACTION" == @(all|sshkey) && -z "$PH_SSH_KEY" ]] && (! confoper_ph.sh -h) && exit 1
	[[ "$PH_ACTION" == @(all|netwait) && -z "$PH_NETWAIT" ]] && (! confoper_ph.sh -h) && exit 1
	[[ "$PH_ACTION" == @(all|host) && -z "$PH_HOST" ]] && (! confoper_ph.sh -h) && exit 1
	[[ "$PH_ACTION" == @(all|memsplit) && -z "$PH_VID_MEM" ]] && (! confoper_ph.sh -h) && exit 1
	[[ "$PH_ACTION" == @(all|ssh) && -z "$PH_SSH_STATE" ]] && (! confoper_ph.sh -h) && exit 1
	[[ "$PH_ACTION" == @(all|bootenv) && -z "$PH_ENV" ]] && (! confoper_ph.sh -h) && exit 1
	[[ "$PH_ACTION" == @(all|audio) && -z "$PH_AUDIO" ]] && (! confoper_ph.sh -h) && exit 1
	[[ "$PH_ACTION" == @(all|tzone) && -z "$PH_TZONE" ]] && (! confoper_ph.sh -h) && exit 1
fi
[[ -n "$PH_TZONE" && "$PH_ACTION" != @(all|savedef|tzone) ]] && (! confoper_ph.sh -h) && exit 1
[[ -n "$PH_ENV" && "$PH_ACTION" != @(all|savedef|bootenv) ]] && (! confoper_ph.sh -h) && exit 1
[[ -n "$PH_USER" && "$PH_ACTION" != @(all|savedef|user) ]] && (! confoper_ph.sh -h) && exit 1
[[ -n "$PH_DEL_PIUSER" && "$PH_ACTION" != @(all|savedef|del_stduser) ]] && (! confoper_ph.sh -h) && exit 1
[[ -n "$PH_SSH_KEY" && "$PH_ACTION" != @(all|savedef|sshkey) ]] && (! confoper_ph.sh -h) && exit 1
[[ -n "$PH_HOST" && "$PH_ACTION" != @(all|savedef|host) ]] && (! confoper_ph.sh -h) && exit 1
[[ -n "$PH_NETWAIT" && "$PH_ACTION" != @(all|savedef|netwait) ]] && (! confoper_ph.sh -h) && exit 1
[[ -n "$PH_LOCALE" && "$PH_ACTION" != @(all|savedef|locale) ]] && (! confoper_ph.sh -h) && exit 1
[[ -n "$PH_KEYB" && "$PH_ACTION" != @(all|savedef|keyb) ]] && (! confoper_ph.sh -h) && exit 1
[[ -n "$PH_AUDIO" && "$PH_ACTION" != @(all|savedef|audio) ]] && (! confoper_ph.sh -h) && exit 1
[[ -n "$PH_SSH_STATE" && "$PH_ACTION" != @(all|savedef|ssh) ]] && (! confoper_ph.sh -h) && exit 1
[[ -n "$PH_VID_MEM" && "$PH_ACTION" != @(all|savedef|memsplit) ]] && (! confoper_ph.sh -h) && exit 1
if [[ -n "$PH_RIGHTSCAN" || -n "$PH_LEFTSCAN" ]] && [[ "$PH_ACTION" != @(all|savedef|overscan) ]]
then
	(! confoper_ph.sh -h) && exit 1
fi
if [[ -n "$PH_BOTTOMSCAN" || -n "$PH_UPPERSCAN" ]] && [[ "$PH_ACTION" != @(all|savedef|overscan) ]]
then
	(! confoper_ph.sh -h) && exit 1
fi
[[ "$PH_INTERACTIVE_FLAG" -eq "0" && "$PH_ACTION" == @(filesys|update|boot|dispdef|all-usedef) ]] && (! confoper_ph.sh -h) && exit 1
if [[ "$PH_INTERACTIVE_FLAG" -eq "0" ]]
then
	[[ -n "$PH_USER" || -n "$PH_TZONE" || -n "$PH_SSH_STATE" || -n "$PH_AUDIO" || -n "$PH_HOST" || -n "$PH_ENV" || -n "$PH_LOCALE" || -n "$PH_KEYB" ]] && (! confoper_ph.sh -h) && exit 1
	[[ -n "$PH_VID_MEM" || -n "$PH_LEFTSCAN" || -n "$PH_BOTTOMSCAN" || -n "$PH_UPPERSCAN" || -n "$PH_DEL_PIUSER" || -n "$PH_NETWAIT" || -n "$PH_SSH_KEY" ]] && (! confoper_ph.sh -h) && exit 1
fi

if [[ "$(cat /proc/"$PPID"/comm 2>/dev/null)" != "confoper_ph.sh" ]]
then
	printf "\n\033[36m%s\033[0m\n\n" "- Checking prerequisites for system configuration"
	printf "%8s%s\n" "" "--> Checking run account"
	[[ "$(whoami)" == "root" ]] && printf "%10s\033[32m%s\033[0m\n" "" "OK (root)" || (>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : confoper_ph.sh must be run as root" ; >&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" ; exit 1) || exit "$?"
	printf "%2s\033[32m%s\033[0m\n\n" "" "SUCCESS"
	printf "\033[36m%s\033[0m\n\n" "- Checking prerequisites for PieHelper"
	printf "%8s%s\n" "" "--> Checking for presence of /proc filesystem"
	if mount 2>/dev/null | grep ^"proc on /proc type proc" >/dev/null
	then
        	printf "%10s\033[32m%s\033[0m\n" "" "OK (Found)"
	else
		>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Not found"
		>&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED"
		exit 1
	fi
	for PH_i in sudo alsa-utils tzdata $PH_KEYB_PKGS
	do
		printf "%8s%s\n" "" "--> Checking for '$PH_i' package"
		if ph_get_pkg_inst_state "$PH_i"
		then
			printf "%10s\033[32m%s\033[0m\n" "" "OK (Found)"
		else
			printf "%10s\033[33m%s\033[0m\n" "" "Warning : Not found -> Installing"
			printf "%8s%s\n" "" "--> Installing $PH_i"
			if ph_install_pkg "$PH_i"
			then
				printf "%10s\033[32m%s\033[0m\n" "" "OK"
			else
				>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not install $PH_i"
				>&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED"
				exit 1
			fi
		fi
	done
	printf "%8s%s\n" "" "--> Checking for systemd service management"
	[[ -f "$(which systemctl 2>/dev/null)" ]] && printf "%10s\033[32m%s\033[0m\n" "" "OK (Found)" || (>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Not found" ; >&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" ; exit 1) || exit "$?"
	printf "%8s%s\n" "" "--> Checking for package manager"
	if [[ -f /usr/bin/pacman || -f /usr/bin/apt-get ]]
	then
		[[ -f /usr/bin/apt-get ]] && printf "%10s\033[32m%s\033[0m\n" "" "OK (apt-get)" || printf "%10s\033[32m%s\033[0m\n" "" "OK (pacman)"
	else
		>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Not found"
		>&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED"
		exit 1
	fi
	printf "%2s\033[32m%s\033[0m\n\n" "" "SUCCESS"
fi
if [[ "$PH_SSH_KEY" == "root" ]]
then
	if [[ "$PH_INTERACTIVE_FLAG" -eq "1" ]]
	then
		printf "\033[36m%s\033[0m\n" "- Executing function '$PH_ACTION' (Normal mode)"
	else
		printf "\033[36m%s\033[0m\n" "- Executing function '$PH_ACTION' (Interactive mode)"
	fi
	>&2 printf "%2s\033[31m%s\033[0m%s\n\n" "" "FAILED" " : Creating a public/private keypair for 'root' is not permitted"
	exit 1
fi
if [[ "$PH_USER" == "root" ]]
then
	if [[ "$PH_INTERACTIVE_FLAG" -eq "1" ]]
	then
		printf "\033[36m%s\033[0m\n" "- Executing function '$PH_ACTION' (Normal mode)"
	else
		printf "\033[36m%s\033[0m\n" "- Executing function '$PH_ACTION' (Interactive mode)"
	fi
	>&2 printf "%2s\033[31m%s\033[0m%s\n\n" "" "FAILED" " : Modifying the 'root' account is not permitted"
	exit 1
fi
if [[ "$PH_ACTION" == @(locale|savedef) ]] && [[ "$PH_LOCALE" != "def" && -n "$PH_LOCALE" ]]
then
	if [[ "$PH_INTERACTIVE_FLAG" -eq "1" ]]
	then
		if ! ph_check_locale_validity "$PH_LOCALE"
		then
			printf "\033[36m%s\033[0m\n" "- Executing function '$PH_ACTION' (Normal mode)"
			>&2 printf "%2s\033[31m%s\033[0m%s\n\n" "" "FAILED" " : Not a system supported locale"
			exit 1
		fi
	fi
fi
if [[ "$PH_ACTION" == @(tzone|savedef) ]] && [[ "$PH_TZONE" != "def" && -n "$PH_TZONE" ]]
then
	if [[ "$PH_INTERACTIVE_FLAG" -eq "1" ]]
	then
		if ! ph_check_tzone_validity "$PH_TZONE"
		then
			printf "\033[36m%s\033[0m\n" "- Executing function '$PH_ACTION' (Normal mode)"
			>&2 printf "%2s\033[31m%s\033[0m%s\n\n" "" "FAILED" " : Invalid timezone identifier specified"
			exit 1
		fi
	fi
fi
if [[ "$PH_ACTION" == @(keyb|savedef) ]] && [[ "$PH_KEYB" != "def" && -n "$PH_KEYB" ]]
then
	if [[ "$PH_INTERACTIVE_FLAG" -eq "1" ]]
	then
		if ! ph_check_keyb_layout_validity "$PH_KEYB"
		then
			printf "\033[36m%s\033[0m\n" "- Executing function '$PH_ACTION' (Normal mode)"
			>&2 printf "%2s\033[31m%s\033[0m%s\n\n" "" "FAILED" " : Invalid keyboard layout specified"
			exit 1
		fi
	fi
fi
if [[ "$PH_ACTION" == @(sshkey|savedef) ]] && [[ "$PH_SSH_KEY" != "def" && -n "$PH_SSH_KEY" ]]
then
	if [[ "$PH_INTERACTIVE_FLAG" -eq "1" ]]
	then
		if ! ph_check_user_state "$PH_SSH_KEY"
		then
			printf "\033[36m%s\033[0m\n" "- Executing function '$PH_ACTION' for user '$PH_SSH_KEY' (Normal mode)"
			>&2 printf "%2s\033[31m%s\033[0m%s\n\n" "" "FAILED" " : User does not exist"
			exit 1
		fi
	fi
fi
if [[ "$PH_ACTION" == "user" ]]
then
	if who -us 2>/dev/null | nawk '{ print $1 }' 2>/dev/null | grep ^"$PH_USER"$ >/dev/null 2>&1
	then
		if [[ "$PH_INTERACTIVE_FLAG" -eq "1" ]]
		then
			printf "\033[36m%s\033[0m\n" "- Executing function '$PH_ACTION' for user '$PH_USER' (Normal mode)"
		else
			printf "\033[36m%s\033[0m\n" "- Executing function '$PH_ACTION' for user '$PH_USER' (Interactive mode)"
		fi
		>&2 printf "%2s\033[31m%s\033[0m%s\n\n" "" "FAILED" " : User is currently logged in"
		exit 1
	fi
fi
if [[ "$PH_ACTION" == "del_stduser" ]]
then
	if who -us 2>/dev/null | nawk '{ print $1 }' 2>/dev/null | grep ^"$PH_DEF_USER"$ >/dev/null 2>&1
	then
		if [[ "$PH_INTERACTIVE_FLAG" -eq "1" ]]
		then
			printf "\033[36m%s\033[0m\n" "- Executing function '$PH_ACTION' for user '$PH_DEF_USER' (Normal mode)"
		else
			printf "\033[36m%s\033[0m\n" "- Executing function '$PH_ACTION' for user '$PH_DEF_USER' (Interactive mode)"
		fi
		>&2 printf "%2s\033[31m%s\033[0m%s\n\n" "" "FAILED" " : User is currently logged in"
		exit 1
	fi
fi
case $PH_ACTION in all)
	if [[ "$PH_INTERACTIVE_FLAG" -eq "0" ]]
	then
		"$PH_SCRIPTS_DIR"/confoper_ph.sh -p keyb -i
		ph_set_result -r "$?"
		"$PH_SCRIPTS_DIR"/confoper_ph.sh -p user -i
		ph_set_result -r "$?"
		"$PH_SCRIPTS_DIR"/confoper_ph.sh -p sshkey -i
		ph_set_result -r "$?"
		"$PH_SCRIPTS_DIR"/confoper_ph.sh -p locale -i
		ph_set_result -r "$?"
		"$PH_SCRIPTS_DIR"/confoper_ph.sh -p tzone -i
		ph_set_result -r "$?"
		"$PH_SCRIPTS_DIR"/confoper_ph.sh -p host -i
		ph_set_result -r "$?"
#		"$PH_SCRIPTS_DIR"/confoper_ph.sh -p filesys
#		ph_set_result -r "$?"
		"$PH_SCRIPTS_DIR"/confoper_ph.sh -p audio -i
		ph_set_result -r "$?"
		"$PH_SCRIPTS_DIR"/confoper_ph.sh -p overscan -i
		ph_set_result -r "$?"
		"$PH_SCRIPTS_DIR"/confoper_ph.sh -p memsplit -i
		ph_set_result -r "$?"
		"$PH_SCRIPTS_DIR"/confoper_ph.sh -p ssh -i
		ph_set_result -r "$?"
		"$PH_SCRIPTS_DIR"/confoper_ph.sh -p update
		ph_set_result -r "$?"
		"$PH_SCRIPTS_DIR"/confoper_ph.sh -p netwait -i
		ph_set_result -r "$?"
		"$PH_SCRIPTS_DIR"/confoper_ph.sh -p bootenv -i
		ph_set_result -r "$?"
		"$PH_SCRIPTS_DIR"/confoper_ph.sh -p del_stduser -i
		ph_set_result -r "$?"
	else
		"$PH_SCRIPTS_DIR"/confoper_ph.sh -p keyb -k "$PH_KEYB"
		ph_set_result -r "$?"
		"$PH_SCRIPTS_DIR"/confoper_ph.sh -p user -a "$PH_USER"
		ph_set_result -r "$?"
		"$PH_SCRIPTS_DIR"/confoper_ph.sh -p sshkey -t "$PH_SSH_KEY"
		ph_set_result -r "$?"
		"$PH_SCRIPTS_DIR"/confoper_ph.sh -p locale -f "$PH_LOCALE"
		ph_set_result -r "$?"
		"$PH_SCRIPTS_DIR"/confoper_ph.sh -p tzone -z "$PH_TZONE"
		ph_set_result -r "$?"
		"$PH_SCRIPTS_DIR"/confoper_ph.sh -p host -n "$PH_HOST"
		ph_set_result -r "$?"
#		"$PH_SCRIPTS_DIR"/confoper_ph.sh -p filesys
#		ph_set_result -r "$?"
		"$PH_SCRIPTS_DIR"/confoper_ph.sh -p audio -c "$PH_AUDIO"
		ph_set_result -r "$?"
		"$PH_SCRIPTS_DIR"/confoper_ph.sh -p overscan -u "$PH_UPPERSCAN" -b "$PH_BOTTOMSCAN" -l "$PH_LEFTSCAN" -r "$PH_RIGHTSCAN"
		ph_set_result -r "$?"
		"$PH_SCRIPTS_DIR"/confoper_ph.sh -p memsplit -m "$PH_VID_MEM"
		ph_set_result -r "$?"
		"$PH_SCRIPTS_DIR"/confoper_ph.sh -p ssh -s "$PH_SSH_STATE"
		ph_set_result -r "$?"
		"$PH_SCRIPTS_DIR"/confoper_ph.sh -p update
		ph_set_result -r "$?"
		"$PH_SCRIPTS_DIR"/confoper_ph.sh -p netwait -w "$PH_NETWAIT"
		ph_set_result -r "$?"
		"$PH_SCRIPTS_DIR"/confoper_ph.sh -p bootenv -e "$PH_ENV"
		ph_set_result -r "$?"
		"$PH_SCRIPTS_DIR"/confoper_ph.sh -p del_stduser -d "$PH_DEL_PIUSER"
		ph_set_result -r "$?"
	fi
	[[ "$PH_RESULT" == "SUCCESS" ]] && printf "%2s\033[32m%s\033[0m\n\n" "" "Total : $PH_RESULT" || >&2 printf "%2s%s\033[31m%s\033[0m\n\n" "" "Total : " "$PH_RESULT"
	"$PH_SCRIPTS_DIR"/confoper_ph.sh -p boot ;;
	     all-usedef)
	"$PH_SCRIPTS_DIR"/confoper_ph.sh -p keyb -k def
	ph_set_result -r "$?"
	"$PH_SCRIPTS_DIR"/confoper_ph.sh -p user -a def
	ph_set_result -r "$?"
	"$PH_SCRIPTS_DIR"/confoper_ph.sh -p sshkey -t def
	ph_set_result -r "$?"
	"$PH_SCRIPTS_DIR"/confoper_ph.sh -p locale -f def
	ph_set_result -r "$?"
	"$PH_SCRIPTS_DIR"/confoper_ph.sh -p tzone -z def
	ph_set_result -r "$?"
	"$PH_SCRIPTS_DIR"/confoper_ph.sh -p host -n def
	ph_set_result -r "$?"
#	"$PH_SCRIPTS_DIR"/confoper_ph.sh -p filesys
#	ph_set_result -r "$?"
	"$PH_SCRIPTS_DIR"/confoper_ph.sh -p audio -c def
	ph_set_result -r "$?"
	"$PH_SCRIPTS_DIR"/confoper_ph.sh -p overscan -u def -b def -l def -r def
	ph_set_result -r "$?"
	"$PH_SCRIPTS_DIR"/confoper_ph.sh -p memsplit -m def
	ph_set_result -r "$?"
	"$PH_SCRIPTS_DIR"/confoper_ph.sh -p ssh -s def
	ph_set_result -r "$?"
	"$PH_SCRIPTS_DIR"/confoper_ph.sh -p update
	ph_set_result -r "$?"
	"$PH_SCRIPTS_DIR"/confoper_ph.sh -p netwait -w def
	ph_set_result -r "$?"
	"$PH_SCRIPTS_DIR"/confoper_ph.sh -p bootenv -e def
	ph_set_result -r "$?"
	"$PH_SCRIPTS_DIR"/confoper_ph.sh -p del_stduser -d def
	ph_set_result -r "$?"
	printf "\n"
	[[ "$PH_RESULT" == "SUCCESS" ]] && printf "%2s\033[32m%s\033[0m\n\n" "" "Total : $PH_RESULT" || >&2 printf "%2s%s\033[31m%s\033[0m\n\n" "" "Total : " "$PH_RESULT"
	"$PH_SCRIPTS_DIR"/confoper_ph.sh -p boot ;;
		dispdef)
	printf "\033[36m%s\033[0m\n" "- Executing function '$PH_ACTION'"
	for PH_i in PH_USER PH_DEL_PIUSER PH_LOCALE PH_KEYB PH_TZONE PH_HOST PH_AUDIO PH_BOTTOMSCAN PH_UPPERSCAN PH_RIGHTSCAN PH_LEFTSCAN PH_VID_MEM PH_SSH_STATE PH_NETWAIT PH_ENV PH_SSH_KEY
	do
		case "$PH_i" in PH_USER)
				printf "%8s%s\n" "" "--> Displaying stored default value for the 'create new user/modify existing user' operation" ;;
			    PH_DEL_PIUSER)
				printf "%8s%s\n" "" "--> Displaying stored default value for the 'delete standard user $PH_DEF_USER' operation" ;;
				PH_LOCALE)
				printf "%8s%s\n" "" "--> Displaying stored default value for the system's locale" ;;
				  PH_KEYB)
				printf "%8s%s\n" "" "--> Displaying stored default value for the keyboard layout" ;;
				 PH_TZONE)
				printf "%8s%s\n" "" "--> Displaying stored default value for the system's timezone" ;;
				  PH_HOST)
				printf "%8s%s\n" "" "--> Displaying stored default value for the system's hostname" ;;
				 PH_AUDIO)
				printf "%8s%s\n" "" "--> Displaying stored default value for the audio channel" ;;
			    PH_BOTTOMSCAN)
				printf "%8s%s\n" "" "--> Displaying stored default value for the bottom overscan" ;;
			     PH_UPPERSCAN)
				printf "%8s%s\n" "" "--> Displaying stored default value for the upper overscan" ;;
			     PH_RIGHTSCAN)
				printf "%8s%s\n" "" "--> Displaying stored default value for the right overscan" ;;
			      PH_LEFTSCAN)
				printf "%8s%s\n" "" "--> Displaying stored default value for the left overscan" ;;
			       PH_VID_MEM)	
				printf "%8s%s\n" "" "--> Displaying stored default value for the 'memory amount exclusively reserved for the GPU'" ;;
			     PH_SSH_STATE)
				printf "%8s%s\n" "" "--> Displaying stored default value for the state of SSH" ;;
			       PH_SSH_KEY)
				printf "%8s%s\n" "" "--> Displaying stored default value for the user account for which to create a public/private keypair" ;;
			       PH_ENV)
				printf "%8s%s\n" "" "--> Displaying stored default value for the default boot environment" ;;
			       PH_NETWAIT)
				printf "%8s%s\n" "" "--> Displaying stored default value for 'wait for network on boot'" ;;
		esac
		if [[ -z "$(nawk -F\' -v opt=^"$PH_i="$ '$1 ~ opt { print $2 }' "$PH_CONF_DIR"/OS.defaults)" ]]
		then
			printf "%10s%s\n" "" "No stored default value found"
		else
			printf "%10s%s\n" "" "$(nawk -F\' -v opt=^"$PH_i="$ '$1 ~ opt { print $2 }' "$PH_CONF_DIR"/OS.defaults)"
		fi
	done
	printf "%2s\033[32m%s\033[0m\n\n" "" "SUCCESS" ;;
		savedef)
	if [[ "$PH_INTERACTIVE_FLAG" -eq "1" ]]
	then
		printf "\033[36m%s\033[0m\n" "- Executing function '$PH_ACTION' (Normal mode)"
	else
		printf "\033[36m%s\033[0m\n" "- Executing function '$PH_ACTION' (Interactive mode)"
	fi
	if [[ $# -eq 2 ]]
	then
		PH_FUNCTIONS="PH_BOTTOMSCAN PH_UPPERSCAN PH_RIGHTSCAN PH_LEFTSCAN"
		PH_COUNT2=4
	else
		if [[ "$PH_INTERACTIVE_FLAG" -eq "0" ]]
		then
			if [[ -z "$4" ]]
			then
				PH_FUNCTIONS="PH_SSH_STATE PH_USER PH_HOST PH_VID_MEM PH_AUDIO PH_TZONE PH_KEYB PH_ENV PH_DEL_PIUSER PH_BOTTOMSCAN PH_UPPERSCAN PH_RIGHTSCAN PH_LEFTSCAN PH_NETWAIT PH_LOCALE PH_SSH_KEY"
			else
				PH_FUNCTIONS="PH_BOTTOMSCAN PH_UPPERSCAN PH_RIGHTSCAN PH_LEFTSCAN"
				case "$4" in user)
					PH_FUNCTIONS="$PH_FUNCTIONS PH_USER" ;;
					     del_stduser)
					PH_FUNCTIONS="$PH_FUNCTIONS PH_DEL_PIUSER" ;;
			 		     locale)
					PH_FUNCTIONS="$PH_FUNCTIONS PH_LOCALE" ;;
		 			     keyb)
					PH_FUNCTIONS="$PH_FUNCTIONS PH_KEYB" ;;
					     tzone)
					PH_FUNCTIONS="$PH_FUNCTIONS PH_TZONE" ;;
					     host)
					PH_FUNCTIONS="$PH_FUNCTIONS PH_HOST" ;;
					     audio)
					PH_FUNCTIONS="$PH_FUNCTIONS PH_AUDIO" ;;
					     overscan)
					: ;;
					     memsplit)	
					PH_FUNCTIONS="$PH_FUNCTIONS PH_VID_MEM" ;;
					     ssh)
					PH_FUNCTIONS="$PH_FUNCTIONS PH_SSH_STATE" ;;
					     bootenv)
					PH_FUNCTIONS="$PH_FUNCTIONS PH_ENV" ;;
					     netwait)
					PH_FUNCTIONS="$PH_FUNCTIONS PH_NETWAIT" ;;
					     sshkey)
					PH_FUNCTIONS="$PH_FUNCTIONS PH_SSH_KEY" ;;
				esac
			fi
			PH_COUNT2="$(echo -n "$PH_FUNCTIONS" | nawk 'BEGIN { RS = " " } { next } END { print NR }')"
			for PH_i in `echo -n "$PH_FUNCTIONS"`
			do
				PH_COUNT="$((PH_COUNT+1))"
				PH_ANSWER=""
				while [[ -z "$PH_ANSWER" ]]
				do
					case "$PH_i" in PH_USER)
						printf "%8s%s" "" "--> Please enter the default non-root account to store for the 'create new user/modify existing user' operation : " ;;
							PH_DEL_PIUSER)
						printf "%8s%s" "" "--> Please choose the default to store for the 'delete standard user $PH_DEF_USER' operation : "
						ph_present_list PH_DEL_PIUSER ;;
							PH_LOCALE)
						printf "%8s%s" "" "--> Please choose the default to store for the 'configure system locale' operation : "
						ph_present_list PH_LOCALE ;;
		 					PH_KEYB)
						printf "%8s%s" "" "--> Please choose the default to store for the 'configure keyboard layout' operation : "
						ph_present_list PH_KEYB ;;
							PH_TZONE)
						printf "%8s%s" "" "--> Please choose the default to store for the 'configure system timezone' operation : "
						ph_present_list PH_TZONE ;;
							PH_HOST)
						printf "%8s%s" "" "--> Please choose the default to store for the 'configure system hostname' operation : " ;;
							PH_AUDIO)
						printf "%8s%s" "" "--> Please choose the default to store for the 'configure audio channel' operation : "
						ph_present_list PH_AUDIO ;;
							PH_BOTTOMSCAN)
						printf "%8s%s" "" "--> Please enter the default to store for overscan bottom (must be numeric or empty (empty defaults to '30')) : " ;;
							PH_UPPERSCAN)
						printf "%8s%s" "" "--> Please enter the default to store for overscan upper (must be numeric or empty (empty defaults to '30')) : " ;;
							PH_RIGHTSCAN)
						printf "%8s%s" "" "--> Please enter the default to store for overscan right (must be numeric or empty (empty defaults to '16')) : " ;;
							PH_LEFTSCAN)
						printf "%8s%s" "" "--> Please enter the default to store for overscan left (must be numeric or empty (empty defaults to '16')) : " ;;
							PH_VID_MEM)	
						printf "%8s%s" "" "--> Please choose the default to store for the 'configure amount of memory, exclusively reserved for the GPU' operation : "
						ph_present_list PH_VID_MEM ;;
							PH_SSH_STATE)
						printf "%8s%s" "" "--> Please choose the default to store for the 'configure SSH state' operation : "
						ph_present_list PH_SSH_STATE ;;
							PH_SSH_KEY)
						printf "%8s%s" "" "--> Please choose the default non-root account to store for the 'generate sshkey for user' operation : "
						ph_present_list PH_SSH_KEY ;;
							PH_ENV)
						printf "%8s%s" "" "--> Please choose the default to store for the 'configure default boot environment' operation : "
						ph_present_list PH_ENV ;;
							PH_NETWAIT)
						printf "%8s%s" "" "--> Please choose the default to store for the 'wait for network on boot' operation : "
						ph_present_list PH_NETWAIT ;;
					esac
					if [[ "$PH_i" == @(PH_USER|PH_HOST|PH_LEFTSCAN|PH_RIGHTSCAN|PH_BOTTOMSCAN|PH_UPPERSCAN) ]]
					then
						read -r PH_ANSWER 2>/dev/null
					else
						PH_ANSWER="$PH_CHOICE"
					fi
					case "$PH_i" in PH_USER)
						if ph_screen_input "$PH_ANSWER"
						then
							if [[ "$PH_ANSWER" == @(root|def) ]]
							then
								>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Cannot accept a default value of 'root' or 'def'"
								PH_RET_CODE=1
								PH_FUNCTIONS=`echo -n "$PH_FUNCTIONS" | sed 's/ PH_USER / /g;s/^PH_USER //g;s/ PH_USER$//g;s/^PH_USER$//g'`
								break
							else
								[[ -n "$PH_ANSWER" ]] && PH_USER="$PH_ANSWER" && printf "%10s\033[32m%s\033[0m\n" "" "OK" && PH_RET_CODE="0" && break
							fi
						else
							exit 1
						fi ;;
							PH_DEL_PIUSER)
						PH_DEL_PIUSER="$PH_CHOICE" && printf "%10s\033[32m%s\033[0m\n" "" "OK" && PH_RET_CODE="0" && break ;;
							PH_LOCALE)
						PH_LOCALE="$PH_CHOICE" && printf "%10s\033[32m%s\033[0m\n" "" "OK" && PH_RET_CODE="0" && break ;;
		 					PH_KEYB)
						PH_KEYB="$PH_CHOICE" && printf "%10s\033[32m%s\033[0m\n" "" "OK" && PH_RET_CODE="0" && break ;;
							PH_TZONE)
						PH_TZONE="$PH_CHOICE" && printf "%10s\033[32m%s\033[0m\n" "" "OK" && PH_RET_CODE="0" && break ;;
							PH_HOST)
						if ph_screen_input "$PH_ANSWER"
						then
							if [[ "$PH_ANSWER" == "def" ]]
							then
								>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Cannot accept a default value of 'def'"
								PH_RET_CODE="1"
								PH_FUNCTIONS="$(echo -n "$PH_FUNCTIONS" | sed 's/ PH_HOST / /g;s/^PH_HOST //g;s/ PH_HOST$//g;s/^PH_HOST$//g')"
								break
							else
								[[ -n "$PH_ANSWER" ]] && PH_HOST="$PH_ANSWER" && printf "%10s\033[32m%s\033[0m\n" "" "OK" && PH_RET_CODE="0" && break
							fi
						else
							exit 1
						fi ;;
							PH_AUDIO)
						PH_AUDIO="$PH_CHOICE" && printf "%10s\033[32m%s\033[0m\n" "" "OK" && PH_RET_CODE="0" && break ;;
							PH_BOTTOMSCAN)
						if [[ "$PH_ANSWER" == @(+([[:digit:]])|) ]]
						then
							PH_BOTTOMSCAN="$PH_ANSWER" && printf "%10s\033[32m%s\033[0m\n" "" "OK" && PH_RET_CODE="0" && break
						else
							[[ -n "$PH_ANSWER" ]] && printf "%10s\033[33m%s\033[0m\n" "" "Warning : Cannot accept a default value of '$PH_ANSWER' (Not a numeric value) -> Defaulting to '30'" && PH_RET_CODE="0" && break
						fi ;;
							PH_UPPERSCAN)
						if [[ "$PH_ANSWER" == @(+([[:digit:]])|) ]]
						then
							PH_UPPERSCAN="$PH_ANSWER" && printf "%10s\033[32m%s\033[0m\n" "" "OK" && PH_RET_CODE="0" && break
						else
							[[ -n "$PH_ANSWER" ]] && printf "%10s\033[33m%s\033[0m\n" "" "Warning : Cannot accept a default value of '$PH_ANSWER' (Not a numeric value) -> Defaulting to '30'" && PH_RET_CODE="0" && break
						fi ;;
							PH_RIGHTSCAN)
						if [[ "$PH_ANSWER" == @(+([[:digit:]])|) ]]
						then
							PH_RIGHTSCAN="$PH_ANSWER" && printf "%10s\033[32m%s\033[0m\n" "" "OK" && PH_RET_CODE="0" && break
						else
							[[ -n "$PH_ANSWER" ]] && printf "%10s\033[33m%s\033[0m\n" "" "Warning : Cannot accept a default value of '$PH_ANSWER' (Not a numeric value) -> Defaulting to '16'" && PH_RET_CODE="0" && break
						fi ;;
							PH_LEFTSCAN)
						if [[ "$PH_ANSWER" == @(+([[:digit:]])|) ]]
						then
							PH_LEFTSCAN="$PH_ANSWER" && printf "%10s\033[32m%s\033[0m\n" "" "OK" && PH_RET_CODE="0" && break
						else
							[[ -n "$PH_ANSWER" ]] && printf "%10s\033[33m%s\033[0m\n" "" "Warning : Cannot accept a default value of '$PH_ANSWER' (Not a numeric value) -> Defaulting to '16'" && PH_RET_CODE="0" && break
						fi ;;
							PH_VID_MEM)	
						PH_VID_MEM="$PH_CHOICE" && printf "%10s\033[32m%s\033[0m\n" "" "OK" && PH_RET_CODE="0" && break ;;
							PH_SSH_STATE)
						PH_SSH_STATE="$PH_CHOICE" && printf "%10s\033[32m%s\033[0m\n" "" "OK" && PH_RET_CODE="0" && break ;;
							PH_SSH_KEY)
						PH_SSH_KEY="$PH_CHOICE" && printf "%10s\033[32m%s\033[0m\n" "" "OK" && PH_RET_CODE="0" && break ;;
							PH_ENV)
						PH_ENV="$PH_CHOICE" && printf "%10s\033[32m%s\033[0m\n" "" "OK" && PH_RET_CODE="0" && break ;;
							PH_NETWAIT)
						PH_NETWAIT="$PH_CHOICE" && printf "%10s\033[32m%s\033[0m\n" "" "OK" && PH_RET_CODE="0" && break ;;
					esac
					PH_ANSWER=""
					>&2 printf "\n%10s\033[31m%s\033[0m%s\n\n" "" "ERROR" " : $PH_MESSAGE"
				done
				ph_set_result -r "$PH_RET_CODE"
			done
		else
			PH_FUNCTIONS="PH_BOTTOMSCAN PH_UPPERSCAN PH_RIGHTSCAN PH_LEFTSCAN"
			[[ -n "$PH_SSH_STATE" ]] && PH_FUNCTIONS="$PH_FUNCTIONS PH_SSH_STATE"
			[[ -n "$PH_USER" ]] && PH_FUNCTIONS="$PH_FUNCTIONS PH_USER"
			[[ -n "$PH_HOST" ]] && PH_FUNCTIONS="$PH_FUNCTIONS PH_HOST"
			[[ -n "$PH_VID_MEM" ]] && PH_FUNCTIONS="$PH_FUNCTIONS PH_VID_MEM"
			[[ -n "$PH_AUDIO" ]] && PH_FUNCTIONS="$PH_FUNCTIONS PH_AUDIO"
			[[ -n "$PH_TZONE" ]] && PH_FUNCTIONS="$PH_FUNCTIONS PH_TZONE"
			[[ -n "$PH_KEYB" ]] && PH_FUNCTIONS="$PH_FUNCTIONS PH_KEYB"
			[[ -n "$PH_ENV" ]] && PH_FUNCTIONS="$PH_FUNCTIONS PH_ENV"
			[[ -n "$PH_DEL_PIUSER" ]] && PH_FUNCTIONS="$PH_FUNCTIONS PH_DEL_PIUSER"
			[[ -n "$PH_NETWAIT" ]] && PH_FUNCTIONS="$PH_FUNCTIONS PH_NETWAIT"
			[[ -n "$PH_SSH_KEY" ]] && PH_FUNCTIONS="$PH_FUNCTIONS PH_SSH_KEY"
			[[ -n "$PH_LOCALE" ]] && PH_FUNCTIONS="$PH_FUNCTIONS PH_LOCALE"
			PH_COUNT2="$(echo -n "$PH_FUNCTIONS" 2>/dev/null | nawk 'BEGIN { RS = " " } { next } END { print NR }')"
                	for PH_i in `echo -n "$PH_FUNCTIONS"`
                	do
				PH_COUNT="$((PH_COUNT+1))"
				if [[ "$PH_i" == @(PH_USER|PH_SSH_KEY) && "$(eval echo -n \"\$PH_i\")" == @(root|def) ]]
				then
					>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Cannot accept a default value of 'root' or 'def'"
					PH_RET_CODE="1"
					PH_FUNCTIONS="$(echo -n "$PH_FUNCTIONS" | sed 's/ '"$PH_i"' / /g;s/^'"$PH_i"' //g;s/ '"$PH_i"'$//g;s/^'"$PH_i"'$//g')"
				else
					if [[ "$(eval echo -n \"\$PH_i\")" == @(root|def) ]]
					then
						>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Cannot accept a default value of 'def'"
						PH_RET_CODE="1"
						PH_FUNCTIONS="$(echo -n "$PH_FUNCTIONS" | sed 's/ '"$PH_i"' / /g;s/^'"$PH_i"' //g;s/ '"$PH_i"'$//g;s/^'"$PH_i"'$//g')"
					else
						PH_RET_CODE="0"
					fi
				fi
				ph_set_result -r "$PH_RET_CODE"
			done
		fi
	fi
	[[ "$PH_RESULT" == "SUCCESS" ]] && printf "%2s\033[32m%s\033[0m\n\n" "" "Prompting phase : $PH_RESULT" || >&2 printf "%2s%s\033[31m%s\033[0m\n\n" "" "Prompting phase : " "$PH_RESULT"
	PH_OLD_RESULT="$PH_RESULT"
	PH_RESULT="SUCCESS"
	PH_COUNT="0"
	PH_COUNT2="$(echo -n "$PH_FUNCTIONS" 2>/dev/null | nawk 'BEGIN { RS = " " } { next } END { print NR }')"
	for PH_i in `echo -n "$PH_FUNCTIONS"`
	do
		PH_COUNT="$((PH_COUNT+1))"
		if [[ "$PH_i" == @(PH_BOTTOMSCAN|PH_UPPERSCAN|PH_RIGHTSCAN|PH_LEFTSCAN) ]]
		then
			if [[ "$PH_i" == @(PH_RIGHTSCAN|PH_LEFTSCAN) ]]
			then
				if ! grep ^"$PH_i=16"$ "$PH_CONF_DIR"/OS.defaults >/dev/null
				then
					ph_savedef "$PH_i" "16" 
					PH_RET_CODE="$?"
				else
					PH_RET_CODE="0"
				fi
			else
				if ! grep ^"$PH_i=30"$ "$PH_CONF_DIR"/OS.defaults >/dev/null
				then
					ph_savedef "$PH_i" "30" 
					PH_RET_CODE="$?"
				else
					PH_RET_CODE="0"
				fi
			fi
		else
			ph_savedef "$PH_i" "$(eval echo -n \"\$PH_i\")"
			PH_RET_CODE="$?"
		fi
		ph_set_result -r "$PH_RET_CODE"
	done
	printf "%2s%s\n" "" "INFO : Your defaults are stored in '$PH_CONF_DIR/OS.defaults'"
	[[ "$PH_RESULT" == "SUCCESS" ]] && printf "%2s\033[32m%s\033[0m\n\n" "" "Storing phase : $PH_RESULT" || >&2 printf "%2s%s\033[31m%s\033[0m\n\n" "" "Storing phase : " "$PH_RESULT"
	case "$PH_RESULT"'_'"$PH_OLD_RESULT" in SUCCESS_SUCCESS)
			PH_RESULT="SUCCESS" ;;
			       		          FAILED_FAILED)
			PH_RESULT="FAILED" ;;
			        		              *)
			PH_RESULT="PARTIALLY FAILED" ;;
	esac
	[[ "$PH_RESULT" == "SUCCESS" ]] && printf "%2s\033[32m%s\033[0m\n\n" "" "Total : $PH_RESULT" || >&2 printf "%2s%s\033[31m%s\033[0m\n\n" "" "Total : " "$PH_RESULT"
	PH_COUNT2="0" && PH_COUNT="0"
	[[ "$PH_RESULT" != "SUCCESS" ]] && exit 1 || exit 0 ;;
		      *)
	if [[ "$PH_ACTION" != "update" ]]
	then
		if [[ "$PH_INTERACTIVE_FLAG" -eq "1" ]]
		then
			printf "\033[36m%s\033[0m\n" "- Executing function '$PH_ACTION' (Normal mode)"
		else
			printf "\033[36m%s\033[0m\n" "- Executing function '$PH_ACTION' (Interactive mode)"
		fi
	fi
	PH_RET_CODE="0"
	PH_COUNT="0"
	PH_ANSWER=""
	case "$PH_ACTION" in user)
		if [[ "$PH_INTERACTIVE_FLAG" -eq "0" ]]
		then
			PH_ANSWER=""
			PH_COUNT="0"
			while [[ -z "$PH_ANSWER" ]]
			do
				[[ "$PH_COUNT" -gt "0" ]] && >&2 printf "\n%10s\033[31m%s\033[0m%s\n\n" "" "ERROR" " : $PH_MESSAGE"
				PH_MESSAGE="Invalid response"
				printf "%8s%s" "" "--> Please enter a non-root, non logged-in account to use for the 'create new user/modify existing user' operation (Use keyword 'def' to retrieve stored default) : "
				read -r PH_ANSWER 2>/dev/null
				if ph_screen_input "$PH_ANSWER"
				then
					if [[ "$PH_ANSWER" == "def" ]]
					then
						printf "%10s\033[32m%s\033[0m\n" "" "OK -> Fetching default"
						if ph_getdef PH_USER
						then
							PH_ANSWER="$PH_USER"
							PH_USER=""
							printf "%8s%s" "" "--> Checking if '$PH_ANSWER' is currently logged-in"
							if ! who -us 2>/dev/null | nawk '{ print $1 }' | grep ^"$PH_ANSWER"$ >/dev/null
							then
								printf "%10s\033[32m%s\033[0m\n" "" "OK (No)"
								PH_USER="$PH_ANSWER"
								break
							else
								>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" "(Yes)" && >&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" && exit 1
							fi
						else
							>&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED"
							exit 1
						fi
					else
						if [[ "$PH_ANSWER" == "root" ]]
						then
							>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Modifying the 'root' account is not permitted"
							>&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" && exit 1
						else
							if (! who -us 2>/dev/null | nawk '{ print $1 }' | grep ^"$PH_ANSWER"$ >/dev/null) && [[ -n "$PH_ANSWER" ]]
							then
								printf "%10s\033[32m%s\033[0m\n" "" "OK ('$PH_ANSWER')"
								PH_USER="$PH_ANSWER"
								break
							else
								[[ -n "$PH_ANSWER" ]] && >&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : User is currently logged in" && >&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" && exit 1
							fi
						fi
					fi
				else
					exit 1
				fi
				PH_COUNT="$((PH_COUNT+1))"
				PH_ANSWER=""
			done
		else
			if [[ "$PH_USER" == "def" ]]
			then
				ph_getdef PH_USER || (>&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" ; exit 1) || exit "$?"
			fi
		fi
		printf "%8s%s\n" "" "--> Checking for group '$PH_USER'"
		if ! grep ^"$PH_USER:" /etc/group >/dev/null 2>&1
		then
			printf "%10s\033[33m%s\033[0m\n" "" "Warning : (Not found) -> Creating"
			printf "%8s%s\n" "" "--> Creating group '$PH_USER'"
			if groupadd "$PH_USER" >/dev/null 2>&1
			then
				printf "%10s\033[32m%s\033[0m\n" "" "OK"
			else
				>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not create group"
				>&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED"
				exit 1
			fi
		else
			printf "%10s\033[32m%s\033[0m\n" "" "OK (Nothing to do)"
		fi
		printf "%8s%s\n" "" "--> Checking for user '$PH_USER'"
		if id "$PH_USER" >/dev/null 2>&1
		then
			printf "%10s\033[33m%s\033[0m\n" "" "Warning : Found -> Modifying"
			printf "%8s%s\n" "" "--> Modifying user '$PH_USER'"
			if usermod -d /home/"$PH_USER" -m -c "$PH_USER account" -s /bin/bash -G tty,input,video,audio -g "$PH_USER" "$PH_USER" >/dev/null 2>&1
			then
				printf "%10s\033[32m%s\033[0m\n" "" "OK"
			else
				>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not modify user"
				>&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED"
				exit 1
			fi
		else
			printf "%10s\033[32m%s\033[0m\n" "" "OK (Not found) -> Creating"
			printf "%8s%s\n" "" "--> Creating user '$PH_USER'"
			if useradd -d /home/"$PH_USER" -c "$PH_USER account" -m -s /bin/bash -G tty,input,video,audio -g "$PH_USER" "$PH_USER" >/dev/null 2>&1
			then
				printf "%10s\033[32m%s\033[0m\n" "" "OK"
				while true
				do
					[[ "$PH_COUNT2" -ne "0" ]] && >&2 printf "\n%10s\033[31m%s\033[0m%s\n\n" "" "ERROR" " : Could not set password"
					printf "%8s%s\n\n" "" "--> Please provide a password for '$PH_USER'"
					passwd "$PH_USER"
					[[ "$?" -eq "0" ]] && printf "\n%10s\033[32m%s\033[0m\n" "" "OK" && break
					PH_COUNT2=$((PH_COUNT2+1))
				done
				PH_COUNT2="0"
			else
				>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not create user"
				>&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED"
				exit 1
			fi
		fi
		printf "%8s%s\n" "" "--> Checking sudo rules for full root rights for user '$PH_USER'"
		if [[ -f /etc/sudoers.d/010_"$PH_USER"-nopasswd ]]
		then
			printf "%10s\033[32m%s\033[0m\n" "" "OK (Found)"
		else
			printf "%10s\033[33m%s\033[0m\n" "" "Warning : Not Found -> Creating"
			printf "%8s%s\n" "" "--> Creating sudo rules for user '$PH_USER'"
			echo "$PH_USER ALL=(ALL) NOPASSWD: ALL" >/tmp/010_"$PH_USER"-nopasswd_tmp 2>/dev/null
			if ! mv /tmp/010_"$PH_USER"-nopasswd_tmp /etc/sudoers.d/010_"$PH_USER"-nopasswd 2>/dev/null
			then
				>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not create sudo rules"
				PH_RESULT="PARTIALLY FAILED"
			else
				chown root:root /etc/sudoers.d/010_"$PH_USER"-nopasswd 2>/dev/null
				chmod 440 /etc/sudoers.d/010_"$PH_USER"-nopasswd 2>/dev/null
				printf "%10s\033[32m%s\033[0m\n" "" "OK"
			fi
		fi
		[[ "$PH_RESULT" == "SUCCESS" ]] && printf "%2s\033[32m%s\033[0m\n\n" "" "$PH_RESULT" || >&2 printf "%2s\033[31m%s\033[0m\n\n" "" "$PH_RESULT"
		[[ "$PH_RESULT" == "SUCCESS" ]] && exit 0 || exit 1 ;;
		    del_stduser)
		if ! ph_check_user_state "$PH_DEF_USER"
		then
			printf "%2s\033[32m%s\033[0m\n\n" "" "SUCCESS : User does not exist"
			exit 0
		fi
		if [[ "$PH_INTERACTIVE_FLAG" -eq "0" ]]
		then
			ph_present_list PH_DEL_PIUSER && PH_DEL_PIUSER="$PH_CHOICE" && printf "%10s\033[32m%s\033[0m\n" "" "OK"
		else
			if [[ "$PH_DEL_PIUSER" == "def" ]]
			then
				ph_getdef PH_DEL_PIUSER || (>&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" ; exit 1) || exit "$?"
			fi
		fi
		if [[ "$PH_DEL_PIUSER" == "yes" ]]
		then
			printf "%8s%s\n" "" "--> Removing user '$PH_DEF_USER'"
			if userdel -r "$PH_DEF_USER" >/dev/null 2>&1
			then
				printf "%10s\033[32m%s\033[0m\n" "" "OK"
			else
				>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not delete user '$PH_DEF_USER'"
				PH_RESULT="PARTIALLY FAILED"
			fi
			if [[ -f /etc/sudoers.d/010_"$PH_DEF_USER"-nopasswd ]]
			then
				printf "%8s%s\n" "" "--> Deleting sudo rules for default user '$PH_DEF_USER'"
				if rm /etc/sudoers.d/010_"$PH_DEF_USER"-nopasswd >/dev/null 2>&1
				then
					printf "%10s\033[32m%s\033[0m\n" "" "OK"
				else
					printf "%10s\033[33m%s\033[0m\n" "" "Warning : Could not delete sudo rules"
					[[ "$PH_RESULT" == "PARTIALLY FAILED" ]] && PH_RESULT="FAILED"
				fi
			fi
		else
			printf "%8s%s\n" "" "--> Leaving user '$PH_DEF_USER' configured"
			printf "%10s\033[32m%s\033[0m\n" "" "OK (Nothing to do)"
		fi
		[[ "$PH_RESULT" == "SUCCESS" ]] && printf "%2s\033[32m%s\033[0m\n\n" "" "$PH_RESULT" || >&2 printf "%2s\033[31m%s\033[0m\n\n" "" "$PH_RESULT"
		[[ "$PH_RESULT" == "SUCCESS" ]] && exit 0 || exit 1 ;;
			 sshkey)
		if [[ "$PH_INTERACTIVE_FLAG" -eq "0" ]]
		then
			ph_present_list PH_SSH_KEY && PH_SSH_KEY="$PH_CHOICE" && printf "%10s\033[32m%s\033[0m\n" "" "OK"
		else
			if [[ "$PH_SSH_KEY" == "def" ]]
			then
				ph_getdef PH_SSH_KEY || (>&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" ; exit 1) || exit "$?"
			fi
		fi
		PH_HOME="$(getent passwd "${PH_SSH_KEY}" 2>/dev/null | head -1 | cut -d':' -f6)"
		printf "%8s%s\n" "" "--> Checking for existing keys for user '$PH_SSH_KEY'"
		if [[ ! -f "$PH_HOME/.ssh/id_rsa.pub" ]]
		then
			printf "%10s\033[32m%s\033[0m\n" "" "OK (None)"
			printf "%8s%s\n" "" "--> Creating public/private keypair and trusting public key"
			mkdir -p "$PH_HOME/.ssh" 2>/dev/null
			if ssh-keygen -t rsa -b 2048 -N "" -f "$PH_HOME/.ssh/id_rsa" >/dev/null 2>&1
			then
				chmod 700 "$PH_HOME/.ssh" 2>/dev/null
				chmod 600 "$PH_HOME/.ssh/id_rsa" 2>/dev/null
				chmod 644 "$PH_HOME/.ssh/id_rsa.pub" 2>/dev/null
				chmod 755 "$PH_HOME" 2>/dev/null
				cp -p "$PH_HOME/.ssh/id_rsa" "$PH_HOME/.ssh/authorized_keys"
				chown -R "$PH_SSH_KEY":"$PH_SSH_KEY" "$PH_HOME" 2>/dev/null
				printf "%10s\033[32m%s\033[0m\n" "" "OK"
			else
				>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not create a keypair"
				PH_RESULT="FAILED"
			fi
		else
			printf "%10s\033[32m%s\033[0m\n" "" "OK (Nothing to do)"
		fi
		[[ "$PH_RESULT" == "SUCCESS" ]] && printf "%2s\033[32m%s\033[0m\n\n" "" "$PH_RESULT" || >&2 printf "%2s\033[31m%s\033[0m\n\n" "" "$PH_RESULT"
		[[ "$PH_RESULT" == "SUCCESS" ]] && exit 0 || exit 1 ;;
			 locale)
		if [[ "$PH_INTERACTIVE_FLAG" -eq "0" ]]
		then
			ph_present_list PH_LOCALE && PH_LOCALE="$PH_CHOICE" && printf "%10s\033[32m%s\033[0m\n" "" "OK"
		else
			if [[ "$PH_LOCALE" == "def" ]]
			then
				ph_getdef PH_LOCALE || (>&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" ; exit 1) || exit "$?"
			fi
		fi
		printf "%8s%s\n" "" "--> Checking currently configured system locale"
		PH_VALUE="$(localectl status 2>/dev/null | nawk -F'=' '$0 ~ /System Locale/ { print $2 }' 2>/dev/null)"
		if [[ "$PH_VALUE" != "$PH_LOCALE" ]]
		then
			printf "%10s\033[32m%s\033[0m\n" "" "OK ('$PH_VALUE')"
			printf "%8s%s\n" "" "--> Generating locales"
			PH_VALUE="$PH_LOCALE $(localectl list-locales 2>/dev/null | paste -s -d" ")"
			for PH_i in `echo -n "$PH_VALUE"`
			do
				PH_LOCALE_NAME="$(grep -i ^"$PH_i " /usr/share/i18n/SUPPORTED 2>/dev/null | nawk '{ print $1 }')"
				PH_LOCALE_ENCODING="$(grep -i ^"$PH_i " /usr/share/i18n/SUPPORTED 2>/dev/null | nawk '{ print $2 }')"
				if ! grep -i "$PH_LOCALE_NAME $PH_LOCALE_ENCODING" /etc/locale.gen >/dev/null 2>&1
				then
					echo "$PH_LOCALE_NAME $PH_LOCALE_ENCODING" >>/etc/locale.gen 2>/dev/null
				else
					if grep -i "# $PH_LOCALE_NAME $PH_LOCALE_ENCODING" /etc/locale.gen >/dev/null 2>&1
					then
						if nawk -v loc=^"$PH_LOCALE_NAME"$ '$1 ~ /^#$/ && $2 ~ loc { for(i=2;i<=NF;i++) { print $i ; next } { print }}' /etc/locale.gen >/tmp/locale.gen_tmp 2>/dev/null
						then
							mv /tmp/locale.gen_tmp /etc/locale.gen 2>/dev/null
						else
							rm /tmp/locale.gen_tmp 2>/dev/null
							>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not generate locale"
							PH_RESULT="FAILED"
						fi
					fi
				fi
			done
			locale 2>/dev/null | sed 's/\(.*\)=\(.*\)/\1='"$PH_LOCALE"'/g' >/etc/default/locale
			cp -p /etc/default/locale /etc/locale.conf 2>/dev/null
			unset LANG 2>/dev/null
			if [[ "$PH_RESULT" != "FAILED" ]]
			then
				if locale-gen >/dev/null 2>&1
				then
					printf "%10s\033[32m%s\033[0m\n" "" "OK"
					printf "%8s%s\n" "" "--> Configuring locale '$PH_LOCALE'"
					if localectl set-locale LANG="$PH_LOCALE" >/dev/null 2>&1
					then
						printf "%10s\033[32m%s\033[0m\n" "" "OK"
						source /etc/default/locale
					else
						>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not configure locale"
						PH_RESULT="PARTIALLY FAILED"
					fi
				else
					>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not generate locale"
					PH_RESULT="FAILED"
				fi
			fi
		else
			printf "%10s\033[32m%s\033[0m\n" "" "OK (Nothing to do)"
		fi
		[[ "$PH_RESULT" == "SUCCESS" ]] && printf "%2s\033[32m%s\033[0m\n\n" "" "$PH_RESULT" || >&2 printf "%2s\033[31m%s\033[0m\n\n" "" "$PH_RESULT"
		[[ "$PH_RESULT" == "SUCCESS" ]] && exit 0 || exit 1 ;;
			   keyb)
		if [[ "$PH_INTERACTIVE_FLAG" -eq "0" ]]
		then
			ph_present_list PH_KEYB && PH_KEYB="$PH_CHOICE" && printf "%10s\033[32m%s\033[0m\n" "" "OK"
		else
			if [[ "$PH_KEYB" == "def" ]]
			then
				ph_getdef PH_KEYB || (>&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" ; exit 1) || exit "$?"
			fi
		fi
		printf "%8s%s\n" "" "--> Checking currently configured keyboard layout"
		if [[ -f /usr/bin/pacman ]]
		then
			PH_VALUE="$(localectl status 2>/dev/null | nawk -F': ' '$0 ~ /X11 Layout/ { print $2 ; exit 0 } { next }')"
			if [[ "$PH_VALUE" != "$PH_KEYB" ]]
			then
				printf "%10s\033[32m%s\033[0m\n" "" "OK ('$PH_VALUE')"
				printf "%8s%s\n" "" "--> Configuring keyboard layout"
				if localectl set-x11-keymap be >/dev/null 2>&1
				then
					if ! nawk -F'=' -v val="$PH_KEYB" '$1 ~ /KEYMAP/ { print $1 "=" val ; next } { print }' /etc/vconsole.conf >/tmp/vconsole.conf_tmp 2>/dev/null
					then
						>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not configure keyboard"
						rm /tmp/vconsole.conf_tmp 2>/dev/null
						localectl set-x11-keymap "$PH_VALUE" >/dev/null 2>&1
					else
						printf "%10s\033[32m%s\033[0m\n" "" "OK"
						mv /tmp/vconsole.conf_tmp /etc/vconsole.conf 2>/dev/null
						! grep "KEYMAP=$PH_KEYB" /etc/vconsole.conf >/dev/null 2>&1 && echo "KEYMAP=$PH_KEYB" >>/etc/vconsole.conf 2>/dev/null
						if [[ "$(cat /proc/"$PPID"/comm)" != "confoper_ph.sh" ]]
						then
							while [[ "$PH_ANSWER" != @(y|n) ]]
							do
								[[ "$PH_COUNT" -gt "0" ]] && >&2 printf "\n%10s\033[31m%s\033[0m%s\n\n" "" "ERROR" " : Invalid response"
								printf "%8s%s" "" "--> Reboot to activate keyboard settings (y/n) ? "
								read -r PH_ANSWER 2>/dev/null
								PH_COUNT="$((PH_COUNT+1))"
							done
							printf "%10s\033[32m%s\033[0m\n" "" "OK"
						fi
					fi
				else
					>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not configure keyboard"
					PH_RESULT="FAILED"
				fi
			else
				printf "%10s\033[32m%s\033[0m\n" "" "OK (Nothing to do)"
			fi
		else
			PH_VALUE="$(nawk -F'\"' '$1 ~ /^XKBLAYOUT=$/ { print $2 ; exit 0 } { next }' /etc/default/keyboard 2>/dev/null)"
			if [[ "$PH_VALUE" != "$PH_KEYB" ]]
			then
				printf "%10s\033[32m%s\033[0m\n" "" "OK ('$PH_VALUE')"
				printf "%8s%s\n" "" "--> Configuring keyboard layout"
				cp -p /etc/default/keyboard /tmp/default_keyboard_bck 2>/dev/null
				nawk -F'"' -v val="$PH_KEYB" '$1 ~ /^XKBLAYOUT=$/ { print $1 "\"" val "\"" ; next } { print }' /etc/default/keyboard >/tmp/default_keyboard_tmp 2>/dev/null
				if [[ "$?" -eq "0" ]]
				then
					mv /tmp/default_keyboard_tmp /etc/default/keyboard 2>/dev/null
					if dpkg-reconfigure -f noninteractive keyboard-configuration >/dev/null 2>&1
					then
						printf "%10s\033[32m%s\033[0m\n" "" "OK"
						rm /tmp/default_keyboard_bck 2>/dev/null
						invoke-rc.d keyboard-setup start >/dev/null 2>&1
						setsid sh -c 'exec setupcon -k --force <> /dev/tty1 >&0 2>&1' >/dev/null 2>&1
						udevadm trigger --subsystem-match=input --action=change >/dev/null 2>&1
					else
						>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not configure keyboard"
						mv /tmp/default_keyboard_bck /etc/default/keyboard 2>/dev/null
						PH_RESULT="FAILED"
					fi
				else
					>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not configure keyboard"
					PH_RESULT="FAILED"
				fi
			else
				printf "%10s\033[32m%s\033[0m\n" "" "OK (Nothing to do)"
			fi
		fi
		[[ "$PH_RESULT" == "SUCCESS" ]] && printf "%2s\033[32m%s\033[0m\n\n" "" "$PH_RESULT" || >&2 printf "%2s\033[31m%s\033[0m\n\n" "" "$PH_RESULT"
		[[ "$PH_ANSWER" == "y" ]] && init 6
		[[ "$PH_RESULT" == "SUCCESS" ]] && exit 0 || exit 1 ;;
			  tzone)
		if [[ "$PH_INTERACTIVE_FLAG" -eq "0" ]]
		then
			ph_present_list PH_TZONE && PH_TZONE="$PH_CHOICE" && printf "%10s\033[32m%s\033[0m\n" "" "OK"
		else
			if [[ "$PH_TZONE" == "def" ]]
			then
				ph_getdef PH_TZONE || (>&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" ; exit 1) || exit "$?"
			fi
		fi
		printf "%8s%s\n" "" "--> Checking currently configured system timezone"
		PH_VALUE="$(cat /etc/timezone 2>/dev/null)"
		if [[ "$PH_VALUE" != "$PH_TZONE" ]]
		then
			printf "%10s\033[32m%s\033[0m\n" "" "OK ('$PH_VALUE')"
			cp -p /etc/localtime /tmp/localtime_bck 2>/dev/null
			cp -p /etc/timezone /tmp/timezone_bck 2>/dev/null
			printf "%8s%s\n" "" "--> Configuring timezone"
			rm /etc/localtime 2>/dev/null
			if timedatectl set-timezone "$PH_TZONE" >/dev/null 2>&1
			then
				rm /tmp/localtime_bck /tmp/timezone_bck 2>/dev/null
				printf "%10s\033[32m%s\033[0m\n" "" "OK"
			else
				mv /tmp/timezone_bck /etc/timezone 2>/dev/null
				mv /tmp/localtime_bck /etc/localtime 2>/dev/null
				>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not configure timezone"
				PH_RESULT="FAILED"
			fi
		else
			printf "%10s\033[32m%s\033[0m\n" "" "OK (Nothing to do)"
		fi
		[[ "$PH_RESULT" == "SUCCESS" ]] && printf "%2s\033[32m%s\033[0m\n\n" "" "$PH_RESULT" || >&2 printf "%2s\033[31m%s\033[0m\n\n" "" "$PH_RESULT"
		[[ "$PH_RESULT" == "SUCCESS" ]] && exit 0 || exit 1 ;;
			   host)
		if [[ "$PH_INTERACTIVE_FLAG" -eq "0" ]]
		then
			while [[ -z "$PH_ANSWER" ]]
			do
				[[ "$PH_COUNT" -gt "0" ]] && >&2 printf "\n%10s\033[31m%s\033[0m%s\n\n" "" "ERROR" " : $PH_MESSAGE"
				printf "%8s%s" "" "--> Please enter a value to use for the 'configure system hostname' operation (Use keyword 'def' to retrieve stored default) : "
				read -r PH_ANSWER 2>/dev/null
				if ph_screen_input "$PH_ANSWER"
				then
					if [[ "$PH_ANSWER" == "def" ]]
					then
						printf "%10s\033[32m%s\033[0m\n" "" "OK -> Fetching default"
						if ! ph_getdef PH_HOST
						then
							>&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" && exit 1
						else
							PH_ANSWER="$PH_HOST"
							PH_HOST=""
						fi
					else
						[[ -n "$PH_ANSWER" ]] && printf "%10s\033[32m%s\033[0m\n" "" "OK ('$PH_ANSWER')"
					fi
					[[ -n "$PH_ANSWER" ]] && PH_HOST="$PH_ANSWER" && break
				else
					exit 1
				fi
				PH_COUNT="$((PH_COUNT+1))"
				PH_ANSWER=""
			done
		else
			if [[ "$PH_HOST" == "def" ]]
			then
				ph_getdef PH_HOST || (>&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" ; exit 1) || exit "$?"
			fi
		fi
		printf "%8s%s\n" "" "--> Checking current hostname"
		if [[ "$PH_HOST" != "$HOSTNAME" ]]
		then
			printf "%10s\033[32m%s\033[0m\n" "" "OK ('$HOSTNAME')"
			printf "%8s%s\n" "" "--> Configuring hostname"
			echo "$PH_HOST" >/etc/hostname 2>/dev/null
			cp -p /etc/hosts /tmp/hosts_bck 2>/dev/null
			if nawk -v oldhost=^"$HOSTNAME"$ -v newhost="$PH_HOST" '$2 ~ oldhost { print $1 "\t" newhost ; next } { print }' /etc/hosts >/tmp/hosts_tmp 2>/dev/null
			then
				mv /tmp/hosts_tmp /etc/hosts 2>/dev/null
				if ! hostname "$PH_HOST" >/dev/null 2>&1
				then
					mv /tmp/hosts_bck /etc/hosts 2>/dev/null
					>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not set hostname"
					PH_RESULT="FAILED"
				else
					printf "%10s\033[32m%s\033[0m\n" "" "OK"
					rm /tmp/hosts_bck 2>/dev/null
				fi
			else
				>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not set hostname"
				PH_RESULT="FAILED"
			fi
		else
			printf "%10s\033[32m%s\033[0m\n" "" "OK (Nothing to do)"
		fi
		[[ "$PH_RESULT" == "SUCCESS" ]] && printf "%2s\033[32m%s\033[0m\n\n" "" "$PH_RESULT" || >&2 printf "%2s\033[31m%s\033[0m\n\n" "" "$PH_RESULT"
		[[ "$PH_RESULT" == "SUCCESS" ]] && exit 0 || exit 1 ;;
#			filesys)
#		PH_RESULT="FAILED : Currently unimplemented"
#		[[ "$PH_RESULT" == "SUCCESS" ]] && printf "%2s\033[32m%s\033[0m\n\n" "" "$PH_RESULT" || >&2 printf "%2s\033[31m%s\033[0m\n\n" "" "$PH_RESULT"
#		[[ "$PH_RESULT" == "SUCCESS" ]] && exit 0 || exit 1 ;;
			  audio)
		if [[ "$PH_INTERACTIVE_FLAG" -eq "0" ]]
		then
			ph_present_list PH_AUDIO && PH_AUDIO="$PH_CHOICE" && printf "%10s\033[32m%s\033[0m\n" "" "OK"
		else
			if [[ "$PH_AUDIO" == "def" ]]
			then
				ph_getdef PH_AUDIO || (>&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" ; exit 1) || exit "$?"
			fi
		fi
		printf "%8s%s\n" "" "--> Checking currently configured audio channel"
		PH_VALUE="$(amixer cget numid=3 2>/dev/null | tail -1 | nawk -F'=' '{ print $2 }')"
		case "$PH_VALUE" in 1)
				PH_VALUE="auto" ;;
				    2)
				PH_VALUE="hdmi" ;;
				    3)
				PH_VALUE="jack" ;;
		esac
		if [[ "$PH_VALUE" != "$PH_AUDIO" ]]
		then
			printf "%10s\033[32m%s\033[0m\n" "" "OK ('$PH_VALUE')"
			printf "%8s%s\n" "" "--> Configuring audio channel"
			case "$PH_AUDIO" in auto)
				PH_AUDIO="1" ;;
					    hdmi)
				PH_AUDIO="2" ;;
				  	    jack)
				PH_AUDIO="3" ;;
			esac
			if amixer cset numid=3 "$PH_AUDIO" >/dev/null 2>&1
			then
				printf "%10s\033[32m%s\033[0m\n" "" "OK"
			else
				>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not configure audio channel"
				PH_RESULT="FAILED"
			fi
		else
			printf "%10s\033[32m%s\033[0m\n" "" "OK (Nothing to do)"
		fi
		[[ "$PH_RESULT" == "SUCCESS" ]] && printf "%2s\033[32m%s\033[0m\n\n" "" "$PH_RESULT" || >&2 printf "%2s\033[31m%s\033[0m\n\n" "" "$PH_RESULT"
		[[ "$PH_RESULT" == "SUCCESS" ]] && exit 0 || exit 1 ;;
		       overscan)
		if [[ "$PH_INTERACTIVE_FLAG" -eq "0" ]]
		then
			for PH_i in PH_BOTTOMSCAN PH_UPPERSCAN PH_RIGHTSCAN PH_LEFTSCAN
			do
				PH_ANSWER=""
				PH_COUNT="0"
				while [[ -z "$PH_ANSWER" ]]
				do
					[[ "$PH_COUNT" -gt "0" ]] && >&2 printf "\n%10s\033[31m%s\033[0m%s\n\n" "" "ERROR" " : $PH_MESSAGE"
					case "$PH_i" in PH_BOTTOMSCAN)
						printf "%8s%s" "" "--> Please enter the value to use for overscan bottom (must be numeric, 'def' or empty ('def' defaults to '30', empty is leave unchanged)) : " ;;
							PH_UPPERSCAN)
						printf "%8s%s" "" "--> Please enter the value to use for overscan upper (must be numeric, 'def' or empty ('def' defaults to '30', empty is leave unchanged)) : " ;;
							PH_RIGHTSCAN)
						printf "%8s%s" "" "--> Please enter the value to use for overscan right (must be numeric, 'def' or empty ('def' defaults to '16', empty is leave unchanged)) : " ;;
							PH_LEFTSCAN)
						printf "%8s%s" "" "--> Please enter the value to use for overscan left (must be numeric, 'def' or empty ('def' defaults to '16', empty is leave unchanged)) : " ;;
					esac
					PH_MESSAGE="Not a numeric value"
					read -r PH_ANSWER 2>/dev/null
					if [[ "$PH_ANSWER" == @(+([[:digit:]])|def) || -z "$PH_ANSWER" ]]
					then
						eval export "$PH_i"="$PH_ANSWER" 2>/dev/null
						[[ "$PH_ANSWER" == "def" ]] && printf "%10s\033[32m%s\033[0m\n" "" "OK -> Fetching default" || printf "%10s\033[32m%s\033[0m\n" "" "OK ('$PH_ANSWER')"
						break
					fi
					PH_COUNT="$((PH_COUNT+1))"
					PH_ANSWER=""
				done
			done
		fi
		for PH_i in PH_BOTTOMSCAN PH_UPPERSCAN PH_LEFTSCAN PH_RIGHTSCAN
		do
			if [[ "$(eval echo -n \"\$PH_i\")" == "def" ]]
			then
				if ! ph_getdef "$PH_i"
				then
					PH_RET_CODE="$((PH_RET_CODE+1))"
					continue
				fi
			fi
			case "$PH_i" in PH_BOTTOMSCAN)
				PH_STRING="overscan_bottom" ;;
					PH_UPPERSCAN)
				PH_STRING="overscan_top" ;;
					PH_LEFTSCAN)
				PH_STRING="overscan_left" ;;
					PH_RIGHTSCAN)
				PH_STRING="overscan_right" ;;
			esac
			if [[ -n "$(eval echo -n \"\$PH_i\")" ]]
			then
				printf "%8s%s\n" "" "--> Checking currently configured value for '$PH_STRING'"
				if [[ "$(nawk -F'=' -v str=^"$PH_STRING"$ '$1 ~ str { print $2 ; exit 0 } { next }' /boot/config.txt 2>/dev/null)" == "$(eval echo -n \"\$PH_i\" 2>/dev/null)" ]]
				then
					PH_COUNT2="$((PH_COUNT2+1))"
					printf "%10s\033[32m%s\033[0m\n" "" "OK (Nothing to do)"
				else
					printf "%10s\033[32m%s\033[0m\n" "" "OK ('$(nawk -F'=' -v str=^"$PH_STRING"$ '$1 ~ str { print $2 ; exit 0 } { next }' /boot/config.txt 2>/dev/null)')"
					printf "%8s%s\n" "" "--> Configuring value '$(eval echo -n \"\$PH_i\" 2>/dev/null)' for '$PH_STRING'"
					nawk -F'=' -v str=^"$PH_STRING"$ -v val="$(eval echo -n \"\$PH_i\")" '$1 ~ str { print $1 "=" val ; next } { print }' /boot/config.txt >/tmp/boot_config.txt_tmp 2>/dev/null
					if [[ "$?" -eq "0" ]]
					then
						printf "%10s\033[32m%s\033[0m\n" "" "OK"
						mv /tmp/boot_config.txt_tmp /boot/config.txt 2>/dev/null
					else
						>&2 printf "%10s\033[31m%s\033[0m\n" "" "ERROR : Could not configure value"
						PH_RET_CODE="$((PH_RET_CODE+1))"
					fi
				fi
			else
				printf "%8s%s\n" "" "--> Configuring value for '$PH_STRING'"
				printf "%10s\033[33m%s\033[0m\n" "" "Warning : No new value entered for '$PH_i' -> Skipping" 
				PH_COUNT2="$((PH_COUNT2+1))"
			fi
		done
		if [[ "$(cat /proc/"$PPID"/comm)" != "confoper_ph.sh" && "$PH_COUNT2" -lt "4" ]] && [[ "$PH_RET_CODE" -lt "4" ]]
		then
			while [[ "$PH_ANSWER" != @(y|n) ]]
			do
				[[ "$PH_COUNT" -gt "0" ]] && >&2 printf "\n%10s\033[31m%s\033[0m%s\n\n" "" "ERROR" " : Invalid response"
				printf "%8s%s" "" "--> Reboot now to activate the new values (y/n) ? "
				read -r PH_ANSWER 2>/dev/null
				PH_COUNT="$((PH_COUNT+1))"
			done
			printf "%10s\033[32m%s\033[0m\n" "" "OK"
		fi
		if [[ "$PH_RET_CODE" -eq "4" ]]
		then
			>&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED"
		else
			[[ "$PH_RET_CODE" -eq "0" ]] && printf "%2s\033[32m%s\033[0m\n\n" "" "SUCCESS" || >&2 printf "%2s\033[31m%s\033[0m\n\n" "" "PARTIALLY FAILED"
		fi
		[[ "$PH_ANSWER" == "y" ]] && init 6
		[[ "$PH_RET_CODE" -eq "0" ]] && exit 0 || exit 1 ;;
		       memsplit)
		if [[ "$PH_INTERACTIVE_FLAG" -eq "0" ]]
		then
			ph_present_list PH_VID_MEM && PH_VID_MEM="$PH_CHOICE" && printf "%10s\033[32m%s\033[0m\n" "" "OK"
		else
			if [[ "$PH_VID_MEM" == "def" ]]
			then
				ph_getdef PH_VID_MEM || (>&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" ; exit 1) || exit "$?"
			fi
		fi
		printf "%8s%s\n" "" "--> Checking memory amount currently configured as being exclusively reserved for the GPU"
		PH_VALUE="$(nawk -F'=' -v str=^"gpu_mem"$ '$1 ~ str { print $2 ; exit 0 } { next }' /boot/config.txt 2>/dev/null)"
		if [[ "$PH_VID_MEM" != "$PH_VALUE" ]]
		then
			printf "%10s\033[32m%s\033[0m\n" "" "OK ('$PH_VALUE')"
			printf "%8s%s\n" "" "--> Configuring memory amount to be reserved exclusively for the GPU"
			if [[ -n "$PH_VALUE" ]]
			then
				nawk -F'=' -v str=^"gpu_mem" -v val="$PH_VID_MEM" '$1 ~ str { print "gpu_mem=" val ; next } { print }' /boot/config.txt >/tmp/boot_config.txt_tmp 2>/dev/null
				if [[ "$?" -eq "0" ]]
				then
					printf "%10s\033[32m%s\033[0m\n" "" "OK"
					mv /tmp/boot_config.txt_tmp /boot/config.txt 2>/dev/null
				else
					>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not configure GPU memory reservation"
					PH_RESULT="FAILED"
				fi
			else
				echo "gpu_mem=$PH_VID_MEM" >>/boot/config.txt 2>/dev/null
				printf "%10s\033[32m%s\033[0m\n" "" "OK"
			fi
			if [[ "$(cat /proc/"$PPID"/comm)" != "confoper_ph.sh" && "$PH_RESULT" != "FAILED" ]]
			then
				while [[ "$PH_ANSWER" != @(y|n) ]]
				do
					[[ "$PH_COUNT" -gt "0" ]] && >&2 printf "\n%10s\033[31m%s\033[0m%s\n\n" "" "ERROR" " : Invalid response"
					printf "%8s%s" "" "--> Reboot to activate the new values (y/n) ? "
					read -r PH_ANSWER 2>/dev/null
					PH_COUNT="$((PH_COUNT+1))"
				done
				printf "%10s\033[32m%s\033[0m\n" "" "OK"
			fi
		else
			printf "%10s\033[32m%s\033[0m\n" "" "OK (Nothing to do)"
		fi
		[[ "$PH_RESULT" == "SUCCESS" ]] && printf "%2s\033[32m%s\033[0m\n\n" "" "$PH_RESULT" || >&2 printf "%2s\033[31m%s\033[0m\n\n" "" "$PH_RESULT"
		[[ "$PH_ANSWER" == "y" ]] && init 6
		[[ "$PH_RESULT" == "SUCCESS" ]] && exit 0 || exit 1 ;;
			    ssh)
		if [[ "$PH_INTERACTIVE_FLAG" -eq "0" ]]
		then
			ph_present_list PH_SSH_STATE && PH_SSH_STATE="$PH_CHOICE" && printf "%10s\033[32m%s\033[0m\n" "" "OK"
		else
			if [[ "$PH_SSH_STATE" == "def" ]]
			then
				ph_getdef PH_SSH_STATE || (>&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" ; exit 1) || exit "$?"
			fi
		fi
		if [[ "$PH_SSH_STATE" == "allowed" ]]
		then
			printf "%8s%s\n" "" "--> Checking for current state of 'SSH'"
			if systemctl is-enabled ssh >/dev/null 2>&1
			then
				printf "%10s\033[32m%s\033[0m\n" "" "OK (Nothing to do)"
			else
				printf "%10s\033[32m%s\033[0m\n" "" "OK ('Disabled')"
				printf "%8s%s\n" "" "--> Enabling 'SSH'"
				if ! systemctl enable ssh >/dev/null 2>&1
				then
					>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not enable 'SSH'"
					PH_RESULT="PARTIALLY FAILED"
				else
					printf "%10s\033[32m%s\033[0m\n" "" "OK"
				fi
			fi
			printf "%8s%s\n" "" "--> Checking for current 'sshd' status"
			if systemctl is-active ssh >/dev/null 2>&1
			then
				printf "%10s\033[32m%s\033[0m\n" "" "OK (Nothing to do)"
			else
				printf "%10s\033[32m%s\033[0m\n" "" "OK ('Inactive')"
				printf "%8s%s\n" "" "--> Starting 'sshd'"
				if ! systemctl start ssh >/dev/null 2>&1
				then
					>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not start 'sshd'"
					[[ "$PH_RESULT" == "PARTIALLY FAILED" ]] && PH_RESULT="FAILED"
					[[ "$PH_RESULT" == "SUCCESS" ]] && PH_RESULT="PARTIALLY FAILED"
				else
					printf "%10s\033[32m%s\033[0m\n" "" "OK"
				fi
			fi
		else
			printf "%8s%s\n" "" "--> Checking for current state of 'SSH'"
			if ! systemctl is-enabled ssh >/dev/null 2>&1
			then
				printf "%10s\033[32m%s\033[0m\n" "" "OK (Nothing to do)"
			else
				printf "%10s\033[32m%s\033[0m\n" "" "OK ('Enabled')"
				printf "%8s%s\n" "" "--> Disabling 'SSH'"
				if ! systemctl disable ssh >/dev/null 2>&1
				then
					>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not disable 'SSH'"
					PH_RESULT="PARTIALLY FAILED"
				else
					printf "%10s\033[32m%s\033[0m\n" "" "OK"
				fi
			fi
			printf "%8s%s\n" "" "--> Checking for current 'sshd' status"
			if ! systemctl is-active ssh >/dev/null 2>&1
			then
				printf "%10s\033[32m%s\033[0m\n" "" "OK (Nothing to do)"
			else
				printf "%10s\033[32m%s\033[0m\n" "" "OK ('Active')"
				printf "%8s%s\n" "" "--> Stopping 'sshd'"
				if ! systemctl stop ssh >/dev/null 2>&1
				then
					>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not stop 'sshd'"
					[[ "$PH_RESULT" == "PARTIALLY FAILED" ]] && PH_RESULT="FAILED"
					[[ "$PH_RESULT" == "SUCCESS" ]] && PH_RESULT="PARTIALLY FAILED"
				else
					printf "%10s\033[32m%s\033[0m\n" "" "OK"
				fi
			fi
		fi
		[[ "$PH_RESULT" == "SUCCESS" ]] && printf "%2s\033[32m%s\033[0m\n\n" "" "$PH_RESULT" || >&2 printf "%2s\033[31m%s\033[0m\n\n" "" "$PH_RESULT"
		[[ "$PH_RESULT" == "SUCCESS" ]] && exit 0 || exit 1 ;;
			 update)
		ph_update_system | sed 's/Starting system update/Executing function update/'
		[[ "$?" -eq "0" ]] && PH_RESULT="SUCCESS" || PH_RESULT="FAILED"
                if [[ "$(cat /proc/"$PPID"/comm)" != "confoper_ph.sh" ]]
                then
			printf "\033[36m%s\033[0m\n" "- Proposing recommended and possibly required (only in case of kernel and/or bootloader/firmware update) reboot" 
                        while [[ "$PH_ANSWER" != @(y|n) ]]
                        do
                                [[ "$PH_COUNT" -gt "0" ]] && >&2 printf "\n%10s\033[31m%s\033[0m%s\n\n" "" "ERROR" " : Invalid response"
                                printf "%8s%s" "" "--> Reboot system (y/n) ? "
                                read -r PH_ANSWER 2>/dev/null
                                PH_COUNT="$((PH_COUNT+1))"
                        done
                        printf "%10s\033[32m%s\033[0m\n" "" "OK"
			if [[ "$PH_ANSWER" == "y" ]]
			then
				[[ "$PH_RESULT" == "SUCCESS" ]] && printf "%2s\033[32m%s\033[0m\n\n" "" "$PH_RESULT" || >&2 printf "%2s\033[31m%s\033[0m\n\n" "" "$PH_RESULT"
				init 6
			else
				[[ "$PH_RESULT" == "SUCCESS" ]] && printf "%2s\033[32m%s\033[0m\n\n" "" "$PH_RESULT" || >&2 printf "%2s\033[31m%s\033[0m\n\n" "" "$PH_RESULT"
			fi
                fi
		[[ "$PH_RESULT" == "SUCCESS" ]] && exit 0 || exit 1 ;;
			netwait)
		if [[ "$PH_INTERACTIVE_FLAG" -eq "0" ]]
		then
			ph_present_list PH_NETWAIT && PH_NETWAIT="$PH_CHOICE" && printf "%10s\033[32m%s\033[0m\n" "" "OK"
		else
			if [[ "$PH_NETWAIT" == "def" ]]
			then
				ph_getdef PH_NETWAIT || (>&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" ; exit 1) || exit "$?"
			fi
		fi
		printf "%8s%s\n" "" "--> Checking current configuration of 'wait for network on boot'"
		[[ -f /etc/systemd/system/dhcpcd.service.d/wait.conf ]] && PH_VALUE="enabled" || PH_VALUE="disabled"
		if [[ "$PH_NETWAIT" != "$PH_VALUE" ]]
		then
			printf "%10s\033[32m%s\033[0m\n" "" "OK ('$PH_VALUE')"
			if [[ "$PH_NETWAIT" == "enabled" ]]
			then
				printf "%8s%s\n" "" "--> Creating 'dhcpd' configuration file"
				mkdir -p /etc/systemd/system/dhcpcd.service.d/ 2>/dev/null
				cat >/etc/systemd/system/dhcpcd.service.d/wait.conf << EOF 2>/dev/null
[Service]
ExecStart=
ExecStart=/usr/lib/dhcpcd5/dhcpcd -q -w
EOF
				if [[ "$?" -ne "0" ]]
				then
					>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not create configuration file"
					PH_RESULT="FAILED" 
				else
					printf "%10s\033[32m%s\033[0m\n" "" "OK"
				fi
			else
				printf "%8s%s\n" "" "--> Removing 'dhcpd' configuration file"
				rm -f /etc/systemd/system/dhcpcd.service.d/wait.conf 2>/dev/null
				if [[ "$?" -ne "0" ]]
				then
					>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not remove configuration file"
					PH_RESULT="FAILED" 
				else
					printf "%10s\033[32m%s\033[0m\n" "" "OK"
				fi
			fi
		else
			printf "%10s\033[32m%s\033[0m\n" "" "OK (Nothing to do)"
		fi
		[[ "$PH_RESULT" == "SUCCESS" ]] && printf "%2s\033[32m%s\033[0m\n\n" "" "$PH_RESULT" || >&2 printf "%2s\033[31m%s\033[0m\n\n" "" "$PH_RESULT"
		[[ "$PH_RESULT" == "SUCCESS" ]] && exit 0 || exit 1 ;;
			bootenv)
		if [[ "$PH_INTERACTIVE_FLAG" -eq "0" ]]
		then
			ph_present_list PH_ENV && PH_ENV="$PH_CHOICE" && printf "%10s\033[32m%s\033[0m\n" "" "OK"
		else
			if [[ "$PH_ENV" == "def" ]]
			then
				ph_getdef PH_ENV || (>&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" ; exit 1) || exit "$?"
			fi
		fi
		if (grep "PH_RUNAPP_CMD='.*/PieHelper/scripts/startpieh.sh'" /etc/profile.d/PieHelper_tty* >/dev/null 2>&1) && [[ "$PH_ENV" == "gui" ]]
		then
			printf "%8s%s\n" "" "--> Setting default boot environment to '$PH_ENV'"
			>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : PieHelper state is 'Configured' and is not compatible with a graphical default boot environment"
			>&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED"
			exit 1
		fi
		printf "%8s%s\n" "" "--> Checking currently configured default boot environment"
		[[ "$PH_ENV" == "cli" ]] && PH_ENV="multi-user.target" || \
			PH_ENV="graphical.target"
		if [[ "$(systemctl get-default 2>/dev/null)" != "$PH_ENV" ]]
		then
			[[ "$PH_ENV" == "graphical.target" ]] && printf "%10s\033[32m%s\033[0m\n" "" "OK ('multi-user.target')" || \
						printf "%10s\033[32m%s\033[0m\n" "" "OK ('graphical.target')"
			printf "%8s%s\n" "" "--> Setting default boot environment to '$PH_ENV'"
			if systemctl set-default "$PH_ENV" >/dev/null 2>&1
			then
				printf "%10s\033[32m%s\033[0m\n" "" "OK"
			else
				>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not configure default boot environment"
				PH_RESULT="FAILED"
			fi
		else
			printf "%10s\033[32m%s\033[0m\n" "" "OK (Nothing to do)"
		fi
		[[ "$PH_RESULT" == "SUCCESS" ]] && printf "%2s\033[32m%s\033[0m\n\n" "" "$PH_RESULT" || >&2 printf "%2s\033[31m%s\033[0m\n\n" "" "$PH_RESULT"
		[[ "$PH_RESULT" == "SUCCESS" ]] && exit 0 || exit 1 ;;
			   boot)
		[[ "$PH_RESULT" == "SUCCESS" ]] && printf "%2s\033[32m%s\033[0m\n\n" "" "$PH_RESULT" || >&2 printf "%2s\033[31m%s\033[0m\n\n" "" "$PH_RESULT"
		printf "%s" "Press Enter to reboot"
		read -r 2>/dev/null
		init 6 ;;
	esac
	[[ "$PH_RET_CODE" -ne "0" ]] && PH_RESULT="FAILED"
	[[ "$PH_RESULT" == "SUCCESS" ]] && printf "%2s\033[32m%s\033[0m\n\n" "" "$PH_RESULT" || >&2 printf "%2s\033[31m%s\033[0m\n\n" "" "$PH_RESULT"
	exit $PH_RET_CODE ;;
esac
