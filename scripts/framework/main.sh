# Main PieHelper (By Davy Keppens on 06/10/18)
# Enable/Disable debug by running 'confpieh_ph.sh -p debug -m main.sh'

#set -x

# Trap some common interrupts

trap ":" INT TERM

# Enable robust coding options

set -o pipefail

# Enable extended shell globbing and terminal resizing

shopt -s extglob
shopt -s checkwinsize

# Declare local variables

declare PH_i
declare PH_CUR_USER
declare PH_MOVE_SCRIPTS_REGEX
declare PH_OLD_DISTRO_REL
declare -i PH_FORMAT_FLAG
declare -u PH_DISTROU

PH_i=""
PH_CUR_USER=""
PH_MOVE_SCRIPTS_REGEX=""
PH_OLD_DISTRO_REL=""
PH_FORMAT_FLAG="1"
PH_DISTROU=""

# Declare global variables not related to rollback

declare -x PH_SCRIPTS_DIR
declare -x PH_INST_DIR
declare -x PH_BASE_DIR
declare -x PH_BUILD_DIR
declare -x PH_SNAPSHOT_DIR
declare -x PH_MNT_DIR
declare -x PH_CONF_DIR
declare -x PH_MAIN_DIR
declare -x PH_FUNCS_DIR
declare -x PH_TMP_DIR
declare -x PH_FILES_DIR
declare -x PH_MENUS_DIR
declare -x PH_TEMPLATES_DIR
declare -x PH_EXCLUDES_DIR
declare -x PH_VERSION
declare -x PH_DISTRO
declare -x PH_DISTRO_REL
declare -x PH_RUN_USER
declare -x PH_RUN_GROUP
declare -x PH_SUDO
declare -x PH_PI_MODEL
declare -x PH_FILE_SUFFIX
declare -ax PH_SUPPORTED_DISTROS
declare -ax PH_SUPPORTED_DEBIAN_RELS
declare -ax PH_DISTRO_CONFIGS

PH_SCRIPTS_DIR="$(cd "$(dirname "${0}")" && pwd)"
PH_INST_DIR="${PH_SCRIPTS_DIR%/PieHelper/scripts}"
PH_BASE_DIR="${PH_INST_DIR}/PieHelper"
PH_BUILD_DIR="${PH_BASE_DIR}/builds"
PH_SNAPSHOT_DIR="${PH_BASE_DIR}/snapshots"
PH_MNT_DIR="${PH_BASE_DIR}/mnt"
PH_CONF_DIR="${PH_BASE_DIR}/conf"
PH_MAIN_DIR="${PH_SCRIPTS_DIR}/framework"
PH_FUNCS_DIR="${PH_BASE_DIR}/functions"
PH_TMP_DIR="${PH_BASE_DIR}/tmp"
PH_FILES_DIR="${PH_BASE_DIR}/files"
PH_MENUS_DIR="${PH_FILES_DIR}/menus"
PH_TEMPLATES_DIR="${PH_FILES_DIR}/templates"
PH_EXCLUDES_DIR="${PH_FILES_DIR}/excludes"
PH_VERSION=""
PH_DISTRO=""
PH_DISTRO_REL=""
PH_RUN_USER=""
PH_RUN_GROUP=""
PH_SUDO=""
PH_PI_MODEL=""

# Determine the current user

if ! PH_CUR_USER="$(whoami 2>&1)"
then
	>&2 printf "\n%2s\033[1;31m%s\033[0m\n\n" "" "ABORT : An error occurred trying to determine the current user account"
	exit 1
fi

# Determine sudo state and privilege escalation rights of current user

if command -v sudo >/dev/null 2>&1
then
	if "$(command -v sudo 2>/dev/null)" bash -c exit 2>/dev/null
	then
		PH_SUDO="$(command -v sudo 2>/dev/null)"
	else
		>&2 printf "\n%2s\033[1;31m%s\033[0m\n\n" "" "ABORT : An error occurred trying to escalate privileges for user '${PH_CUR_USER}'"
		>&2 printf "%12s\033[1;37m%s\033[0m\n\n" "" "Configure full sudo rights for the current user as follows : "
		>&2 printf "%14s\033[1;37m%s\033[33m%s\033[37m%s\033[0m\n" "" "- Run " "'su'" " and provide the administrator password when asked"
		>&2 printf "%14s\033[1;37m%s\033[33m%s\033[37m%s\033[33m%s\033[37m%s\033[0m\n\n" "" "- Run " "'${PH_SCRIPTS_DIR}/confoper_ph.sh -p sudo -a ${PH_CUR_USER}'" " and " "'exit'" " afterwards"
		exit 1
	fi
else
	>&2 printf "\n%2s\033[1;31m%s\033[0m\n\n" "" "ABORT : An error occurred trying to determine the location of the 'sudo' command"
	>&2 printf "%12s\033[1;37m%s\033[33m%s\033[37m%s\033[0mm\n\n" "" "- If " "'sudo'" " is not installed, install it as follows : "
	>&2 printf "%14s\033[1;37m%s\033[33m%s\033[37m%s\033[0m\n" "" "- Run " "'su'" " and provide the administrator password when asked"
	>&2 printf "%14s\033[1;37m%s\033[33m%s\033[37m%s\033[33m%s\033[37m%s\033[0m\n\n" "" "- Run " "'apt-get install sudo'" " and " "'exit'" " afterwards"
	>&2 printf "%12s\033[1;31m%s\033[33m%s\033[37m%s\033[0mm\n\n" "" "- If " "'sudo'" " is already installed, change your environment as follows : "
	>&2 printf "%14s\033[1;37m%s\033[33m%s\033[37m%s\033[0m\n" "" "- Determine the full pathname of the main " "'sudo'" " executable"
	>&2 printf "%14s\033[1;37m%s\033[33m%s\033[37m%s\033[0m\n\n" "" "- Run " "'export PATH=\"[location]:${PATH}\"'" " where [location] should be the previously determined pathname"
	exit 1
fi

# Determine the Raspberry PI model

if PH_PI_MODEL="$(nawk '$0 ~ /Raspberry Pi/ { \
		for (i=1;i<=NF;i++) { \
			if ($i ~ /^Raspberry$/ && $(i+1) ~ /^Pi$/) { \
				printf "pi" $(i+2) ; \
				exit 0 \
			} \
		} \
	}' /proc/cpuinfo 2>/dev/null)"
then
	if [[ "$(dtoverlay -l 2>/dev/null | grep -E "vc4-(f)*kms-v3d" >/dev/null ; echo "${?}")" -eq "0" || \
		( "${PH_PI_MODEL}" == "pi4" && "$(dtoverlay -l 2>/dev/null | grep -E "vc4-kms-v3d-pi4" >/dev/null ; echo "${?}")" -eq "0" ) || \
		"$("${PH_SUDO}" find /sys/firmware/devicetree/base/chosen -mount -type d -name "framebuffer@*" 2>/dev/null | wc -l)" -gt "0" ]]
	then
		PH_FILE_SUFFIX="_GL"
	else
		PH_FILE_SUFFIX="_X"
	fi
else
	>&2 printf "\n%2s\033[1;31m%s\033[0m\n\n" "" "ABORT : An error occurred trying to determine the Raspberry PI model"
	exit 1
fi

# Configure Linux distros/releases support and set the list of distro configs

PH_SUPPORTED_DISTROS=("Archlinux" "Debian")
PH_SUPPORTED_DEBIAN_RELS=("jessie" "stretch" "buster" "bullseye")
for PH_i in "${PH_SUPPORTED_DISTROS[@]}"
do
	PH_DISTROU="${PH_i}"
	if [[ "$(declare -p "PH_SUPPORTED_${PH_DISTROU}_RELS" 2>/dev/null)" == declare* ]]
	then
		declare -n PH_DISTRO_RELS
		PH_DISTRO_RELS="PH_SUPPORTED_${PH_DISTROU}_RELS"
		PH_DISTRO_CONFIGS+=("${PH_DISTRO_RELS[@]}")
		unset -n PH_DISTRO_RELS
	else
		PH_DISTRO_CONFIGS+=("${PH_i}")
	fi
done

# Declare global variables related to rollback

declare -x PH_ROLLBACK_USED
declare -x PH_RESULT_MSG
declare -x PH_RESULT_TYPE_USED
declare -x PH_TOTAL_RESULT
declare -x PH_RESULT
declare -ix PH_RESULT_COUNT
declare -ix PH_TOTAL_RESULT_COUNT
declare -ix PH_ROLLBACK_DEPTH
declare -ax PH_ALL_ROLLBACK_PARAMS

PH_ROLLBACK_USED=""
PH_RESULT_MSG=""
PH_RESULT_TYPE_USED=""
PH_TOTAL_RESULT=""
PH_RESULT=""
PH_RESULT_COUNT="0"
PH_TOTAL_RESULT_COUNT="0"
PH_ROLLBACK_DEPTH="0"
PH_ALL_ROLLBACK_PARAMS+=(PH_DEPTH_PARAMS PH_DEPTH PH_CONFIGURED_STATE PH_UNCONFIGURED_STATE PH_GROUPS PH_REMOVE_ACLS_USERS PH_CREATE_ACLS_USERS \
	PH_REMOVE_RIGHTS_USERS PH_CREATE_RIGHTS_USERS PH_INSTALL_PKGS PH_REMOVE_PKGS PH_INT_APPS PH_SUP_APPS PH_UNINT_APPS PH_UNSUP_APPS PH_OPTIONS PH_PIEH_VERSION PH_OLD_VERSION \
	PH_BOOTENV PH_ENABLE_SERVICES PH_DISABLE_SERVICES PH_SETUP_TTYS PH_UNDO_SETUP_TTYS PH_BLACKLIST_MODULES PH_UNBLACKLIST_MODULES PH_LOAD_MODULES PH_UNLOAD_MODULES \
	PH_CREATE_EMPTY_FILES PH_REMOVE_EMPTY_FILES PH_CREATE_APPS_ITEMS PH_REMOVE_APPS_ITEMS PH_GIT_ADD_LOCAL PH_GIT_TAG_LOCAL PH_GIT_COMMIT_LOCAL PH_GIT_CLONE_MASTER \
	PH_GIT_UNDO_CLONE_MASTER PH_GIT_COMMIT_MASTER PH_OLD_GIT_COMMIT_MSG PH_SECURE PH_LINK_MENUS PH_UNDO_LINK_MENUS PH_STORE_FILES PH_RESTORE_FILES PH_ADD_LINES PH_REMOVE_LINES \
	PH_ADD_APPS_TO_INT_FILE PH_REMOVE_APPS_FROM_INT_FILE PH_ADD_APPS_TO_SUP_FILE PH_REMOVE_APPS_FROM_SUP_FILE PH_MODIFY_APPS_SCRIPT PH_APPS_ACTION PH_STARTAPP \
	PH_SET_BOOT_TTYS PH_COPY_FILES PH_GRANT_APPS_ACCESS PH_REVOKE_APPS_ACCESS PH_CREATE_APPS_CIFS_MPT PH_REMOVE_APPS_CIFS_MPT PH_CREATE_APPS_ALLOWEDS PH_REMOVE_APPS_ALLOWEDS \
	PH_CREATE_APPS_DEFAULTS PH_REMOVE_APPS_DEFAULTS PH_CREATE_APPS_CONF_FILE PH_REMOVE_APPS_CONF_FILE PH_CREATE_APPS_MENUS PH_REMOVE_APPS_MENUS PH_CREATE_APPS_SCRIPTS \
	PH_REMOVE_APPS_SCRIPTS PH_CREATE_OOS_APPS_CODE PH_REMOVE_OOS_APPS_CODE PH_VARIABLES PH_STORE_OPTION PH_RETRIEVE_STORED_OPTION PH_INSTALL_APPS PH_UNINSTALL_APPS \
	PH_CREATE_APP_USER PH_REMOVE_APP_USER PH_APP_MOUNT_CIFS PH_APP_UMOUNT_CIFS PH_STOP_SERVICES PH_START_SERVICES)

# Determine the current Linux distro and release

if [[ -f /usr/bin/pacman ]]
then
	PH_DISTRO="Archlinux"
else
	PH_DISTRO="$(nawk -F '=' 'BEGIN { \
			id = "" ; \
			id_like = "" \
		} \
		$1 ~ /^(ID|ID_LIKE)$/ { \
			if ($1 ~ /^ID$/) { \
				id = $2 \
			} else { \
				id_like = $2 \
			} \
		} { \
			next \
		} END { \
			if (id_like ~ /^$/) { \
				printf toupper(substr(id,1,1)) ; \
				printf tolower(substr(id,2)) \
			} else { \
				printf toupper(substr(id_like,1,1)) ; \
				printf tolower(substr(id_like,2)) \
			} \
		}' /etc/os-release 2>/dev/null)"
fi
if [[ -n "${PH_DISTRO}" ]]
then
	PH_DISTRO="${PH_DISTRO// /}"
	PH_DISTROU="${PH_DISTRO}"
	if [[ "$(declare -p "PH_SUPPORTED_${PH_DISTROU}_RELS" 2>/dev/null)" == declare* ]]
	then
		PH_DISTRO_REL="$(lsb_release -a 2>/dev/null | nawk '$1 ~ /^Codename:/ { \
                       		printf $2 \
                	}')"
	else
		PH_DISTRO_REL="${PH_DISTRO}"
	fi
	if [[ -z "${PH_DISTRO_REL}" ]]
	then
		>&2 printf "\n%2s\033[1;31m%s\033[0m\n\n" "" "ABORT : An error occurred trying to determine the release of the current '${PH_DISTRO}' distro"
		exit 1
	fi
else
	>&2 printf "\n%2s\033[1;31m%s\033[0m\n\n" "" "ABORT : An error occurred trying to determine the Linux distro"
	exit 1
fi

# Ensure some additional PATH and LD_LIBRARY_PATH entries

if [[ -z "${PATH}" ]]
then
	declare -x PATH 2>/dev/null

	PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:${PH_SCRIPTS_DIR}"
else
	for PH_i in "${PH_SCRIPTS_DIR}" "/sbin" "/bin" "/usr/sbin" "/usr/bin" "/usr/local/sbin" "/usr/local/bin"
	do
		if ! echo -n "${PATH}" | grep -E "(^|(:)+)${PH_i}((:)+|$)" >/dev/null
		then
			PATH="${PH_i}:${PATH}"
		fi
	done
fi
if [[ -z "${LD_LIBRARY_PATH}" ]]
then
	declare -x LD_LIBRARY_PATH 2>/dev/null

	LD_LIBRARY_PATH="/lib:/usr/lib:/usr/local/lib:/lib64:/usr/lib64:/usr/local/lib64"
else
	for PH_i in "/usr/local/lib64" "/usr/lib64" "/lib64" "/usr/local/lib" "/usr/lib" "/lib"
	do
		if ! echo -n "${LD_LIBRARY_PATH}" | grep -E "(^|(:)+)${PH_i}((:)+|$)" >/dev/null
		then
			LD_LIBRARY_PATH="${PH_i}:${LD_LIBRARY_PATH}"
		fi
	done
fi
export PATH LD_LIBRARY_PATH

# Force a color terminal

if [[ "${TERM}" != "xterm-256color" ]]
then
	export TERM="xterm-256color"
fi

# Load shared and distro-dependent codebase

for PH_i in functions.main functions.user functions.update "distros/functions.${PH_DISTRO}"
do
	if [[ -r "${PH_FUNCS_DIR}/${PH_i}" ]]
	then
		if ! source "${PH_FUNCS_DIR}/${PH_i}" >/dev/null 2>&1
		then
			>&2 printf "\n%2s\033[1;31m%s\033[0m\n\n" "" "ABORT : Reinstallation of PieHelper is required (Corrupted critical codebase file '${PH_FUNCS_DIR}/${PH_i}')"
			exit 1
		fi
	else
		>&2 printf "\n%2s\033[1;31m%s\033[0m\n\n" "" "ABORT : Reinstallation of PieHelper is required (Missing or unreadable critical codebase file '${PH_FUNCS_DIR}/${PH_i}')"
		exit 1
	fi
done

# Run basic sanity checks

ph_check_pieh_shared_config basic

# Set current framework version

PH_VERSION="$(cat "${PH_CONF_DIR}/VERSION" 2>/dev/null)"
if [[ "${PH_VERSION}" != @(0\.+([[:digit:]])|@(1|2|3|4|5|6|7|8|9)*([[:digit:]])*(\.+([[:digit:]]))) ]]
then
	ph_set_result -a -m "Reinstallation of PieHelper is required (Corrupted critical configuration file '${PH_CONF_DIR}/VERSION')"
fi

# Load release-dependent configuration

source "${PH_CONF_DIR}/distros/${PH_DISTRO}.conf" >/dev/null 2>&1

# Load applications/controller configurations

declare -a PH_PARSE_FILES

PH_PARSE_FILES+=("${PH_FILES_DIR}/default_apps${PH_FILE_SUFFIX}")

if [[ -f "${PH_CONF_DIR}/supported_apps" ]]
then
	PH_PARSE_FILES+=("${PH_CONF_DIR}/supported_apps")
fi
for PH_i in Controllers $(nawk 'BEGIN { \
		i = "1" \
	} \
	NR == "1" { \
		optarr[i] = $1 ; \
		next \
	} { \
		for (j=1;j<=i;j++) { \
			if ($1 == optarr[j]) { \
				next \
			} ; \
			i++ ; \
			optarr[i] = $1 ; \
			next \
		} \
	} END { \
		for (j=1;j<=i;j++) { \
			printf optarr[j] ; \
			delete optarr[j] ; \
			if (j != i) { \
				printf " " \
			} \
		} \
	}' "${PH_PARSE_FILES[@]}" 2>/dev/null)
do
	if [[ -f "${PH_CONF_DIR}/${PH_i}.conf" ]]
	then
		source "${PH_CONF_DIR}/${PH_i}.conf" >/dev/null 2>&1
	else
		source "${PH_TEMPLATES_DIR}/${PH_i}_conf.template" >/dev/null 2>&1
	fi
done
unset PH_PARSE_FILES

# Enable xtrace for modules in debug

if [[ -n "${PH_PIEH_DEBUG}" ]]
then
	for PH_i in ${PH_PIEH_DEBUG//,/ }
	do
		if [[ "${PH_i}" != *.sh ]]
		then
			if ! functions -t "${PH_i}" >/dev/null 2>&1
			then
				if [[ "${PH_FORMAT_FLAG}" -eq "1" ]]
				then
					PH_FORMAT_FLAG="0"
					printf "\n"
				fi
				printf "\n%2s\033[33m%s\033[0m" "" "Warning : Failed to enable debug for module '${PH_i}'"
			fi
		fi
	done
	if [[ "${PH_FORMAT_FLAG}" -eq "0" ]]
	then
		printf "\n\n"
		sleep 4
	fi
fi

# Initialize rollback

for PH_i in "${PH_ALL_ROLLBACK_PARAMS[@]}"
do
	unset "${PH_i}" 2>/dev/null
	declare -ax "${PH_i}"
done
ph_initialize_rollback

# Clean the temp directory

ph_clean_tmp_dir

# Ensure priority of repair attempts over extended sanity checks

if [[ "$(ps -p "${$}" -o args 2>/dev/null | tail -1)" == "/bin/bash ${PH_SCRIPTS_DIR}/confpieh_ph.sh -v" ]]
then
	ph_repair_pieh
	exit "${?}"
fi

# Run extended sanity checks when enabled

if [[ "${PH_PIEH_SANITY_EXTENDED}" == "yes" ]]
then
	PH_MOVE_SCRIPTS_REGEX="$(ph_get_move_scripts_regex)"
	if [[ "$("${PH_SUDO}" cat "/proc/${PPID}/comm" 2>/dev/null)" != +(@(conf|list)*_ph|@(re|)start*|${PH_MOVE_SCRIPTS_REGEX}).sh ]]
	then
		if [[ -e "${PH_TMP_DIR}/.reported_issues" ]]
		then
			ph_show_report
			exit 1
		else
			if [[ -e "${PH_TMP_DIR}/.first_run" ]]
			then
				ph_check_pieh_shared_config extended
				ph_check_pieh_unconfigured_config
				if [[ -e "${PH_TMP_DIR}/.reported_issues" ]]
				then
					ph_add_line_to_file -f "${PH_TMP_DIR}/.reported_issues" -l "  OR"
					ph_check_pieh_shared_config extended
					ph_check_pieh_configured_config
				fi
			else
				ph_check_pieh_shared_config extended
				ph_check_pieh_configured_config
				if [[ -e "${PH_TMP_DIR}/.reported_issues" ]]
				then
					ph_add_line_to_file -f "${PH_TMP_DIR}/.reported_issues" -l "  OR"
					ph_check_pieh_shared_config extended
					ph_check_pieh_unconfigured_config
				fi
			fi
		fi
	fi
	if [[ -e "${PH_TMP_DIR}/.reported_issues" ]]
	then
		ph_show_report
		exit 1
	fi
fi

# Clean the temp directory again

ph_clean_tmp_dir

# Reinitialize rollback

for PH_i in "${PH_ALL_ROLLBACK_PARAMS[@]}"
do
	unset "${PH_i}" 2>/dev/null
	declare -ax "${PH_i}"
done
ph_initialize_rollback

# Autodetect first run

if [[ -f "${PH_TMP_DIR}/.first_run" ]]
then
	clear
	printf "\n\033[1;36m%s\033[0m\n\n" "- Configuring PieHelper '${PH_VERSION}'"
	ph_configure_pieh
	exit "${?}"
fi

# Set user and group accounts for the framework

PH_RUN_USER="$(ph_get_app_user_from_app_name PieHelper)"
PH_RUN_GROUP="$(id -ng "${PH_RUN_USER}")"
for PH_i in USER GROUP
do
	if [[ -z "$(eval "echo -n \"\$PH_RUN_${PH_i}\"")" ]]
	then
		if [[ "${PH_i}" == "USER" && "${PH_PIEH_SANITY_EXTENDED}" == "no" ]]
		then
			ph_set_option_to_value "PieHelper" -o "PH_PIEH_SANITY_EXTENDED'yes" >/dev/null 2>&1
			ph_set_result -a -m "An error occurred trying to set the $(echo -n "${PH_i}" | tr '[:upper:]' '[:lower:]') account for PieHelper (Auto-enabling extended sanity checks)"
		else
			ph_set_result -a -m "An error occurred trying to set the $(echo -n "${PH_i}" | tr '[:upper:]' '[:lower:]') account for PieHelper (Check user '${PH_RUN_USER}')"
		fi
	fi
done

# Check if the current user has framework access

declare -a PH_ALLOW_USERS
[[ "${PH_RUN_USER}" == "root" ]] && \
	PH_ALLOW_USERS+=("${PH_RUN_USER}")
for PH_i in $("${PH_SUDO}" find "/etc/sudoers.d" -maxdepth 1 -name "020_pieh-*" 2>/dev/null | paste -d " " -s)
do
	PH_ALLOW_USERS+=("${PH_i##/etc/sudoers.d/020_pieh-}")
done
if [[ "${#PH_ALLOW_USERS[@]}" -eq "0" ]]
then
	PH_ROLLBACK_USED="no"
	if [[ "${PH_PIEH_SANITY_EXTENDED}" == "no" ]]
	then
		ph_set_option_to_value "PieHelper" -o "PH_PIEH_SANITY_EXTENDED'yes" >/dev/null 2>&1
		ph_set_result -a -m "An error occurred trying to determine the users with PieHelper access (Auto-enabling extended sanity checks)"
	else
		ph_set_result -a -m "An error occurred trying to determine the users with PieHelper access (Check/correct 'sudo' configurations)"
	fi
else
	if [[ "${PH_CUR_USER}" != @($(sed 's/ /|/g'<<<"${PH_ALLOW_USERS[*]}")) ]]
	then
		ph_set_result -a -m "Current user '${PH_CUR_USER}' does not match any account with PieHelper access ('${PH_ALLOW_USERS[*]// /|}')"
	fi
fi
unset PH_ALLOW_USERS

# Detect/handle changes in release for the current distro

if [[ -L "${PH_CONF_DIR}/distros/${PH_DISTRO}.conf" ]]
then
	if PH_OLD_DISTRO_REL="$(ph_get_link_target "${PH_CONF_DIR}/distros/${PH_DISTRO}.conf")"
	then
		if [[ "${PH_OLD_DISTRO_REL}" != "${PH_DISTRO_REL}" ]]
		then
			PH_DISTROU="${PH_DISTRO}"
			if ph_check_array_index -n "PH_SUPPORTED_${PH_DISTROU}_RELS" -v "${PH_DISTRO_REL}" -q
			then
				ph_remove_empty_file -q -t link -d "${PH_CONF_DIR}/distros/${PH_DISTRO}.conf"
				ph_create_empty_file -q -t link -s "${PH_CONF_DIR}/distros/${PH_DISTRO_REL}.conf" -d "${PH_CONF_DIR}/distros/${PH_DISTRO}.conf"
			else
				ph_set_result -a -m "This ${PH_DISTRO} instance changed release from '${PH_OLD_DISTRO_REL}' to the currently unsupported '${PH_DISTRO_REL}'"
			fi
		fi
	else
		ph_set_result -a
	fi
fi

# Unset all local variables

unset PH_i PH_CUR_USER PH_MOVE_SCRIPTS_REGEX PH_OLD_DISTRO_REL PH_FORMAT_FLAG PH_DISTROU
