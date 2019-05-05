# Kodi POST-command script to run after Kodi shutdown
# by Davy Keppens on 04/10/2018
#

#set -x

typeset PH_KODI_USER=""
typeset PH_KODI_HOME=""
typeset PH_z=""

PH_KODI_USER="`nawk -v app=^"Kodi"$ '$1 ~ app { print $2 }' $PH_CONF_DIR/installed_apps`"
PH_KODI_HOME="`echo -n $(getent passwd $PH_KODI_USER | cut -d':' -f6)`"
if [[ "$PH_KODI_CIFS_SHARE" == "yes" ]]
then
	printf "%8s%s\n" "" "--> Checking for mount"
	mount | nawk -v rempath=^"//`eval echo -n "$PH_KODI_CIFS_SRV$PH_KODI_CIFS_DIR$PH_KODI_CIFS_SUBDIR"`"$ -F' on ' '$1 ~ rempath { exit 1 }'
	if [[ $? -eq 1 ]]
	then
		printf "%10s%s\n" "" "OK (Found)"
		printf "%8s%s\n" "" "--> Backing up latest Kodi preferences directory for run account $PH_KODI_USER (This may take a while)"
		cd "$PH_KODI_HOME" >/dev/null 2>&1
		[[ -f `eval echo -n "$PH_KODI_CIFS_MPT"`/Kodi-Prefs.tar && -d "$PH_KODI_HOME/.kodi" ]] && $PH_SUDO -E rm `eval echo -n "$PH_KODI_CIFS_MPT"`/Kodi-Prefs.tar 2>/dev/null
		$PH_SUDO -E tar -X "$PH_FILES_DIR/exclude.Kodi" -cf "$PH_SCRIPTS_DIR/../tmp/Kodi-Prefs.tar" ./.kodi 2>/dev/null
		if [[ $? -eq 0 ]]
		then
			$PH_SUDO -E mv "$PH_SCRIPTS_DIR/../tmp/Kodi-Prefs.tar" `eval echo -n "$PH_KODI_CIFS_MPT"`/Kodi-Prefs.tar 2>/dev/null
			printf "%10s%s\n" "" "OK"
		else
			PH_z="NOK"
			printf "%10s%s\n" "" "Warning : Could not create valid up-to-date preferences backup -> Removing"
			printf "%8s%s\n" "" "--> Removing invalid backup"
			$PH_SUDO -E rm "$PH_SCRIPTS_DIR/../tmp/Kodi-Prefs.tar" 2>/dev/null
			printf "%10s%s\n" "" "OK"
		fi
		cd - >/dev/null 2>&1
	else
		printf "%10s%s\n" "" "Warning : CIFS configured but mount not found -> Skipping"
	fi
else
	printf "%10s%s\n" "" "Warning : dependent on CIFS -> Skipping"
fi
[[ "$PH_z" == "NOK" ]] && return 1 || return 0
