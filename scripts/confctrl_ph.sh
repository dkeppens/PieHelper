#!/bin/ksh
# Display some minimal help about the required configuration steps for different controller types and connection methods (by Davy Keppens on 25/11/2018)
# Enable/Disable debug by running confpieh_ph.sh -d confctrl_ph.sh

. $(dirname $0)/../main/main.sh || exit $? && set +x

#set -x

typeset PH_ACTION=""
typeset PH_TYPE=""
typeset PH_CONN=""

while getopts hp:t:c: PH_OPTION 2>/dev/null
do
	case $PH_OPTION in p)
		ph_screen_input "$OPTARG" || exit $?
		[[ "$OPTARG" != "help" ]] && (! confctrl_ph.sh -h) && exit 1
		[[ -n "$PH_ACTION" ]] && (! confctrl_ph.sh -h) && exit 1
		PH_ACTION="$OPTARG" ;;
			   t)
		ph_screen_input "$OPTARG" || exit $?
		[[ "$OPTARG" != @(PS3|PS4|XBOX360) ]] && (! confctrl_ph.sh -h) && exit 1
		[[ -n "$PH_TYPE" ]] && (! confctrl_ph.sh -h) && exit 1
		PH_TYPE="$OPTARG" ;;
			   c)
		ph_screen_input "$OPTARG" || exit $?
		[[ "$OPTARG" != @(usb|bluetooth|xboxurec|sonywadapt) ]] && (! confctrl_ph.sh -h) && exit 1
		[[ -n "$PH_CONN" ]] && (! confctrl_ph.sh -h) && exit 1
		PH_CONN="$OPTARG" ;;
			   *)
		>&2 printf "%s\n" "Usage : confctrl_ph.sh -h |"
		>&2 printf "%23s%s\n" "" "-p \"help\" -t [ctrltype] -c [conntype]"
		>&2 printf "\n"
		>&2 printf "%3s%s\n" "" "Where -h displays this usage"
		>&2 printf "%9s%s\n" "" "-p specifies the action to take"
		>&2 printf "%12s%s\n" "" "\"help\" allows requesting the display of basic configuration information for controllers of type [ctrltype] using connection method [conntype]"
		>&2 printf "%15s%s\n" "" "-t allows selecting one of a list of supported controller types as value for [ctrltype]"
		>&2 printf "%18s%s\n" "" "- The currently supported controller types are \"PS3\", \"XBOX360\" and \"PS4\""
		>&2 printf "%15s%s\n" "" "-c allows selecting one of a list of known controller connection types as value for [conntype]"
		>&2 printf "%18s%s\n" "" "- The currently known controller connection types are \"usb\", \"bluetooth\", \"xboxurec\" (Xbox 360 USB Receiver) and \"sonywadapt\" (Sony Wireless Adapter)"
		>&2 printf "\n"
		exit 1 ;;
	esac
done
(([[ -z "$PH_CONN" || -z "$PH_TYPE" ]]) || ([[ -z "$PH_ACTION" ]])) && (! confctrl_ph.sh -h) && exit 1
[[ "$PH_CONN" == "sonywadapt" && "$PH_TYPE" != "PS4" ]] && (printf "%s\n" "- Displaying help for configuring $PH_TYPE $PH_CONN controllers" ; \
			printf "%2s%s\n" "" "ERROR : Sony Wireless Adapter is only supported for PS4 controllers") && exit 1 
[[ "$PH_CONN" == "xboxurec" && "$PH_TYPE" != "XBOX360" ]] && (printf "%s\n" "- Displaying help for configuring $PH_TYPE $PH_CONN controllers" ; \
			printf "%2s%s\n" "" "ERROR : Xbox 360 USB Receiver is only supported for XBOX360 controllers") && exit 1 
case $PH_ACTION in help)
	printf "%s\n" "- Displaying help for configuring $PH_TYPE $PH_CONN controllers"
	printf "%2s%s\n" "" "SUCCESS"
	printf "\n"
	ph_print_bannerline
	printf "\n"
	case $PH_CONN in usb)
			printf "%s\n" "- For $PH_CONN $PH_TYPE controllers, just plug your controller into one of the Raspberry Pi's usb ports"
			printf "%s\n" "  It should be configured automatically" ;;
		  sonywadapt)
			printf "%s\n" "- Plug your Sony Wireless Adapter into one of the Raspberry Pi's usb ports"
			printf "%s\n" "- Push the wireless adapter down and hold for 3-5 seconds to enable pairing mode for your adapter"
			printf "%s\n" "- Push in and hold the Playstation and share buttons on your $PH_TYPE controller simultaneously for 3-5 seconds to enable pairing mode for your controller"
			printf "%s\n" "  Your controller should now be paired" ;;
		    xboxurec)
			printf "%s\n" "- This help is currently unimplemented" ;;
		   bluetooth) 
			printf "%s\n" "- To connect your $PH_CONN $PH_TYPE controller you need a separate bluetooth adapter for all Raspberry Pi 2 revisions and older models"
			printf "%s\n" "  A list of compatible usb bluetooth adapters for Raspberry Pi 2 and older models can be found online"
			printf "%s\n" "  Plug your bluetooth adapter into one of the Raspberry Pi's usb ports"
			printf "%s\n" "  Raspberry Pi 3 and newer models have an on-board bluetooth adapter so there is no need for a separate one"
			[[ "$PH_TYPE" == "PS3" ]] && printf "%s\n" "- Start by connecting your $PH_TYPE controller using usb"
			printf "%s\n" "- Start a terminal or console window on your Raspberry Pi"
			printf "%s\n" "- Become root by typing 'sudo bash'"
			printf "%s\n" "- Enable the bluetooth service by typing 'systemctl enable bluetooth'"
			printf "%s\n" "- Start the bluetooth service by typing 'systemctl start bluetooth'"
			printf "%s\n" "- Start bluetooth control by typing 'bluetoothctl'"
			printf "%s\n" "- List your available bluetooth adapter(s) by typing 'list'"
			printf "%s\n" "- If you have multiple bluetooth adapters, select the one you wish to use by typing 'select XX:XX:XX:XX:XX:XX' where 'XX:XX:XX:XX:XX:XX' is the id of the adapter you wish to use"
			printf "%s\n" "- Power on your bluetooth adapter by typing 'power on'"
			printf "%s\n" "- Set your bluetooth adapter mode to discoverable by typing 'discoverable on'"
			printf "%s\n" "- Set your bluetooth adapter mode to pairable by typing 'pairable on'"
			printf "%s\n" "- Turn on the default bluetooth agent by typing 'agent on'"
			printf "%s\n" "- Enable scanning for bluetooth devices by typing 'scan on'"
			printf "%s\n" "- Turn on your $PH_TYPE controller"
			printf "%s\n" "- Disconnect your $PH_TYPE controller from the usb port if it was connected"
			printf "%s\n" "- List all devices visible to your adapter by typing 'devices'"
			printf "%s\n" "  You should see a list of available bluetooth devices and their corresponding ids"
			printf "%s\n" "  Note the id of the controller you wish to pair"
			printf "%s\n" "- Enable trust by typing 'trust XX:XX:XX:XX:XX:XX' where 'XX:XX:XX:XX:XX:XX' is the id of the controller you wish to pair"
			printf "%s\n" "- Connect to your controller by typing 'connect XX:XX:XX:XX:XX:XX' where 'XX:XX:XX:XX:XX:XX' is once again your controller id"
			printf "%s\n" "- Pair your controller by typing 'pair XX:XX:XX:XX:XX:XX' where 'XX:XX:XX:XX:XX:XX' is once again your controller id"
			printf "%s\n" "  The agent will ask for the bluetooth password"
			printf "%s\n" "  Reply with '0000'"
			printf "%s\n" "  Your controller should now be paired"
			printf "%s\n" "- Exit bluetooth control by typing 'quit'"
			printf "%s\n" "- Optionally quit your root session by typing 'exit'"
			printf "%s\n" "- Optionally quit your terminal or console window by typing 'exit'" ;;
	esac
	printf "\n"
	ph_print_bannerline
	printf "\n"
	exit 0 ;;
esac
confctrl_ph.sh -h || exit $?
