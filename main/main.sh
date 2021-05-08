# Main PieHelper (By Davy Keppens on 06/10/18)
# Enable/Disable debug by running 'confpieh_ph.sh -p debug -m main.sh'

#set -x

# Enable extended globbing for bash

shopt -s extglob

# Local variable declarations

declare PH_i=""
declare PH_LOAD_FILES=""
declare PH_MOVE_SCRIPTS_REGEX=""
declare PH_ALLOW_USERS=""
declare -i PH_FLAG="1"

# Global variable declarations not related to rollback

PH_SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PH_INST_DIR="${PH_SCRIPTS_DIR%/PieHelper/scripts}"
PH_BASE_DIR="${PH_INST_DIR}/PieHelper"
PH_BUILD_DIR="${PH_BASE_DIR}/builds"
PH_SNAPSHOT_DIR="${PH_BASE_DIR}/snapshots"
PH_MNT_DIR="${PH_BASE_DIR}/mnt"
PH_CONF_DIR="${PH_SCRIPTS_DIR}/../conf"
PH_MAIN_DIR="${PH_SCRIPTS_DIR}/../main"
PH_TMP_DIR="${PH_SCRIPTS_DIR}/../tmp"
PH_FILES_DIR="${PH_SCRIPTS_DIR}/../files"
PH_MENUS_DIR="${PH_FILES_DIR}/menus"
PH_TEMPLATES_DIR="${PH_FILES_DIR}/templates"
PH_EXCLUDES_DIR="${PH_FILES_DIR}/excludes"
PH_SUPPORTED_DISTROS+=("Archlinux" "jessie" "stretch" "buster" "bullseye")
PH_VERSION=""
PH_DISTRO=""
PH_SPEC_DISTRO=""
PH_RUN_USER=""
PH_SUDO=""
PH_PI_MODEL="$(nawk '$0 ~ /Raspberry Pi/ { \
		for (i=1;i<=NF;i++) { \
			if ($i ~ /^Raspberry$/ && $(i+1) ~ /^Pi$/) { \
				printf "pi" $(i+2) ; \
				exit 0 \
			} \
		} \
	}' /proc/cpuinfo 2>/dev/null)"

if [[ "$(dtoverlay -l 2>/dev/null | grep -E "vc4-(f)*kms-v3d" >/dev/null ; echo "$?")" -eq "0" || \
	( "$PH_PI_MODEL" == "pi4" && "$(dtoverlay -l 2>/dev/null | grep -E "vc4-kms-v3d-pi4" >/dev/null ; echo "$?")" -eq "0" ) || \
	"$(ls -ld /sys/firmware/devicetree/base/chosen/framebuffer\@* 2>/dev/null | wc -l)" -gt "0" ]]
then
	PH_FILE_SUFFIX="_GL"
else
	PH_FILE_SUFFIX="_X"
fi

export PH_SCRIPTS_DIR PH_INST_DIR PH_BASE_DIR PH_BUILD_DIR PH_SNAPSHOT_DIR PH_MNT_DIR PH_CONF_DIR PH_MAIN_DIR PH_TMP_DIR PH_FILES_DIR PH_MENUS_DIR PH_EXCLUDES_DIR PH_TEMPLATES_DIR
export PH_VERSION PH_DISTRO PH_SPEC_DISTRO PH_RUN_USER PH_SUDO PH_PI_MODEL PH_FILE_SUFFIX PH_SUPPORTED_DISTROS

# Global variable declarations related to rollback

PH_ROLLBACK_USED=""
PH_RESULT_MSG=""
PH_RESULT_TYPE_USED=""
PH_TOTAL_RESULT=""
PH_RESULT=""
PH_ALL_ROLLBACK_PARAMS="PH_DEPTH_PARAMS PH_DEPTH PH_CONFIGURED_STATE PH_UNCONFIGURED_STATE PH_GROUPS PH_REMOVE_ACLS_USERS PH_CREATE_ACLS_USERS \
	PH_REMOVE_RIGHTS_USERS PH_CREATE_RIGHTS_USERS PH_INSTALL_PKGS PH_REMOVE_PKGS PH_INT_APPS PH_SUP_APPS PH_UNINT_APPS PH_UNSUP_APPS PH_OPTIONS PH_PIEH_VERSION PH_OLD_VERSION \
	PH_BOOTENV PH_ENABLE_TTYS PH_DISABLE_TTYS PH_SETUP_TTYS PH_UNDO_SETUP_TTYS PH_BLACKLIST_MODULES PH_UNBLACKLIST_MODULES PH_LOAD_MODULES PH_UNLOAD_MODULES \
	PH_CREATE_EMPTY_FILES PH_REMOVE_EMPTY_FILES PH_CREATE_APPS_ITEMS PH_REMOVE_APPS_ITEMS PH_GIT_ADD_LOCAL PH_GIT_TAG_LOCAL PH_GIT_COMMIT_LOCAL PH_GIT_CLONE_MASTER \
	PH_GIT_UNDO_CLONE_MASTER PH_GIT_COMMIT_MASTER PH_OLD_GIT_COMMIT_MSG PH_SECURE PH_LINK_MENUS PH_UNDO_LINK_MENUS PH_STORE_FILES PH_RESTORE_FILES PH_ADD_LINES PH_REMOVE_LINES \
	PH_ADD_APPS_TO_INT_FILE PH_REMOVE_APPS_FROM_INT_FILE PH_ADD_APPS_TO_SUP_FILE PH_REMOVE_APPS_FROM_SUP_FILE PH_MODIFY_APPS_SCRIPT PH_START_APPS PH_STOP_APPS PH_STARTAPP \
	PH_SET_BOOT_TTYS PH_COPY_FILES PH_GRANT_APPS_ACCESS PH_REVOKE_APPS_ACCESS PH_CREATE_APPS_DIR PH_REMOVE_APPS_DIR PH_CREATE_APPS_ALLOWEDS PH_REMOVE_APPS_ALLOWEDS \
	PH_CREATE_APPS_DEFAULTS PH_REMOVE_APPS_DEFAULTS PH_CREATE_APPS_CONF_FILE PH_REMOVE_APPS_CONF_FILE PH_CREATE_APPS_MENUS PH_REMOVE_APPS_MENUS PH_CREATE_APPS_SCRIPTS \
	PH_REMOVE_APPS_SCRIPTS PH_CREATE_OOS_APPS_CODE PH_REMOVE_OOS_APPS_CODE PH_VARIABLES PH_STORE_OPTION PH_RETRIEVE_STORED_OPTION PH_INSTALL_APPS PH_UNINSTALL_APPS"

export PH_ROLLBACK_USED PH_RESULT_MSG PH_RESULT_TYPE_USED PH_TOTAL_RESULT PH_RESULT PH_ALL_ROLLBACK_PARAMS

declare -ix PH_RESULT_COUNT="0"
declare -ix PH_TOTAL_RESULT_COUNT="0"
declare -ix PH_ROLLBACK_DEPTH="0"

# Set Linux distro and release

if [[ -f /usr/bin/pacman ]]
then
	PH_DISTRO="Archlinux"
	PH_SPEC_DISTRO="Archlinux"
else
	PH_DISTRO="Debian"
	[[ -L "${PH_CONF_DIR}/distros/${PH_DISTRO}.conf" ]] && \
		PH_SPEC_DISTRO="$(find "${PH_CONF_DIR}/distros" -name "${PH_DISTRO}.conf" -mount -exec ls -l {} \; 2>/dev/null | nawk -F"/" '{ \
				print substr($NF,1,length($NF)-5) \
			}')"
fi

# Set PATH and LD_LIBRARY_PATH

LD_LIBRARY_PATH="/usr/local/lib:/usr/lib:/lib:${LD_LIBRARY_PATH}"
PATH="${PH_SCRIPTS_DIR}:/usr/local/bin:${PATH}"
export LD_LIBRARY_PATH PATH

# Load all relevant module declarations

for PH_i in functions functions.user functions.update "distros/functions.${PH_DISTRO}"
do
	if [[ -f "${PH_MAIN_DIR}/${PH_i}" && -r "${PH_MAIN_DIR}/${PH_i}" ]]
	then
		if ! source "${PH_MAIN_DIR}/${PH_i}" >/dev/null 2>&1
		then
			printf "\n%2s\033[31m%s\033[0m\n\n" "" "ABORT : Reinstallation of PieHelper is required (Could not load critical codebase file '${PH_MAIN_DIR}/${PH_i}')"
			exit 1
		fi
	else
		printf "\n%2s\033[31m%s\033[0m\n\n" "" "ABORT : Reinstallation of PieHelper is required (Missing or unreadable critical codebase file '${PH_MAIN_DIR}/${PH_i}')"
		exit 1
	fi
done

# Load distribution configuration

for PH_i in "${PH_SUPPORTED_DISTROS[@]}"
do
        if [[ ! -f "${PH_CONF_DIR}/distros/${PH_i}.conf" || ! -r "${PH_CONF_DIR}/distros/${PH_i}.conf" ]]
        then
		ph_set_result -a -m "Reinstallation of PieHelper is required (Missing or unreadable critical config file '${PH_CONF_DIR}/distros/${PH_i}.conf')"
        fi
done

# Set version

PH_VERSION="$(cat "${PH_FILES_DIR}/VERSION" 2>/dev/null)"
if [[ "$PH_VERSION" != +([[:digit:]])\.+([[:digit:]]) ]]
then
	ph_set_result -a -m "Reinstallation of PieHelper is required (Missing or corrupted critical config file '${PH_FILES_DIR}/VERSION')"
fi

# Load controller settings and configuration of all supported and default applications as well as distro-specific configuration

for PH_i in Ctrls "${PH_DISTRO}" $(nawk 'BEGIN { \
		i = "1" \
	} \
	NR == "1" { \
		optarr[i] = $1 ; \
		next \
	} { \
		for (j=1;j<=i;j++) { \
			if ($1 == optarr[j]) { \
				next \
			} else { \
				i++ ; \
				optarr[i] = $1 \
			}
		} \
	} END { \
		for (j=1;j<=i;j++) { \
			printf optarr[j] ; \
			delete optarr[j] \
		} ; \
		if (j != i) { \
			printf " " \
		} \
	}' "${PH_CONF_DIR}/default_apps${PH_FILE_SUFFIX}" "${PH_CONF_DIR}/supported_apps" 2>/dev/null)
do
	if [[ -f "${PH_CONF_DIR}/${PH_i}.conf" ]]
	then
		source "${PH_CONF_DIR}/${PH_i}.conf" >/dev/null 2>&1
	else
		source "${PH_TEMPLATES_DIR}/${PH_i}_conf.template" >/dev/null 2>&1
	fi
done

# Handle modules xtrace

if [[ -n "$PH_PIEH_DEBUG" ]]
then
	for PH_i in ${PH_PIEH_DEBUG//,/ }
	do
		if [[ "$PH_i" != *.sh ]]
		then
			if ! functions -t "$PH_i" >/dev/null 2>&1
			then
				[[ "$PH_FLAG" -eq "1" ]] && \
					PH_FLAG="0" && \
					printf "\n"
				printf "\n%2s\033[33m%s\033[0m" "" "Warning : Failed to enable debug for module '${PH_i}'"
			fi
		fi
	done
	if [[ "$PH_FLAG" -eq "0" ]]
	then
		printf "\n\n"
		sleep 3
	fi
fi

# Initialize rollback

for PH_i in ${PH_ALL_ROLLBACK_PARAMS}
do
	unset "$PH_i" 2>/dev/null
	declare -a "$PH_i"
done
ph_initialize_rollback

# Set sudo variable PH_SUDO

"$(command -v sudo 2>/dev/null)" bash -c exit 2>/dev/null && \
	PH_SUDO="$(command -v sudo 2>/dev/null)"

# Clean temp directory

ph_clean_tmp_dir

# Checking configuration

if [[ "$(ps -p "$$" -o args 2>/dev/null | tail -1)" == "/bin/bash ${PH_SCRIPTS_DIR}/confpieh_ph.sh -v" ]]
then
	if [[ "$(whoami 2>/dev/null)" != "root" ]]
	then
		if [[ -n "$PH_SUDO" ]]
		then
			printf "\n\033[31m%s\033[0m\n" "Run '${PH_SUDO} ${PH_SCRIPTS_DIR}/confpieh_ph.sh -v'"
		else
			printf "\n\033[31m%s\33[0m\n" "Run 'su' and provide the system's admin password to become user 'root' and try again"
		fi
		ph_set_result -a -m "Privilege elevation is required to repair PieHelper : Use the method listed above to obtain elevation"
	fi
	ph_repair_pieh
	exit "$?"
fi
if [[ "$PH_PIEH_SANITY" == "yes" ]]
then
	PH_MOVE_SCRIPTS_REGEX="$(ph_get_move_scripts_regex)"
	if [[ "$("$PH_SUDO" cat "/proc/${PPID}/comm" 2>/dev/null)" != +(conf*_ph|list*_ph|start*|restart*${PH_MOVE_SCRIPTS_REGEX}).sh ]]
	then
		if [[ -f "${PH_TMP_DIR}/reported_issues" ]]
		then
			ph_show_report || \
				exit "$?"
		else
			if [[ -f "${PH_TMP_DIR}/.first_run" ]]
			then
				ph_check_pieh_shared_config
				ph_check_pieh_unconfigured_config
				if [[ -f "${PH_TMP_DIR}/reported_issues" ]]
				then
					printf "%2s%s\n" "" "OR" >>"${PH_TMP_DIR}/reported_issues"
					ph_check_pieh_shared_config
					ph_check_pieh_configured_config
				fi
			else
				ph_check_pieh_shared_config
				ph_check_pieh_configured_config
				if [[ -f "${PH_TMP_DIR}/reported_issues" ]]
				then
					printf "%2s%s\n" "" "OR" >>"${PH_TMP_DIR}/reported_issues"
					ph_check_pieh_shared_config
					ph_check_pieh_unconfigured_config
				fi
			fi
		fi
	fi
	if [[ -f "${PH_TMP_DIR}/reported_issues" ]]
	then
		ph_show_report || \
			exit "$?"
	fi
fi

# Clean temp directory again

ph_clean_tmp_dir

# Re-initialize rollback

for PH_i in ${PH_ALL_ROLLBACK_PARAMS}
do
	unset "$PH_i" 2>/dev/null
	declare -a "$PH_i"
done
ph_initialize_rollback

# Autodetect first run

if [[ -f "${PH_TMP_DIR}/.first_run" ]]
then
	clear
	printf "\n\033[36m%s\033[0m\n\n" "- Configuring PieHelper '${PH_VERSION}'"
	ph_configure_pieh
	exit "$?"
fi

# Set the user account configured to run PieHelper

PH_RUN_USER="$(nawk -v mstring="^PieHelper$" '$1 ~ mstring { \
		printf $2 \
	}' "${PH_CONF_DIR}/integrated_apps" 2>/dev/null)"

# Set all user accounts allowed to run PieHelper

[[ "$PH_RUN_USER" == "root" ]] && \
	PH_ALLOW_USERS="$PH_RUN_USER"
for PH_i in $("$PH_SUDO" find "/etc/sudoers.d" -name "020_pieh-*" -mount 2>/dev/null | paste -d " " -s)
do
	PH_i="${PH_i##/etc/sudoers.d/020_pieh-}"
	if [[ -z "$PH_ALLOW_USERS" ]]
	then
		PH_ALLOW_USERS="$PH_i"
	else
		PH_ALLOW_USERS="${PH_ALLOW_USERS}|${PH_i}"
	fi
done
[[ -z "$PH_ALLOW_USERS" ]] && \
	ph_set_result -a -m "Failed to determine users with access : Make sure the sudo config for user '${PH_RUN_USER}' exists as '/etc/sudoers.d/020_pieh-${PH_RUN_USER}'"

# Check whether the current user is allowed

if [[ "$(whoami 2>/dev/null)" != @(${PH_ALLOW_USERS}) ]]
then
	if [[ -z "$PH_RUN_USER" ]]
	then
		touch "${PH_TMP_DIR}/.first_run" 2>/dev/null
		ph_set_result -a -m "Unknown user account for PieHelper : Try configuring first by running '${PH_SCRIPTS_DIR}/confpieh_ph.sh -c'"
	else
		ph_set_result -a -m "Only the following accounts are allowed to run PieHelper : '${PH_ALLOW_USERS//|/ /}'"
	fi
fi

# Unset local variables

unset PH_i PH_ALLOW_USERS PH_MOVE_SCRIPTS_REGEX PH_FLAG 2>/dev/null
