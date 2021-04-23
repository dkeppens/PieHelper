# PieHelper PRE-command script to run before PieHelper startup
# by Davy Keppens on 04/10/2018
#

#set -x

declare PH_FAILED="no"

printf "%8s%s\n" "" "--> Checking for 'PieHelper' PRE-command CIFS mount requirement"
ph_set_result -r 0
if [[ "$PH_PIEH_CIFS_SHARE" == "yes" ]]
then
	printf "%10s\033[32m%s\033[0m\n" "" "OK (Yes)"
        printf "%8s%s\n" "" "--> Checking for 'PieHelper' PRE-command CIFS mount presence"
	ph_set_result -r 0
        mount 2>/dev/null | nawk -v rempath=^"//$PH_PIEH_CIFS_SRV$(eval echo -n "$PH_PIEH_CIFS_DIR""$PH_PIEH_CIFS_SUBDIR")"$ -F' on ' '$1 ~ rempath { exit 1 }'
        if [[ "$?" -eq "1" ]]
        then
                printf "%10s\033[32m%s\033[0m\n" "" "OK (Found) -> Restoring OS configuration defaults"
		printf "%8s%s%s%s\n" "" "--> Restoring 'OS.defaults' backup to '" "$PH_FILES_DIR" "/'"
		ph_set_result -r 0
		if [[ -s "$(eval echo -n "$PH_PIEH_CIFS_MPT")"/OS.defaults ]]
		then
			cp -p "$(eval echo -n "$PH_PIEH_CIFS_MPT")"/OS.defaults "$PH_FILES_DIR"/ 2>/dev/null
			if [[ "$?" -ne "0" ]]
			then
				printf "%10s\033[33m%s\033[0m\n" "" "Warning : Could not restore backup"
				PH_FAILED="yes"
			else
				printf "%10s\033[32m%s\033[0m\n" "" "OK"
			fi
		else
			printf "%10s\033[33m%s\033[0m\n" "" "Warning : Backup not found -> Skipping"
		fi
	else
		printf "%10s\033[33m%s\033[0m\n" "" "Warning : CIFS mount '//$PH_PIEH_CIFS_SRV$(eval echo -n "$PH_PIEH_CIFS_DIR""$PH_PIEH_CIFS_SUBDIR")' presence on mountpoint '$(eval echo -n "$PH_PIEH_CIFS_MPT")' is mandatory for 'PieHelper' PRE-command -> Skipping"
	fi
else
	printf "%10s\033[33m%s\033[0m\n" "" "Warning : CIFS is mandatory for 'PieHelper' PRE-command -> Skipping"
fi
[[ "$PH_FAILED" == "yes" ]] && return 1 || return 0
