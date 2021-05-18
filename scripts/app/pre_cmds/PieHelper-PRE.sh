# PieHelper PRE-command script which runs before PieHelper startup
#
# - Will check if a valid System Settings backup file called 'OS.defaults' exists in the CIFS-mounted directory defined by option PH_PIEH_CIFS_MPT
#   The user for PieHelper will require priorly configured read/write permissions for the remote share
# - Will attempt to copy the file to the '/conf' subdirectory of the PieHelper application directory
# - Will attempt to set proper ownership and permissions of the restored file
# - Will replace a previously existing file with the same name on success for all or restore it in case of failure for any
#
# @Davy Keppens on 04/10/2018
#

#set -x

declare PH_PIEH_LOC_DIR
declare PH_PIEH_REM_DIR

PH_PIEH_LOC_DIR="$(ph_get_app_cifs_mpt -a PieHelper -r)"
PH_PIEH_REM_DIR="$(eval "echo -n ${PH_PIEH_CIFS_DIR}${PH_PIEH_CIFS_SUBDIR}")"

printf "%8s%s\n" "" "--> Checking for PieHelper PRE-command prerequisite : CIFS configured"
if [[ "$PH_PIEH_CIFS_SHARE" == "yes" ]]
then
	ph_run_with_rollback -c true -m Yes
	printf "%8s%s\n" "" "--> Checking for PieHelper PRE-command prerequisite : CIFS mounted"
       	if [[ "$(mount 2>/dev/null | nawk -v rempath="^//${PH_PIEH_CIFS_SRV}${PH_PIEH_REM_DIR}$" -F' on ' '$1 ~ rempath { \
			printf "%s", "yes" ; \
			exit \
		} { \
			next \
		}')" == "yes" ]]
       	then
		ph_run_with_rollback -c true -m Yes
		printf "%8s%s\n" "" "--> Checking for PieHelper PRE-command prerequisite : Accessible backup"
		if [[ -r "${PH_PIEH_LOC_DIR}/OS.defaults" ]]
		then
			ph_run_with_rollback -c true -m Yes
			printf "%8s%s\n" "" "--> Checking for PieHelper PRE-command prerequisite : Valid backup"
			if [[ -s "${PH_PIEH_LOC_DIR}/OS.defaults" ]]
			then
				ph_run_with_rollback -c true -m Yes
				printf "%8s%s\n" "" "--> Restoring CIFS backup '${PH_PIEH_LOC_DIR}/OS.defaults' as '${PH_CONF_DIR}/OS.defaults'"
				if [[ -f "${PH_CONF_DIR}/OS.defaults" ]]
				then
					if ! mv "${PH_CONF_DIR}/OS.defaults" "${PH_TMP_DIR}/OS.defaults_tmp" 2>/dev/null
					then
						printf "%10s\033[33m%s\033[0m\n" "" "Warning : Could not store '${PH_CONF_DIR}/OS.defaults' as '${PH_TMP_DIR}/OS.defaults_tmp' -> Skipping"
						ph_set_result -r 0
						unset PH_PIEH_LOC_DIR PH_PIEH_REM_DIR
						return 1
					fi
				fi
				if cp "${PH_PIEH_LOC_DIR}/OS.defaults" "${PH_CONF_DIR}/" 2>/dev/null
				then
					if ph_secure_pieh -q -f "${PH_CONF_DIR}/OS.defaults" 2>/dev/null
					then
						"$PH_SUDO" rm "${PH_TMP_DIR}/OS.defaults_tmp" 2>/dev/null
						unset PH_PIEH_LOC_DIR PH_PIEH_REM_DIR
						ph_run_with_rollback -c true && \
							return "$?"
					else
						printf "%10s\033[33m%s\033[0m\n" "" "Warning : Could not set ownership of '${PH_CONF_DIR}/OS.defaults' to '${PH_APP_USER}:$(id -gn 2>/dev/null)' -> Skipping"
						PH_RESULT_MSG=""
					fi
				else
					printf "%10s\033[33m%s\033[0m\n" "" "Warning : Could not copy '${PH_PIEH_LOC_DIR}/OS.defaults' to '${PH_CONF_DIR}/' -> Skipping"
				fi
				mv "${PH_TMP_DIR}/OS.defaults_tmp" "${PH_CONF_DIR}/OS.defaults" 2>/dev/null
			else
				printf "%10s\033[33m%s\033[0m\n" "" "Warning : '${PH_PIEH_LOC_DIR}/OS.defaults' is not a valid System Settings backup -> Skipping" 
			fi
		else
			printf "%10s\033[33m%s\033[0m\n" "" "Warning : Could not access '${PH_PIEH_LOC_DIR}/OS.defaults' -> Skipping" 
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
