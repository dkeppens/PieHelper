# Kodi POST-command script to run after Kodi shutdown
# by Davy Keppens on 04/10/2018
#

#set -x

declare PH_KODI_USER=""
declare PH_KODI_HOME=""
declare PH_FAILED="no"

PH_KODI_USER="$(ph_get_app_user_from_app_name Kodi)"
PH_KODI_HOME="$(getent passwd "$PH_KODI_USER" 2>/dev/null | cut -d':' -f6)"
printf "%8s%s\n" "" "--> Checking for 'Kodi' POST-command CIFS mount requirement"
ph_set_result -r 0
if [[ "$PH_KODI_CIFS_SHARE" == "yes" ]]
then
	printf "%10s\033[32m%s\033[0m\n" "" "OK (Yes)"
	printf "%8s%s\n" "" "--> Checking for 'Kodi' POST-command CIFS mount presence"
	ph_set_result -r 0
	mount 2>/dev/null | nawk -v rempath=^"//${PH_KODI_CIFS_SRV}$(eval echo -n "${PH_KODI_CIFS_DIR}${PH_KODI_CIFS_SUBDIR}")"$ -F' on ' '$1 ~ rempath { exit 1 }'
	if [[ "$?" -eq "1" ]]
	then
		printf "%10s\033[32m%s\033[0m\n" "" "OK (Found) -> Backing up 'Kodi' preferences"
		printf "%8s%s\n" "" "--> Creating CIFS backup of '.kodi' directory for run account '${PH_KODI_USER}' (This may take a while)"
		ph_set_result -r 0
		cd "$PH_KODI_HOME" >/dev/null 2>&1
		if [[ -d ./.kodi ]]
		then
			[[ -f "$(eval echo -n "$PH_KODI_CIFS_MPT")/Kodi-Prefs.tar" && -d "${PH_KODI_HOME}/.kodi" ]] && \
				rm "$(eval echo -n "$PH_KODI_CIFS_MPT")/Kodi-Prefs.tar" 2>/dev/null
			"$PH_SUDO" -E tar -X "${PH_FILES_DIR}/kodi.excludes" -cf "${PH_TMP_DIR}/Kodi-Prefs.tar" ./.kodi 2>/dev/null
			if [[ "$?" -eq "0" ]]
			then
				"$PH_SUDO" -E chown "${PH_RUN_USER}:$("$PH_SUDO" id -gn "$PH_RUN_USER" 2>/dev/null)" "${PH_TMP_DIR}/Kodi-Prefs.tar" 2>/dev/null
				"$PH_SUDO" -E chmod 744 "${PH_TMP_DIR}/Kodi-Prefs.tar" 2>/dev/null
				mv "${PH_TMP_DIR}/Kodi-Prefs.tar" "$(eval echo -n "$PH_KODI_CIFS_MPT")/Kodi-Prefs.tar"
				printf "%10s\033[32m%s\033[0m\n" "" "OK"
			else
				printf "%10s\033[33m%s\033[0m\n" "" "Warning : Could not create valid backup -> Removing"
				printf "%8s%s\n" "" "--> Removing invalid backup"
				"$PH_SUDO" -E rm "${PH_TMP_DIR}/Kodi-Prefs.tar" 2>/dev/null
				printf "%10s\033[32m%s\033[0m\n" "" "OK"
				ph_set_result -r 0
				PH_FAILED="yes"
			fi
			cd - >/dev/null 2>&1
		else
			printf "%10s\033[33m%s\033[0m\n" "" "Warning : Directory not found -> Skipping"
		fi
	else
		printf "%10s\033[33m%s\033[0m\n" "" "Warning : CIFS mount '//${PH_KODI_CIFS_SRV}$(eval echo -n "${PH_KODI_CIFS_DIR}${PH_KODI_CIFS_SUBDIR}")' presence on mountpoint '$(eval echo -n "$PH_KODI_CIFS_MPT")' is mandatory for 'Kodi' POST-command -> Skipping"
	fi
else
	printf "%10s\033[33m%s\033[0m\n" "" "Warning : CIFS is mandatory for 'Kodi' POST-command -> Skipping"
fi
[[ "$PH_FAILED" == "yes" ]] && \
	return 1 || \
	return 0
