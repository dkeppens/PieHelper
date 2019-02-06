# PieHelper POST-command script to run after PieHelper shutdown
# by Davy Keppens on 04/10/2018
#

#set -x

typeset PH_z=""

printf "%8s%s\n" "" "--> Creating backup of stored defaults for OS configuration functions"
if [[ "$PH_PIEH_CIFS_SHARE" == "yes" ]]
then
	if [[ -s $PH_SCRIPTS_DIR/../files/OS.defaults ]]
	then
		$PH_SUDO -E `which cp` -p $PH_SCRIPTS_DIR/../files/OS.defaults `eval echo -n "$PH_PIEH_CIFS_MPT"`
		if [[ $? -ne 0 ]]
		then
			printf "%10s%s\n" "" "Warning : Could not succesfully create stored defaults backup"
			PH_z="NOK"
		else
			printf "%10s%s\n" "" "OK"
		fi
	else
		printf "%10s%s\n" "" "Warning : No defaults currently stored"
	fi
else
	printf "%10s%s\n" "" "Warning : Dependent on CIFS -> Skipping"
fi
[[ "$PH_z" == "NOK" ]] && return 1 || return 0
