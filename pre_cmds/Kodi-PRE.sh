# Kodi PRE-command script to run before Kodi startup
# by Davy Keppens on 04/10/2018
#

#set -x

declare PH_KODI_USER=""
declare PH_KODI_HOME=""
declare PH_FAILED="no"

PH_KODI_USER="$(ph_get_app_user_from_app_name Kodi)"
PH_KODI_HOME="$(getent passwd "$PH_KODI_USER" 2>/dev/null | cut -d':' -f6)"
printf "%8s%s\n" "" "--> Checking for 'Kodi' PRE-command CIFS mount requirement"
ph_set_result -r 0
if [[ "$PH_KODI_CIFS_SHARE" == "yes" ]]
then
	printf "%10s\033[32m%s\033[0m\n" "" "OK (Yes)"
        printf "%8s%s\n" "" "--> Checking for 'Kodi' PRE-command CIFS mount presence"
	ph_set_result -r 0
        mount 2>/dev/null | nawk -v rempath=^"//$PH_KODI_CIFS_SRV$(eval echo -n "$PH_KODI_CIFS_DIR""$PH_KODI_CIFS_SUBDIR")"$ -F' on ' '$1 ~ rempath { exit 1 }'
        if [[ "$?" -eq "1" ]]
        then
                printf "%10s\033[32m%s\033[0m\n" "" "OK (Found) -> Restoring 'Kodi' preferences"
		printf "%8s%s\n" "" "--> Restoring CIFS backup of '.kodi' directory backup for run account '$PH_KODI_USER' (This may take a while)"
		ph_set_result -r 0
		cd "$PH_KODI_HOME" >/dev/null 2>&1
		if [[ -f "$(eval echo -n "$PH_KODI_CIFS_MPT")"/Kodi-Prefs.tar ]]
		then
			mv "$(eval echo -n "$PH_KODI_CIFS_MPT")"/Kodi-Prefs.tar "$PH_TMP_DIR"/Kodi-Prefs.tar 2>/dev/null
			[[ -d "$PH_KODI_HOME"/.kodi ]] && "$PH_SUDO" -E rm -r "$PH_KODI_HOME"/.kodi 2>/dev/null
			"$PH_SUDO" -E tar -xf "$PH_TMP_DIR"/Kodi-Prefs.tar 2>/dev/null
			if [[ "$?" -ne "0" ]]
			then
				printf "%10s\033[33m%s\033[0m\n" "" "Warning : Could not create valid restore -> Removing"
				printf "%8s%s\n" "" "--> Removing invalid restore"
				"$PH_SUDO" -E rm -r "$PH_KODI_HOME"/.kodi 2>/dev/null
				printf "%10s\033[32m%s\033[0m\n" "" "OK ('Kodi' preferences will need to be reconfigured)"
				ph_set_result -r 0
				PH_FAILED="yes"
			else
				[[ "$(ls -ld "$PH_KODI_HOME"/.kodi 2>/dev/null | nawk '{ print $3 }')" != "$PH_KODI_USER" ]] && \
					"$PH_SUDO" -E chown -R "$PH_KODI_USER":"$("$PH_SUDO" -E id -gn "$PH_KODI_USER" 2>/dev/null)" ./.kodi 2>/dev/null
				printf "%10s\033[32m%s\033[0m\n" "" "OK"
			fi
			mv "$PH_TMP_DIR"/Kodi-Prefs.tar "$(eval echo -n "$PH_KODI_CIFS_MPT")"/Kodi-Prefs.tar 2>/dev/null
		else
			printf "%10s\033[33m%s\033[0m\n" "" "Warning : Backup not found -> Skipping"
		fi
		cd - >/dev/null 2>&1
	else
		printf "%10s\033[33m%s\033[0m\n" "" "Warning : CIFS mount '//$PH_KODI_CIFS_SRV$(eval echo -n "$PH_KODI_CIFS_DIR""$PH_KODI_CIFS_SUBDIR")' presence on mountpoint '$(eval echo -n "$PH_KODI_CIFS_MPT")' is mandatory for 'Kodi' PRE-command -> Skipping"
	fi
else
	printf "%10s\033[33m%s\033[0m\n" "" "Warning : CIFS is mandatory for 'Kodi' PRE-command -> Skipping"
fi
[[ "$PH_FAILED" == "yes" ]] && return 1 || return 0
