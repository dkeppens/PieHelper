# Main PieHelper (By Davy Keppens on 06/10/18)
# Enable/Disable debug by running 'confpieh_ph.sh -p debug -m main.sh'

#set -x

# Enable extended globbing for bash

shopt -s extglob

# Local variable declarations

declare PH_i=""
declare PH_ALLOW_USERS=""
declare PH_MOVE_SCRIPTS_REGEX=""

# Global variable declarations not related to rollback

PH_SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PH_INST_DIR="${PH_SCRIPTS_DIR%/PieHelper/scripts}"
PH_BASE_DIR="$PH_INST_DIR"/PieHelper
PH_BUILD_DIR="$PH_BASE_DIR"/builds
PH_SNAPSHOT_DIR="$PH_BASE_DIR"/snapshots
PH_MNT_DIR="$PH_BASE_DIR"/mnt
PH_CONF_DIR="$PH_SCRIPTS_DIR"/../conf
PH_MAIN_DIR="$PH_SCRIPTS_DIR"/../main
PH_TMP_DIR="$PH_SCRIPTS_DIR"/../tmp
PH_FILES_DIR="$PH_SCRIPTS_DIR"/../files
PH_MENUS_DIR="$PH_FILES_DIR"/menus
PH_VERSION=""
PH_DISTRO=""
PH_SPEC_DISTRO=""
PH_RUN_USER=""
PH_SUDO=""
PH_PI_MODEL="$(nawk '$0 ~ /Raspberry Pi/ { for (i=1;i<=NF;i++) { if ($i~/^Raspberry$/ && $(i+1)~/^Pi$/) { print "RPI" $(i+2) ; exit 0 }}}' /proc/cpuinfo 2>/dev/null)"

if [[ "$PH_PI_MODEL" == "RPI4" ]]
then
	PH_FILE_SUFFIX="_GL"
else
	PH_FILE_SUFFIX="_X"
fi

export PH_SCRIPTS_DIR PH_INST_DIR PH_BASE_DIR PH_BUILD_DIR PH_SNAPSHOT_DIR PH_MNT_DIR PH_CONF_DIR PH_MAIN_DIR PH_TMP_DIR PH_FILES_DIR PH_MENUS_DIR
export PH_VERSION PH_DISTRO PH_SPEC_DISTRO PH_RUN_USER PH_SUDO PH_PI_MODEL PH_FILE_SUFFIX

# Global variable declarations related to rollback

PH_ROLLBACK_USED=""
PH_RESULT_MSG=""
PH_RESULT_TYPE_USED=""
PH_TOTAL_RESULT=""
PH_RESULT=""
PH_ALL_ROLLBACK_PARAMS="PH_ROLLBACK_PARAMS PH_DEPTH_PARAMS PH_DEPTH PH_CONFIGURED_STATE PH_UNCONFIGURED_STATE PH_GROUPS PH_REMOVE_ACLS_USERS PH_CREATE_ACLS_USERS PH_REMOVE_RIGHTS_USERS PH_CREATE_RIGHTS_USERS \
	PH_INSTALL_PKGS	PH_REMOVE_PKGS PH_INT_APPS PH_SUP_APPS PH_UNINT_APPS PH_UNSUP_APPS PH_OPTIONS PH_PIEH_VERSION PH_BOOTENV PH_ENABLE_TTYS PH_DISABLE_TTYS PH_SETUP_TTYS PH_UNDO_SETUP_TTYS PH_BLACKLIST_MODULES \
	PH_UNBLACKLIST_MODULES PH_LOAD_MODULES PH_UNLOAD_MODULES PH_CREATE_EMPTY_FILES PH_REMOVE_EMPTY_FILES PH_CREATE_APPS_ITEMS PH_REMOVE_APPS_ITEMS PH_GIT_ADD_LOCAL PH_GIT_TAG_LOCAL PH_GIT_COMMIT_LOCAL \
	PH_GIT_COMMIT_MASTER PH_OLD_VERSION PH_OLD_GIT_COMMIT_MSG PH_SECURE PH_LINK_MENUS PH_UNDO_LINK_MENUS PH_STORE_FILES PH_RESTORE_FILES PH_ADD_LINES PH_REMOVE_LINES GIT_CLONE_MASTER GIT_UNDO_CLONE_MASTER \
	PH_ADD_APPS_TO_INT_FILE PH_REMOVE_APPS_FROM_INT_FILE PH_ADD_APPS_TO_SUP_FILE PH_REMOVE_APPS_FROM_SUP_FILE PH_MODIFY_APPS_SCRIPT PH_START_APPS PH_STOP_APPS PH_STARTAPP PH_SET_BOOT_TTYS PH_COPY_FILES \
	PH_GRANT_APPS_ACCESS PH_REVOKE_APPS_ACCESS PH_CREATE_APPS_DIR PH_REMOVE_APPS_DIR PH_CREATE_APPS_ALLOWEDS PH_REMOVE_APPS_ALLOWEDS PH_CREATE_APPS_DEFAULTS PH_REMOVE_APPS_DEFAULTS \
	PH_CREATE_APPS_CONF_FILE PH_REMOVE_APPS_CONF_FILE PH_CREATE_APPS_MENUS PH_REMOVE_APPS_MENUS PH_CREATE_APPS_SCRIPTS PH_REMOVE_APPS_SCRIPTS PH_CREATE_OOS_APPS_CODE PH_REMOVE_OOS_APPS_CODE"

export PH_ROLLBACK_USED PH_RESULT_MSG PH_RESULT_TYPE_USED PH_TOTAL_RESULT PH_RESULT PH_ALL_ROLLBACK_PARAMS

declare -ix PH_SCRIPT_FLAG="1"
declare -ix PH_RESULT_COUNT="0"
declare -ix PH_TOTAL_RESULT_COUNT="0"
declare -ix PH_ROLLBACK_DEPTH="0"

# Set Linux distro and release variables PH_DISTRO and PH_SPEC_DISTRO

if [[ -f /usr/bin/pacman ]]
then
	PH_DISTRO="Archlinux"
	PH_SPEC_DISTRO="Archlinux"
else
	PH_DISTRO="Debian"
	[[ -L "$PH_CONF_DIR/distros/$PH_DISTRO.conf" ]] && PH_SPEC_DISTRO="$(find "$PH_CONF_DIR/distros" -name "$PH_DISTRO.conf" -mount -exec ls -l {} \; 2>/dev/null | nawk -F"/" '{ print substr($NF,1,length($NF)-5) }')"
fi

# Set variables PATH and LD_LIBRARY_PATH

LD_LIBRARY_PATH="/usr/local/lib:/usr/lib:/lib:$LD_LIBRARY_PATH"
PATH="$PH_SCRIPTS_DIR:/usr/local/bin:$PATH"
export LD_LIBRARY_PATH PATH

# Source relevant module declarations

for PH_i in "$PH_MAIN_DIR/functions" "$PH_MAIN_DIR/functions.user" "$PH_MAIN_DIR/functions.update" "$PH_MAIN_DIR/distros/functions.$PH_DISTRO"
do
	if [[ ! -f "$PH_i" ]]
	then
		printf "\n%2s\033[31m%s\033[0m\n\n" "" "ABORT : Reinstallation and reconfiguration of PieHelper is required (Critical codebase file '$PH_i' missing)"
		exit 1
	fi
	. "$PH_i"
done

# Source system and all application configs as well as controller settings

for PH_i in buster jessie stretch
do
        if [[ ! -f "$PH_CONF_DIR/distros/$PH_i.conf" ]]
        then
		ph_set_result -a -m "Reinstallation and reconfiguration of PieHelper is required (Critical configuration file(s) '$PH_CONF_DIR/distros/$PH_i.conf' missing)"
        fi
done
for PH_i in $(nawk -v confdir="$PH_CONF_DIR" 'BEGIN { ORS = " " } { print confdir "/" $1 ".conf" } END { print confdir "/Ctrls.conf" }' "$PH_CONF_DIR/supported_apps" 2>/dev/null) "$PH_CONF_DIR/distros/$PH_DISTRO.conf"
do
	[[ -f "$PH_i" ]] && . "$PH_i" 2>/dev/null
done

# Handle modules xtrace

if [[ -n "$PH_PIEH_DEBUG" ]]
then
	for PH_i in $(sed 's/,/ /g' <<<"$PH_PIEH_DEBUG" 2>/dev/null)
	do
		[[ "$PH_i" != *.sh ]] && functions -t "$PH_i" 2>/dev/null
	done
fi

# Initialize rollback

for PH_i in ${PH_ALL_ROLLBACK_PARAMS}
do
	unset "$PH_i" 2>/dev/null
	declare -a "$PH_i"
done
ph_initialize_rollback

# Set version variable PH_VERSION

PH_VERSION="$(cat "$PH_CONF_DIR/VERSION" 2>/dev/null)"

# Set sudo variable PH_SUDO

"$(command -v sudo 2>/dev/null)" bash -c exit 2>/dev/null && PH_SUDO="$(command -v sudo 2>/dev/null)"

# Clear temp directory

"$PH_SUDO" rm "$PH_TMP_DIR/"!(@(.gitignore|unconfigure_in_progress)) 2>/dev/null

# Checking configuration

if [[ "$(ps -p "$$" -o args | tail -1)" == "/bin/bash $PH_SCRIPTS_DIR/confpieh_ph.sh -v" ]]
then
	if [[ "$(whoami)" != "root" ]]
	then
		if [[ -n "$PH_SUDO" ]]
		then
			printf "\n\033[31m%s\033[0m\n" "Run '$PH_SUDO $PH_SCRIPTS_DIR/confpieh_ph.sh -v'"
		else
			printf "\n\033[31m%s\33[0m\n" "Use 'su' to become 'root' and run '$PH_SCRIPTS_DIR/confpieh_ph.sh -v'"
		fi
		ph_set_result -a -m "'Root' privileges are mandatory to run PieHelper repair"
	fi
	ph_repair_pieh
	exit "$?"
fi
if [[ "$PH_PIEH_SANITY" == "yes" ]]
then
	PH_MOVE_SCRIPTS_REGEX="$(ph_get_move_scripts_regex)"
	if [[ "$("$PH_SUDO" cat "/proc/$PPID/comm" 2>/dev/null)" != +(conf*_ph|list*_ph|start*|restart*$PH_MOVE_SCRIPTS_REGEX).sh ]]
	then
		if [[ -f "$PH_TMP_DIR/reported_issues" ]]
		then
			ph_show_report || exit "$?"
		else
			if [[ -f "$PH_FILES_DIR/first_run" ]]
			then
				ph_check_pieh_shared_config
				ph_check_pieh_unconfigured_config
				if [[ -f "$PH_TMP_DIR/reported_issues" ]]
				then
					printf "%2s%s\n" "" "OR" >>"$PH_TMP_DIR/reported_issues"
					ph_check_pieh_shared_config
					ph_check_pieh_configured_config
				fi
			else
				ph_check_pieh_shared_config
				ph_check_pieh_configured_config
				if [[ -f "$PH_TMP_DIR/reported_issues" ]]
				then
					printf "%2s%s\n" "" "OR" >>"$PH_TMP_DIR/reported_issues"
					ph_check_pieh_shared_config
					ph_check_pieh_unconfigured_config
				fi
			fi
		fi
	fi
	if [[ -f "$PH_TMP_DIR/reported_issues" ]]
	then
		ph_show_report || exit "$?"
	fi
fi

# Clear temp directory again

"$PH_SUDO" rm "$PH_TMP_DIR/"!(@(.gitignore|unconfigure_in_progress)) 2>/dev/null

# Re-initialize rollback

for PH_i in ${PH_ALL_ROLLBACK_PARAMS}
do
	unset "$PH_i" 2>/dev/null
	declare -a "$PH_i"
done
ph_initialize_rollback

# Autodetect first run

if [[ -f "$PH_FILES_DIR/first_run" ]]
then
	clear
	printf "\n\033[36m%s\033[0m\n\n" "- Configuring PieHelper version '$PH_VERSION'"
	ph_configure_pieh
	exit "$?"
fi

# Set run account variable PH_RUN_USER

PH_RUN_USER="$(nawk -v app=^"PieHelper"$ '$1 ~ app { print $2 }' "$PH_CONF_DIR/integrated_apps" 2>/dev/null)"

# Set allowed run accounts variable PH_ALLOW_USERS

[[ "$PH_RUN_USER" == "root" ]] && PH_ALLOW_USERS="$PH_RUN_USER"
for PH_i in $("$PH_SUDO" find "/etc/sudoers.d" -name "020_pieh-*" -mount 2>/dev/null | paste -d " " -s)
do
	PH_i="${PH_i##/etc/sudoers.d/020_pieh-}"
	if [[ -z "$PH_ALLOW_USERS" ]]
	then
		PH_ALLOW_USERS="$PH_i"
	else
		PH_ALLOW_USERS="$PH_ALLOW_USERS"'|'"$PH_i"
	fi
done

# Checking variable PH_RUN_USER value against allowed values

if [[ "$(whoami)" != @($PH_ALLOW_USERS) ]]
then
	if [[ -z "$PH_RUN_USER" ]]
	then
		touch "$PH_FILES_DIR/first_run" 2>/dev/null
		ph_set_result -a -m "PieHelper run account is unknown -> Try configuring first by running '$PH_SCRIPTS_DIR/confpieh_ph.sh -c'"
	else
		ph_set_result -a -m "Running PieHelper as one of the following accounts is mandatory : '$(echo -n "$PH_ALLOW_USERS" | sed 's/|/ /g')'"
	fi
fi
