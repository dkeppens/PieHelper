#!/bin/ksh
# Generate a new tar archive of PieHelper (by Davy Keppens on 04/10/2018)
# Enable/Disable debug by running 'confpieh_ph.sh -p debug -m confgenb_ph.sh'

. $(dirname "$0")/../main/main.sh || exit "$?" && set +x

#set -x

typeset PH_i=""
typeset PH_OLD_VERSION=""
typeset PH_NEW_VERSION=""
typeset PH_RESULT="SUCCESS"
typeset PH_GIT_UPDATE="no"
typeset PH_GIT_COMMSG=""
typeset PH_ACL_USERS=""
typeset PH_OLDOPTARG="$OPTARG"
typeset -i PH_OLDOPTIND="$OPTIND"
PH_BUILD_DIR="$PH_SCRIPTS_DIR"/../build
PH_REVERSE=""
OPTIND="1"

while getopts v:hgm: PH_OPTION 2>/dev/null
do
	case "$PH_OPTION" in v)
		[[ -n "$PH_NEW_VERSION" ]] && (! confgenb_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND="$PH_OLDOPTIND" && unset PH_REVERSE && exit 1
		! ph_screen_input "$OPTARG" && OPTARG="$PH_OLDOPTARG" && OPTIND="$PH_OLDOPTIND" && unset PH_REVERSE && exit 1
		[[ "$OPTARG" != +([[:digit:]])\.+([[:digit:]]) ]] && (! confgenb_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND="$PH_OLDOPTIND" && unset PH_REVERSE && exit 1
		PH_NEW_VERSION="$OPTARG" ;;
			     g)
		PH_GIT_UPDATE="yes" ;;
			     m)
		PH_GIT_COMMSG="$OPTARG" ;;
			     *)
		>&2 printf "%s\n" "Usage : confgenb_ph.sh -h |"
		>&2 printf "%23s%s\n" "" "-v [version] |"
		>&2 printf "%23s%s\n" "" "'[-g '-m [commitmsg]']'"
		>&2 printf "\n"
		>&2 printf "%3s%s\n" "" "Where -h displays this usage"
		>&2 printf "%9s%s\n" "" "-v allows setting a new version number [version] and will make all the files and settings modifications required to"
		>&2 printf "%9s%s\n" "" "   generate a new build archive named 'PieHelper-[version].tar'"
		>&2 printf "%12s%s\n" "" "- [version] should be specified as a decimal number"
		>&2 printf "%12s%s\n" "" "- No active CIFS mounts related to PieHelper-integrated applications on default mountpoints should be present or build generation will refuse to start"
		>&2 printf "%12s%s\n" "" "- Non-recoverable errors encountered will reset all settings and files modified so far to their initial"
		>&2 printf "%12s%s\n" "" "  state or value before ending build generation"
		>&2 printf "%12s%s\n" "" "- Recoverable errors encountered will generate error messages and continue with build generation"
		>&2 printf "%12s%s\n" "" "- Warnings encountered will generate warning messages and continue with build generation"
		>&2 printf "%12s%s\n" "" "- The archive will be placed in '$PH_BUILD_DIR'"
		>&2 printf "%15s%s\n" "" "- Failure to generate the archive will generate a non-recoverable error"
		>&2 printf "%15s%s\n" "" "- Any old archives in '$PH_BUILD_DIR' with the same version number"
		>&2 printf "%15s%s\n" "" "  will be deleted before writing the new archive"
		>&2 printf "%15s%s\n" "" "- If PH_PIEH_CIFS_SHARE is set to 'yes' a uniquely timestamped backup copy of this archive"
		>&2 printf "%15s%s\n" "" "  will also be created in directory PH_PIEH_CIFS_SUBDIR on local network server PH_PIEH_CIFS_SRV"
		>&2 printf "%15s%s\n" "" "  More info on these settings can be viewed using 'confopts_ph.sh' or the PieHelper menu"
		>&2 printf "%18s%s\n" "" "- Failure to generate the timestamped backup will generate a recoverable error"
		>&2 printf "%9s%s\n" "" "-g allows committing all changes between the build being generated and the remote master github repository to the master as"
		>&2 printf "%9s%s\n" "" "   well as tagging the github update with version number [version]"
		>&2 printf "%12s%s\n" "" "- Specifying -g is optional"
		>&2 printf "%12s%s\n" "" "- Any git-related failures will generate a recoverable error"
		>&2 printf "%12s%s\n" "" "- Any commit attempts to the github master repository will fail if upstream access has not been previously granted"
		>&2 printf "%12s%s\n" "" "-m allows setting a commit message string [commitmsg] for git commit operations"
		>&2 printf "%15s%s\n" "" "- Specifying -m is optional but will cancel the commit operation and generate a warning if left unspecified when comitting"
		>&2 printf "%15s%s\n" "" "- [commitmsg] should always be surrounded with single or double quotes"
		>&2 printf "\n"
		OPTIND="$PH_OLDOPTIND"
		OPTARG="$PH_OLDOPTARG"
		unset PH_REVERSE
		exit 1 ;;
	esac
done
OPTIND="$PH_OLDOPTIND"
OPTARG="$PH_OLDOPTARG"

if [[ "$#" -ne 0 ]]
then
	[[ -z "$PH_NEW_VERSION" ]] && printf "\033[36m%s\033[0m\n" "- Creating a new build archive for PieHelper" && printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED : Version is required and unspecified" && exit 1
	printf "\033[36m%s\033[0m\n" "- Creating a new build archive for PieHelper version '$PH_NEW_VERSION'"
	[[ "$PH_GIT_UPDATE" == "no" && -n "$PH_GIT_COMMSG" ]] && printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED : Commit message specified while not comitting" && exit 1
	for PH_i in `nawk 'BEGIN { ORS = " " } { print $1 }' "$PH_CONF_DIR"/installed_apps`
	do
		if mount | nawk '{ for (i=0;i<NF;i++) { if ($i == "type") { print $(i-1) }}}' | grep ^"${PH_SCRIPTS_DIR%/*}/mnt/$PH_i"$ >/dev/null 2>&1
		then
			printf "%2s\033[31m%s\033[0m%s\n\n" "" "FAILED" " : Active CIFS mount for $PH_i present on default mountpoint"
			exit 1
		fi
	done
	PH_ACL_USERS=`getfacl "$PH_SCRIPTS_DIR" 2>/dev/null | nawk -F':' 'BEGIN { ORS = " " } $1 ~ /^user$/ && $2 !~ /^$/ { print $2 }' 2>/dev/null`
	for PH_i in `echo -n "$PH_ACL_USERS"`
	do
		printf "%8s%s\n" "" "--> Removing ACLs for user '$PH_i'"
		if "$PH_SUDO" setfacl -R -x u:"$PH_i" "$PH_SCRIPTS_DIR"/.. >/dev/null 2>&1
		then
			printf "%10s\033[32m%s\033[0m\n" "" "OK"
		else
			printf "%10s\033[31m%s\033[0m\n" "" "ERROR : Could not remove ACLs"
			printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED"
			exit 1
		fi
	done
	ph_set_all_options_to_default || (printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" ; return 1) || exit "$?"
	printf "%8s%s\n" "" "--> Creating new first_run file in '$PH_FILES_DIR'"
	touch "$PH_FILES_DIR"/first_run 2>/dev/null || (printf "%10s\033[31m%s\033[0m\n" "" "ERROR : Could not create file" ; \
							ph_restore_options ; printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" ; exit 1) || exit "$?"
	printf "%10s\033[32m%s\033[0m\n" "" "OK"
	printf "%8s%s\n" "" "--> Updating version number to '$PH_NEW_VERSION'"
	PH_OLD_VERSION="$PH_VERSION"
	echo "$PH_NEW_VERSION" >"$PH_CONF_DIR"/VERSION
	printf "%10s\033[32m%s\033[0m\n" "" "OK"
	printf "%8s%s\n" "" "--> Emptying OS configuration tool's configuration file"
	"$PH_SUDO" mv "$PH_FILES_DIR"/OS.defaults /tmp/OS.defaults_tmp 2>/dev/null
	"$PH_SUDO" touch "$PH_FILES_DIR"/OS.defaults 2>/dev/null
	printf "%10s\033[32m%s\033[0m\n" "" "OK"
	printf "%8s%s\n" "" "--> Emptying controller ids' configuration file"
	cp -p "$PH_CONF_DIR"/controller_cli_ids /tmp/controller_cli_ids_tmp 2>/dev/null
	>"$PH_CONF_DIR"/controller_cli_ids
	printf "%10s\033[32m%s\033[0m\n" "" "OK"
	printf "%8s%s\n" "" "--> Setting supported applications configuration file back to default"
	mv "$PH_CONF_DIR"/supported_apps /tmp/supported_apps_tmp 2>/dev/null
	cat >"$PH_CONF_DIR"/supported_apps <<EOF
PieHelper	`echo -n "$PH_SCRIPTS_DIR"`/startpieh.sh
Bash	/bin/bash
Moonlight	/usr/local/bin/moonlight stream
Kodi	/usr/bin/xinit /usr/bin/kodi-standalone -- :0 -nolisten tcp vtPH_TTY
X11	/usr/bin/startx -- :1 vtPH_TTY
Emulationstation	/usr/bin/emulationstation
EOF
	printf "%10s\033[32m%s\033[0m\n" "" "OK"
	printf "%8s%s\n" "" "--> Removing installed applications configuration file"
	mv "$PH_CONF_DIR"/installed_apps /tmp/installed_apps_tmp 2>/dev/null
	[[ "$?" -eq 0 ]] && printf "%10s\033[32m%s\033[0m\n" "" "OK" || (printf "%10s\033[31m%s\033[0m\n" "" "ERROR : Could not remove file" ; \
							mv /tmp/supported_apps_tmp "$PH_CONF_DIR"/supported_apps ; mv /tmp/controller_cli_ids_tmp "$PH_CONF_DIR"/controller_cli_ids ; \
							echo "$PH_OLD_VERSION" >"$PH_CONF_DIR"/VERSION ; rm "$PH_FILES_DIR"/first_run ; ph_restore_options ; printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" ; return 1) || \
							exit 1
	printf "%8s%s\n" "" "--> Removing any old build archives"
	rm "$PH_BUILD_DIR"/PieHelper-*.tar 2>/dev/null
	printf "%10s\033[32m%s\033[0m\n" "" "OK"
	if [[ "$PH_GIT_UPDATE" == "yes" ]]
	then
		if [[ -z "$PH_GIT_COMMSG" ]]
		then
			printf "%8s%s\n" "" "--> Locally committing '$PH_NEW_VERSION' changes to git"
			printf "%10s%s\n" "" "Warning : Empty commit message -> Skipping"
			printf "%8s%s\n" "" "--> Tagging local git build as '$PH_NEW_VERSION'"
			printf "%10s%s\n" "" "Warning : Empty commit message -> Skipping"
			printf "%8s%s\n" "" "--> Committing all changes to remote github master repository"
			printf "%10s%s\n" "" "Warning : Empty commit message -> Skipping"
		else
			cd "$PH_SCRIPTS_DIR"/.. >/dev/null 2>&1
			git add . >/dev/null 2>&1
			printf "%8s%s\n" "" "--> Locally committing '$PH_NEW_VERSION' changes to git"
			if git commit -a --message="$PH_GIT_COMMSG" >/dev/null 2>&1
			then
				printf "%10s\033[32m%s\033[0m\n" "" "OK"
			else
				printf "%10s\033[31m%s\033[0m\n" "" "ERROR : Could not commit to local"
				PH_RESULT="PARTIALLY FAILED"
			fi
			printf "%8s%s\n" "" "--> Tagging local git build as '$PH_NEW_VERSION'"
			if git tag -a "$PH_NEW_VERSION" -m "$PH_GIT_COMMSG" >/dev/null 2>&1
			then
				printf "%10s\033[32m%s\033[0m\n" "" "OK"
			else
				printf "%10s%s\n" "" "Warning : Could not tag build"
			fi
			printf "%8s%s\n" "" "--> Committing all changes to remote github master repository"
			git push --mirror >/dev/null 2>&1
			if [[ "$?" -eq 0 ]]
			then
				printf "%10s\033[32m%s\033[0m\n" "" "OK"
			else
				printf "%10s\033[31m%s\033[0m\n" "" "ERROR : Could not commit to remote"
				PH_RESULT="PARTIALLY FAILED"
			fi
			cd - >/dev/null 2>&1
		fi
	fi
	printf "%8s%s\n" "" "--> Creating a new tarball archive for PieHelper '$PH_NEW_VERSION'"
	cd "$PH_SCRIPTS_DIR"/.. ; tar -X "$PH_FILES_DIR"/exclude -cvf "$PH_BUILD_DIR"/PieHelper-"$PH_NEW_VERSION".tar ./* >/dev/null 2>&1 || \
		(printf "%10s\033[31m%s\033[0m\n" "" "ERROR : Could not create tarball" ; mv /tmp/installed_apps_tmp "$PH_CONF_DIR"/installed_apps ; \
		 mv /tmp/supported_apps_tmp "$PH_CONF_DIR"/supported_apps ; mv /tmp/controller_cli_ids_tmp "$PH_CONF_DIR"/controller_cli_ids ; \
		 echo "$PH_OLD_VERSION" >"$PH_CONF_DIR"/VERSION ; rm "$PH_FILES_DIR"/first_run ; ph_restore_options ; printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" ; exit 1) || \
		 exit "$?"
	printf "%10s\033[32m%s\033[0m\n" "" "OK"
	printf "%8s%s\n" "" "--> Attempting to determine required remote mounts for PieHelper"
	if [[ "$OLD_PH_PIEH_CIFS_SHARE" == "yes" ]]
	then
		printf "%10s\033[32m%s\033[0m\n" "" "OK"
		ph_mount_cifs_share PieHelper
		if [[ "$?" -eq 0 ]]
		then
			printf "%8s%s\n" "" "--> Creating timestamped backup of '$PH_BUILD_DIR/PieHelper-$PH_NEW_VERSION.tar' to '$OLD_PH_PIEH_CIFS_SRV:$OLD_PH_PIEH_CIFS_DIR$OLD_PH_PIEH_CIFS_SUBDIR'"
			cp -p "$PH_BUILD_DIR"/PieHelper-"$PH_NEW_VERSION".tar `eval echo -n "$OLD_PH_PIEH_CIFS_MPT"`/PieHelper-"$PH_NEW_VERSION"-`date +'%d%m%y-%Hh%M'`.tar 2>/dev/null
			if [[ "$?" -ne 0 ]]
			then
				PH_RESULT="PARTIALLY FAILED"
				printf "%10s\033[31m%s\033[0m\n" "" "ERROR : Could not create backup"
			else
				printf "%10s\033[32m%s\033[0m\n" "" "OK"
			fi
			ph_umount_cifs_share PieHelper 2>&1
		else
			PH_RESULT="PARTIALLY FAILED"
		fi
	else
		printf "%10s\033[32m%s\033[0m\n" "" "OK (None)"
	fi
	printf "%8s%s\n" "" "--> Restoring installed applications configuration file"
	mv /tmp/installed_apps_tmp "$PH_CONF_DIR"/installed_apps
	printf "%10s\033[32m%s\033[0m\n" "" "OK"
	printf "%8s%s\n" "" "--> Restoring supported applications configuration file" 
	mv /tmp/supported_apps_tmp "$PH_CONF_DIR"/supported_apps
	printf "%10s\033[32m%s\033[0m\n" "" "OK"
	printf "%8s%s\n" "" "--> Restoring controller ids' configuration file"
	mv /tmp/controller_cli_ids_tmp "$PH_CONF_DIR"/controller_cli_ids
	printf "%10s\033[32m%s\033[0m\n" "" "OK"
	printf "%8s%s\n" "" "--> Restoring OS configuration tool's configuration file"
	"$PH_SUDO" mv /tmp/OS.defaults_tmp "$PH_FILES_DIR"/OS.defaults
	printf "%10s\033[32m%s\033[0m\n" "" "OK"
	printf "%8s%s\n" "" "--> Removing first_run file in '$PH_FILES_DIR'"
	rm "$PH_FILES_DIR"/first_run 2>/dev/null
	printf "%10s\033[32m%s\033[0m\n" "" "OK"
	ph_restore_options
	for PH_i in `echo -n "$PH_ACL_USERS"`
	do
		printf "%8s%s\n" "" "--> Restoring ACLs for user '$PH_i'"
		if "$PH_SUDO" setfacl -R -m u:"$PH_i":rwx "$PH_SCRIPTS_DIR"/.. >/dev/null 2>&1
		then
			printf "%10s\033[32m%s\033[0m\n" "" "OK"
		else
			printf "%10s\033[31m%s\033[0m\n" "" "ERROR : Could not restore ACLs"
			PH_RESULT="PARTIALLY FAILED"
		fi
	done
	[[ "$PH_RESULT" == "SUCCESS" ]] && printf "%2s\033[32m%s\033[0m\n\n" "" "$PH_RESULT" || printf "%2s\033[31m%s\033[0m\n\n" "" "$PH_RESULT"
	unset PH_REVERSE
	exit 0
else
	(! confgenb_ph.sh -h) && unset PH_REVERSE && exit 1
fi
