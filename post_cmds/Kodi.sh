# Kodi post command script to run after Kodi shutdown
# by Davy Keppens on 04/10/2018
#

#set -x

PH_KODI_USER="`nawk -v app=^"Kodi"$ '$1 ~ app { print $2 }' $PH_CONF_DIR/installed_apps`"
PH_KODI_HOME="`echo -n $(getent passwd $PH_KODI_USER | cut -d':' -f6)`"
printf "%8s%s\n" "" "--> Backing up latest Kodi preferences directory for run account $PH_KODI_USER (This may take a while)"
if [[ "$PH_KODI_CIFS_SHARE" == "yes" ]]
then
	cd "$PH_KODI_HOME" >/dev/null 2>&1
	[[ -f `eval echo -n "$PH_KODI_CIFS_MPT"`/Kodi-Prefs.tar && -d "$PH_KODI_HOME/.kodi" ]] && $PH_SUDO rm `eval echo -n "$PH_KODI_CIFS_MPT"`/Kodi-Prefs.tar
	$PH_SUDO tar -X "$PH_FILES_DIR/exclude.Kodi" -cf "$PH_SCRIPTS_DIR/../tmp/Kodi-Prefs.tar" ./.kodi 2>/dev/null
	if [[ $? -eq 0 ]]
	then
		$PH_SUDO mv "$PH_SCRIPTS_DIR/../tmp/Kodi-Prefs.tar" `eval echo -n "$PH_KODI_CIFS_MPT"`/Kodi-Prefs.tar >/dev/null 2>&1
		printf "%10s%s\n" "" "OK"
	else
		PH_i="NOK"
		printf "%10s%s\n" "" "Warning : Could not create valid up-to-date preferences backup -> Removing"
		printf "%8s%s\n" "" "--> Removing invalid backup"
		$PH_SUDO rm "$PH_SCRIPTS_DIR/../tmp/Kodi-Prefs.tar" 2>/dev/null
		printf "%10s%s\n" "" "OK"
	fi
	cd - >/dev/null 2>&1
else
	printf "%10s%s\n" "" "Warning : dependent on CIFS -> Skipping"
fi
[[ "$PH_i" == "NOK" ]] && return 1 || return 0
