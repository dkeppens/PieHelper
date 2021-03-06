# Kodi PRE-command script to run before Kodi startup
# by Davy Keppens on 04/10/2018
#

#set -x

typeset PH_KODI_USER=""
typeset PH_KODI_HOME=""
typeset PH_z=""

PH_KODI_USER="`nawk -v app=^"Kodi"$ '$1 ~ app { print $2 }' $PH_CONF_DIR/installed_apps`"
PH_KODI_HOME="`echo -n $(getent passwd $PH_KODI_USER | cut -d':' -f6)`"
printf "%8s%s\n" "" "--> Restoring last backup of Kodi preferences directory for run account $PH_KODI_USER (This may take a while)"
if [[ "$PH_KODI_CIFS_SHARE" == "yes" ]]
then
	cd "$PH_KODI_HOME" >/dev/null 2>&1
	if [[ -f `eval echo -n "$PH_KODI_CIFS_MPT"`/Kodi-Prefs.tar ]]
	then
		$PH_SUDO -E mv `eval echo -n "$PH_KODI_CIFS_MPT"`/Kodi-Prefs.tar "$PH_SCRIPTS_DIR/../tmp/Kodi-Prefs.tar" 2>/dev/null
		[[ -d "$PH_KODI_HOME/.kodi" ]] && $PH_SUDO -E rm -r "$PH_KODI_HOME/.kodi" 2>/dev/null
		$PH_SUDO -E tar -xf "$PH_SCRIPTS_DIR/../tmp/Kodi-Prefs.tar" 2>/dev/null
		if [[ $? -ne 0 ]]
		then
			printf "%10s%s\n" "" "Warning : Could not succesfully restore last preferences backup -> Removing"
			$PH_SUDO -E rm -r "$PH_KODI_HOME/.kodi" 2>/dev/null
			PH_z="NOK"
		else
			[[ `ls -ld "$PH_KODI_HOME/.kodi" | nawk '{ print $3 }'` != "$PH_KODI_USER" ]] && $PH_SUDO -E chown -R "$PH_KODI_USER":`$PH_SUDO -E id -gn $PH_KODI_USER` ./.kodi 2>/dev/null
			printf "%10s%s\n" "" "OK"
		fi
		$PH_SUDO -E mv "$PH_SCRIPTS_DIR/../tmp/Kodi-Prefs.tar" `eval echo -n "$PH_KODI_CIFS_MPT"`/Kodi-Prefs.tar 2>/dev/null
	else
		printf "%10s%s\n" "" "Warning : Not found"
	fi
	cd - >/dev/null 2>&1
else
	printf "%10s%s\n" "" "Warning : Dependent on CIFS -> Skipping"
fi
[[ "$PH_z" == "NOK" ]] && return 1 || return 0
