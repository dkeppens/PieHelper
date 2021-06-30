#!/bin/bash
# Display configuration steps for different combinations of controller types and connection methods
# or interactively configure bluetooth controllers (by Davy Keppens on 25/11/2018)
# Enable/Disable debug by running 'confpieh_ph.sh -p debug -m confctrl_ph.sh'

if [[ -r "$(dirname "${0}" 2>/dev/null)/main/main.sh" ]]
then
	if ! source "$(dirname "${0}" 2>/dev/null)/main/main.sh"
	then
		set +x
		>&2 printf "\n%2s\033[1;31m%s\033[0m\n\n" "" "ABORT : Reinstallation of PieHelper is required (Corrupted critical codebase file '$(dirname "${0}" 2>/dev/null)/main/main.sh'"
		exit 1
	fi
	set +x
else
	>&2 printf "\n%2s\033[1;31m%s\033[0m\n\n" "" "ABORT : Reinstallation of PieHelper is required (Missing or unreadable critical codebase file '$(dirname "${0}" 2>/dev/null)/main/main.sh'"
	exit 1
fi

#set -x

declare PH_i=""
declare PH_ALL_CTRL=""
declare PH_NEW_CTRL=""
declare PH_PAIRED_CTRL=""
declare PH_CONN_CTRL=""
declare PH_NUM_CTRL=""
declare PH_ADAPTER=""
declare PH_ACTION=""
declare PH_TYPE=""
declare PH_CONN=""
declare PH_PAIRED="no"
declare PH_TRUSTED=""
declare PH_OLDOPTARG="$OPTARG"
declare -i PH_OLDOPTIND="$OPTIND"
declare -i PH_COUNT="0"
declare -i PH_CONF_CTRL="0"

OPTIND="1"

while getopts hp:t:c:n: PH_OPTION 2>/dev/null
do
	case "$PH_OPTION" in p)
		! ph_screen_input "$OPTARG" && OPTARG="$PH_OLDOPTARG" && OPTIND="$PH_OLDOPTIND" && exit 1
		[[ "$OPTARG" != @(conf|help|prompt) ]] && (! confctrl_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND="$PH_OLDOPTIND" && exit 1
		[[ -n "$PH_ACTION" ]] && (! confctrl_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND="$PH_OLDOPTIND" && exit 1
		PH_ACTION="$OPTARG" ;;
			     t)
		! ph_screen_input "$OPTARG" && OPTARG="$PH_OLDOPTARG" && OPTIND="$PH_OLDOPTIND" && exit 1
		[[ "$OPTARG" != @(PS3|PS4|XBOX360) ]] && (! confctrl_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND="$PH_OLDOPTIND" && exit 1
		[[ -n "$PH_TYPE" ]] && (! confctrl_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND="$PH_OLDOPTIND" && exit 1
		PH_TYPE="$OPTARG" ;;
			     c)
		! ph_screen_input "$OPTARG" && OPTARG="$PH_OLDOPTARG" && OPTIND="$PH_OLDOPTIND" && exit 1
		[[ "$PH_ACTION" != @(help|) ]] && (! confctrl_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND="$PH_OLDOPTIND" && exit 1
		[[ "$OPTARG" != @(usb|bluetooth|xboxurecv|sonywadapt) ]] && (! confctrl_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND="$PH_OLDOPTIND" && exit 1
		[[ -n "$PH_CONN" ]] && (! confctrl_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND="$PH_OLDOPTIND" && exit 1
		PH_CONN="$OPTARG" ;;
			     n)
		! ph_screen_input "$OPTARG" && OPTARG="$PH_OLDOPTARG" && OPTIND="$PH_OLDOPTIND" && exit 1
		[[ "$PH_ACTION" != @(conf|) ]] && (! confctrl_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND="$PH_OLDOPTIND" && exit 1
		[[ -n "$PH_NUM_CTRL" ]] && (! confctrl_ph.sh -h) && OPTARG="$PH_OLDOPTARG" && OPTIND="$PH_OLDOPTIND" && exit 1
		PH_NUM_CTRL="$OPTARG" ;;
			     *)
		>&2 printf "\n"
		>&2 printf "\033[36m%s\033[0m\n" "Usage : confctrl_ph.sh -h |"
		>&2 printf "%23s\033[36m%s\033[0m\n" "" "-p \"conf\" -t [\"PS3\" '-n [numctrl]'|\"PS4\" '-n [numctrl]'] |"
		>&2 printf "%23s\033[36m%s\033[0m\n" "" "-p \"prompt\" -t [\"PS3\"|\"PS4\"] |"
		>&2 printf "%23s\033[36m%s\033[0m\n" "" "-p \"help\" -t [\"PS3\"|\"PS4\"|\"XBOX360\"] -c [\"usb\"|\"bluetooth\"|\"xboxurecv\"|\"sonywadapt\"]" 
		>&2 printf "\n"
		>&2 printf "%3s%s\n" "" "Where -h displays this usage"
		>&2 printf "%9s%s\n" "" "-p specifies the action to take"
		>&2 printf "%12s%s\n" "" "\"conf\" allows interactively configuring an amount of [numctrl] bluetooth controllers of the specified type"
		>&2 printf "%15s%s\n" "" "- This will only configure controllers on the OS level"
		>&2 printf "%15s%s\n" "" "  Most applications will still require some additional in-app configuration such as button mapping"
		>&2 printf "%15s%s\n" "" "-t allows selecting one of a list of supported controller types"
		>&2 printf "%18s%s\n" "" "- The currently supported controller types are \"PS3\" and \"PS4\""
		>&2 printf "%18s%s\n" "" "- Different controller types need to be configured separately"
		>&2 printf "%18s%s\n" "" "-n allows setting a numeric value for [numctrl] as the amount of controllers to configure of the type specified"
		>&2 printf "%21s%s\n" "" "- Configuration will fail if insufficient unconfigured controllers of the specified type are found"
		>&2 printf "%21s%s\n" "" "- Specifying -n is optional"
		>&2 printf "%24s%s\n" "" "- A value of 1 will be used if -n is not specified"
		>&2 printf "%12s%s\n" "" "\"prompt\" behaves as \"conf\" but will prompt for the value of [numctrl]"
		>&2 printf "%12s%s\n" "" "\"help\" allows displaying the manual configuration steps for controllers of the specified type and connection method"
		>&2 printf "%15s%s\n" "" "-t allows selecting one of a list of supported controller types"
		>&2 printf "%18s%s\n" "" "- The currently supported controller types are \"PS3\", \"PS4\" and \"XBOX360\""
		>&2 printf "%15s%s\n" "" "-c allows selecting one of a list of supported controller connection methods"
		>&2 printf "%18s%s\n" "" "- The currently supported controller connection methods are \"usb\", \"bluetooth\", \"xboxurecv\" (Xbox360 USB Receiver) and \"sonywadapt\" (Sony Wireless Adapter)"
		>&2 printf "%21s%s\n" "" "- connection method \"xboxurecv\" (Xbox360 USB Receiver) is only valid for XBOX360 controllers"
		>&2 printf "%21s%s\n" "" "- connection method \"bluetooth\" is only valid for PS3 or PS4 controllers"
		>&2 printf "%21s%s\n" "" "- connection method \"sonywadapt\" (Sony Wireless Adapter) is only valid for PS4 controllers"
		>&2 printf "\n"
		OPTIND="$PH_OLDOPTIND"
		OPTARG="$PH_OLDOPTARG"
		exit 1 ;;
	esac
done
OPTIND="$PH_OLDOPTIND"
OPTARG="$PH_OLDOPTARG"

[[ "$PH_ACTION" == @(conf|prompt) && -n "$PH_CONN" ]] && (! confctrl_ph.sh -h) && exit 1
[[ "$PH_ACTION" == @(conf|prompt) ]] && PH_CONN="bluetooth"
(([[ -z "$PH_CONN" || -z "$PH_TYPE" ]]) || ([[ -z "$PH_ACTION" ]])) && (! confctrl_ph.sh -h) && exit 1
[[ -n "$PH_NUM_CTRL" && "$PH_ACTION" != "conf" ]] && (! confctrl_ph.sh -h) && exit 1
[[ -z "$PH_NUM_CTRL" && "$PH_ACTION" != "prompt" ]] && PH_NUM_CTRL="1"
[[ "$PH_NUM_CTRL" != @([1-9]|+([1-9])+([0-9])) && "$PH_ACTION" != "prompt" ]] && (printf "%s\n" "- Configuring a '$PH_CONN' '$PH_TYPE' controller" ; >&2 printf "%2s\033[31m%s\033[0m%s\n\n" "" "FAILED" " : Not a numeric value" ; return 0) && exit 1
[[ "$PH_TYPE" == "XBOX360" && "$PH_CONN" != @(usb|xboxurecv) ]] && (printf "%s\n" "- Displaying help for configuring '$PH_CONN' '$PH_TYPE' controllers" ; \
			>&2 printf "%2s\033[31m%s\033[0m%s\n\n" "" "FAILED" " : Unsupported connection method") && exit 1 
[[ "$PH_TYPE" == "PS3" && "$PH_CONN" == @(xboxurecv|sonywadapt) ]] && (printf "%s\n" "- Displaying help for configuring '$PH_CONN' '$PH_TYPE' controllers" ; \
			>&2 printf "%2s\033[31m%s\033[0m%s\n\n" "" "FAILED" " : Unsupported connection method") && exit 1 
[[ "$PH_TYPE" == "PS4" && "$PH_CONN" == "xboxurecv" ]] && (printf "%s\n" "- Displaying help for configuring '$PH_CONN' '$PH_TYPE' controllers" ; \
			>&2 printf "%2s\033[31m%s\033[0m%s\n\n" "" "FAILED" " : Unsupported connection method") && exit 1 
case "$PH_ACTION" in help)
	printf "\033[36m%s\033[0m\n" "- Displaying configuration steps for '$PH_CONN' '$PH_TYPE' controllers"
	[[ "$PH_RESULT" == "SUCCESS" ]] && printf "%2s%s\n\n" "" "$PH_RESULT" || printf "%2s\033[31m%s\033[0m\n\n" "" "$PH_RESULT"
	ph_print_bannerline
	printf "\n"
	case $PH_CONN in usb)
			printf "%s\n" "- For $PH_CONN $PH_TYPE controllers, just plug each controller you wish to configure into one of the Raspberry Pi's usb ports"
			printf "%s\n" "  The controller(s) should now be configured" ;;
		  sonywadapt)
			printf "%s\n" "- If there is a $PH_TYPE console nearby, unplug it now to avoid the console automatically pairing with the controller"
			printf "%s\n" "- Plug the Sony Wireless Adapter into one of the Raspberry Pi's usb ports"
			printf "%s\n" "  A Wireless Adapter can pair only one controller"
			printf "%s\n" "- Push the Wireless Adapter down and hold for 3-5 seconds to enable pairing mode for the adapter"
			printf "%s\n" "- Put the $PH_TYPE controller in pairing mode by holding down the Playstation and Share buttons simultaneously for 3-5 seconds"
			printf "%s\n" "  The controller should now be configured"
			printf "%s\n" "- Repeat steps 2-4 for each additional controller you wish to configure" ;;
		   xboxurecv)
			printf "%s\n" "- If there is a $PH_TYPE console nearby, unplug it now to avoid the console automatically pairing with the controller"
			printf "%s\n" "- Plug the Xbox360 USB Receiver into one of the Raspberry Pi's usb ports"
			printf "%s\n" "  Multiple controllers can be connected to just one USB Receiver"
			printf "%s\n" "- Turn on the $PH_TYPE controller by holding down the Guide button"
			printf "%s\n" "- Press the connect button on the receiver"
			printf "%s\n" "- Press the connect button on top of the controller"
			printf "%s\n" "  Your controller should now be configured"
			printf "%s\n" "- Repeat steps 3-5 for each additional controller you wish to configure" ;;
		   bluetooth) 
			printf "%s\n" "- For a $PH_CONN $PH_TYPE controller, a separate bluetooth adapter is required for all Raspberry Pi 2 revisions and older models"
			printf "%s\n" "  A list of compatible usb bluetooth adapters for Raspberry Pi 2 and older models can be found online"
			printf "%s\n" "  Raspberry Pi 3 and newer models have an on-board bluetooth adapter so there is no need for a separate one"
			printf "%s\n" "  If a separate adapter is required, plug it into one of the Raspberry Pi's usb ports now"
			printf "%s\n" "  Multiple controllers can be paired to just one bluetooth adapter"
			printf "%s\n" "- If there is a $PH_TYPE console nearby, unplug it now to avoid the console automatically pairing with the controller"
			printf "%s\n" "- Start a terminal or console window on your Raspberry Pi"
			printf "%s\n" "- Become root by typing 'sudo bash'"
			printf "%s\n" "- Enable the bluetooth service by typing 'systemctl enable bluetooth'"
			printf "%s\n" "- Start the bluetooth service by typing 'systemctl start bluetooth'"
			printf "%s\n" "- Start bluetooth control by typing 'bluetoothctl'"
			printf "%s\n" "- List the available bluetooth adapter(s) by typing 'list'"
			printf "%s\n" "- In case of multiple bluetooth adapters being present, select the one to use by typing 'select XX:XX:XX:XX:XX:XX' where 'XX:XX:XX:XX:XX:XX' is the id of the adapter you wish to use"
			printf "%s\n" "- Make sure the adapter is enabled by typing 'power on'"
			printf "%s\n" "- Set the bluetooth adapter mode to pairable by typing 'pairable on'"
			printf "%s\n" "- Enable scanning for bluetooth devices by typing 'scan on'"
			case $PH_TYPE in PS3)
				printf "%s\n" "- Enable the bluetooth agent by typing 'agent on'" 
				printf "%s\n" "- Connect the $PH_TYPE controller to the Raspberry Pi with a usb cable"
				printf "%s\n" "- Turn on the $PH_TYPE controller" ;;
					 PS4)
				printf "%s\n" "- Put the $PH_TYPE controller in pairing mode by holding down the Playstation and Share buttons simultaneously for 3-5 seconds" ;;
			esac
			printf "%s\n" "- List all bluetooth devices visible to the selected adapter by typing 'devices'"
			printf "%s\n" "  A list of available bluetooth devices and their corresponding ids will be shown"
			printf "%s\n" "  Note the id of the controller you wish to configure"
			[[ "$PH_TYPE" == "PS3" ]] && printf "%s\n" "- Disconnect the $PH_TYPE controller from the Raspberry Pi's usb port"
			printf "%s\n" "- Display the controller status by typing 'info XX:XX:XX:XX:XX:XX' where 'XX:XX:XX:XX:XX:XX' is the id of the controller you wish to configure"
			printf "%s\n" "- If the controller status was 'Paired: no' then pair the controller by typing 'pair XX:XX:XX:XX:XX:XX' where 'XX:XX:XX:XX:XX:XX' is once again the controller id"
			printf "%s\n" "- Connect to the controller by typing 'connect XX:XX:XX:XX:XX:XX' where 'XX:XX:XX:XX:XX:XX' is once again the controller id"
			[[ "$PH_TYPE" == "PS3" ]] && (printf "%s\n" "  The agent will ask for the bluetooth password" ; \
			printf "%s\n" "  Reply with the default password token (Usually '0000' or '1111')")
			printf "%s\n" "  The controller should now be configured"
			case $PH_TYPE in PS3)
				printf "%s\n" "- Repeat steps 14-20 for each additional controller you wish to configure" ;;
					 PS4)
				printf "%s\n" "- Repeat steps 13-17 for each additional controller you wish to configure" ;;
			esac
			printf "%s\n" "- Exit bluetooth control by typing 'quit'"
			printf "%s\n" "- Optionally quit the root session by typing 'exit'"
			printf "%s\n" "- Optionally quit the terminal or console window by typing 'exit'" ;;
	esac
	printf "%s\n" "- Reminder : Some applications (e.g. Emulationstation and Kodi) will still require additional controller configuration such as button mapping when started"
	printf "\n"
	ph_print_bannerline
	printf "\n"
	exit 0 ;;
		 prompt)
	printf "%s\n" "- Using interactive mode"
	while [[ $PH_NUM_CTRL == "" ]]
	do
		[[ $PH_COUNT -gt 0 ]] && >&2 printf "\n%10s\033[31m%s\033[0m%s\n\n" "" "ERROR" " : Invalid response"
		printf "%8s%s" "" "--> Please enter the number of $PH_TYPE controllers you want to configure (empty defaults to '1') : "
		read PH_NUM_CTRL >/dev/null 2>&1
		[[ -z "$PH_NUM_CTRL" ]] && PH_NUM_CTRL="1"
		[[ "$PH_NUM_CTRL" != @([1-9]|+([1-9])+([0-9])) ]] && PH_NUM_CTRL=""
		((PH_COUNT++))
	done
	printf "%10s%s\n" "" "OK"
	[[ "$PH_RESULT" == "SUCCESS" ]] && printf "%2s%s\n\n" "" "$PH_RESULT" || printf "%2s\033[31m%s\033[0m\n\n" "" "$PH_RESULT"
	$PH_SCRIPTS_DIR/confctrl_ph.sh -p conf -t "$PH_TYPE" -n "$PH_NUM_CTRL"
	exit $? ;;
	           conf)
	printf "%s\n" "- Configuring $PH_CONN $PH_TYPE controller(s)"
	printf "%8s%s\n" "" "--> Displaying initially required manual actions"
	printf "%10s%s\n" "" "OK"
	printf "\n"
	ph_print_bannerline
	printf "\n"
	printf "%s\n" "- For $PH_CONN $PH_TYPE controllers, a separate bluetooth adapter is required for all Raspberry Pi 2 revisions and older models"
	printf "%s\n" "  A list of compatible usb bluetooth adapters for Raspberry Pi 2 and older models can be found online"
	printf "%s\n" "  Raspberry Pi 3 and newer models have an on-board bluetooth adapter so there is no need for a separate one"
	printf "%s\n" "  If a separate adapter is required, plug it into one of the Raspberry Pi's usb ports now"
	printf "%s\n" "  Multiple controllers can be paired to just one adapter"
	printf "%s\n" "  In case of multiple adapters, the default can be changed with confopts_ph.sh or the PieHelper menu"
	printf "%s\n" "- If there is a $PH_TYPE console nearby, unplug it now to avoid the console automatically pairing with the controller(s)"
	printf "\n"
	ph_print_bannerline
	printf "\n"
	printf "%8s%s" "" "--> Press Enter when ready"
	read >/dev/null 2>&1
	printf "%10s%s\n" "" "OK"
## handle possibly different bluetooth service on newest model Pi here and in other places
	if ! systemctl is-enabled bluetooth >/dev/null 2>&1
	then
		printf "%8s%s\n" "" "--> Enabling bluetooth service"
		$PH_SUDO systemctl enable bluetooth >/dev/null 2>&1 && printf "%10s%s\n" "" "OK" || \
			(>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not enable bluetooth service" ; >&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" ; return 1) || \
			 return $?
	fi
	if ! systemctl is-active bluetooth >/dev/null 2>&1
	then
		printf "%8s%s\n" "" "--> Starting bluetooth service"
		$PH_SUDO systemctl start bluetooth >/dev/null 2>&1 && printf "%10s%s\n" "" "OK" || \
			(>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not start bluetooth service" ; >&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" ; return 1) || \
			 return $?
	fi
        printf "%8s%s\n" "" "--> Detecting $PH_CONN adapter(s)"
        if [[ "$PH_CONT_BLUE_ADAPT" == "none" ]]
        then
                PH_ADAPTER=`$PH_SCRIPTS_DIR/listblue_ph.sh | tail -n +5 | nawk '$0 !~ /SUCCESS/ { print $1 ; exit 0 }'`
                [[ -z "$PH_ADAPTER" ]] && (>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Not found" ; \
                                                        >&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" ; return 0) && exit 1
                printf "%10s%s\n" "" "OK (Using first available : $PH_ADAPTER) -> Setting as default"
                ph_set_option_to_value Ctrls -r "PH_CONT_BLUE_ADAPT'$PH_ADAPTER" || \
                                (>&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" ; return 1) || exit $?
        else
                printf "%10s%s\n" "" "OK (Using default : $PH_CONT_BLUE_ADAPT)"
        fi
        for PH_i in Powered Pairable
        do
                printf "%8s%s\n" "" "--> Enabling bluetooth adapter \"$PH_i\" mode"
                $PH_SUDO bt-adapter -a "$PH_CONT_BLUE_ADAPT" -s "$PH_i" 1 >/dev/null 2>&1 && printf "%10s%s\n" "" "OK" || \
						(>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not enable $PH_i mode" ; \
						 >&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" ; return 1) || \
						 exit $?
        done
	if ! pgrep bt-adapter >/dev/null 2>&1
	then
        	printf "%8s%s\n" "" "--> Enabling bluetooth discovery mode"
		("$PH_SUDO" bt-adapter -d &) >/dev/null 2>&1
		sleep 3
		if ! pgrep bt-adapter >/dev/null 2>&1
		then
			>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not start bluetooth discovery mode"
			>&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED"
			exit 1
		fi
		printf "%10s%s\n" "" "OK"
	fi
	printf "%8s%s\n" "" "--> Displaying additionally required manual action"
	printf "%10s%s\n" "" "OK"
	printf "\n"
	ph_print_bannerline
	printf "\n"
	case $PH_TYPE in PS3)
		printf "%s\n" "- Connect each $PH_TYPE controller to configure to the Raspberry Pi with a usb cable"
		printf "%s\n" "- Turn on each $PH_TYPE controller you wish to configure"
		printf "%s\n" "- Disconnect all $PH_TYPE controllers from the Raspberry Pi" ;;
			 PS4)
		printf "%s\n" "- Put the $PH_TYPE controller(s) in pairing mode by holding down the Playstation and Share buttons simultaneously for 3-5 seconds"
		printf "%s\n" "  on each controller you wish to configure" ;;
	esac
	printf "\n"
	ph_print_bannerline
	printf "\n"
	printf "%8s%s" "" "--> Press Enter when ready"
	read >/dev/null 2>&1
	printf "%10s%s\n" "" "OK"
        printf "%8s%s\n" "" "--> Checking for bluetooth devices"
	sleep 3
        PH_ALL_CTRL=`$PH_SUDO bt-device -a "$PH_CONT_BLUE_ADAPT" -l 2>/dev/null | nawk -F'\(' 'BEGIN { ORS = " " } $0 ~ /No devices found/ { print "none" ; exit 0 } \
                                                        $0 ~ /PLAYSTATION\(R\)3 Controller/ { print "PS3:" substr($NF,1,length($NF)-1) }
                                                        $0 ~ /Wireless Controller/ { print "PS4:" substr($NF,1,length($NF)-1) } { next }'`
	[[ "$PH_ALL_CTRL" == "none" ]] && (>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Not found" ; >&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" ; return 0) && exit 1 
        for PH_i in `echo -n "$PH_ALL_CTRL"`
        do
		$PH_SUDO bt-device -a "$PH_CONT_BLUE_ADAPT" -i "${PH_i#*:}" 2>/dev/null | nawk '$0 ~ /Paired:/ { exit $2 } { next }'
		if [[ $? -ne 0 ]]
		then
			$PH_SUDO bt-device -a "$PH_CONT_BLUE_ADAPT" -i "${PH_i#*:}" 2>/dev/null | nawk '$0 ~ /Connected:/ { exit $2 } { next }'
			if [[ $? -ne 0 ]]
			then
				printf "%10s%s\n" "" "(Found connected ${PH_i%%:*} controller : ${PH_i#*:})"
				if [[ "$PH_TYPE" == "${PH_i%%:*}" ]]
				then
					[[ -z "$PH_CONN_CTRL" ]] && PH_CONN_CTRL="${PH_i#*:}" || PH_CONN_CTRL="$PH_CONN_CTRL ${PH_i#*:}"
				fi
			else
				printf "%10s%s\n" "" "(Found paired ${PH_i%%:*} controller : ${PH_i#*:})"
				if [[ "$PH_TYPE" == "${PH_i%%:*}" ]]
				then
					((PH_COUNT++))
					[[ -z "$PH_PAIRED_CTRL" ]] && PH_PAIRED_CTRL="${PH_i#*:}" || PH_PAIRED_CTRL="$PH_PAIRED_CTRL ${PH_i#*:}"
				fi
			fi
		else
			printf "%10s%s\n" "" "(Found new ${PH_i%%:*} controller : ${PH_i#*:})"
			if [[ "$PH_TYPE" == "${PH_i%%:*}" ]]
			then
				((PH_COUNT++))
				[[ -z "$PH_NEW_CTRL" ]] && PH_NEW_CTRL="${PH_i#*:}" || PH_NEW_CTRL="$PH_NEW_CTRL ${PH_i#*:}"
			fi
		fi
	done
	printf "%10s%s\n" "" "OK"
	printf "%8s%s\n" "" "--> Verifying $PH_TYPE controller count"
	[[ $PH_COUNT -lt $PH_NUM_CTRL ]] && (>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Insufficient number of unconfigured $PH_TYPE controllers found" ; \
				>&2 printf "%2s\033[31m%s\033[0m\n\n" "" "FAILED" ; return 0) && exit 1
	printf "%10s%s\n" "" "OK"
	PH_CONF_CTRL=$((PH_COUNT-`echo $PH_NUM_CTRL`))
	while [[ $PH_COUNT -gt $PH_CONF_CTRL ]]
	do
		for PH_i in `echo -n "$PH_NEW_CTRL"`
		do
			printf "%8s%s\n" "" "--> Checking for existing trust for controller ($PH_i)"
			$PH_SUDO bt-device -a "$PH_CONT_BLUE_ADAPT" -i "$PH_i" 2>/dev/null | nawk '$0 ~ /Trusted:/ { exit $2 } { next }'
			if [[ $? -ne 0 ]]
			then
				printf "%10s%s\n" "" "OK (Trusted)"
				PH_TRUSTED="yes"
			else
				printf "%10s%s\n" "" "OK (Not trusted)"
				PH_TRUSTED="no"
			fi
			echo "$PH_PAIRED_CTRL" | grep "$PH_i" >/dev/null 2>&1 && PH_PAIRED="yes" || PH_PAIRED="no"
			printf "%8s%s\n" "" "--> Connecting to $PH_TYPE controller ($PH_i)"
			declare -n PH_CTRL_PIN=PH_CONT_"$PH_TYPE"_PIN
			"$PH_SUDO" "${PH_SCRIPTS_DIR}/expect/cfgctrls.expect" "$PH_CONT_BLUE_ADAPT" "$PH_i" "$PH_PAIRED" "$PH_TRUSTED" ${PH_CTRL_PIN} >/dev/null 2>&1
			if [[ "$?" -eq "0" ]]
			then
				printf "%10s%s\n" "" "OK"
				((PH_COUNT--))
				[[ "$PH_RESULT" != "SUCCESS" ]] && PH_RESULT="PARTIALLY FAILED"
				PH_NEW_CTRL=`sed 's/ '$PH_i' //;s/ '$PH_i'//;s/'$PH_i' //;s/'$PH_i'//g' <<<$PH_NEW_CTRL`
			else
				>&2 printf "%10s\033[31m%s\033[0m%s\n" "" "ERROR" " : Could not connect to controller $PH_i"
				[[ $PH_NUM_CTRL -eq 1 && "${PH_RESULT}" == "SUCCESS" ]] && PH_RESULT="FAILED" || PH_RESULT="PARTIALLY FAILED"
			fi
			unset -n PH_CTRL_PIN
			[[ $PH_COUNT -eq $PH_CONF_CTRL ]] && break 2
		done
		[[ "$PH_PAIRED" == "yes" ]] && break
		PH_NEW_CTRL="$PH_PAIRED_CTRL"
		PH_PAIRED="yes"
	done
	printf "%8s%s\n" "" "--> Cleaning up"
	$PH_SUDO pkill -9 bt-adapter 2>/dev/null
	printf "%10s%s\n" "" "OK"
	printf "%8s%s\n" "" "--> Displaying reminder"
	printf "%10s%s\n" "" "OK"
	printf "\n"
	ph_print_bannerline
	printf "\n"
	printf "%s\n" "- Reminder : Some applications (e.g. Emulationstation and Kodi) will still require additional controller configuration such as button mapping when started"
	printf "%s\n" "- Additional controller types can be configured by re-running this script"
	printf "\n"
	ph_print_bannerline
	printf "\n"
	[[ "$PH_RESULT" == "SUCCESS" ]] && printf "%2s%s\n\n" "" "$PH_RESULT" || printf "%2s\033[31m%s\033[0m\n\n" "" "$PH_RESULT"
	exit 0 ;;
esac
confctrl_ph.sh -h || exit $?
