# PieHelper POST-command script which runs after PieHelper shutdown
#
# - Will check if a System Settings file called 'OS.defaults' exists in the '/conf' subdirectory of the PieHelper application directory
# - Will attempt to create a backup copy on the CIFS-mountpoint defined by option PH_PIEH_CIFS_MPT
#   The user for PieHelper will require priorly configured read/write permissions for the remote share
# - Will replace a file with the same name on success or restore it in case of failure
#
# @Davy Keppens on 04/10/2018
#

#set -x

declare PH_PIEH_LOC_DIR=""
declare PH_PIEH_REM_DIR=""

PH_PIEH_LOC_DIR="$(ph_get_app_cifs_mpt -a PieHelper -r)"
PH_PIEH_REM_DIR="$(eval "echo -n ${PH_PIEH_CIFS_DIR}${PH_PIEH_CIFS_SUBDIR}")"
printf "%8s%s\n" "" "--> Checking for PieHelper POST-command prerequisite : CIFS configured"
if [[ "$PH_PIEH_CIFS_SHARE" == "yes" ]]
then
	ph_run_with_rollback -c true -m Yes
        printf "%8s%s\n" "" "--> Checking for PieHelper POST-command prerequisite : CIFS mounted"
	if [[ "$(mount 2>/dev/null | nawk -v rempath="^//${PH_PIEH_CIFS_SRV}${PH_PIEH_REM_DIR}$" -F' on ' '$1 ~ rempath { \
			printf "%s", "yes" ; \
			exit \
		} { \
			next \
		}')" == "yes" ]]
	then
		printf "%8s%s\n" "" "--> Checking for PieHelper POST-command prerequisite : Accessible System Settings"
		if [[ -f "${PH_CONF_DIR}/OS.defaults" ]]
		then
			ph_run_with_rollback -c true -m Yes
			printf "%8s%s\n" "" "--> Creating CIFS backup of System Settings file '${PH_CONF_DIR}/OS.defaults' as '${PH_PIEH_LOC_DIR}/OS.defaults'"
			if [[ -f "${PH_PIEH_LOC_DIR}/OS.defaults" ]]
			then
				if ! mv "${PH_PIEH_LOC_DIR}/OS.defaults" "${PH_TMP_DIR}/OS.defaults_tmp" 2>/dev/nul
				then
					printf "%10s\033[33m%s\033[0m\n" "" "Warning : Could not store '${PH_PIEH_LOC_DIR}/OS.defaults' as '${PH_TMP_DIR}/OS.defaults_tmp' -> Skipping"
					ph_set_result -r 0
					unset PH_PIEH_LOC_DIR PH_PIEH_REM_DIR
					return 1
				fi
			fi
			if cp "${PH_CONF_DIR}/OS.defaults" "${PH_PIEH_LOC_DIR}/" 2>/dev/null
			then
				"$PH_SUDO" rm "${PH_TMP_DIR}/OS.defaults_tmp" 2>/dev/null
				unset PH_PIEH_LOC_DIR PH_PIEH_REM_DIR
				ph_run_with_rollback -c true -m "${PH_PIEH_LOC_DIR}/OS.defaults" && \
					return "$?"
			else
				printf "%10s\033[33m%s\033[0m\n" "" "Warning : Could not backup '${PH_CONF_DIR}/OS.defaults' to '${PH_PIEH_LOC_DIR}/' -> Skipping"
			fi
			mv "${PH_TMP_DIR}/OS.defaults_tmp" "${PH_PIEH_LOC_DIR}/" 2>/dev/null
		else
			printf "%10s\033[33m%s\033[0m\n" "" "Warning : Could not access '${PH_CONF_DIR}/OS.defaults' -> Skipping" 
		fi
	else
		printf "%10s\033[33m%s\033[0m\n" "" "Warning : No -> Skipping" 
	fi
else
	printf "%10s\033[33m%s\033[0m\n" "" "Warning : No -> Skipping" 
fi
ph_set_result -r 0
unset PH_PIEH_LOC_DIR PH_PIEH_REM_DIR
return 1
