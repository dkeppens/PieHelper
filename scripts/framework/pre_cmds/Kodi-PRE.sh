# Kodi PRE-command script which runs before Kodi startup
#
# - Will check if a valid tar archive called 'Kodi-Prefs.tar' exists in the CIFS-mounted directory defined by option PH_KODI_CIFS_MPT
#   The user for Kodi will require priorly configured read/write permissions for the remote share
# - Will attempt to restore its contents to the home directory of the Kodi user as Kodi preferences directory '.kodi'
# - Will attempt to change ownership of the new Kodi preferences directory if the user for Kodi has changed
# - Will replace previous directory contents on success for all or restore them in case of failure for any
#
# @Davy Keppens on 04/10/2018
#

#set -x

declare PH_KODI_GROUP
declare PH_KODI_LOC_DIR
declare PH_KODI_REM_DIR

PH_KODI_GROUP="$(id -gn 2>/dev/null)"
PH_KODI_LOC_DIR="$(ph_get_app_cifs_mpt -a Kodi -r)"
PH_KODI_REM_DIR="$(ph_resolve_dynamic_value "${PH_KODI_CIFS_DIR}${PH_KODI_CIFS_SUBDIR}")"

printf "%8s%s\n" "" "--> Checking for Kodi PRE-command prerequisite : CIFS configured"
if [[ "${PH_KODI_CIFS_SHARE}" == "yes" ]]
then
	ph_run_with_rollback -c true -m Yes
	printf "%8s%s\n" "" "--> Checking for Kodi PRE-command prerequisite : CIFS mounted"
       	if [[ "$(mount 2>/dev/null | nawk -v rempath="^//${PH_KODI_CIFS_SRV}${PH_KODI_REM_DIR}$" -F' on ' '$1 ~ rempath { \
			printf "%s", "yes" ; \
			exit \
		} { \
			next \
		}')" == "yes" ]]
       	then
		ph_run_with_rollback -c true -m Yes
		printf "%8s%s\n" "" "--> Checking for Kodi PRE-command prerequisite : Accessible backup"
		if [[ -r "${PH_KODI_LOC_DIR}/Kodi-Prefs.tar" ]]
		then
			ph_run_with_rollback -c true -m Yes
			printf "%8s%s\n" "" "--> Checking for Kodi PRE-command prerequisite : Valid backup"
			if [[ "$(tar --test-label -f "${PH_KODI_LOC_DIR}/Kodi-Prefs.tar" >/dev/null 2>&1 ; echo "${?}")" -eq "0" && \
				-s "${PH_KODI_LOC_DIR}/Kodi-Prefs.tar" ]]
			then
				ph_run_with_rollback -c true -m Yes
				printf "%8s%s\n" "" "--> Restoring CIFS backup '${PH_KODI_LOC_DIR}/Kodi-Prefs.tar' to '${HOME}/' (This may take a while)"
				if cp "${PH_KODI_LOC_DIR}/Kodi-Prefs.tar" "${PH_TMP_DIR}/" 2>/dev/null
				then
					if [[ -d "${HOME}/.kodi" ]]
					then
						if ! "${PH_SUDO}" mv "${HOME}/.kodi" "${PH_TMP_DIR}/.kodi_tmp" 2>/dev/null
						then
							rm "${PH_TMP_DIR}/Kodi-Prefs.tar" 2>/dev/null
							printf "%10s\033[33m%s\033[0m\n" "" "Warning : Could not store '${HOME}/.kodi' as '${PH_TMP_DIR}/.kodi_tmp' -> Skipping"
							ph_set_result -r 0
							unset PH_KODI_GROUP PH_KODI_LOC_DIR PH_KODI_REM_DIR
							return 1
						fi
					fi
					if ( cd "${HOME}" ; "${PH_SUDO}" tar -xf "${PH_TMP_DIR}/Kodi-Prefs.tar" 2>/dev/null )
					then
						ph_run_with_rollback -c true -m "${HOME}/.kodi"
						printf "%8s%s\n" "" "--> Checking if the user for Kodi has changed"
						if [[ "$("${PH_SUDO}" ls -ld "${HOME}/.kodi" 2>/dev/null | nawk '{ \
								print $3 \
							}')" != "${PH_APP_USER}" ]]
						then
							printf "%10s\033[33m%s\033[0m\n" "" "Warning : Kodi user appears to have changed to '${PH_APP_USER}'"
							ph_set_result -r 0
							printf "%8s%s\n" "" "--> Recursively setting ownership of '${HOME}/.kodi' to '${PH_APP_USER}:${PH_KODI_GROUP}'"
							if "${PH_SUDO}" chown -R "${PH_APP_USER}:${PH_KODI_GROUP}" "${HOME}/.kodi" 2>/dev/null
							then
								"${PH_SUDO}" rm -r "${PH_TMP_DIR}/Kodi-Prefs.tar" "${PH_TMP_DIR}/.kodi_tmp" 2>/dev/null
								unset PH_KODI_GROUP PH_KODI_LOC_DIR PH_KODI_REM_DIR
								ph_run_with_rollback -c true && \
									return "${?}"
							else
								printf "%10s\033[33m%s\033[0m\n" "" "Warning : Could not recursively set ownership of '${HOME}/.kodi' to '${PH_APP_USER}:${PH_KODI_GROUP}' -> Skipping"
							fi
						else
							"${PH_SUDO}" rm -r "${PH_TMP_DIR}/Kodi-Prefs.tar" "${PH_TMP_DIR}/.kodi_tmp" 2>/dev/null
							unset PH_KODI_GROUP PH_KODI_LOC_DIR PH_KODI_REM_DIR
							ph_run_with_rollback -c true -m No && \
								return "${?}"
						fi
					else
						printf "%10s\033[33m%s\033[0m\n" "" "Warning : Could not restore '${PH_KODI_LOC_DIR}/Kodi-Prefs.tar' to '${HOME}/' -> Skipping"
					fi
					"${PH_SUDO}" rm -r "${PH_TMP_DIR}/Kodi-Prefs.tar" "${HOME}/.kodi" 2>/dev/null
					"${PH_SUDO}" mv "${PH_TMP_DIR}/.kodi_tmp" "${HOME}/.kodi" 2>/dev/null
				else
					printf "%10s\033[33m%s\033[0m\n" "" "Warning : Could not copy '${PH_KODI_LOC_DIR}/Kodi-Prefs.tar' to '${PH_TMP_DIR}/' -> Skipping"
				fi
			else
				printf "%10s\033[33m%s\033[0m\n" "" "Warning : '${PH_KODI_LOC_DIR}/Kodi-Prefs.tar' is not a valid tar archive -> Skipping" 
			fi
		else
			printf "%10s\033[33m%s\033[0m\n" "" "Warning : Could not access '${PH_KODI_LOC_DIR}/Kodi-Prefs.tar' -> Skipping" 
		fi
	else
		printf "%10s\033[33m%s\033[0m\n" "" "Warning : No -> Skipping" 
	fi
else
	printf "%10s\033[33m%s\033[0m\n" "" "Warning : No -> Skipping" 
fi
ph_set_result -r 0
unset PH_KODI_GROUP PH_KODI_LOC_DIR PH_KODI_REM_DIR
return 1
