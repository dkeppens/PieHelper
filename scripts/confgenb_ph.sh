#!/bin/ksh
# Generate a new tar archive of PieHelper (by Davy Keppens on 04/10/2018)
# Enable/Disable debug by running confpieh_ph.sh -d confgenb_ph.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

typeset PH_OLD_VERSION=""
typeset PH_NEW_VERSION=""
typeset PH_RESULT="SUCCESS"
typeset PH_GIT_UPDATE="no"
typeset PH_GIT_COMMSG=""
PH_BUILD_DIR=$PH_SCRIPTS_DIR/../build
PH_REVERSE=""

while getopts v:hgm: PH_OPTION 2>/dev/null
do
	case $PH_OPTION in v)
		[[ -n "$PH_NEW_VERSION" ]] && (! confgenb_ph.sh -h) && exit 1
		ph_screen_input "$OPTARG" || exit $?
		[[ "$OPTARG" != +([[:digit:]])\.+([[:digit:]]) ]] && (! confgenb_ph.sh -h) && exit 1
		PH_NEW_VERSION="$OPTARG" ;;
			   g)
		PH_GIT_UPDATE="yes" ;;
			   m)
		PH_GIT_COMMSG="$OPTARG" ;;
			   *)
		>&2 printf "%s\n" "Usage : confgenb_ph.sh -h |"
		>&2 printf "%23s%s\n" "" "'-g '-m'' |"
		>&2 printf "%23s%s\n" "" "-v [version]"
		>&2 printf "\n"
		>&2 printf "%3s%s\n" "" "Where -h displays this usage"
		>&2 printf "%9s%s\n" "" "-g allows updating the remote git master repository with all new changes for [version] in the new build"
		>&2 printf "%12s%s\n" "" "- Specifying -g is optional"
		>&2 printf "%12s%s\n" "" "-m allows setting a commit message for git"
		>&2 printf "%15s%s\n" "" "- Specifying -m is optional"
		>&2 printf "%15s%s\n" "" "- Commit messages should always be surrounded with single or double quotes"
		>&2 printf "%15s%s\n" "" "- Empty or left-out commit messages will cancel the commit operation"
		>&2 printf "%9s%s\n" "" "-v allows setting a new version number [version] and will generate a new build archive named PieHelper-[version].tar"
		>&2 printf "%12s%s\n" "" "- [version] should be specified as a decimal number"
		>&2 printf "%12s%s\n" "" "- The archive will be placed in $PH_BUILD_DIR"
		>&2 printf "%12s%s\n" "" "- Any old archives in $PH_BUILD_DIR with the same version number"
		>&2 printf "%14s%s\n" "" "will be overwritten"
		>&2 printf "%12s%s\n" "" "- If PH_PIEH_CIFS_SHARE is set to \"yes\" a uniquely timestamped backup copy of this archive"
		>&2 printf "%14s%s\n" "" "will also be created in directory PH_PIEH_CIFS_SUBDIR on local network server PH_PIEH_CIFS_SRV"
		>&2 printf "%14s%s\n" "" "More info on these settings can be viewed using confopts_ph.sh or the PieHelper menu"
		>&2 printf "\n"
		unset PH_REVERSE
		exit 1 ;;
	esac
done
if [[ -n "$PH_NEW_VERSION" ]]
then
	printf "%s\n" "- Creating a new build archive for PieHelper version $PH_NEW_VERSION"
	ph_set_all_options_to_default || (printf "%2s%s\n" "" "FAILED" ; return 1) || exit $?
	printf "%8s%s\n" "" "--> Creating new first_run file in $PH_FILES_DIR"
	touch $PH_FILES_DIR/first_run 2>/dev/null || (printf "%10s%s\n" "" "ERROR : Could not create new first_run file in $PH_FILES_DIR" ; \
							ph_restore_options ; printf "%2s%s\n" "" "FAILED" ; exit 1) || exit $?
	printf "%10s%s\n" "" "OK"
	printf "%8s%s\n" "" "--> Updating version number to $PH_NEW_VERSION"
	PH_OLD_VERSION="$PH_VERSION"
	echo "$PH_NEW_VERSION" >$PH_CONF_DIR/VERSION
	printf "%10s%s\n" "" "OK"
	printf "%8s%s\n" "" "--> Removing controller ids' configuration file"
	cp -p $PH_CONF_DIR/controller_cli_ids /tmp/controller_cli_ids_tmp 2>/dev/null
	>$PH_CONF_DIR/controller_cli_ids
	printf "%10s%s\n" "" "OK"
	printf "%8s%s\n" "" "--> Setting supported applications configuration file back to default"
	mv $PH_CONF_DIR/supported_apps /tmp/supported_apps_tmp 2>/dev/null
cat >$PH_CONF_DIR/supported_apps <<EOF
PieHelper	$PH_SCRIPTS_DIR/startpieh.sh
Bash	/bin/bash
Moonlight	/usr/local/bin/moonlight stream
Kodi	/usr/bin/xinit /usr/bin/kodi-standalone -- :0 -nolisten tcp vtPH_TTY
X11	/usr/bin/startx -- :1 vtPH_TTY
Emulationstation	/usr/bin/emulationstation
EOF
	printf "%10s%s\n" "" "OK"
	printf "%8s%s\n" "" "--> Removing installed applications configuration file"
	mv $PH_CONF_DIR/installed_apps /tmp/installed_apps_tmp 2>/dev/null
	[[ $? -eq 0 ]] && printf "%10s%s\n" "" "OK" || (printf "%10s%s\n" "" "ERROR : Could not remove installed applications configuration file" ; \
							mv /tmp/supported_apps_tmp $PH_CONF_DIR/supported_apps ; mv /tmp/controller_cli_ids_tmp $PH_CONF_DIR/controller_cli_ids ; \
							echo "$PH_OLD_VERSION" >$PH_CONF_DIR/VERSION ; rm $PH_FILES_DIR/first_run ; ph_restore_options ; printf "%2s%s\n" "" "FAILED" ; return 1) || \
							exit 1
	printf "%8s%s\n" "" "--> Removing any old build archives"
	rm $PH_BUILD_DIR/PieHelper-*.tar 2>/dev/null
	printf "%10s%s\n" "" "OK"
	if [[ "$PH_GIT_UPDATE" == "yes" ]]
	then
		if [[ -z "$PH_GIT_COMMSG" ]]
		then
			printf "%8s%s\n" "" "--> Syncing $PH_NEW_VERSION changes to github master --> Skippping (Empty commit message)"
			printf "%10s%s\n" "" "OK"
		else
			printf "%8s%s\n" "" "--> Syncing $PH_NEW_VERSION changes to github master"
			cd $PH_SCRIPTS_DIR/.. >/dev/null 2>&1
			git add . >/dev/null 2>&1
			git commit -a --message="$PH_GIT_COMMSG" >/dev/null 2>&1
			git push >/dev/null 2>&1
			if [[ $? -eq 0 ]]
			then
				printf "%10s%s\n" "" "OK"
			else
				printf "%10s%s\n" "" "ERROR : Issues encountered during repo synchronisation"
				PH_RESULT="PARTIALLY FAILED"
			fi
			cd - >/dev/null 2>&1
		fi
	fi
	printf "%8s%s\n" "" "--> Creating a new tarball archive for PieHelper \"$PH_NEW_VERSION\""
	cd $PH_SCRIPTS_DIR/.. ; tar -X $PH_FILES_DIR/exclude -cvf $PH_BUILD_DIR/PieHelper-$PH_NEW_VERSION.tar ./* >/dev/null 2>&1 || \
		(printf "%10s%s\n" "" "ERROR : Could not create a new tarball archive for PieHelper $PH_NEW_VERSION" ; mv /tmp/installed_apps_tmp $PH_CONF_DIR/installed_apps ; \
		 mv /tmp/supported_apps_tmp $PH_CONF_DIR/supported_apps ; mv /tmp/controller_cli_ids_tmp $PH_CONF_DIR/controller_cli_ids ; \
		 echo "$PH_OLD_VERSION" >$PH_CONF_DIR/VERSION ; rm $PH_FILES_DIR/first_run ; ph_restore_options ; printf "%2s%s\n" "" "FAILED" ; exit 1) || \
		 exit $?
	printf "%10s%s\n" "" "OK"
	printf "%8s%s\n" "" "--> Attempting to determine required remote mounts for PieHelper"
	if [[ "$OLD_PH_PIEH_CIFS_SHARE" == "yes" ]]
	then
		printf "%10s%s\n" "" "OK"
		ph_mount_cifs_share PieHelper
		if [[ $? -eq 0 ]]
		then
			printf "%8s%s\n" "" "--> Creating timestamped backup of $PH_BUILD_DIR/PieHelper-$PH_NEW_VERSION.tar to $OLD_PH_PIEH_CIFS_SRV:$OLD_PH_PIEH_CIFS_DIR$OLD_PH_PIEH_CIFS_SUBDIR"
			cp -p $PH_BUILD_DIR/PieHelper-$PH_NEW_VERSION.tar "$PH_CONF_DIR/../mnt/PieHelper-$PH_NEW_VERSION-`date +'%d%m%y-%Hh%M'`.tar" 2>/dev/null
			if [[ $? -ne 0 ]]
			then
				PH_RESULT="PARTIALLY FAILED"
				printf "%10s%s\n" "" "Warning : Could not create timestamped backup of PieHelper-$PH_NEW_VERSION.tar"
			else
				printf "%10s%s\n" "" "OK"
			fi
			ph_umount_cifs_share PieHelper 2>&1
		else
			PH_RESULT="PARTIALLY FAILED"
		fi
	else
		printf "%10s%s\n" "" "OK (None)"
	fi
	printf "%8s%s\n" "" "--> Restoring installed applications configuration file"
	mv /tmp/installed_apps_tmp $PH_CONF_DIR/installed_apps
	printf "%10s%s\n" "" "OK"
	printf "%8s%s\n" "" "--> Restoring supported applications configuration file" 
	mv /tmp/supported_apps_tmp $PH_CONF_DIR/supported_apps
	printf "%10s%s\n" "" "OK"
	printf "%8s%s\n" "" "--> Restoring controller ids' configuration file"
	mv /tmp/controller_cli_ids_tmp $PH_CONF_DIR/controller_cli_ids
	printf "%10s%s\n" "" "OK"
	printf "%8s%s\n" "" "--> Removing first_run file in $PH_FILES_DIR"
	rm $PH_FILES_DIR/first_run 2>/dev/null
	printf "%10s%s\n" "" "OK"
	ph_restore_options
	printf "%2s%s\n" "" "$PH_RESULT"
	unset PH_REVERSE
	exit 0
fi
confgenb_ph.sh -h || unset PH_REVERSE
exit 1
