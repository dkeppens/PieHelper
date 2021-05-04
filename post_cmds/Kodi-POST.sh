# Kodi POST-command script which runs after Kodi shutdown
#
# - Will check if a Kodi preferences directory '.kodi' exists in the home directory of the Kodi user
# - Will attempt to back it up as a tar archive called 'Kodi-Prefs.tar' to the CIFS-mountpoint defined by option PH_KODI_CIFS_MPT
#   The user for PieHelper will require priorly configured read/write permissions for the remote share
# - Will replace a file with the same name on success or restore it in case of failure
#
# @Davy Keppens on 04/10/2018
#

#set -x

declare PH_KODI_HOME=""
declare PH_KODI_LOC_DIR=""
declare PH_KODI_REM_DIR=""

PH_KODI_HOME="$(getent passwd "$PH_APP_USER" 2>/dev/null | cut -d':' -f6)"
PH_KODI_LOC_DIR="$(ph_get_app_cifs_mpt -a Kodi -r)"
PH_KODI_REM_DIR="$(eval "echo -n ${PH_KODI_CIFS_DIR}${PH_KODI_CIFS_SUBDIR}")"
printf "%8s%s\n" "" "--> Checking for Kodi POST-command prerequisite : CIFS configured"
if [[ "$PH_KODI_CIFS_SHARE" == "yes" ]]
then
	ph_run_with_rollback -c true -m Yes
	printf "%8s%s\n" "" "--> Checking for Kodi POST-command prerequisite : CIFS mounted"
	if [[ "$(mount 2>/dev/null | nawk -v rempath="^//${PH_KODI_CIFS_SRV}${PH_KODI_REM_DIR}$" -F' on ' '$1 ~ rempath { \
			printf "%s", "yes" ; \
			exit \
		} { \
			next \
		}')" == "yes" ]]
	then
		ph_run_with_rollback -c true -m Yes
		printf "%8s%s\n" "" "--> Checking for Kodi POST-command prerequisite : Accessible preferences"
		if [[ -d "${PH_KODI_HOME}/.kodi" ]]
		then
			ph_run_with_rollback -c true -m Yes
			printf "%8s%s\n" "" "--> Creating CIFS backup of directory '${PH_KODI_HOME}/.kodi' as '${PH_KODI_LOC_DIR}/Kodi-Prefs.tar' (This may take a while)"
			if [[ -f "${PH_KODI_LOC_DIR}/Kodi-Prefs.tar" ]]
			then
				if ! mv "${PH_KODI_LOC_DIR}/Kodi-Prefs.tar" "${PH_TMP_DIR}/Kodi-Prefs.tar_tmp" 2>/dev/null
				then
					printf "%10s\033[33m%s\033[0m\n" "" "Warning : Could not store '${PH_KODI_LOC_DIR}/Kodi-Prefs.tar' as '${PH_TMP_DIR}/Kodi-Prefs.tar_tmp' -> Skipping"
					ph_set_result -r 0
					unset PH_KODI_HOME PH_KODI_LOC_DIR PH_KODI_REM_DIR
					return 1
				fi
			fi
			if ( cd "$PH_KODI_HOME" ; "$PH_SUDO" tar -X "${PH_FILES_DIR}/kodi.excludes" -cf "${PH_TMP_DIR}/Kodi-Prefs.tar" ./.kodi >/dev/null 2>&1 )
			then
				if "$PH_SUDO" chown "${PH_PIEH_USER}:$(id -gn 2>/dev/null)" "${PH_TMP_DIR}/Kodi-Prefs.tar" 2>/dev/null
				then
					if mv "${PH_TMP_DIR}/Kodi-Prefs.tar" "${PH_KODI_LOC_DIR}/" 2>/dev/null
					then
						"$PH_SUDO" rm "${PH_TMP_DIR}/Kodi-Prefs.tar_tmp" 2>/dev/null
						unset PH_KODI_HOME PH_KODI_LOC_DIR PH_KODI_REM_DIR
						ph_run_with_rollback -c true -m "${PH_KODI_LOC_DIR}/Kodi-Prefs.tar" && \
							return "$?"
					else
						printf "%10s\033[33m%s\033[0m\n" "" "Warning : Could not move '${PH_TMP_DIR}/Kodi-Prefs.tar' to '${PH_KODI_LOC_DIR}/' -> Skipping"
					fi
				else
					printf "%10s\033[33m%s\033[0m\n" "" "Warning : Could not set ownership of '${PH_TMP_DIR}/Kodi-Prefs.tar' to '${PH_PIEH_USER}:$(id -gn 2>/dev/null)' -> Skipping"
				fi
			else
				printf "%10s\033[33m%s\033[0m\n" "" "Warning : Could not backup '${PH_KODI_HOME}/.kodi' as '${PH_TMP_DIR}/Kodi-Prefs.tar' -> Skipping"
			fi
			mv "${PH_TMP_DIR}/Kodi-Prefs.tar_tmp" "${PH_KODI_LOC_DIR}/Kodi-Prefs.tar" 2>/dev/null
			"$PH_SUDO" rm "${PH_TMP_DIR}/Kodi-Prefs.tar" 2>/dev/null
		else
			printf "%10s\033[33m%s\033[0m\n" "" "Warning : Could not access '${PH_KODI_HOME}/.kodi' -> Skipping" 
		fi
	else
		printf "%10s\033[33m%s\033[0m\n" "" "Warning : No -> Skipping" 
	fi
else
	printf "%10s\033[33m%s\033[0m\n" "" "Warning : No -> Skipping" 
fi
ph_set_result -r 0
unset PH_KODI_HOME PH_KODI_LOC_DIR PH_KODI_REM_DIR
return 1
