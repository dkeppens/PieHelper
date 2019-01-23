# PieHelper PRE-command script to run before PieHelper startup
# by Davy Keppens on 04/10/2018
#

#set -x

printf "%8s%s\n" "" "--> Restoring last backup of stored defaults for OS configuration functions"
if [[ "$PH_PIEH_CIFS_SHARE" == "yes" ]]
then
	if [[ -s "`eval echo -n \"$PH_PIEH_CIFS_MPT\"/OS.defaults`" ]]
	then
		$PH_SUDO -E `which cp` -p "`eval echo -n \"$PH_PIEH_CIFS_MPT\"/OS.defaults`" `eval echo -n "$PH_SCRIPTS_DIR"/../files`
		if [[ $? -ne 0 ]]
		then
			printf "%10s%s\n" "" "Warning : Could not succesfully restore stored defaults backup"
			PH_i="NOK"
		else
			printf "%10s%s\n" "" "OK"
		fi
	else
		printf "%10s%s\n" "" "Warning : Not found"
	fi
else
	printf "%10s%s\n" "" "Warning : Dependent on CIFS -> Skipping"
fi
[[ "$PH_i" == "NOK" ]] && return 1 || return 0
