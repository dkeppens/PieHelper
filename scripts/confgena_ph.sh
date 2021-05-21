#!/bin/bash
# Build and Snapshot archive management for PieHelper (by Davy Keppens on 04/10/2018)
# Enable/Disable debug by running 'confpieh_ph.sh -p debug -m confgena_ph.sh'

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

declare PH_APP=""
declare PH_NEW_VERSION=""
declare PH_OPTION=""
declare PH_ARCHIVE_TYPE=""
declare PH_ARCHIVE_NAME=""
declare PH_ARCHIVE_DIR=""
declare PH_ACTION=""
declare PH_TIMESTAMP="$(date +'%d%m%y-%Hh%M' 2>/dev/null)"
declare PH_DENY_AUTO_UPDATE=""
declare PH_GIT_COMMIT_MASTER=""
declare PH_GIT_COMMIT_MSG=""
declare PH_OLDOPTARG="$OPTARG"
declare -u PH_APPU=""
declare -i PH_OLDOPTIND="$OPTIND"
declare -i PH_RET_CODE="0"
declare -i PH_ARRAY_INDEX="0"

OPTIND="1"

while getopts p:v:m:t:gdh PH_OPTION 2>/dev/null
do
	case "$PH_OPTION" in v)
		[[ -n "$PH_NEW_VERSION" ]] && \
			(! confgena_ph.sh -h) && \
			OPTARG="$PH_OLDOPTARG" && \
			OPTIND="$PH_OLDOPTIND" && \
			exit 1
		! ph_screen_input "$OPTARG" && \
			OPTARG="$PH_OLDOPTARG" && \
			OPTIND="$PH_OLDOPTIND" && \
			exit 1
		[[ "$OPTARG" != +([[:digit:]])\.+([[:digit:]]) ]] && \
			(! confgena_ph.sh -h) && \
			OPTARG="$PH_OLDOPTARG" && \
			OPTIND="$PH_OLDOPTIND" && \
			exit 1
		PH_NEW_VERSION="$OPTARG" ;;
			     p)
		[[ -n "$PH_ACTION" ]] && \
			(! confgena_ph.sh -h) && \
			OPTARG="$PH_OLDOPTARG" && \
			OPTIND="$PH_OLDOPTIND" && \
			exit 1
		! ph_screen_input "$OPTARG" && \
			OPTARG="$PH_OLDOPTARG" && \
			OPTIND="$PH_OLDOPTIND" && \
			exit 1
		[[ "$OPTARG" != @(gen|rem) ]] && \
			(! confgena_ph.sh -h) && \
			OPTARG="$PH_OLDOPTARG" && \
			OPTIND="$PH_OLDOPTIND" && \
			exit 1
		PH_ACTION="$OPTARG" ;;
			     t)
		[[ -n "$PH_ARCHIVE_TYPE" ]] && \
			(! confgena_ph.sh -h) && \
			OPTARG="$PH_OLDOPTARG" && \
			OPTIND="$PH_OLDOPTIND" && \
			exit 1
		! ph_screen_input "$OPTARG" && \
			OPTARG="$PH_OLDOPTARG" && \
			OPTIND="$PH_OLDOPTIND" && \
			exit 1
		[[ "$OPTARG" != @(snapshot|build) ]] && \
			(! confgena_ph.sh -h) && \
			OPTARG="$PH_OLDOPTARG" && \
			OPTIND="$PH_OLDOPTIND" && \
			exit 1
		PH_ARCHIVE_TYPE="$OPTARG" ;;
			     d)
		PH_DENY_AUTO_UPDATE="yes" ;;
			     g)
		PH_GIT_COMMIT_MASTER="yes" ;;
			     m)
		PH_GIT_COMMIT_MSG="$OPTARG" ;;
			     *)
		>&2 printf "\n"
		>&2 printf "\033[36m%s\033[0m\n" "Usage : confgena_ph.sh -h |"
		>&2 printf "%23s\033[36m%s\033[0m\n" "" "-p [\"gen\"] -t [\"snapshot\"|\"build\" -v [version] '-m [commitmsg]' '-g' '-d'] |"
		>&2 printf "%23s\033[36m%s\033[0m\n" "" "-p [\"rem\"] -t [\"snapshot\"|\"build\"] -v [version]"
		>&2 printf "\n"
		>&2 printf "%3s%s\n" "" "Where -h displays this usage"
		>&2 printf "%9s%s\n" "" "-p specifies the action to take"
		>&2 printf "%12s%s\n" "" "\"gen\" allows generating a timestamped tar archive of the specified type and for version [curversion] for 'snapshot' archives or"
		>&2 printf "%12s%s\n" "" "  specified version [version] for 'build' archives"
		>&2 printf "%15s%s\n" "" "- If PH_PIEH_CIFS_SHARE is set to 'yes' a backup copy of the generated archive"
		>&2 printf "%15s%s\n" "" "  will be created in directory PH_PIEH_CIFS_DIR/PH_PIEH_CIFS_SUBDIR on CIFS server PH_PIEH_CIFS_SRV"
		>&2 printf "%15s%s\n" "" "  More info on these settings can be viewed using 'confopts_ph.sh' or the PieHelper menu"
		>&2 printf "%15s%s\n" "" "- Integrated applications with active CIFS mounts on default mountpoints will be halted before archive generation"
		>&2 printf "%12s%s\n" "" "\"rem\" allows removing the most recently modified tar archive of the specified type and version"
		>&2 printf "%15s%s\n" "" "- If PH_PIEH_CIFS_SHARE is set to 'yes' the most recent backup of the specified archive type"
		>&2 printf "%15s%s\n" "" "  will be removed in directory PH_PIEH_CIFS_DIR/PH_PIEH_CIFS_SUBDIR on CIFS server PH_PIEH_CIFS_SRV when found"
		>&2 printf "%15s%s\n" "" "  More info on these settings can be viewed using 'confopts_ph.sh' or the PieHelper menu"
		>&2 printf "%9s%s\n" "" "-t allows specifying a supported archive type to act on"
		>&2 printf "%12s%s\n" "" "- Supported archive types are :"
		>&2 printf "%15s%s\n" "" "\"snapshot\" type archives are configuration snapshots"
		>&2 printf "%18s%s\n" "" "- The archive name will be set to :"
		>&2 printf "%21s%s\n" "" "- 'PieHelper-[timestamp]-snapshot-[curversion].tar' for 'gen' operations"
		>&2 printf "%24s%s\n" "" "- The value for [timestamp] is formatted as 'DDMMYY-HHhMM' where"
		>&2 printf "%27s%s\n" "" "- 'DD' is a two digit identifier representing the current day of month"
		>&2 printf "%27s%s\n" "" "- 'MM' is a two digit identifier representing the current month of year"
		>&2 printf "%27s%s\n" "" "- 'YY' is a two digit identifier representing the current year"
		>&2 printf "%27s%s\n" "" "- 'HH' is a two digit identifier representing the current hour of day"
		>&2 printf "%27s%s\n" "" "- 'MM' is a two digit identifier representing the current minute of hour"
		>&2 printf "%24s%s\n" "" "- The value for [curversion] is the currently installed version of PieHelper"
		>&2 printf "%21s%s\n" "" "- 'PieHelper-*-snapshot-[version].tar' for 'rem' operations and will select the most recently modified file of all matched files"
		>&2 printf "%18s%s\n" "" "- The archive location will be set to '${PH_SNAPSHOT_DIR}'"
		>&2 printf "%15s%s\n" "" "\"build\" type archives are developer builds"
		>&2 printf "%18s%s\n" "" "- Differences between the current configuration and the last build committed to the local git repository will always be locally committed"
		>&2 printf "%18s%s\n" "" "- [version] will be used as tag for any local or remote git commits"
		>&2 printf "%18s%s\n" "" "- Any git related failures will generate warnings"
		>&2 printf "%18s%s\n" "" "- The archive name will be set to :"
		>&2 printf "%21s%s\n" "" "- 'PieHelper-[timestamp]-build-[version].tar' for 'gen' operations"
		>&2 printf "%24s%s\n" "" "- The value for [timestamp] is formatted as 'DDMMYY-HHhMM' where"
		>&2 printf "%27s%s\n" "" "- 'DD' is a two digit identifier representing the current day of month"
		>&2 printf "%27s%s\n" "" "- 'MM' is a two digit identifier representing the current month of year"
		>&2 printf "%27s%s\n" "" "- 'YY' is a two digit identifier representing the current year"
		>&2 printf "%27s%s\n" "" "- 'HH' is a two digit identifier representing the current hour of day"
		>&2 printf "%27s%s\n" "" "- 'MM' is a two digit identifier representing the current minute of hour"
		>&2 printf "%21s%s\n" "" "- 'PieHelper-*-build-[version].tar' for 'rem' operations and will select the most recently modified file of all matched files"
		>&2 printf "%18s%s\n" "" "- The archive location will be set to '${PH_BUILD_DIR}'"
		>&2 printf "%9s%s\n" "" "-v allows specifying the version number [version] for either the build to generate or remove or the snapshot to remove"
		>&2 printf "%12s%s\n" "" "- [version] must be a decimal number"
		>&2 printf "%9s%s\n" "" "-d allows setting auto-update to denied for older builds migrating to new build [version]"
		>&2 printf "%12s%s\n" "" "- Specifying -d is optional"
		>&2 printf "%12s%s\n" "" "- Auto-update is allowed by default"
		>&2 printf "%9s%s\n" "" "-g allows requesting to commit all differences between the current configuration and the last build committed upstream to the master repository"
		>&2 printf "%12s%s\n" "" "- Specifying -g is optional"
		>&2 printf "%12s%s\n" "" "- Master repository commits require previously granted upstream access to the remote repository"
		>&2 printf "%12s%s\n" "" "- Master commits are disabled by default"
		>&2 printf "%9s%s\n" "" "-m allows setting a commit message [commitmsg] for commit operations"
		>&2 printf "%12s%s\n" "" "- Specifying -m is optional"
		>&2 printf "%12s%s\n" "" "- Always quote the value for [commitmsg] using single or double quotes"
		>&2 printf "%12s%s\n" "" "- Not specifying a [commitmsg] will skip any git operations with a warning"
		>&2 printf "\n"
		OPTIND="$PH_OLDOPTIND"
		OPTARG="$PH_OLDOPTARG"
		exit 1 ;;
	esac
done
OPTIND="$PH_OLDOPTIND"
OPTARG="$PH_OLDOPTARG"

PH_ROLLBACK_USED="yes"
[[ -z "$PH_ACTION" || -z "$PH_ARCHIVE_TYPE" ]] && \
	(! confgena_ph.sh -h) && \
	exit 1
[[ ( "$PH_ACTION" == "rem" ) && ( -n "$PH_DENY_AUTO_UPDATE" || -n "$PH_GIT_COMMIT_MASTER" || -n "$PH_GIT_COMMIT_MSG" ) ]] && \
	(! confgena_ph.sh -h) && \
	exit 1
[[ ( "$PH_ARCHIVE_TYPE" == "snapshot" && "$PH_ACTION" == "gen" ) && ( -n "$PH_DENY_AUTO_UPDATE" || -n "$PH_GIT_COMMIT_MASTER" || -n "$PH_GIT_COMMIT_MSG" || -n "$PH_NEW_VERSION" ) ]] && \
	(! confgena_ph.sh -h) && \
	exit 1
[[ "$PH_ACTION" == "rem" && -z "$PH_NEW_VERSION" ]] && \
	(! confgena_ph.sh -h) && \
	exit 1
[[ -z "$PH_GIT_COMMIT_MASTER" ]] && \
	PH_GIT_COMMIT_MASTER="no"
[[ -z "$PH_DENY_AUTO_UPDATE" ]] && \
	PH_DENY_AUTO_UPDATE="no"
if [[ "$PH_ARCHIVE_TYPE" == "snapshot" ]]
then
	PH_ARCHIVE_DIR="$PH_SNAPSHOT_DIR"
	if [[ "$PH_ACTION" == "gen" ]]
	then
		PH_ARCHIVE_NAME="PieHelper-${PH_TIMESTAMP}-${PH_ARCHIVE_TYPE}-${PH_VERSION}.tar"
	else
		PH_ARCHIVE_NAME="PieHelper-*-${PH_ARCHIVE_TYPE}-${PH_NEW_VERSION}.tar"
	fi
else
	PH_ARCHIVE_DIR="$PH_BUILD_DIR"
	if [[ "$PH_ACTION" == "gen" ]]
	then
		PH_ARCHIVE_NAME="PieHelper-${PH_TIMESTAMP}-${PH_ARCHIVE_TYPE}-${PH_NEW_VERSION}.tar"
	else
		PH_ARCHIVE_NAME="PieHelper-*-${PH_ARCHIVE_TYPE}-${PH_NEW_VERSION}.tar"
	fi
fi
printf "\n"
case "$PH_ACTION" in gen)
	printf "\033[36m%s\033[0m" "- Creating '${PH_ARCHIVE_TYPE}' archive for 'PieHelper' version "
	for PH_APP in $(nawk 'BEGIN { \
			ORS = " " \
		} \
		$3 !~ /^-$/ { \
			print $1 \
		}' "${PH_CONF_DIR}/integrated_apps" 2>/dev/null)
	do
		PH_APPU="${PH_APP:0:4}"
		if ! mount 2>/dev/null | nawk -v path=^"${PH_MNT_DIR}/${PH_APP}"$ '$3 ~ path { \
				exit 1 \
			}'
		then
			if [[ "$(eval "echo -n \"\$PH_${PH_APPU}_CIFS_MPT\"")" == "${PH_MNT_DIR}/${PH_APP}" ]]
			then
				ph_stop_all_running_apps "$PH_APP" || \
					exit 1
			fi
		fi
	done
	if [[ "$PH_ARCHIVE_TYPE" == "build" ]]
	then
		printf "\033[36m%s\033[0m\n\n" "'${PH_NEW_VERSION}'"
		ph_run_with_rollback -c "ph_update_pieh_version \"$PH_NEW_VERSION\"" || \
			exit 1
		if [[ "$PH_DENY_AUTO_UPDATE" == "yes" ]]
		then
			ph_run_with_rollback -c "ph_create_empty_file -t file -d \"${PH_FILES_DIR}/auto_update_denied\"" || \
				exit 1
		fi
		ph_unconfigure_pieh -u -b || \
			exit 1
		ph_git_local -v "$PH_NEW_VERSION" -m "$PH_GIT_COMMIT_MSG"
		if [[ "$PH_GIT_COMMIT_MASTER" == "yes" ]]
		then
			ph_git_master -v "$PH_NEW_VERSION" -m "$PH_GIT_COMMIT_MSG"
		fi
	else
		printf "\033[36m%s\033[0m\n\n" "'${PH_VERSION}'"
	fi
	printf "%8s%s\n" "" "--> Creating '${PH_ARCHIVE_DIR}/${PH_ARCHIVE_NAME}'"
	cd "$PH_BASE_DIR" >/dev/null 2>&1
	if tar -X "${PH_EXCLUDES_DIR}/tar.excludes" --anchored -cvf "${PH_ARCHIVE_DIR}/${PH_ARCHIVE_NAME}" ./* >/dev/null 2>&1
	then
		if [[ "$PH_ARCHIVE_TYPE" == "build" ]]
		then
			ph_run_with_rollback -c true
			for PH_ARRAY_INDEX in "${!PH_DEPTH[@]}"
			do
				PH_ROLLBACK_PARAMS+=("${PH_DEPTH_PARAMS["$PH_ARRAY_INDEX"]}")
				unset PH_DEPTH["$PH_ARRAY_INDEX"]
			done
			ph_rollback_changes
			PH_RET_CODE="$?"
		else
			ph_run_with_rollback -l -c true
		fi
	else
		printf "%10s\033[31m%s\033[0m\n" "" "ERROR : Could not create ${PH_ARCHIVE_TYPE}"
		ph_run_with_rollback -l -c false || \
			exit 1
	fi
	cd - >/dev/null 2>&1
	if [[ "$PH_PIEH_CIFS_SHARE" == "yes" ]]
	then
		ph_set_result -t -r "$PH_RET_CODE"
		printf "\033[36m%s\033[0m\n\n" "- Creating CIFS backup for '${PH_ARCHIVE_TYPE}' archive"
		if ph_mount_cifs_share PieHelper
		then
			printf "%8s%s\n" "" "--> Creating CIFS backup '//${PH_PIEH_CIFS_SRV}:${PH_PIEH_CIFS_DIR}${PH_PIEH_CIFS_SUBDIR}/${PH_ARCHIVE_NAME}'"
			if cp -p "${PH_ARCHIVE_DIR}/${PH_ARCHIVE_NAME}" "$(eval echo -n "$PH_PIEH_CIFS_MPT")"/ >/dev/null 2>&1
			then
				ph_run_with_rollback -c true
			else
				printf "%10s\033[31m%s\033[0m\n" "" "ERROR : Could not create backup"
				ph_set_result -r 1
			fi
			ph_umount_cifs_share PieHelper
		fi
		ph_show_result
		ph_set_result -t -r "$?"
		ph_show_result -t
	fi
	exit "$?" ;;
		     rem)
	PH_ARCHIVE_NAME="$(ls -t "${PH_ARCHIVE_DIR}/${PH_ARCHIVE_NAME}" 2>/dev/null | head -n1)"
	printf "\033[36m%s\033[0m\n\n" "- Removing most recently modified '${PH_ARCHIVE_TYPE}' archive for 'PieHelper' version '${PH_NEW_VERSION}'"
	if [[ -z "$PH_ARCHIVE_NAME" ]]
	then
		ph_set_result -r 0 -w -m "No archives matched"
	else
		printf "%8s%s\n" "" "--> Removing '${PH_ARCHIVE_NAME}'"
		if "$PH_SUDO" rm "$PH_ARCHIVE_NAME" >/dev/null 2>&1
		then
			ph_run_with_rollback -l -c true
		else
			printf "%10s\033[31m%s\033[0m\n" "" "ERROR : Could not remove ${PH_ARCHIVE_TYPE}"
			ph_run_with_rollback -l -c false || \
				exit 1
		fi
	fi
	if [[ "$PH_PIEH_CIFS_SHARE" == "yes" ]]
	then
		ph_set_result -t -r 0
		printf "\033[36m%s\033[0m\n\n" "- Removing CIFS backup for '${PH_ARCHIVE_TYPE}' archive"
		ph_mount_cifs_share PieHelper
		if [[ "$?" -eq "0" ]]
		then
			printf "%8s%s\n" "" "--> Removing CIFS backup '${PH_PIEH_CIFS_SRV}:${PH_PIEH_CIFS_DIR}${PH_PIEH_CIFS_SUBDIR}/${PH_ARCHIVE_NAME##*/}'"
			"$PH_SUDO" rm "$(eval echo -n "${PH_PIEH_CIFS_MPT}")/${PH_ARCHIVE_NAME##*/}" >/dev/null 2>&1
			if [[ "$?" -ne "0" ]]
			then
				printf "%10s\033[31m%s\033[0m\n" "" "ERROR : Could not remove backup"
				ph_set_result -r 1
			else
				ph_run_with_rollback -c true
			fi
			ph_umount_cifs_share PieHelper
		fi
		ph_show_result
		ph_set_result -t -r "$?"
		ph_show_result -t
	fi
	exit "$?" ;;
esac
confgena_ph.sh -h || \
	exit 1
