#!/bin/bash
# Archive management of Developer Builds and Configuration Snapshots (by Davy Keppens on 04/10/2018)
# Enable/Disable debug by running 'confpieh_ph.sh -p debug -m confgena_ph.sh'

if [[ -f "$(dirname "${0}" 2>/dev/null)/app/main.sh" && -r "$(dirname "${0}" 2>/dev/null)/app/main.sh" ]]
then
	source "$(dirname "${0}" 2>/dev/null)/app/main.sh"
	set +x
else
	printf "\n%2s\033[1;31m%s\033[0m\n\n" "" "ABORT : Reinstallation of PieHelper is required (Missing or unreadable critical codebase file '$(dirname "${0}" 2>/dev/null)/app/main.sh'"
	exit 1
fi

#set -x

declare PH_APP
declare PH_NEW_VERSION
declare PH_ARCHIVE_TYPE
declare PH_ARCHIVE_NAME
declare PH_ARCHIVE_DIR
declare PH_ACTION
declare PH_TIMESTAMP
declare PH_DENY_AUTO_UPDATE
declare PH_GIT_COMMIT_MASTER
declare PH_GIT_COMMIT_MSG
declare PH_PIEH_CIFS_MPT
declare PH_RUNNING_APPS
declare PH_LAST_RUNNING_APP
declare PH_OPTION
declare PH_OLDOPTARG
declare -i PH_OLDOPTIND
declare -u PH_APPU

PH_OLDOPTARG="${OPTARG}"
PH_OLDOPTIND="${OPTIND}"
PH_APP=""
PH_NEW_VERSION=""
PH_ARCHIVE_TYPE=""
PH_ARCHIVE_NAME=""
PH_ARCHIVE_DIR=""
PH_ACTION=""
PH_TIMESTAMP="$(date +'%d%m%y-%Hh%M' 2>/dev/null)"
PH_DENY_AUTO_UPDATE=""
PH_GIT_COMMIT_MASTER=""
PH_GIT_COMMIT_MSG=""
PH_PIEH_CIFS_MPT=""
PH_RUNNING_APPS=""
PH_LAST_RUNNING_APP=""
PH_OPTION=""
PH_APPU=""

OPTIND="1"

while getopts :v:p:t:m:gdh PH_OPTION
do
	case "${PH_OPTION}" in v)
		[[ -n "${PH_NEW_VERSION}" || "${OPTARG}" != +([[:digit:]])\.+([[:digit:]]) ]] && \
			(! confgena_ph.sh -h) && \
			OPTARG="${PH_OLDOPTARG}" && \
			OPTIND="${PH_OLDOPTIND}" && \
			exit 1
		PH_NEW_VERSION="${OPTARG}" ;;
			p)
		[[ -n "${PH_ACTION}" || "${OPTARG}" != @(gen|rem) ]] && \
			(! confgena_ph.sh -h) && \
			OPTARG="${PH_OLDOPTARG}" && \
			OPTIND="${PH_OLDOPTIND}" && \
			exit 1
		PH_ACTION="${OPTARG}" ;;
			t)
		[[ -n "${PH_ARCHIVE_TYPE}" || "${OPTARG}" != @(snapshot|build) ]] && \
			(! confgena_ph.sh -h) && \
			OPTARG="${PH_OLDOPTARG}" && \
			OPTIND="${PH_OLDOPTIND}" && \
			exit 1
		PH_ARCHIVE_TYPE="${OPTARG}" ;;
			m)
		[[ -n "${PH_GIT_COMMIT_MSG}" ]] && \
			(! confgena_ph.sh -h) && \
			OPTARG="${PH_OLDOPTARG}" && \
			OPTIND="${PH_OLDOPTIND}" && \
			exit 1
		PH_GIT_COMMIT_MSG="${OPTARG}" ;;
			g)
		[[ -n "${PH_GIT_COMMIT_MASTER}" ]] && \
			(! confgena_ph.sh -h) && \
			OPTARG="${PH_OLDOPTARG}" && \
			OPTIND="${PH_OLDOPTIND}" && \
			exit 1
		PH_GIT_COMMIT_MASTER="yes" ;;
			d)
		[[ -n "${PH_DENY_AUTO_UPDATE}" ]] && \
			(! confgena_ph.sh -h) && \
			OPTARG="${PH_OLDOPTARG}" && \
			OPTIND="${PH_OLDOPTIND}" && \
			exit 1
		PH_DENY_AUTO_UPDATE="yes" ;;
			*)
		>&2 printf "\n\n"
		>&2 printf "%2s\033[1;36m%s%s\033[1;4;35m%s\033[0m\n" "" "Archives" " : " "Create/Remove development builds or configuration snapshots"
		>&2 printf "\n\n"
		>&2 printf "%4s\033[1;5;33m%s\033[0m\n" "" "General options"
		>&2 printf "\n\n"
		>&2 printf "%6s\033[1;36m%s\033[1;37m%s\n" "" "$(basename "${0}" 2>/dev/null) : " "-p \"gen\" -t [\"snapshot\"|\"build\" -v [version] '-m [commitmsg]' '-g' '-d'] |"
		>&2 printf "%23s%s\n" "" "-p \"rem\" -t [\"snapshot\"|\"build\"] -v [version]"
		>&2 printf "%23s%s\n" "" "-h"
		>&2 printf "\n"
		>&2 printf "%15s\033[0m\033[1;37m%s\n" "" "Where : -p specifies the action to take"
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
		>&2 printf "\033[0m\n"
		OPTIND="${PH_OLDOPTIND}"
		OPTARG="${PH_OLDOPTARG}"
		exit 1 ;;
	esac
done
OPTIND="${PH_OLDOPTIND}"
OPTARG="${PH_OLDOPTARG}"

[[ -z "${PH_ACTION}" || -z "${PH_ARCHIVE_TYPE}" || \
	(( "${PH_ACTION}" == "rem" || ( "${PH_ARCHIVE_TYPE}" == "snapshot" && "${PH_ACTION}" == "gen" )) && ( -n "${PH_DENY_AUTO_UPDATE}" || -n "${PH_GIT_COMMIT_MASTER}" || -n "${PH_GIT_COMMIT_MSG}" )) || \
	( "${PH_ARCHIVE_TYPE}" == "snapshot" && "${PH_ACTION}" == "gen" && -n "${PH_NEW_VERSION}" ) || ( "${PH_ACTION}" == "rem" && -z "${PH_NEW_VERSION}" ) ]] && \
	(! confgena_ph.sh -h) && \
	exit 1

printf "\n"
PH_ROLLBACK_USED="yes"
[[ -z "${PH_GIT_COMMIT_MASTER}" ]] && \
	PH_GIT_COMMIT_MASTER="no"
[[ -z "${PH_DENY_AUTO_UPDATE}" ]] && \
	PH_DENY_AUTO_UPDATE="no"
if [[ "${PH_ARCHIVE_TYPE}" == "snapshot" ]]
then
	PH_ARCHIVE_DIR="${PH_SNAPSHOT_DIR}"
	if [[ "${PH_ACTION}" == "gen" ]]
	then
		PH_ARCHIVE_NAME="PieHelper-${PH_TIMESTAMP}-${PH_ARCHIVE_TYPE}-${PH_VERSION}.tar"
	else
		PH_ARCHIVE_NAME="-${PH_ARCHIVE_TYPE}-${PH_NEW_VERSION}.tar"
	fi
else
	PH_ARCHIVE_DIR="${PH_BUILD_DIR}"
	if [[ "${PH_ACTION}" == "gen" ]]
	then
		PH_ARCHIVE_NAME="PieHelper-${PH_TIMESTAMP}-${PH_ARCHIVE_TYPE}-${PH_NEW_VERSION}.tar"
	else
		PH_ARCHIVE_NAME="-${PH_ARCHIVE_TYPE}-${PH_NEW_VERSION}.tar"
	fi
fi
PH_PIEH_CIFS_MPT="$(ph_get_app_cifs_mpt -a PieHelper -r)"
PH_RUNNING_APPS="$(ph_get_app_list_by_state -s Running -t exact)"
if [[ "${PH_ACTION}" == "gen" ]]
then
	printf "\033[1;36m%s\033[0m\n\n" "- Creating a 'PieHelper' ${PH_ARCHIVE_TYPE} archive"
	for PH_APP in ${PH_RUNNING_APPS}
	do
		if [[ "$(ph_get_app_cifs_mpt -a "${PH_APP}" -r)" == "${PH_MNT_DIR}/${PH_APP}" && \
			"$(mount 2>/dev/null | nawk -v path="^${PH_MNT_DIR}/${PH_APP}$" '$3 ~ path && $5 ~ /^cifs$/ { \
					printf "yes" ; \
					exit 0 \
				}')" == "yes" ]]
		then
			ph_run_with_rollback -c "ph_do_app_action stop '${PH_APP}' force" || \
				exit 1
		fi
	done
	if [[ "${PH_ARCHIVE_TYPE}" == "build" ]]
	then
		ph_run_with_rollback -c "ph_update_pieh_version '${PH_NEW_VERSION}'" || \
			exit 1
		if [[ "${PH_DENY_AUTO_UPDATE}" == "yes" ]]
		then
			ph_run_with_rollback -c "ph_create_empty_file -t file -d '${PH_FILES_DIR}/auto_update_denied'" || \
				exit 1
		fi
		ph_run_with_rollback -c "ph_unconfigure_pieh -u -b" || \
			exit 1
		ph_git_local -v "${PH_NEW_VERSION}" -m "${PH_GIT_COMMIT_MSG}" || \
			exit 1
		if [[ "${PH_GIT_COMMIT_MASTER}" == "yes" ]]
		then
			ph_run_with_rollback -c "ph_git_commit_master -v '${PH_NEW_VERSION}' -m '${PH_GIT_COMMIT_MSG}'" || \
				exit 1
		fi
	fi
	printf "%8s%s\033[1;33m%s\033[0m%s\033[1;33m%s\033[0m%s\033[1;33m%s\033[0m" "" "--> Creating ${PH_ARCHIVE_TYPE} archive of " "'PieHelper'" " version " \
		"'${PH_NEW_VERSION}'" " as " "'${PH_ARCHIVE_DIR}/${PH_ARCHIVE_NAME}'"
	if [[ "${PH_ARCHIVE_TYPE}" == "build" ]]
	then
		printf "\033[1;33m%s\033[0m\n" "'${PH_NEW_VERSION}'"
	else
		printf "\033[1;33m%s\033[0m\n" "'${PH_VERSION}'"
	fi
	while true
	do
		while true
		do
			if cd "${PH_BASE_DIR}" >/dev/null 2>&1
			then
				if tar -X "${PH_EXCLUDES_DIR}/tar.excludes" --anchored -cf "${PH_ARCHIVE_DIR}/${PH_ARCHIVE_NAME}" ./* >/dev/null 2>&1
				then
					if cd - >/dev/null 2>&1
					then
						ph_run_with_rollback -c true -m "${PH_ARCHIVE_DIR}/${PH_ARCHIVE_NAME}"
						if [[ "${PH_ARCHIVE_TYPE}" == "build" ]]
						then
							ph_run_with_rollback -c "ph_configure_pieh -b" || \
								break 2
						fi
						for PH_APP in ${PH_RUNNING_APPS}
						do
							PH_APPU="${PH_APP}"
							if [[ "$(eval "echo -n \"\$PH_${PH_APPU:0:4}_PERSISTENT\"")" == "yes" ]]
							then
								ph_run_with_rollback -c "ph_do_app_action start '${PH_APP}'" || \
									 break 3
							else
								PH_LAST_RUNNING_APP="${PH_APP}"
							fi
						done
						if [[ -n "${PH_LAST_RUNNING_APP}" ]]
						then
							ph_run_with_rollback -c "ph_do_app_action start '${PH_LAST_RUNNING_APP}'" || \
								break 2
						fi
						if [[ "${PH_PIEH_CIFS_SHARE}" == "yes" ]]
						then
							if [[ "${PH_RUNNING_APPS}" != PieHelper* ]]
							then
								ph_run_with_rollback -c "ph_mount_cifs_share PieHelper" || \
									break 2
							fi
							printf "%8s%s\033[1;33m%s\033[0m\n" "" "--> Creating ${PH_ARCHIVE_TYPE} archive CIFS backup as " \
								"'//${PH_PIEH_CIFS_SRV}:$(ph_resolve_dynamic_value ${PH_PIEH_CIFS_DIR})$(ph_resolve_dynamic_value ${PH_PIEH_CIFS_SUBDIR})/${PH_ARCHIVE_NAME}'"
							if ph_run_with_rollback -c "ph_copy_file -s '${PH_ARCHIVE_DIR}/${PH_ARCHIVE_NAME}' -d '${PH_PIEH_CIFS_MPT}/${PH_ARCHIVE_NAME}' -q"
							then
								ph_run_with_rollback -c true -m \
									"//${PH_PIEH_CIFS_SRV}:$(ph_resolve_dynamic_value ${PH_PIEH_CIFS_DIR})$(ph_resolve_dynamic_value ${PH_PIEH_CIFS_SUBDIR})/${PH_ARCHIVE_NAME}"
								if [[ "${PH_RUNNING_APPS}" != PieHelper* ]]
								then
									ph_run_with_rolback -c "ph_umount_cifs_share PieHelper" || \
										break 2
								fi
							else
								break
							fi
						fi
						ph_show_result
						exit "${?}"
					else
						ph_set_result -m "An error occurred trying to change directory to '${OLDPWD}'"
					fi
				else
					ph_set_result -m "An error occurred trying to create ${PH_ARCHIVE_TYPE} archive '${PH_ARCHIVE_DIR}/$PH_ARCHIVE_NAME}'"
				fi
			else
				ph_set_result -m "An error occurred trying to change directory to '${PH_BASE_DIR}'"
			fi
			break
		done
		ph_run_with_rollback -c false -m "Could not create"
		break
	done
	"${PH_SUDO}" rm "${PH_ARCHIVE_DIR}/${PH_ARCHIVE_NAME}" 2>/dev/null
else
	printf "\033[1;36m%s\033[0m\n\n" "- Removing a 'PieHelper' ${PH_ARCHIVE_TYPE} archive"
	printf "%8s%s\n" "" "--> Determining the most recently modified ${PH_ARCHIVE_TYPE} archive"
	PH_ARCHIVE_NAME="$(ls -t "${PH_ARCHIVE_DIR}/PieHelper-"*"${PH_ARCHIVE_NAME}" 2>/dev/null | head -n1)"
	while true
	do
		if [[ -z "${PH_ARCHIVE_NAME}" ]]
		then
			printf "%10s\033[33m%s\033[0m\n" "" "Warning : No ${PH_ARCHIVE_TYPE} archives matched"
			ph_set_result -r 0 -w -m "Could not find any ${PH_ARCHIVE_TYPE} archives in directory '${PH_ARCHIVE_DIR}'"
		else
			PH_ARCHIVE_NAME="${PH_ARCHIVE_NAME##*/}"
			ph_run_with_rollback -c true -m "${PH_ARCHIVE_DIR}/${PH_ARCHIVE_NAME}"
			printf "%8s%s\033[1;33m%s\033[0m%s\033[1;33m%s\033[0m%s\033[1;33m%s\033[0m\n" "" "--> Removing ${PH_ARCHIVE_TYPE} archive of " "'PieHelper'" " version " "'${PH_NEW_VERSION}'" \
				" as " "'${PH_ARCHIVE_DIR}/${PH_ARCHIVE_NAME}'"
			if ph_run_with_rollback -c "ph_store_file -f '${PH_ARCHIVE_DIR}/${PH_ARCHIVE_NAME}'"
			then
				ph_run_with_rollback -c true -m "${PH_ARCHIVE_DIR}/${PH_ARCHIVE_NAME}"
				if [[ "${PH_PIEH_CIFS_SHARE}" == "yes" ]]
				then
					if [[ "${PH_RUNNING_APPS}" != PieHelper* ]]
					then
						ph_run_with_rollback -c "ph_mount_cifs_share PieHelper" || \
							break
					fi
					printf "%8s%s\033[1;33m%s\033[0m\n" "" "--> Removing ${PH_ARCHIVE_TYPE} archive CIFS backup as " \
						"'//${PH_PIEH_CIFS_SRV}:$(ph_resolve_dynamic_value ${PH_PIEH_CIFS_DIR})$(ph_resolve_dynamic_value ${PH_PIEH_CIFS_SUBDIR})/${PH_ARCHIVE_NAME}'"
					if ph_run_with_rollback -c "ph_store_file -f '${PH_PIEH_CIFS_MPT}/${PH_ARCHIVE_NAME}'"
					then
						ph_run_with_rollback -c true -m "//${PH_PIEH_CIFS_SRV}:$(ph_resolve_dynamic_value ${PH_PIEH_CIFS_DIR})$(ph_resolve_dynamic_value ${PH_PIEH_CIFS_SUBDIR})/${PH_ARCHIVE_NAME}"
					else
						ph_run_with_rollback -c false -m "Could not remove" || \
							break
					fi
					if [[ "${PH_RUNNING_APPS}" != PieHelper* ]]
					then
						ph_run_with_rollback -c "ph_umount_cifs_share PieHelper" || \
							break
					fi
				fi
			else
				ph_run_with_rollback -c false -m "Could not remove" || \
					break
			fi
		fi
		ph_show_result
		exit "${?}"
	done
fi
exit 1
